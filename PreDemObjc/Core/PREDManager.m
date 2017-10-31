//
//  PREDManager.m
//  PreDemObjc
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PreDemObjc.h"
#import "PREDManagerPrivate.h"
#import "PREDHelper.h"
#import "PREDNetworkClient.h"
#import "PREDVersion.h"
#import "PREDConfigManager.h"
#import "PREDNetDiag.h"
#import "PREDURLProtocol.h"
#import "PREDCrashManager.h"
#import "PREDLagMonitorController.h"
#import "PREDLogger.h"
#import "PREDError.h"
#import "PREDLoggerPrivate.h"
#import "PREDSender.h"

static NSString* app_id(NSString* appKey){
    if (appKey.length >= PREDAppIdLength) {
        return [appKey substringToIndex:PREDAppIdLength];
    } else {
        return appKey;
    }
}

@implementation PREDManager {
    PREDConfigManager *_configManager;
    
    PREDCrashManager *_crashManager;
    
    PREDLagMonitorController *_lagManager;
    
    PREDPersistence *_persistence;
    
    PREDSender *_sender;
}


#pragma mark - Public Class Methods

+ (void)startWithAppKey:(NSString *)appKey
          serviceDomain:(NSString *)serviceDomain
               complete:(PREDStartCompleteHandler)complete {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[self sharedPREDManager] startWithAppKey:appKey serviceDomain:serviceDomain complete:complete];
    });
}


+ (void)diagnose:(NSString *)host
        complete:(PREDNetDiagCompleteHandler)complete {
    [[self sharedPREDManager] diagnose:host complete:complete];
}

+ (void)trackEvent:(PREDEvent *)event {
    if (!event) {
        PREDLogError(@"event should not be nil");
        return;
    }
    [[self sharedPREDManager]->_persistence persistCustomEvent:event];
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
    }
    return self;
}

- (void)startWithAppKey:(NSString *)appKey serviceDomain:(NSString *)serviceDomain complete:(PREDStartCompleteHandler)complete {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _appKey = appKey;
        NSError *error;
        if (![self initSenderWithDomain:serviceDomain appKey:appKey error:&error]) {
            if (complete) {
                complete(NO, error);
            }
            return;
        }
        
        [self initializeModules];
        
        [self registerObservers];
        
        [_sender sendAllSavedData];
    });
    return;
}

- (BOOL)initSenderWithDomain:(NSString *)aServerURL appKey:(NSString *)appKey error:(NSError **)error {
    if (!aServerURL.length) {
        if (error) {
            *error = [PREDError GenerateNSError:kPREDErrorCodeInvalidServiceDomain description:@"you must specify server domain"];
        }
        return NO;
    }
    if (appKey.length < PREDAppIdLength) {
        if (error) {
            *error = [PREDError GenerateNSError:kPREDErrorCodeInvalidAppKey description:@"the length of your app key must be longer than %d", PREDAppIdLength];
        }
        return NO;
    }
    if (![aServerURL hasPrefix:@"http://"] && ![aServerURL hasPrefix:@"https://"]) {
        aServerURL = [NSString stringWithFormat:@"http://%@", aServerURL];
    }
    
    aServerURL = [NSString stringWithFormat:@"%@/v1/%@/", aServerURL, app_id(appKey)];
    
    NSURL *url = [NSURL URLWithString:aServerURL];
    
    if (!url) {
        if (error) {
            *error = [PREDError GenerateNSError:kPREDErrorCodeInvalidServiceDomain description:@"the service domain has a wrong structure: %@", aServerURL];
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
    
    // this process will get default config and then use it to initialize all module, besides it will also retrieve config from the server and config will refresh when done.
    [self setConfig:[_configManager getConfig]];
    
    _lagManager = [[PREDLagMonitorController alloc] initWithPersistence:_persistence];
    [PREDLogger setPersistence:_persistence];
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

@end
