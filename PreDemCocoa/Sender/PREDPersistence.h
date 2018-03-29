//
//  PREDPersistence.h
//  Pods
//
//  Created by 王思宇 on 14/09/2017.
//
//

#import <Foundation/Foundation.h>
#import "PREDHTTPMonitorModel.h"
#import "PREDNetDiagResult.h"
#import "PREDAppInfo.h"
#import "PREDCustomEvent.h"

@class PREDTransaction;

@interface PREDPersistence : NSObject

- (void)persistAppInfo:(PREDAppInfo *)appInfo;

- (void)persistHttpMonitor:(PREDHTTPMonitorModel *)httpMonitor;

- (void)persistNetDiagResult:(PREDNetDiagResult *)netDiagResult;

- (void)persistCustomEvent:(PREDCustomEvent *)event;

- (void)persistTransaction:(PREDTransaction *)transaction;

- (NSString *)nextArchivedAppInfoPath;

- (NSString *)nextArchivedHttpMonitorPath;

- (NSString *)nextArchivedNetDiagPath;

- (NSString *)nextArchivedCustomEventsPath;

- (NSString *)nextArchivedTransactionsPath;

- (void)purgeFile:(NSString *)filePath;

- (void)purgeFiles:(NSArray<NSString *> *)filePaths;

- (void)purgeAllAppInfo;

- (void)purgeAllHttpMonitor;

- (void)purgeAllNetDiag;

- (void)purgeAllCustom;

- (void)purgeAllTransactions;

- (void)purgeAllPersistence;

@end
