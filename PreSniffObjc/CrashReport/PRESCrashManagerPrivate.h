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
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */


#import "PreSniffObjc.h"
#import <CrashReporter/CrashReporter.h>

@class PRESNetworkClient;

@interface PRESCrashManager () {
}


///-----------------------------------------------------------------------------
/// @name Delegate
///-----------------------------------------------------------------------------

/**
 Sets the optional `PRESCrashManagerDelegate` delegate.
 
 The delegate is automatically set by using `[PreSniffManager setDelegate:]`. You
 should not need to set this delegate individually.
 
 @see `[PreSniffManager setDelegate:]`
 */
@property (nonatomic, weak) id delegate;

/**
 * must be set
 */
@property (nonatomic, strong) PRESNetworkClient *hockeyAppClient;

@property (nonatomic) NSUncaughtExceptionHandler *exceptionHandler;

@property (nonatomic, strong) NSFileManager *fileManager;

@property (nonatomic, strong) BITPLCrashReporter *plCrashReporter;

@property (nonatomic) NSString *lastCrashFilename;

@property (nonatomic, copy, setter = setAlertViewHandler:) PRESCustomAlertViewHandler alertViewHandler;

@property (nonatomic, strong) NSString *crashesDir;

- (instancetype)initWithAppIdentifier:(NSString *)appIdentifier appEnvironment:(PRESEnvironment)environment hockeyAppClient:(PRESNetworkClient *)hockeyAppClient NS_DESIGNATED_INITIALIZER;

- (void)cleanCrashReports;

- (NSString *)userIDForCrashReport;
- (NSString *)userEmailForCrashReport;
- (NSString *)userNameForCrashReport;

- (void)handleCrashReport;
- (BOOL)hasPendingCrashReport;
- (NSString *)firstNotApprovedCrashReport;

- (void)persistUserProvidedMetaData:(PRESCrashMetaData *)userProvidedMetaData;
- (BOOL)persistAttachment:(PRESAttachment *)attachment withFilename:(NSString *)filename;

- (PRESAttachment *)attachmentForCrashReport:(NSString *)filename;

- (void)invokeDelayedProcessing;
- (void)sendNextCrashReport;

- (void)setLastCrashFilename:(NSString *)lastCrashFilename;

- (void)leavingAppSafely;

@end
