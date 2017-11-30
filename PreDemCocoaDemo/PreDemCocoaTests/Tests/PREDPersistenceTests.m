//
//  PREDPersistenceTests.m
//  PreDemObjcTests
//
//  Created by 王思宇 on 29/09/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PREDPersistence.h"
#import <objc/runtime.h>
#import "PREDNetDiagResultPrivate.h"

@interface PREDPersistenceTests : XCTestCase

@end

@implementation PREDPersistenceTests {
    PREDPersistence *_persistence;
}

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _persistence = [[PREDPersistence alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAppInfo {
    NSError *error;
    [_persistence purgeAllAppInfo];
    
    PREDAppInfo *event1 = [[PREDAppInfo alloc] init];
    [_persistence persistAppInfo:event1];
    
    PREDAppInfo *event2 = [[PREDAppInfo alloc] init];
    [_persistence persistAppInfo:event2];
    
    NSString *path = [_persistence nextArchivedAppInfoPath];
    XCTAssertNotEqual(path.length, 0);
    NSData *data = [NSData dataWithContentsOfFile:path];
    XCTAssertNotEqual(data.length, 0);
    NSString *eventString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *components = [eventString componentsSeparatedByString:@"\n"];
    XCTAssertEqual(components.count, 3);
    
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:[components[0] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(dic);
    XCTAssertNil(error);
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        XCTAssertTrue([[event1 valueForKey:key] isEqual:obj]);
    }];
    
    dic = [NSJSONSerialization JSONObjectWithData:[components[1] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(dic);
    XCTAssertNil(error);
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        XCTAssertTrue([[event2 valueForKey:key] isEqual:obj]);
    }];
    
    [_persistence purgeFile:path];
}

- (void)testHttpMonitor {
    NSError *error;
    [_persistence purgeAllHttpMonitor];
    
    PREDHTTPMonitorModel *event1 = [[PREDHTTPMonitorModel alloc] init];
    [_persistence persistHttpMonitor:event1];
    
    PREDHTTPMonitorModel *event2 = [[PREDHTTPMonitorModel alloc] init];
    [_persistence persistHttpMonitor:event2];
    
    NSString *path = [_persistence nextArchivedHttpMonitorPath];
    XCTAssertNotEqual(path.length, 0);
    NSData *data = [NSData dataWithContentsOfFile:path];
    XCTAssertNotEqual(data.length, 0);
    NSString *eventString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *components = [eventString componentsSeparatedByString:@"\n"];
    XCTAssertEqual(components.count, 3);
    
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:[components[0] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(dic);
    XCTAssertNil(error);
    NSString *content = dic[@"content"];
    XCTAssertNotNil(content);
    NSMutableDictionary *contentDic = [NSJSONSerialization JSONObjectWithData:[content dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
    XCTAssertNotNil(contentDic);
    XCTAssertNil(error);
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        if (![key isEqualToString:@"content"]) {
            XCTAssertTrue([[event1 valueForKey:key] isEqual:obj]);
        }
    }];
    
    [contentDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        XCTAssertTrue([[event1 valueForKey:key] isEqual:obj]);
    }];
    
    dic = [NSJSONSerialization JSONObjectWithData:[components[1] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(dic);
    XCTAssertNil(error);
    content = dic[@"content"];
    XCTAssertNotNil(content);
    contentDic = [NSJSONSerialization JSONObjectWithData:[content dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
    XCTAssertNotNil(contentDic);
    XCTAssertNil(error);
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        if (![key isEqualToString:@"content"]) {
            XCTAssertTrue([[event2 valueForKey:key] isEqual:obj]);
        }
    }];
    [contentDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        XCTAssertTrue([[event1 valueForKey:key] isEqual:obj]);
    }];
    
    [_persistence purgeFile:path];
}

- (void)testNetDiag {
    NSError *error;
    [_persistence purgeAllNetDiag];
    
    PREDNetDiagResult *event1 = [[PREDNetDiagResult alloc] initWithComplete:nil persistence:_persistence];
    [_persistence persistNetDiagResult:event1];
    
    PREDNetDiagResult *event2 = [[PREDNetDiagResult alloc]  initWithComplete:nil persistence:_persistence];
    [_persistence persistNetDiagResult:event2];
    
    NSString *path = [_persistence nextArchivedNetDiagPath];
    XCTAssertNotEqual(path.length, 0);
    NSData *data = [NSData dataWithContentsOfFile:path];
    XCTAssertNotEqual(data.length, 0);
    NSString *eventString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *components = [eventString componentsSeparatedByString:@"\n"];
    XCTAssertEqual(components.count, 3);
    
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:[components[0] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(dic);
    XCTAssertNil(error);
    NSString *content = dic[@"content"];
    XCTAssertNotNil(content);
    NSMutableDictionary *contentDic = [NSJSONSerialization JSONObjectWithData:[content dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
    XCTAssertNotNil(contentDic);
    XCTAssertNil(error);
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        if (![key isEqualToString:@"content"]) {
            XCTAssertTrue([[event1 valueForKey:key] isEqual:obj]);
        }
    }];
    
    [contentDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        XCTAssertTrue([[event1 valueForKey:key] isEqual:obj]);
    }];
    
    dic = [NSJSONSerialization JSONObjectWithData:[components[1] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(dic);
    XCTAssertNil(error);
    content = dic[@"content"];
    XCTAssertNotNil(content);
    contentDic = [NSJSONSerialization JSONObjectWithData:[content dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
    XCTAssertNotNil(contentDic);
    XCTAssertNil(error);
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        if (![key isEqualToString:@"content"]) {
            XCTAssertTrue([[event2 valueForKey:key] isEqual:obj]);
        }
    }];
    [contentDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        XCTAssertTrue([[event1 valueForKey:key] isEqual:obj]);
    }];
    
    [_persistence purgeFile:path];
}

- (void)testCustomEvent {
    NSError *error;
    [_persistence purgeAllCustom];
    
    NSDictionary *dict1 = @{
                            @"stringKey": [NSString stringWithFormat:@"test\t_\n%d", arc4random_uniform(100)],
                            @"longKey": @(arc4random_uniform(100)),
                            @"floatKey": @(arc4random_uniform(10000)/100.0)
                            };
    PREDCustomEvent *event1 = [PREDCustomEvent eventWithName:@"test\t_\nios\t_\nevent_1" contentDic:dict1];
    [_persistence persistCustomEvent:event1];
    
    NSDictionary *dict2 = @{
                            @"stringKey": [NSString stringWithFormat:@"test\t_\n%d", arc4random_uniform(100)],
                            @"longKey": @(arc4random_uniform(100)),
                            @"floatKey": @(arc4random_uniform(10000)/100.0)
                            };
    PREDCustomEvent *event2 = [PREDCustomEvent eventWithName:@"test\t_\nios\t_\nevent_2" contentDic:dict2];
    [_persistence persistCustomEvent:event2];
    
    NSString *path = [_persistence nextArchivedCustomEventsPath];
    XCTAssertNotEqual(path.length, 0);
    NSData *data = [NSData dataWithContentsOfFile:path];
    XCTAssertNotEqual(data.length, 0);
    NSString *eventString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *components = [eventString componentsSeparatedByString:@"\n"];
    XCTAssertEqual(components.count, 3);
    
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:[components[0] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(dic);
    XCTAssertNil(error);
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        XCTAssertTrue([[event1 valueForKey:key] isEqual:obj]);
    }];
    
    dic = [NSJSONSerialization JSONObjectWithData:[components[1] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(dic);
    XCTAssertNil(error);
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        XCTAssertTrue([[event2 valueForKey:key] isEqual:obj]);
    }];
    
    [_persistence purgeFile:path];
}

- (void)testBreadcrumb {
    NSError *error;
    [_persistence purgeAllBreadcrumb];
    
    NSDictionary *dict1 = @{
                            @"stringKey": [NSString stringWithFormat:@"test\t_\n%d", arc4random_uniform(100)],
                            @"longKey": @(arc4random_uniform(100)),
                            @"floatKey": @(arc4random_uniform(10000)/100.0)
                            };
    PREDBreadcrumb *event1 = [PREDBreadcrumb eventWithName:@"test\t_\nios\t_\nevent_1" contentDic:dict1];
    [_persistence persistBreadcrumb:event1];
    
    NSDictionary *dict2 = @{
                            @"stringKey": [NSString stringWithFormat:@"test\t_\n%d", arc4random_uniform(100)],
                            @"longKey": @(arc4random_uniform(100)),
                            @"floatKey": @(arc4random_uniform(10000)/100.0)
                            };
    PREDBreadcrumb *event2 = [PREDBreadcrumb eventWithName:@"test\t_\nios\t_\nevent_2" contentDic:dict2];
    [_persistence persistBreadcrumb:event2];
    
    NSString *path = [_persistence nextArchivedBreadcrumbPath];
    XCTAssertNotEqual(path.length, 0);
    NSData *data = [NSData dataWithContentsOfFile:path];
    XCTAssertNotEqual(data.length, 0);
    NSString *eventString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *components = [eventString componentsSeparatedByString:@"\n"];
    XCTAssertEqual(components.count, 3);
    
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:[components[0] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(dic);
    XCTAssertNil(error);
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        XCTAssertTrue([[event1 valueForKey:key] isEqual:obj]);
    }];
    
    dic = [NSJSONSerialization JSONObjectWithData:[components[1] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(dic);
    XCTAssertNil(error);
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        XCTAssertTrue([[event2 valueForKey:key] isEqual:obj]);
    }];
    
    [_persistence purgeFile:path];
}

- (void)testCrashReport {
    NSError *error;
    [_persistence purgeAllCrashMeta];
    NSString *dataPath = [[NSBundle bundleForClass:self.class] pathForResource:@"crash" ofType:@"dat"];
    XCTAssertNotNil(dataPath);
    NSData *data = [NSData dataWithContentsOfFile:dataPath];
    XCTAssertNotNil(data);
    PREDCrashMeta *meta = [[PREDCrashMeta alloc] initWithData:data error:&error];
    XCTAssertNil(error);
    [_persistence persistCrashMeta:meta];
    NSString *path = [_persistence nextCrashMetaPath];
    XCTAssertNotNil(path);
    NSMutableDictionary *dic = [_persistence getStoredMeta:path error:&error];
    XCTAssertNotNil(dic);
    XCTAssertNil(error);
    NSString *content = dic[@"content"];
    XCTAssertNotNil(content);
    NSMutableDictionary *contentDic = [NSJSONSerialization JSONObjectWithData:[content dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
    XCTAssertNotNil(contentDic);
    XCTAssertNil(error);
    
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
        if (![key isEqualToString:@"content"]) {
            XCTAssertTrue([[meta valueForKey:key] isEqual:obj]);
        }
    }];
    
    [contentDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
        XCTAssertTrue([[meta valueForKey:key] isEqual:obj]);
    }];
    [_persistence purgeFile:path];
}

