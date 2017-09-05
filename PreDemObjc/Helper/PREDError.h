//
//  PREDError.h
//  Pods
//
//  Created by 王思宇 on 04/09/2017.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PREDErrorCode) {
    kPREDErrorCodeUnknown = -1,
    kPREDErrorCodeInvalidServiceDomain = 100,
    kPREDErrorCodeInvalidAppKey = 101,
};

extern NSString *const PREDErrorDomain;

@interface PREDError : NSObject

+ (NSError *)GenerateNSError:(PREDErrorCode)code description:(NSString *)description;

@end
