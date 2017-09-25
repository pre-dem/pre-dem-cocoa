//
//  NSObject+Serialization.h
//  Pods
//
//  Created by 王思宇 on 18/09/2017.
//
//

#import <Foundation/Foundation.h>

@interface NSObject (Serialization)

- (NSData *)toJsonWithError:(NSError **)error;
- (NSMutableDictionary *)toDic;

@end