- (void)testLagMonitor {
    NSError *error;
    [_persistence purgeAllLagMeta];
    NSString *dataPath = [[NSBundle bundleForClass:self.class] pathForResource:@"lag" ofType:@"dat"];
    XCTAssertNotNil(dataPath);
    NSData *data = [NSData dataWithContentsOfFile:dataPath];
    XCTAssertNotNil(data);
    PREDLagMeta *meta = [[PREDLagMeta alloc] initWithData:data error:&error];
    XCTAssertNil(error);
    [_persistence persistLagMeta:meta];
    NSString *path = [_persistence nextLagMetaPath];
    XCTAssertNotNil(path);
    NSMutableDictionary *dic = [_persistence getStoredMeta:path error:&error];
    XCTAssertNotNil(dic);
    XCTAssertNil(error);
    NSString *content = dic[@"content"];
    XCTAssertNotNil(content);
    NSMutableDictionary *contentDic = [NSJSONSerialization JSONObjectWithData:[content dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
    XCTAssertNotNil(contentDic);
    XCTAssertNil(error);
    
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
        if (![key isEqualToString:@"content"]) {
            XCTAssertTrue([[meta valueForKey:key] isEqual:obj]);
        }
    }];
    
    [contentDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
        XCTAssertTrue([[meta valueForKey:key] isEqual:obj]);
    }];
    [_persistence purgeFile:path];
}

