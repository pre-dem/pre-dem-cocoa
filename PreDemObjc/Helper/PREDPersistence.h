//
//  PREDPersistence.h
//  Pods
//
//  Created by 王思宇 on 14/09/2017.
//
//

#import <Foundation/Foundation.h>
#import "PREDCrashMeta.h"
#import "PREDLagMeta.h"
#import "PREDLogMeta.h"
#import "PREDHTTPMonitorModel.h"
#import "PREDNetDiagResult.h"

extern NSString *kPREDDataPersistedNotification;

@interface PREDPersistence : NSObject

- (void)persistCrashMeta:(PREDCrashMeta *)crashMeta;
- (void)persistLagMeta:(PREDLagMeta *)lagMeta;
- (void)persistLogMeta:(PREDLogMeta *)logMeta;
- (void)persistHttpMonitors:(NSArray<PREDHTTPMonitorModel *> *)httpMonitors;
- (void)persistNetDiagResults:(NSArray<PREDNetDiagResult *> *)netDiagResults;

- (NSString *)nextCrashMetaPath;
- (NSString *)nextLagMetaPath;
- (NSString *)nextLogMetaPath;
- (NSString *)nextHttpMonitorPath;
- (NSString *)nextNetDiagPath;

- (NSMutableDictionary *)parseFile:(NSString *)filePath;
- (void)purgeFile:(NSString *)filePath;

@end
