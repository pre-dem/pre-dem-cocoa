/*
 * Author: Andreas Linde <mail@andreaslinde.de>
 *
 * Copyright (c) 2013-2014 HockeyApp, Bit Stadium GmbH.
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
 * EXPREDS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */


#import "PreDemObjc.h"
#import <CrashReporter/CrashReporter.h>

#import "PREDCrashManager.h"

@class PREDNetworkClient;
@class PREDAttachment;

@interface PREDCrashManager () {
}


///-----------------------------------------------------------------------------
/// @name Delegate
///-----------------------------------------------------------------------------

/**
 Sets the optional `PREDCrashManagerDelegate` delegate.
 
 The delegate is automatically set by using `[PREDManager setDelegate:]`. You
 should not need to set this delegate individually.
 
 @see `[PREDManager setDelegate:]`
 */
@property (nonatomic, weak) id delegate;

/**
 * must be set
 */
@property (nonatomic, strong) PREDNetworkClient *hockeyAppClient;

@property (nonatomic) NSUncaughtExceptionHandler *exceptionHandler;

@property (nonatomic, strong) NSFileManager *fileManager;

@property (nonatomic, strong) PREPLCrashReporter *plCrashReporter;

@property (nonatomic) NSString *lastCrashFilename;

@property (nonatomic, copy, setter = setAlertViewHandler:) PREDCustomAlertViewHandler alertViewHandler;

@property (nonatomic, strong) NSString *crashesDir;

- (instancetype)initWithAppIdentifier:(NSString *)appIdentifier appEnvironment:(PREDEnvironment)environment hockeyAppClient:(PREDNetworkClient *)hockeyAppClient NS_DESIGNATED_INITIALIZER;

- (void)cleanCrashReports;

- (NSString *)userIDForCrashReport;
- (NSString *)userEmailForCrashReport;
- (NSString *)userNameForCrashReport;

- (void)handleCrashReport;
- (BOOL)hasPendingCrashReport;
- (NSString *)firstNotApprovedCrashReport;

- (BOOL)persistAttachment:(PREDAttachment *)attachment withFilename:(NSString *)filename;

- (PREDAttachment *)attachmentForCrashReport:(NSString *)filename;

- (void)invokeDelayedProcessing;
- (void)sendNextCrashReport;

- (void)setLastCrashFilename:(NSString *)lastCrashFilename;

- (void)leavingAppSafely;

@end
