//
//  PRESNetDiag.h
//  Pods
//
//  Created by WangSiyu on 24/05/2017.
//
//

#import <Foundation/Foundation.h>

@interface PRESDNSRecord : NSObject

@property (nonatomic, readonly) NSString *value;
@property (readonly) int ttl;
@property (readonly) int type;

@end

@interface PRESNetDiagResult : NSObject

@property (nonatomic, assign) NSInteger ping_code;
@property (nonatomic, strong) NSString* ping_ip;
@property (nonatomic, assign) NSUInteger ping_size;
@property (nonatomic, assign) NSTimeInterval ping_maxRtt;
@property (nonatomic, assign) NSTimeInterval ping_minRtt;
@property (nonatomic, assign) NSTimeInterval ping_avgRtt;
@property (nonatomic, assign) NSInteger ping_loss;
@property (nonatomic, assign) NSInteger ping_count;
@property (nonatomic, assign) NSTimeInterval ping_totalTime;
@property (nonatomic, assign) NSTimeInterval ping_stddev;

@property (nonatomic, assign) NSInteger tcp_code;
@property (nonatomic, strong) NSString* tcp_ip;
@property (nonatomic, assign) NSTimeInterval tcp_maxTime;
@property (nonatomic, assign) NSTimeInterval tcp_minTime;
@property (nonatomic, assign) NSTimeInterval tcp_avgTime;
@property (nonatomic, assign) NSInteger tcp_loss;
@property (nonatomic, assign) NSInteger tcp_count;
@property (nonatomic, assign) NSTimeInterval tcp_totalTime;
@property (nonatomic, assign) NSTimeInterval tcp_stddev;

@property (nonatomic, assign) NSInteger tr_code;
@property (nonatomic, strong) NSString* tr_ip;
@property (nonatomic, strong) NSString* tr_content;

@property (nonatomic, strong) NSArray<PRESDNSRecord *>* dns_records;

@property (nonatomic, assign) NSInteger http_code;
@property (nonatomic, strong) NSString* http_ip;
@property (nonatomic, assign) NSTimeInterval http_duration;
@property (nonatomic, strong) NSDictionary* http_headers;
@property (nonatomic, strong) NSData* http_body;

@end

typedef void (^PRESNetDiagCompleteHandler)(PRESNetDiagResult*);

@interface PRESNetDiag : NSObject

+ (void)diagnose:(NSString *)host
        complete:(PRESNetDiagCompleteHandler)complete;

@end
