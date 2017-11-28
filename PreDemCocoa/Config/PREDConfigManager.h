//
//  PREDConfig.h
//  PreDemCocoa
//
//  Created by WangSiyu on 10/05/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PREDConfig.h"
#import "PREDPersistence.h"

extern NSString *kPREDConfigRefreshedNotification;
extern NSString *kPREDConfigRefreshedNotificationConfigKey;

@interface PREDConfigManager : NSObject

- (instancetype)initWithPersistence:(PREDPersistence *)persistence;

- (PREDConfig *)getConfig;

@end
