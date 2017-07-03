//
//  PREDConfig.h
//  PreDemSDK
//
//  Created by WangSiyu on 10/05/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PREDConfig.h"

@class PREDConfigManager;

@protocol PREDConfigManagerDelegate <NSObject>

- (void)configManager:(PREDConfigManager *)manager didReceivedConfig:(PREDConfig *)config;

@end

@interface PREDConfigManager : NSObject

@property(nonatomic, weak) id<PREDConfigManagerDelegate> delegate;

- (PREDConfig *)getConfigWithAppKey:(NSString *)appKey;

@end
