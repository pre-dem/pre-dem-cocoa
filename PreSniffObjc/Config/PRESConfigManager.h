//
//  PRESConfig.h
//  PreSniffSDK
//
//  Created by WangSiyu on 10/05/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PRESConfig.h"

@class PRESConfigManager;
@protocol PRESConfigManagerDelegate <NSObject>

- (void)configManager:(PRESConfigManager *)manager didReceivedConfig:(PRESConfig *)config;

@end

@interface PRESConfigManager : NSObject

@property(nonatomic, weak) id<PRESConfigManagerDelegate> delegate;

+ (instancetype)sharedInstance;

- (PRESConfig *)getConfigWithAppKey:(NSString *)appKey;

@end
