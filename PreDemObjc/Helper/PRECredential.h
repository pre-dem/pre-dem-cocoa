//
//  PRECredential.h
//  Pods
//
//  Created by BaiLong on 2017/9/5.
//
//

#import <Foundation/Foundation.h>

@interface PRECredential : NSObject

+ (NSString *)authoriztion:(NSString*) data
                    appKey:(NSString*) key;

@end
