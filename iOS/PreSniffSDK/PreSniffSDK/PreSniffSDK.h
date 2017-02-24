//
//  PreSniffSDK.h
//  PreSniffSDK
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for PreSniffSDK.
FOUNDATION_EXPORT double PreSniffSDKVersionNumber;

//! Project version string for PreSniffSDK.
FOUNDATION_EXPORT const unsigned char PreSniffSDKVersionString[];

#if !defined (TARGET_OS_IOS) // Defined starting in iOS 9
#define TARGET_OS_IOS 1
#endif


#import "PreSniffSDKFeatureConfig.h"
#import "PreSniffSDKEnums.h"
#import "PreSniffSDKNullability.h"

#import "PreSniffManager.h"
#import "PreSniffManagerDelegate.h"

#if HOCKEYSDK_FEATURE_CRASH_REPORTER || HOCKEYSDK_FEATURE_FEEDBACK
#import "PRESAttachment.h"
#endif

#if HOCKEYSDK_FEATURE_CRASH_REPORTER
#import "PRESCrashManager.h"
#import "PRESCrashManagerDelegate.h"
#import "PRESCrashDetails.h"
#import "PRESCrashMetaData.h"
#endif /* HOCKEYSDK_FEATURE_CRASH_REPORTER */

#if HOCKEYSDK_FEATURE_UPDATES
#import "BITUpdateManager.h"
#import "BITUpdateManagerDelegate.h"
#import "BITUpdateViewController.h"
#endif /* HOCKEYSDK_FEATURE_UPDATES */

#if HOCKEYSDK_FEATURE_STORE_UPDATES
#import "BITStoreUpdateManager.h"
#import "BITStoreUpdateManagerDelegate.h"
#endif /* HOCKEYSDK_FEATURE_STORE_UPDATES */

#if HOCKEYSDK_FEATURE_FEEDBACK
#import "BITFeedbackManager.h"
#import "BITFeedbackManagerDelegate.h"
#import "BITFeedbackActivity.h"
#import "BITFeedbackComposeViewController.h"
#import "BITFeedbackComposeViewControllerDelegate.h"
#import "BITFeedbackListViewController.h"
#endif /* HOCKEYSDK_FEATURE_FEEDBACK */

#if HOCKEYSDK_FEATURE_AUTHENTICATOR
#import "BITAuthenticator.h"
#endif /* HOCKEYSDK_FEATURE_AUTHENTICATOR */

#if HOCKEYSDK_FEATURE_METRICS
#import "BITMetricsManager.h"
#endif /* HOCKEYSDK_FEATURE_METRICS */

// Notification message which HockeyManager is listening to, to retry requesting updated from the server.
// This can be used by app developers to trigger additional points where the HockeySDK can try sending
// pending crash reports or feedback messages.
// By default the SDK retries sending pending data only when the app becomes active.
#define BITHockeyNetworkDidBecomeReachableNotification @"BITHockeyNetworkDidBecomeReachable"

extern NSString *const __attribute__((unused)) kBITCrashErrorDomain;
extern NSString *const __attribute__((unused)) kBITUpdateErrorDomain;
extern NSString *const __attribute__((unused)) kBITFeedbackErrorDomain;
extern NSString *const __attribute__((unused)) kBITAuthenticatorErrorDomain;
extern NSString *const __attribute__((unused)) kBITHockeyErrorDomain;

