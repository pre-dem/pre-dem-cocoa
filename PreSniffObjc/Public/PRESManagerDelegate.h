/*
 * Author: Andreas Linde <mail@andreaslinde.de>
 *
 * Copyright (c) 2012-2014 HockeyApp, Bit Stadium GmbH.
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

#import <Foundation/Foundation.h>
#import "PRESCrashManagerDelegate.h"

@class PRESManager;
@class PRESBaseManager;

/**
 The `PRESManagerDelegate` formal protocol defines methods further configuring
 the behaviour of `PRESManager`, as well as the delegate of the modules it manages.
 */

@protocol PRESManagerDelegate
<
NSObject,
PRESCrashManagerDelegate
>

@optional


///-----------------------------------------------------------------------------
/// @name App Identifier usage
///-----------------------------------------------------------------------------

/**
 Implement to force the usage of the live identifier
 
 This is useful if you are e.g. distributing an enterprise app inside your company
 and want to use the `liveIdentifier` for that even though it is not running from
 the App Store.
 
 Example:
 
 - (BOOL)shouldUseLiveIdentifierForPRESManager:(PRESManager *)PRESManager {
 #ifdef (CONFIGURATION_AppStore)
 return YES;
 #endif
 return NO;
 }
 
 @param PRESManager PRESManager instance
 */
- (BOOL)shouldUseLiveIdentifierForPRESManager:(PRESManager *)PRESManager;


///-----------------------------------------------------------------------------
/// @name UI presentation
///-----------------------------------------------------------------------------


///-----------------------------------------------------------------------------
/// @name Additional meta data
///-----------------------------------------------------------------------------


/** Return the userid that should used in the SDK components
 
 Right now this is used by the `PRESCrashManager` to attach to a crash report.
 
 You can find out the component requesting the userID like this:
 
 - (NSString *)userIDForPRESManager:(PRESManager *)PRESManager componentManager:(PRESBaseManager *)componentManager {
 if (componentManager == PRESManager.feedbackManager) {
 return UserIDForFeedback;
 } else if (componentManager == PRESManager.crashManager) {
 return UserIDForCrashReports;
 } else {
 return nil;
 }
 }
 
 For crash reports, this delegate is invoked on the startup after the crash!
 
 Alternatively you can also use `[PRESManager userID]` which will cache the value in the keychain.
 
 @warning When returning a non nil value for the `PRESCrashManager` component, crash reports
 are not anonymous any more and the crash alerts will not show the word "anonymous"!
 
 @param PRESManager The `PRESManager` PRESManager instance invoking this delegate
 @param componentManager The `PRESBaseManager` component instance invoking this delegate, can be `PRESCrashManager`
 @see userNameForPRESManager:componentManager:
 @see userEmailForPRESManager:componentManager:
 @see [PRESManager userID]
 */
- (NSString *)userIDForPRESManager:(PRESManager *)PRESManager componentManager:(PRESBaseManager *)componentManager;


/** Return the user name that should used in the SDK components
 
 Right now this is used by the `PRESCrashManager` to attach to a crash report.
 
 You can find out the component requesting the user name like this:
 
 - (NSString *)userNameForPRESManager:(PRESManager *)PRESManager componentManager:(PRESBaseManager *)componentManager {
 if (componentManager == PRESManager.feedbackManager) {
 return UserNameForFeedback;
 } else if (componentManager == PRESManager.crashManager) {
 return UserNameForCrashReports;
 } else {
 return nil;
 }
 }
 
 For crash reports, this delegate is invoked on the startup after the crash!
 
 Alternatively you can also use `[PRESManager userName]` which will cache the value in the keychain.
 
 @warning When returning a non nil value for the `PRESCrashManager` component, crash reports
 are not anonymous any more and the crash alerts will not show the word "anonymous"!
 
 @param PRESManager The `PRESManager` PRESManager instance invoking this delegate
 @param componentManager The `PRESBaseManager` component instance invoking this delegate, can be `PRESCrashManager`
 @see userIDForPRESManager:componentManager:
 @see userEmailForPRESManager:componentManager:
 @see [PRESManager userName]
 */
- (NSString *)userNameForPRESManager:(PRESManager *)PRESManager componentManager:(PRESBaseManager *)componentManager;


/** Return the users email address that should used in the SDK components
 
 Right now this is used by the `PRESCrashManager` to attach to a crash report.
 
 You can find out the component requesting the user email like this:
 
 - (NSString *)userEmailForPRESManager:(PRESManager *)PRESManager componentManager:(PRESBaseManager *)componentManager {
 if (componentManager == PRESManager.feedbackManager) {
 return UserEmailForFeedback;
 } else if (componentManager == PRESManager.crashManager) {
 return UserEmailForCrashReports;
 } else {
 return nil;
 }
 }
 
 For crash reports, this delegate is invoked on the startup after the crash!
 
 Alternatively you can also use `[PRESManager userEmail]` which will cache the value in the keychain.
 
 @warning When returning a non nil value for the `PRESCrashManager` component, crash reports
 are not anonymous any more and the crash alerts will not show the word "anonymous"!
 
 @param PRESManager The `PRESManager` PRESManager instance invoking this delegate
 @param componentManager The `PRESBaseManager` component instance invoking this delegate, can be `PRESCrashManager`
 @see userIDForPRESManager:componentManager:
 @see userNameForPRESManager:componentManager:
 @see [PRESManager userEmail]
 */
- (NSString *)userEmailForPRESManager:(PRESManager *)PRESManager componentManager:(PRESBaseManager *)componentManager;

@end
