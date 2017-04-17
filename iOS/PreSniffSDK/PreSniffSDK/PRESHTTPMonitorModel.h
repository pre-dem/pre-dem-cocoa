//
//  PRESHTTPMonitorModel.h
//  PreSniffSDK
//
//  Created by WangSiyu on 15/03/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PRESHTTPMonitorModel : NSObject

@property (nonatomic, strong) NSString *appName;
@property (nonatomic, strong) NSString *appBundleId;
@property (nonatomic, strong) NSString *osVersion;
@property (nonatomic, strong) NSString *deviceModel;
@property (nonatomic, assign) UInt64 startTimestamp;
@property (nonatomic, assign) UInt64 endTimestamp;
@property (nonatomic, strong) NSString *errorMsg;
@property (nonatomic, assign) NSInteger errorCode;

//request
@property (nonatomic, assign) NSUInteger requestDNSTime;
@property (nonatomic, strong) NSString *requestURLString;
@property (nonatomic, strong) NSString *requestDomain;
@property (nonatomic, assign) double requestTimeoutInterval;
@property (nonatomic, strong) NSString *requestHTTPMethod;
@property (nonatomic, strong) NSString *requestHostIP;

//response
@property (nonatomic, assign) NSInteger responseStatusCode;
@property (nonatomic, assign) NSInteger responseDataLength;
@property (nonatomic, assign) UInt64 responseTimeStamp;

- (void)updateModelWithRequest:(NSURLRequest *)request;
- (void)updateModelWithResponse:(NSHTTPURLResponse *)response;

@end
