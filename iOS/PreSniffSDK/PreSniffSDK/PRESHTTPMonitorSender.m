//
//  PRESHTTPMonitorSender.m
//  PreSniffSDK
//
//  Created by WangSiyu on 28/03/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PRESHTTPMonitorSender.h"
#import <MJExtension/MJExtension.h>

#define PRESHTTPMonitorDomain   @"http://localhost:8080"
#define PRESHTTPMonitorPath     @"/http_monitor"

@implementation PRESHTTPMonitorSender

+ (instancetype)sharedSender {
    static PRESHTTPMonitorSender *object = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        object = [[PRESHTTPMonitorSender alloc] init];
    });
    return object;
}

- (void)addModel:(PRESHTTPMonitorModel *)model {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", PRESHTTPMonitorDomain, PRESHTTPMonitorPath]]];
    [NSURLProtocol setProperty:@YES
                        forKey:@"PRESInternalRequest"
                     inRequest:request];
    request.HTTPBody = [model mj_JSONData];
    request.HTTPMethod = @"POST";
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (error) {
            NSLog(@"report error: %@", error.localizedDescription);
        } else {
            NSLog(@"report success, code: %u, header: %@", httpResponse.statusCode, httpResponse.allHeaderFields);
        }
    }] resume];
}

@end
