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

@class PRESCrashManager;
@class PRESAttachment;

/**
 The `PRESCrashManagerDelegate` formal protocol defines methods further configuring
 the behaviour of `PRESCrashManager`.
 */

@protocol PRESCrashManagerDelegate <NSObject>

@optional


///-----------------------------------------------------------------------------
/// @name Additional meta data
///-----------------------------------------------------------------------------

/** Return any log string based data the crash report being processed should contain
 
 @param crashManager The `PRESCrashManager` instance invoking this delegate
 @see attachmentForCrashManager:
 @see PRESManagerDelegate userNameForHockeyManager:componentManager:
 @see PRESManagerDelegate userEmailForHockeyManager:componentManager:
 */
-(NSString *)applicationLogForCrashManager:(PRESCrashManager *)crashManager;


/** Return a PRESAttachment object providing an NSData object the crash report
 being processed should contain
 
 Please limit your attachments to reasonable files to avoid high traffic costs for your users.
 
 Example implementation:
 
 - (PRESAttachment *)attachmentForCrashManager:(PRESCrashManager *)crashManager {
 NSData *data = [NSData dataWithContentsOfURL:@"mydatafile"];
 
 PRESAttachment *attachment = [[PRESAttachment alloc] initWithFilename:@"myfile.data"
 hockeyAttachmentData:data
 contentType:@"'application/octet-stream"];
 return attachment;
 }
 
 @param crashManager The `PRESCrashManager` instance invoking this delegate
 @see PRESAttachment
 @see applicationLogForCrashManager:
 @see PRESManagerDelegate userNameForHockeyManager:componentManager:
 @see PRESManagerDelegate userEmailForHockeyManager:componentManager:
 */
-(PRESAttachment *)attachmentForCrashManager:(PRESCrashManager *)crashManager;



///-----------------------------------------------------------------------------
/// @name Alert
///-----------------------------------------------------------------------------

/** Invoked before the user is asked to send a crash report, so you can do additional actions.
 E.g. to make sure not to ask the user for an app rating :)
 
 @param crashManager The `PRESCrashManager` instance invoking this delegate
 */
-(void)crashManagerWillShowSubmitCrashReportAlert:(PRESCrashManager *)crashManager;


/** Invoked after the user did choose _NOT_ to send a crash in the alert
 
 @param crashManager The `PRESCrashManager` instance invoking this delegate
 */
-(void)crashManagerWillCancelSendingCrashReport:(PRESCrashManager *)crashManager;


/** Invoked after the user did choose to send crashes always in the alert
 
 @param crashManager The `PRESCrashManager` instance invoking this delegate
 */
-(void)crashManagerWillSendCrashReportsAlways:(PRESCrashManager *)crashManager;


///-----------------------------------------------------------------------------
/// @name Networking
///-----------------------------------------------------------------------------

/** Invoked right before sending crash reports will start
 
 @param crashManager The `PRESCrashManager` instance invoking this delegate
 */
- (void)crashManagerWillSendCrashReport:(PRESCrashManager *)crashManager;

/** Invoked after sending crash reports failed
 
 @param crashManager The `PRESCrashManager` instance invoking this delegate
 @param error The error returned from the NSURLConnection/NSURLSession call or `kPRESCrashErrorDomain`
 with reason of type `PRESCrashErrorReason`.
 */
- (void)crashManager:(PRESCrashManager *)crashManager didFailWithError:(NSError *)error;

/** Invoked after sending crash reports succeeded
 
 @param crashManager The `PRESCrashManager` instance invoking this delegate
 */
- (void)crashManagerDidFinishSendingCrashReport:(PRESCrashManager *)crashManager;

///-----------------------------------------------------------------------------
/// @name Experimental
///-----------------------------------------------------------------------------

/** Define if a report should be considered as a crash report
 
 Due to the risk, that these reports may be false positives, this delegates allows the
 developer to influence which reports detected by the heuristic should actually be reported.
 
 The developer can use the following property to get more information about the crash scenario:
 - `[PRESCrashManager didReceiveMemoryWarningInLastSession]`: Did the app receive a low memory warning
 
 This allows only reports to be considered where at least one low memory warning notification was
 received by the app to reduce to possibility of having false positives.
 
 @param crashManager The `PRESCrashManager` instance invoking this delegate
 @return `YES` if the heuristic based detected report should be reported, otherwise `NO`
 @see `[PRESCrashManager didReceiveMemoryWarningInLastSession]`
 */
-(BOOL)considerAppNotTerminatedCleanlyReportForCrashManager:(PRESCrashManager *)crashManager;

@end
