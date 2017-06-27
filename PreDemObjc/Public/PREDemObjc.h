//
//  PreDemObjc.h
//  PreDemSDK
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PREDEnums.h"
#import "PREDNullability.h"
#import "PREDMetricsManager.h"
#import "PREDManager.h"

// Notification message which PREDManager is listening to, to retry requesting updated from the server.
// This can be used by app developers to trigger additional points where the PreDemObjc can try sending
// pending crash reports or feedback messages.
// By default the SDK retries sending pending data only when the app becomes active.
#define PREDNetworkDidBecomeReachableNotification @"PREDNetworkDidBecomeReachable"

extern NSString *const __attribute__((unused)) kPREDCrashErrorDomain;
extern NSString *const __attribute__((unused)) kPREDUpdateErrorDomain;
extern NSString *const __attribute__((unused)) kPREDFeedbackErrorDomain;
extern NSString *const __attribute__((unused)) kPREDAuthenticatorErrorDomain;
extern NSString *const __attribute__((unused)) kPREDErrorDomain;

