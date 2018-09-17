//
//  PREDConfig.h
//  PreDemCocoa
//
//  Created by WangSiyu on 10/05/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDConfig.h"
#import "PREDPersistence.h"
#import "PREDSender.h"
#import <Foundation/Foundation.h>

extern NSString *kPREDConfigRefreshedNotification;
extern NSString *kPREDConfigRefreshedNotificationConfigKey;

@interface PREDConfigManager : NSObject

- (instancetype)initWithSender:(PREDSender *)sender;

- (PREDConfig *)getConfig;

@end
