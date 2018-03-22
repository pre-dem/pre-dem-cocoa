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
#import "PREDAppInfo.h"
#import "PREDCustomEvent.h"
#import "PREDBreadcrumb.h"
#import "PREDTransaction.h"

@interface PREDPersistence : NSObject

- (void)persistAppInfo:(PREDAppInfo *)appInfo;
- (void)persistHttpMonitor:(PREDHTTPMonitorModel *)httpMonitor;
- (void)persistNetDiagResult:(PREDNetDiagResult *)netDiagResult;
- (void)persistCustomEvent:(PREDCustomEvent *)event;
- (void)persistBreadcrumb:(PREDBreadcrumb *)breadcrumb;
- (void)persistTransaction:(PREDTransaction *)transaction;
- (void)persistCrashMeta:(PREDCrashMeta *)crashMeta;
- (void)persistLagMeta:(PREDLagMeta *)lagMeta;
- (void)persistLogMeta:(PREDLogMeta *)logMeta;

- (NSString *)nextArchivedAppInfoPath;
- (NSString *)nextArchivedHttpMonitorPath;
- (NSString *)nextArchivedNetDiagPath;
- (NSString *)nextArchivedCustomEventsPath;
- (NSString *)nextArchivedBreadcrumbPath;
- (NSString *)nextCrashMetaPath;
- (NSString *)nextLagMetaPath;
- (NSString *)nextLogMetaPath;

- (NSMutableDictionary *)getLogMeta:(NSString *)filePath error:(NSError **)error;
- (NSMutableDictionary *)getStoredMeta:(NSString *)filePath error:(NSError **)error;
- (void)purgeFile:(NSString *)filePath;
- (void)purgeFiles:(NSArray<NSString *> *)filePaths;
- (void)purgeAllAppInfo;
- (void)purgeAllHttpMonitor;
- (void)purgeAllNetDiag;
- (void)purgeAllCustom;
- (void)purgeAllBreadcrumb;
- (void)purgeAllCrashMeta;
- (void)purgeAllLagMeta;
- (void)purgeAllLogMeta;
- (void)purgeAllPersistence;

@end
