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
 * EXPREDS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#import <Foundation/Foundation.h>
#import "PREDCrashManagerDelegate.h"

@class PREDManager;
@class PREDBaseManager;

/**
 The `PREDManagerDelegate` formal protocol defines methods further configuring
 the behaviour of `PREDManager`, as well as the delegate of the modules it manages.
 */

@protocol PREDManagerDelegate
<
NSObject,
PREDCrashManagerDelegate
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
 
 - (BOOL)shouldUseLiveIdentifierForPREDManager:(PREDManager *)PREDManager {
 #ifdef (CONFIGURATION_AppStore)
 return YES;
 #endif
 return NO;
 }
 
 @param PREDManager PREDManager instance
 */
- (BOOL)shouldUseLiveIdentifierForPREDManager:(PREDManager *)PREDManager;


///-----------------------------------------------------------------------------
/// @name UI presentation
///-----------------------------------------------------------------------------


///-----------------------------------------------------------------------------
/// @name Additional meta data
///-----------------------------------------------------------------------------


/** Return the userid that should used in the SDK components
 
 Right now this is used by the `PREDCrashManager` to attach to a crash report.
 
 You can find out the component requesting the userID like this:
 
 - (NSString *)userIDForPREDManager:(PREDManager *)PREDManager componentManager:(PREDBaseManager *)componentManager {
 if (componentManager == PREDManager.feedbackManager) {
 return UserIDForFeedback;
 } else if (componentManager == PREDManager.crashManager) {
 return UserIDForCrashReports;
 } else {
 return nil;
 }
 }
 
 For crash reports, this delegate is invoked on the startup after the crash!
 
 Alternatively you can also use `[PREDManager userID]` which will cache the value in the keychain.
 
 @warning When returning a non nil value for the `PREDCrashManager` component, crash reports
 are not anonymous any more and the crash alerts will not show the word "anonymous"!
 
 @param PREDManager The `PREDManager` PREDManager instance invoking this delegate
 @param componentManager The `PREDBaseManager` component instance invoking this delegate, can be `PREDCrashManager`
 @see userNameForPREDManager:componentManager:
 @see userEmailForPREDManager:componentManager:
 @see [PREDManager userID]
 */
- (NSString *)userIDForPREDManager:(PREDManager *)PREDManager componentManager:(PREDBaseManager *)componentManager;


/** Return the user name that should used in the SDK components
 
 Right now this is used by the `PREDCrashManager` to attach to a crash report.
 
 You can find out the component requesting the user name like this:
 
 - (NSString *)userNameForPREDManager:(PREDManager *)PREDManager componentManager:(PREDBaseManager *)componentManager {
 if (componentManager == PREDManager.feedbackManager) {
 return UserNameForFeedback;
 } else if (componentManager == PREDManager.crashManager) {
 return UserNameForCrashReports;
 } else {
 return nil;
 }
 }
 
 For crash reports, this delegate is invoked on the startup after the crash!
 
 Alternatively you can also use `[PREDManager userName]` which will cache the value in the keychain.
 
 @warning When returning a non nil value for the `PREDCrashManager` component, crash reports
 are not anonymous any more and the crash alerts will not show the word "anonymous"!
 
 @param PREDManager The `PREDManager` PREDManager instance invoking this delegate
 @param componentManager The `PREDBaseManager` component instance invoking this delegate, can be `PREDCrashManager`
 @see userIDForPREDManager:componentManager:
 @see userEmailForPREDManager:componentManager:
 @see [PREDManager userName]
 */
- (NSString *)userNameForPREDManager:(PREDManager *)PREDManager componentManager:(PREDBaseManager *)componentManager;


/** Return the users email address that should used in the SDK components
 
 Right now this is used by the `PREDCrashManager` to attach to a crash report.
 
 You can find out the component requesting the user email like this:
 
 - (NSString *)userEmailForPREDManager:(PREDManager *)PREDManager componentManager:(PREDBaseManager *)componentManager {
 if (componentManager == PREDManager.feedbackManager) {
 return UserEmailForFeedback;
 } else if (componentManager == PREDManager.crashManager) {
 return UserEmailForCrashReports;
 } else {
 return nil;
 }
 }
 
 For crash reports, this delegate is invoked on the startup after the crash!
 
 Alternatively you can also use `[PREDManager userEmail]` which will cache the value in the keychain.
 
 @warning When returning a non nil value for the `PREDCrashManager` component, crash reports
 are not anonymous any more and the crash alerts will not show the word "anonymous"!
 
 @param PREDManager The `PREDManager` PREDManager instance invoking this delegate
 @param componentManager The `PREDBaseManager` component instance invoking this delegate, can be `PREDCrashManager`
 @see userIDForPREDManager:componentManager:
 @see userNameForPREDManager:componentManager:
 @see [PREDManager userEmail]
 */
- (NSString *)userEmailForPREDManager:(PREDManager *)PREDManager componentManager:(PREDBaseManager *)componentManager;

@end
