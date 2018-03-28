//
//  PREDSwizzle.m
//  PRED
//
//  Created by Daniel Griesser on 31/05/2017.
//  Copyright © 2017 PRED. All rights reserved.
//  Original implementation by Yan Rabovik on 05.09.13 https://github.com/rabovik/RSSwizzle


#if __has_include(<PRED/PRED.h>)

#import <PRED/PREDSwizzle.h>

#else

#import "PREDSwizzle.h"

#endif

#import <objc/runtime.h>
#include <pthread.h>

#pragma mark - Swizzling

#pragma mark └ PREDSwizzleInfo

typedef IMP (^PREDSwizzleImpProvider)(void);

@interface PREDSwizzleInfo ()
@property(nonatomic, copy) PREDSwizzleImpProvider impProviderBlock;
@property(nonatomic, readwrite) SEL selector;
@end

@implementation PREDSwizzleInfo

- (PREDSwizzleOriginalIMP)getOriginalImplementation {
    NSAssert(_impProviderBlock, nil);
    // Casting IMP to PREDSwizzleOriginalIMP to force user casting.
    return (PREDSwizzleOriginalIMP) _impProviderBlock();
}

@end


#pragma mark └ PREDSwizzle

@implementation PREDSwizzle

static void swizzle(Class classToSwizzle,
        SEL selector,
        PREDSwizzleImpFactoryBlock factoryBlock) {
    Method method = class_getInstanceMethod(classToSwizzle, selector);

    NSCAssert(NULL != method,
            @"Selector %@ not found in %@ methods of class %@.",
            NSStringFromSelector(selector),
            class_isMetaClass(classToSwizzle) ? @"class" : @"instance",
            classToSwizzle);

    static pthread_mutex_t gLock = PTHREAD_MUTEX_INITIALIZER;

    // To keep things thread-safe, we fill in the originalIMP later,
    // with the result of the class_replaceMethod call below.
    __block IMP originalIMP = NULL;

    // This block will be called by the client to get original implementation and call it.
    PREDSwizzleImpProvider originalImpProvider = ^IMP {
        // It's possible that another thread can call the method between the call to
        // class_replaceMethod and its return value being set.
        // So to be sure originalIMP has the right value, we need a lock.

        pthread_mutex_lock(&gLock);

        IMP imp = originalIMP;

        pthread_mutex_unlock(&gLock);

        if (NULL == imp) {
            // If the class does not implement the method
            // we need to find an implementation in one of the superclasses.
            Class superclass = class_getSuperclass(classToSwizzle);
            imp = method_getImplementation(class_getInstanceMethod(superclass, selector));
        }

        return imp;
    };

    PREDSwizzleInfo *swizzleInfo = [PREDSwizzleInfo new];
    swizzleInfo.selector = selector;
    swizzleInfo.impProviderBlock = originalImpProvider;

    // We ask the client for the new implementation block.
    // We pass swizzleInfo as an argument to factory block, so the client can
    // call original implementation from the new implementation.
    id newIMPBlock = factoryBlock(swizzleInfo);

    const char *methodType = method_getTypeEncoding(method);

    IMP newIMP = imp_implementationWithBlock(newIMPBlock);

    // Atomically replace the original method with our new implementation.
    // This will ensure that if someone else's code on another thread is messing
    // with the class' method list too, we always have a valid method at all times.
    //
    // If the class does not implement the method itself then
    // class_replaceMethod returns NULL and superclasses's implementation will be used.
    //
    // We need a lock to be sure that originalIMP has the right value in the
    // originalImpProvider block above.

    pthread_mutex_lock(&gLock);

    originalIMP = class_replaceMethod(classToSwizzle, selector, newIMP, methodType);

    pthread_mutex_unlock(&gLock);
}


static NSMutableDictionary *swizzledClassesDictionary() {
    static NSMutableDictionary *swizzledClasses;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        swizzledClasses = [NSMutableDictionary new];
    });
    return swizzledClasses;
}

static NSMutableSet *swizzledClassesForKey(const void *key) {
    NSMutableDictionary *classesDictionary = swizzledClassesDictionary();
    NSValue *keyValue = [NSValue valueWithPointer:key];
    NSMutableSet *swizzledClasses = classesDictionary[keyValue];
    if (!swizzledClasses) {
        swizzledClasses = [NSMutableSet new];
        classesDictionary[keyValue] = swizzledClasses;
    }
    return swizzledClasses;
}

+ (BOOL)swizzleInstanceMethod:(SEL)selector
                      inClass:(Class)classToSwizzle
                newImpFactory:(PREDSwizzleImpFactoryBlock)factoryBlock
                         mode:(PREDSwizzleMode)mode
                          key:(const void *)key {
    NSAssert(!(NULL == key && PREDSwizzleModeAlways != mode),
            @"Key may not be NULL if mode is not PREDSwizzleModeAlways.");

    @synchronized (swizzledClassesDictionary()) {
        if (key) {
            NSSet *swizzledClasses = swizzledClassesForKey(key);
            if (mode == PREDSwizzleModeOncePerClass) {
                if ([swizzledClasses containsObject:classToSwizzle]) {
                    return NO;
                }
            } else if (mode == PREDSwizzleModeOncePerClassAndSuperclasses) {
                for (Class currentClass = classToSwizzle;
                     nil != currentClass;
                     currentClass = class_getSuperclass(currentClass)) {
                    if ([swizzledClasses containsObject:currentClass]) {
                        return NO;
                    }
                }
            }
        }

        swizzle(classToSwizzle, selector, factoryBlock);

        if (key) {
            [swizzledClassesForKey(key) addObject:classToSwizzle];
        }
    }

    return YES;
}

+ (void)swizzleClassMethod:(SEL)selector
                   inClass:(Class)classToSwizzle
             newImpFactory:(PREDSwizzleImpFactoryBlock)factoryBlock {
    [self swizzleInstanceMethod:selector
                        inClass:object_getClass(classToSwizzle)
                  newImpFactory:factoryBlock
                           mode:PREDSwizzleModeAlways
                            key:NULL];
}

@end
