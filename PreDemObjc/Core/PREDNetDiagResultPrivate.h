//
//  PREDNetDiagResultPrivate.h
//  Pods
//
//  Created by WangSiyu on 01/06/2017.
//
//

#import "PREDNetDiagResult.h"

@interface PREDNetDiagResult ()

- (instancetype)initWithAppKey:(NSString *)appKey complete:(PREDNetDiagCompleteHandler)complete ;
- (void)gotTcpResult:(QNNTcpPingResult *)r;
- (void)gotPingResult:(QNNPingResult *)r;
- (void)gotHttpResult:(QNNHttpResult *)r;
- (void)gotTrResult:(QNNTraceRouteResult *)r;
- (void)gotNsLookupResult:(NSArray<QNNRecord *> *) r;
- (NSDictionary *)toDic;

@end
