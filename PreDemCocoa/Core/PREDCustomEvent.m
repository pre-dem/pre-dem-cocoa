//
//  PREDEvent.m
//  PreDemCocoa
//
//  Created by Troy on 2017/9/27.
//

#import "PREDCustomEvent.h"
#import "NSObject+Serialization.h"
#import "PREDConstants.h"
#import "PREDLogger.h"

#import "PREDManager.h"

@implementation PREDCustomEvent

+ (instancetype)eventWithName:(NSString *)name
                   contentDic:(NSDictionary *)contentDic {
  return [self eventWithName:name type:CustomEventType contentDic:contentDic];
}

+ (instancetype)eventWithName:(NSString *)name
                         type:(NSString *)type
                   contentDic:(NSDictionary *)contentDic {
  PREDCustomEvent *event = [self eventWithName:name type:type];
  if (event) {
    if (!name.length) {
      PREDLogError(@"event name should not be empty");
      return nil;
    }

    NSError *error;

    NSString *content;
    if (contentDic.count) {
      NSData *contentData = [NSJSONSerialization dataWithJSONObject:contentDic
                                                            options:0
                                                              error:&error];
      if (error) {
        PREDLogError(@"jsonize custom events error: %@", error);
        return nil;
      } else if (!contentData.length) {
        PREDLogWarning(@"discard empty custom event");
        return nil;
      }

      content = [[NSString alloc] initWithData:contentData
                                      encoding:NSUTF8StringEncoding];
    } else {
      content = @"";
    }

    event->_content = content;
  }

  return event;
}

- (NSData *)serializeForSending:(NSError **)error {
  return [self toJsonWithError:error];
}

@end

@implementation PREDEventQueue
- (void)setSizeThreshhold:(NSUInteger)size {
}

- (NSUInteger)sizeThreshhold {
  return 10;
}

- (void)setSendInterval:(NSUInteger)interval {
}

- (NSUInteger)sendInterval {
  return 30;
}

- (void)trackCustomEvent:(PREDCustomEvent *_Nonnull)event {
  [PREDManager trackCustomEvent:event];
}

@end
