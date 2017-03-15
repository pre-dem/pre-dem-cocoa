//
//  PRESurlModel.h
//  PreSniffSDK
//
//  Created by WangSiyu on 15/03/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PRESurlModel : NSObject

@property (nonatomic, strong, nonnull) NSURLRequest *request;
@property (nonatomic, strong, nonnull) NSHTTPURLResponse *response;
@property (nonatomic, assign) double myID;
@property (nonatomic, assign) UInt64 startTimestamp;
@property (nonatomic, assign) UInt64 startTimestampViaMin;
@property (nonatomic, assign) UInt64 endTimestamp;
@property (nonatomic, strong, nonnull) NSString *errMsg;

//request
@property (nonatomic, strong, nonnull) NSString *requestURLString;
@property (nonatomic, strong, nonnull) NSString *requestDomain;
@property (nonatomic, assign) double requestTimeoutInterval;
@property (nonatomic, strong, nonnull) NSString *requestHTTPMethod;
@property (nonatomic, strong, nonnull) NSString *requestHostIP;
@property (nonatomic, assign) UInt8 requestDomainType;
@property (nonatomic, assign) UInt8 requestGroupType;
@property (nonatomic, strong, nonnull) NSString *requestGroupPath;

//response
@property (nonatomic, assign) int responseStatusCode;
@property (nonatomic, assign) UInt64 responseTimeStamp;
@property (nonatomic, assign) UInt64 dnsTime;
@property (nonatomic, assign) NSInteger responseDataLength;
@property (nonatomic, strong, nonnull) NSString *responseMIME;


@end