- (void)testLogCapture {
    NSError *error;
    [_persistence purgeAllLagMeta];
    NSString *dataPath = [[NSBundle bundleForClass:self.class] pathForResource:@"lag" ofType:@"dat"];
    XCTAssertNotNil(dataPath);
    NSData *data = [NSData dataWithContentsOfFile:dataPath];
    XCTAssertNotNil(data);
    PREDLagMeta *meta = [[PREDLagMeta alloc] initWithData:data error:&error];
    XCTAssertNil(error);
    [_persistence persistLagMeta:meta];
    NSString *path = [_persistence nextLagMetaPath];
    XCTAssertNotNil(path);
    NSMutableDictionary *dic = [_persistence getStoredMeta:path error:&error];
    XCTAssertNotNil(dic);
    XCTAssertNil(error);
    NSString *content = dic[@"content"];
    XCTAssertNotNil(content);
    NSMutableDictionary *contentDic = [NSJSONSerialization JSONObjectWithData:[content dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
    XCTAssertNotNil(contentDic);
    XCTAssertNil(error);
    
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
        if (![key isEqualToString:@"content"]) {
            XCTAssertTrue([[meta valueForKey:key] isEqual:obj]);
        }
    }];
    
    [contentDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
        XCTAssertTrue([[meta valueForKey:key] isEqual:obj]);
    }];
    [_persistence purgeFile:path];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
