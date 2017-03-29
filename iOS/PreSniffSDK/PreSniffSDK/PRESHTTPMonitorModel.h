//
//  PRESHTTPMonitorModel.h
//  PreSniffSDK
//
//  Created by WangSiyu on 15/03/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PRESHTTPMonitorModel : NSObject

@property (nonatomic, assign) double myID;
@property (nonatomic, assign) UInt64 startTimestamp;
@property (nonatomic, assign) UInt64 startTimestampViaMin;
@property (nonatomic, assign) UInt64 endTimestamp;
@property (nonatomic, strong) NSString *errMsg;

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
