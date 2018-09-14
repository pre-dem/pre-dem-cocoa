#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "QNNExternalIp.h"
#import "QNNHttp.h"
#import "QNNNslookup.h"
#import "QNNPing.h"
#import "QNNProtocols.h"
#import "QNNQue.h"
#import "QNNRtmp.h"
#import "QNNTcpPing.h"
#import "QNNTraceRoute.h"
#import "QNNUtil.h"
#import "QNNetDiag.h"

FOUNDATION_EXPORT double QNNetDiagVersionNumber;
FOUNDATION_EXPORT const unsigned char QNNetDiagVersionString[];
