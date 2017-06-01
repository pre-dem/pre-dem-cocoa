/*
 * Author: Gwynne Raskind <gwraskin@microsoft.com>
 *
 * Copyright (c) 2015 HockeyApp, Bit Stadium GmbH.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#import "PreSniffObjc.h"
#import "PRESCrashCXXExceptionHandler.h"
#import <vector>
#import <cxxabi.h>
#import <exception>
#import <stdexcept>
#import <typeinfo>
#import <string>
#import <pthread.h>
#import <dlfcn.h>
#import <execinfo.h>
#import <libkern/OSAtomic.h>

typedef std::vector<PRESCrashUncaughtCXXExceptionHandler> PRESCrashUncaughtCXXExceptionHandlerList;
typedef struct
{
    void *exception_object;
    uintptr_t call_stack[128];
    uint32_t num_frames;
} PRESCrashCXXExceptionTSInfo;

static bool _PRESCrashIsOurTerminateHandlerInstalled = false;
static std::terminate_handler _PRESCrashOriginalTerminateHandler = nullptr;
static PRESCrashUncaughtCXXExceptionHandlerList _PRESCrashUncaughtExceptionHandlerList;
static OSSpinLock _PRESCrashCXXExceptionHandlingLock = OS_SPINLOCK_INIT;
static pthread_key_t _PRESCrashCXXExceptionInfoTSDKey = 0;

@implementation PRESCrashUncaughtCXXExceptionHandlerManager

extern "C" void LIBCXXABI_NORETURN __cxa_throw(void *exception_object, std::type_info *tinfo, void (*dest)(void *))
{
    // Purposely do not take a lock in this function. The aim is to be as fast as
    // possible. While we could really use some of the info set up by the real
    // __cxa_throw, if we call through we never get control back - the function is
    // noreturn and jumps to landing pads. Most of the stuff in __cxxabiv1 also
    // won't work yet. We therefore have to do these checks by hand.
    
    // The technique for distinguishing Objective-C exceptions is based on the
    // implementation of objc_exception_throw(). It's weird, but it's fast. The
    // explicit symbol load and NULL checks should guard against the
    // implementation changing in a future version. (Or not existing in an earlier
    // version).
    
    typedef void (*cxa_throw_func)(void *, std::type_info *, void (*)(void *)) LIBCXXABI_NORETURN;
    static dispatch_once_t predicate = 0;
    static cxa_throw_func __original__cxa_throw = nullptr;
    static const void **__real_objc_ehtype_vtable = nullptr;
    
    dispatch_once(&predicate, ^ {
        __original__cxa_throw = reinterpret_cast<cxa_throw_func>(dlsym(RTLD_NEXT, "__cxa_throw"));
        __real_objc_ehtype_vtable = reinterpret_cast<const void **>(dlsym(RTLD_DEFAULT, "objc_ehtype_vtable"));
    });
    
    // Actually check for Objective-C exceptions.
    if (tinfo && __real_objc_ehtype_vtable && // Guard from an ABI change
        *reinterpret_cast<void **>(tinfo) == __real_objc_ehtype_vtable + 2) {
        goto callthrough;
    }
    
    // Any other exception that came here has to be C++, since Objective-C is the
    // only (known) runtime that hijacks the C++ ABI this way. We need to save off
    // a backtrace.
    // Invariant: If the terminate handler is installed, the TSD key must also be
    // initialized.
    if (_PRESCrashIsOurTerminateHandlerInstalled) {
        PRESCrashCXXExceptionTSInfo *info = static_cast<PRESCrashCXXExceptionTSInfo *>(pthread_getspecific(_PRESCrashCXXExceptionInfoTSDKey));
        
        if (!info) {
            info = reinterpret_cast<PRESCrashCXXExceptionTSInfo *>(calloc(1, sizeof(PRESCrashCXXExceptionTSInfo)));
            pthread_setspecific(_PRESCrashCXXExceptionInfoTSDKey, info);
        }
        info->exception_object = exception_object;
        // XXX: All significant time in this call is spent right here.
        info->num_frames = backtrace(reinterpret_cast<void **>(&info->call_stack[0]), sizeof(info->call_stack) / sizeof(info->call_stack[0]));
    }
    
callthrough:
    if (__original__cxa_throw) {
        __original__cxa_throw(exception_object, tinfo, dest);
    } else {
        abort();
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
    __builtin_unreachable();
#pragma clang diagnostic pop
}

__attribute__((always_inline))
static inline void PRESCrashIterateExceptionHandlers_unlocked(const PRESCrashUncaughtCXXExceptionInfo &info)
{
    for (const auto &handler : _PRESCrashUncaughtExceptionHandlerList) {
        handler(&info);
    }
}

static void PRESCrashUncaughtCXXTerminateHandler(void)
{
    PRESCrashUncaughtCXXExceptionInfo info = {
        .exception = nullptr,
        .exception_type_name = nullptr,
        .exception_message = nullptr,
        .exception_frames_count = 0,
        .exception_frames = nullptr,
    };
    auto p = std::current_exception();
    
    OSSpinLockLock(&_PRESCrashCXXExceptionHandlingLock); {
        if (p) { // explicit operator bool
            info.exception = reinterpret_cast<const void *>(&p);
            info.exception_type_name = __cxxabiv1::__cxa_current_exception_type()->name();
            
            PRESCrashCXXExceptionTSInfo *recorded_info = reinterpret_cast<PRESCrashCXXExceptionTSInfo *>(pthread_getspecific(_PRESCrashCXXExceptionInfoTSDKey));
            
            if (recorded_info) {
                info.exception_frames_count = recorded_info->num_frames - 1;
                info.exception_frames = &recorded_info->call_stack[1];
            } else {
                // There's no backtrace, grab this function's trace instead. Probably
                // means the exception came from a dynamically loaded library.
                void *frames[128] = { nullptr };
                
                info.exception_frames_count = backtrace(&frames[0], sizeof(frames) / sizeof(frames[0])) - 1;
                info.exception_frames = reinterpret_cast<uintptr_t *>(&frames[1]);
            }
            
            try {
                std::rethrow_exception(p);
            } catch (const std::exception &e) { // C++ exception.
                info.exception_message = e.what();
                PRESCrashIterateExceptionHandlers_unlocked(info);
            } catch (const std::exception *e) { // C++ exception by pointer.
                info.exception_message = e->what();
                PRESCrashIterateExceptionHandlers_unlocked(info);
            } catch (const std::string &e) { // C++ string as exception.
                info.exception_message = e.c_str();
                PRESCrashIterateExceptionHandlers_unlocked(info);
            } catch (const std::string *e) { // C++ string pointer as exception.
                info.exception_message = e->c_str();
                PRESCrashIterateExceptionHandlers_unlocked(info);
            } catch (const char *e) { // Plain string as exception.
                info.exception_message = e;
                PRESCrashIterateExceptionHandlers_unlocked(info);
            } catch (id e) { // Objective-C exception. Pass it on to Foundation.
                OSSpinLockUnlock(&_PRESCrashCXXExceptionHandlingLock);
                if (_PRESCrashOriginalTerminateHandler != nullptr) {
                    _PRESCrashOriginalTerminateHandler();
                }
                return;
            } catch (...) { // Any other kind of exception. No message.
                PRESCrashIterateExceptionHandlers_unlocked(info);
            }
        }
    } OSSpinLockUnlock(&_PRESCrashCXXExceptionHandlingLock); // In case terminate is called reentrantly by pasing it on
    
    if (_PRESCrashOriginalTerminateHandler != nullptr) {
        _PRESCrashOriginalTerminateHandler();
    } else {
        abort();
    }
}

+ (void)addCXXExceptionHandler:(PRESCrashUncaughtCXXExceptionHandler)handler
{
    static dispatch_once_t key_predicate = 0;
    
    // This only EVER has to be done once, since we don't delete the TSD later
    // (there's no reason to delete it).
    dispatch_once(&key_predicate, ^ {
        pthread_key_create(&_PRESCrashCXXExceptionInfoTSDKey, free);
    });
    
    OSSpinLockLock(&_PRESCrashCXXExceptionHandlingLock); {
        if (!_PRESCrashIsOurTerminateHandlerInstalled) {
            _PRESCrashOriginalTerminateHandler = std::set_terminate(PRESCrashUncaughtCXXTerminateHandler);
            _PRESCrashIsOurTerminateHandlerInstalled = true;
        }
        _PRESCrashUncaughtExceptionHandlerList.push_back(handler);
    } OSSpinLockUnlock(&_PRESCrashCXXExceptionHandlingLock);
}

+ (void)removeCXXExceptionHandler:(PRESCrashUncaughtCXXExceptionHandler)handler
{
    OSSpinLockLock(&_PRESCrashCXXExceptionHandlingLock); {
        auto i = std::find(_PRESCrashUncaughtExceptionHandlerList.begin(), _PRESCrashUncaughtExceptionHandlerList.end(), handler);
        
        if (i != _PRESCrashUncaughtExceptionHandlerList.end()) {
            _PRESCrashUncaughtExceptionHandlerList.erase(i);
        }
        
        if (_PRESCrashIsOurTerminateHandlerInstalled) {
            if (_PRESCrashUncaughtExceptionHandlerList.empty()) {
                std::terminate_handler previous_handler = std::set_terminate(_PRESCrashOriginalTerminateHandler);
                
                if (previous_handler != PRESCrashUncaughtCXXTerminateHandler) {
                    std::set_terminate(previous_handler);
                } else {
                    _PRESCrashIsOurTerminateHandlerInstalled = false;
                    _PRESCrashOriginalTerminateHandler = nullptr;
                }
            }
        }
    } OSSpinLockUnlock(&_PRESCrashCXXExceptionHandlingLock);
}

@end
