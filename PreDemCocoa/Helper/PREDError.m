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

+ (NSError *)GenerateNSError:(PREDErrorCode)code
                 description:(NSString *)format, ... {
  va_list args;
  va_start(args, format);
  NSString *description =
      [[NSString alloc] initWithFormat:format arguments:args];
  va_end(args);
  NSMutableDictionary *userInfo = [NSMutableDictionary new];
  [userInfo setValue:description forKey:NSLocalizedDescriptionKey];
  return [NSError errorWithDomain:PREDErrorDomain code:code userInfo:userInfo];
}

@end
