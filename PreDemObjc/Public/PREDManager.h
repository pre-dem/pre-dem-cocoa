/*
 * Author: Andreas Linde <mail@andreaslinde.de>
 *         Kent Sutherland
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
#import <UIKit/UIKit.h>
#import "PREDNullability.h"
#import "PREDEnums.h"

@protocol PREDManagerDelegate;

@class PREDBaseManager;
@class PREDCrashManager;
@class PREDMetricsManager;

NS_ASSUME_NONNULL_BEGIN

@interface PREDManager: NSObject

#pragma mark - Public Methods

///-----------------------------------------------------------------------------
/// @name Initialization
///-----------------------------------------------------------------------------

/**
 Returns a shared PREDManager object
 
 @return A singleton PREDManager instance ready use
 */
+ (PREDManager *)sharedPREDManager;


/**
 Initializes the manager with a particular app identifier
 
 Initialize the manager with a PreDem app identifier.
 
 [[PREDManager sharedPREDManager]
 startWithAppKey:@"<AppIdentifierFromPreDem>"
 serviceDomain:@"<ServiceDomain>"];
 
 @param appKey The app key that should be used.
 @param serviceDomain The service domain that data will be reported to or requested from.
 */
- (void)startWithAppKey:(NSString *)appKey serviceDomain:(NSString *)serviceDomain;

/**
 *  diagnose current network environment
 *
 *  @param host     the end point you want this diagnose action perform with
 *  @param complete diagnose result can be retrieved from the block
 */
- (void)diagnose:(NSString *)host
        complete:(PREDNetDiagCompleteHandler)complete;

///-----------------------------------------------------------------------------
/// @name SDK meta data
///-----------------------------------------------------------------------------

/**
 Returns the SDK Version (CFBundleShortVersionString).
 */
- (NSString *)version;

/**
 Returns the SDK Build (CFBundleVersion) as a string.
 */
- (NSString *)build;

#pragma mark - Public Properties

///-----------------------------------------------------------------------------
/// @name Modules
///-----------------------------------------------------------------------------

/**
 Reference to the initialized PREDMetricsManager module
 
 Returns the PREDMetricsManager instance initialized by PREDManager
 */
@property (nonatomic, strong, readonly) PREDMetricsManager *metricsManager;

///-----------------------------------------------------------------------------
/// @name Debug Logging
///-----------------------------------------------------------------------------

/**
 This property is used indicate the amount of verboseness and severity for which
 you want to see log messages in the console.
 */
@property (nonatomic, assign) PREDLogLevel logLevel;

@end

NS_ASSUME_NONNULL_END
