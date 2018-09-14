//
//  PRECredential.h
//  Pods
//
//  Created by BaiLong on 2017/9/5.
//
//

#import <Foundation/Foundation.h>

@interface PREDCredential : NSObject

+ (NSString *)authorize:(NSString *)data appKey:(NSString *)key;

@end
