//
//  PREDEvent.m
//  PreDemObjc
//
//  Created by Troy on 2017/9/27.
//

#import <Foundation/Foundation.h>
#import "PREDEvent.h"
#import "PREDLogger.h"

#define CUSTOM_EVENT_TYPE @"custom"

@implementation PREDEvent

+ (instancetype)eventWithName:(NSString *)name contentDic:(NSDictionary *)contentDic {
    return [self eventWithName:name type:CUSTOM_EVENT_TYPE contentDic:contentDic];
}

+ (instancetype)eventWithName:(NSString *)name type:(NSString *)type contentDic:(NSDictionary *)contentDic {
    PREDEvent *event = [[PREDEvent alloc] init];
    if (event) {
        if (!name.length) {
            PREDLogError(@"event name should not be empty");
            return nil;
        }
        
        NSError *error;
        NSData *contentData = [NSJSONSerialization dataWithJSONObject:contentDic options:0 error:&error];
        if (error) {
            PREDLogError(@"jsonize custom events error: %@", error);
            return nil;
        } else if (!contentData.length) {
            PREDLogWarn(@"discard empty custom event");
            return nil;
        }
        
        NSString *content = [[NSString alloc] initWithData:contentData encoding:NSUTF8StringEncoding];
        
        event->_name = name;
        event->_content = content;
        event->_type = type;
    }
    
    return event;
}

@end
