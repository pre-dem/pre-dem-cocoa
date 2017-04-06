//
//  PRESHTTPMonitorModel.m
//  PreSniffSDK
//
//  Created by WangSiyu on 15/03/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PRESHTTPMonitorModel.h"
#import "PRESUtilities.h"
#import <objc/runtime.h>

@implementation PRESHTTPMonitorModel

- (instancetype)init {
    if (self = [super init]) {
        self.appName = [PRESUtilities getAppName];
        self.appBundleId = [PRESUtilities getAppBundleId];
        self.osVersion = [PRESUtilities getOsVersion];
        self.deviceModel = [PRESUtilities getDeviceModel];
    }
    return self;
}

- (void)updateModelWithRequest:(NSURLRequest *)request {
    self.requestURLString = [NSURLProtocol propertyForKey:@"PRESOriginalURL" inRequest:request];
    self.requestDomain = [request valueForHTTPHeaderField:@"Host"];
    self.requestTimeoutInterval = request.timeoutInterval;
    self.requestHTTPMethod = request.HTTPMethod;
    self.requestDNSTime = [[NSURLProtocol propertyForKey:@"PRESDNSTime" inRequest:request] integerValue];
    self.requestHostIP = [NSURLProtocol propertyForKey:@"PRESHostIP" inRequest:request];
}

- (void)updateModelWithResponse:(NSHTTPURLResponse *)response {
    self.responseStatusCode = response.statusCode;
}

@end
