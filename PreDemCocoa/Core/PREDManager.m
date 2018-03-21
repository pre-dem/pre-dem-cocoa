//
//  PREDManager.m
//  PreDemCocoa
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PreDemCocoa.h"
#import "PREDManagerPrivate.h"
#import "PREDHelper.h"
#import "PREDNetworkClient.h"
#import "PREDVersion.h"
#import "PREDConfigManager.h"
#import "PREDNetDiag.h"
#import "PREDURLProtocol.h"
#import "PREDCrashManager.h"
#import "PREDLagMonitorController.h"
#import "PREDLog.h"
#import "PREDError.h"
#import "PREDLogPrivate.h"
#import "PREDSender.h"
#import "PREDBreadcrumbTracker.h"
#import "PREDTransaction.h"

static NSString* app_id(NSString* appKey){
    if (appKey.length >= PREDAppIdLength) {
        return [appKey substringToIndex:PREDAppIdLength];
    } else {
        return appKey;
    }
}

@implementation PREDManager {
    BOOL _started;
    
    PREDConfigManager *_configManager;
    
    PREDCrashManager *_crashManager;
    
    PREDLagMonitorController *_lagManager;
    
    PREDBreadcrumbTracker *_breadcrumbTracker;
    
    PREDPersistence *_persistence;
    
    PREDSender *_sender;
    
    NSMutableDictionary *_transactions;
    
    NSLock *_transactionsLock;
}

#pragma mark - Public Class Methods

+ (void)startWithAppKey:(NSString *)appKey
          serviceDomain:(NSString *)serviceDomain {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[self sharedPREDManager] startWithAppKey:appKey serviceDomain:serviceDomain];
    });
}


+ (void)diagnose:(NSString *)host
        complete:(PREDNetDiagCompleteHandler)complete {
    [[self sharedPREDManager] diagnose:host complete:complete];
}

+ (NSString *)transactionStart:(NSString *)transactionName {
    return [[PREDManager sharedPREDManager] transactionStart:transactionName];
}

+ (NSError *)transactionComplete:(NSString *)transactionID {
    return [[PREDManager sharedPREDManager] transactionComplete:transactionID];
}

+ (NSError *)transactionCancel:(NSString *)transactionID reason:(NSString *)reason {
    return [[PREDManager sharedPREDManager] transactionCancel:transactionID reason:reason];
}

+ (NSError *)transactionFail:(NSString *)transactionID reason:(NSString *)reason {
    return [[PREDManager sharedPREDManager] transactionFail:transactionID reason:reason];
}

+ (void)trackCustomEvent:(PREDCustomEvent *)event {
    if (!event) {
        PREDLogError(@"event should not be nil");
        return;
    }
    [[self sharedPREDManager]->_persistence persistCustomEvent:event];
}

+ (BOOL)started {
    return [PREDManager sharedPREDManager]->_started;
}

+ (NSString *)tag {
    return PREDHelper.tag;
}

+ (void)setTag:(NSString *)tag {
    PREDHelper.tag = tag;
}

+ (NSString *)version {
    return [PREDVersion getSDKVersion];
}

+ (NSString *)build {
    return [PREDVersion getSDKBuild];
}

#pragma mark - Private Methods

