//
//  PREDManager.h
//  PreDemObjc
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PREDDefines.h"

@interface PREDManager: NSObject

#pragma mark - Public Methods

///-----------------------------------------------------------------------------
/// @name Initialization
///-----------------------------------------------------------------------------


/**
 Initialize the manager with a PreDem app identifier.
 
 @param appKey The app key that should be used.
 @param serviceDomain The service domain that data will be reported to or requested from.
 */
+ (void)startWithAppKey:(NSString *_Nonnull)appKey
          serviceDomain:(NSString *_Nonnull)serviceDomain
                  error:(NSError *_Nullable *_Nullable)error;

/**
 *  diagnose current network environment
 *
 *  @param host     the end point you want this diagnose action perform with
 *  @param complete diagnose result can be retrieved from the block
 */
+ (void)diagnose:(NSString *_Nonnull)host
        complete:(PREDNetDiagCompleteHandler _Nullable)complete;

+ (void)trackEventWithName:(NSString *_Nonnull)eventName
                     event:(NSDictionary *_Nonnull)event;

+ (void)trackEventsWithName:(NSString *_Nonnull)eventName
                     events:(NSArray<NSDictionary *>*_Nonnull)events;

///-----------------------------------------------------------------------------
/// @name SDK meta data
///-----------------------------------------------------------------------------

/**
 Returns the SDK Version (CFBundleShortVersionString).
 */
+ (NSString *_Nonnull)version;

/**
 Returns the SDK Build (CFBundleVersion) as a string.
 */
+ (NSString *_Nonnull)build;

#pragma mark - Public Properties

/**
 This property is used to identify a specific user, for instance, you can assign user id to tag, so that you can use user id to search reports gathered by the sdk.
 */
@property (class, nonnull, nonatomic, strong) NSString *tag;

@end
