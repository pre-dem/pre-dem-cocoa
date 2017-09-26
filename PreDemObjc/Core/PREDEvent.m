//
//  PREDEvent.m
//  PreDemObjc
//
//  Created by Troy on 2017/9/27.
//

#import <Foundation/Foundation.h>
#import "PREDHelper.h"
#import "PREDEvent.h"

#define CUSTOM_EVENT_TYPE @"custom"

@implementation PREDEvent

- (NSString *)description {
    return [PREDHelper getObjectData:self].description;
}

- (instancetype)initWithName:(NSString *)name content:(NSString *)content {
    return [self initWithName:name content:content type:CUSTOM_EVENT_TYPE];
}

- (instancetype)initWithName:(NSString *)name content:(NSString *)content type:(NSString *)type {
    if (self = [super init]) {
        _name = name;
        _content = content;
        _type = type;
    }
    
    return self;
}

@end