+ (PREDManager *)sharedPREDManager {
    static PREDManager *sharedInstance = nil;
    static dispatch_once_t pred;
    
    dispatch_once(&pred, ^{
        sharedInstance = [[PREDManager alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    if ((self = [super init])) {
        _persistence = [[PREDPersistence alloc] init];
        _transactions = [NSMutableDictionary new];
        _transactionsLock = [NSLock new];
    }
    return self;
}

- (void)startWithAppKey:(NSString *)appKey serviceDomain:(NSString *)serviceDomain {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _appKey = appKey;
        NSError *error;
        if (![self initSenderWithDomain:serviceDomain appKey:appKey error:&error]) {
            PREDLogError(@"%@", error);
            return;
        }
        
        [self initializeModules];
        
        [self registerObservers];
        
        [_sender sendAllSavedData];
        
        _started = YES;
    });
    return;
}

- (BOOL)initSenderWithDomain:(NSString *)aServerURL appKey:(NSString *)appKey error:(NSError **)error {
    if (!aServerURL.length) {
        if (error) {
            *error = [PREDError GenerateNSError:kPREDErrorCodeInvalidServiceDomain description:@"你必须指定 server domain ！！！！！！"];
        }
        return NO;
    }
    if (appKey.length < PREDAppIdLength) {
        if (error) {
            *error = [PREDError GenerateNSError:kPREDErrorCodeInvalidAppKey description:@"app key 的长度必须大于等于 %d！！！！！！", PREDAppIdLength];
        }
        return NO;
    }
    if (![aServerURL hasPrefix:@"http://"] && ![aServerURL hasPrefix:@"https://"]) {
        aServerURL = [NSString stringWithFormat:@"http://%@", aServerURL];
    }
    
    aServerURL = [NSString stringWithFormat:@"%@/v2/%@/", aServerURL, app_id(appKey)];
    
    NSURL *url = [NSURL URLWithString:aServerURL];
    
    if (!url) {
        if (error) {
            *error = [PREDError GenerateNSError:kPREDErrorCodeInvalidServiceDomain description:@"service domain 的结构不正确: %@ ！！！！！！", aServerURL];
        }
        return NO;
    }
    
    _sender = [[PREDSender alloc] initWithPersistence:_persistence baseUrl:url];
    return YES;
}

- (void)initializeModules {
    _crashManager = [[PREDCrashManager alloc]
                     initWithPersistence:_persistence];
    [PREDURLProtocol setPersistence:_persistence];
    _configManager = [[PREDConfigManager alloc] initWithPersistence:_persistence];
    
    _lagManager = [[PREDLagMonitorController alloc] initWithPersistence:_persistence];
    
    _breadcrumbTracker = [[PREDBreadcrumbTracker alloc] initWithPersistence:_persistence];
    [_breadcrumbTracker start];
    
    [PREDLog setPersistence:_persistence];
    PREDLog.started = YES;
    
    // this process will get default config and then use it to initialize all module, besides it will also retrieve config from the server and config will refresh when done.
    [self setConfig:[_configManager getConfig]];
}

- (void)setConfig:(PREDConfig *)config {
    _crashManager.started = config.crashReportEnabled;
    
    PREDURLProtocol.started = config.httpMonitorEnabled;
    
    _lagManager.started = config.lagMonitorEnabled;
}

- (void)registerObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configRefreshed:) name:kPREDConfigRefreshedNotification object:nil];
}

- (void)diagnose:(NSString *)host
        complete:(PREDNetDiagCompleteHandler)complete {
    [PREDNetDiag diagnose:host persistence:_persistence complete:complete];
}

- (void)configRefreshed:(NSNotification *)noty {
    NSDictionary *dic = noty.userInfo[kPREDConfigRefreshedNotificationConfigKey];
    PREDConfig *config = [PREDConfig configWithDic:dic];
    [self setConfig:config];
}

- (NSString *)transactionStart:(NSString *)transactionName {
    uint64_t startTime = (uint64_t)([[NSDate date] timeIntervalSince1970] * 1000);
    NSString *transactionID = [NSString stringWithFormat:@"%@%llu",transactionName, startTime];
    PREDTransaction *transaction = [[PREDTransaction alloc] init];
    transaction.transaction_name = transactionName;
    transaction.start_time = startTime;
    [_transactionsLock lock];
    [_transactions setObject:transaction forKey:transactionID];
    [_transactionsLock unlock];
    return transactionID;
}

- (NSError *)transactionComplete:(NSString *)transactionID {
    PREDTransaction *transaction = [_transactions objectForKey:transactionID];
    if (!transaction) {
        return [PREDError GenerateNSError:kPREDErrorCodeInvalidTransactionIDError description:@"invalid transaction id, you should generate transaction id via [PREDMnanager transactionStart:] method first before call this method"];
    }
    uint64_t endTime = (uint64_t)([[NSDate date] timeIntervalSince1970] * 1000);
    transaction.end_time = endTime;
    transaction.transaction_type = PREDTransactionTypeCompleted;
    return nil;
}

- (NSError *)transactionCancel:(NSString *)transactionID reason:(NSString *)reason {
    PREDTransaction *transaction = [_transactions objectForKey:transactionID];
    if (!transaction) {
        return [PREDError GenerateNSError:kPREDErrorCodeInvalidTransactionIDError description:@"invalid transaction id, you should generate transaction id via [PREDMnanager transactionStart:] method first before call this method"];
    }
    uint64_t endTime = (uint64_t)([[NSDate date] timeIntervalSince1970] * 1000);
    transaction.end_time = endTime;
    transaction.transaction_type = PREDTransactionTypeCancelled;
    transaction.reason = reason;
    return nil;
}
     
- (NSError *)transactionFail:(NSString *)transactionID reason:(NSString *)reason {
    PREDTransaction *transaction = [_transactions objectForKey:transactionID];
    if (!transaction) {
        return [PREDError GenerateNSError:kPREDErrorCodeInvalidTransactionIDError description:@"invalid transaction id, you should generate transaction id via [PREDMnanager transactionStart:] method first before call this method"];
    }
    uint64_t endTime = (uint64_t)([[NSDate date] timeIntervalSince1970] * 1000);
    transaction.end_time = endTime;
    transaction.transaction_type = PREDTransactionTypeFailed;
    transaction.reason = reason;
    return nil;
}

@end
