//
//  PREDSender.h
//  Pods
//
//  Created by 王思宇 on 18/09/2017.
//
//

#import <Foundation/Foundation.h>
#import "PREDPersistence.h"
#import "PREDNetworkClient.h"

@interface PREDSender : NSObject

- (instancetype)initWithPersistence:(PREDPersistence *)persistence baseUrl:(NSURL *)baseUrl;

@end
