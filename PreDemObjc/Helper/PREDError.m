//
//  PREDError.m
//  Pods
//
//  Created by 王思宇 on 04/09/2017.
//
//

#import "PREDError.h"

@implementation PREDError

NSString *const PREDErrorDomain = @"PREDErrorDomain";

+ (NSError *)GenerateNSError:(PREDErrorCode)code description:(NSString *)description {
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    [userInfo setValue:description forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:PREDErrorDomain code:code userInfo:userInfo];
}

@end
