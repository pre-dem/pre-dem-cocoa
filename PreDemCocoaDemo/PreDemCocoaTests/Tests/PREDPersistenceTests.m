//
//  PREDPersistenceTests.m
//  PreDemObjcTests
//
//  Created by 王思宇 on 29/09/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PREDPersistence.h"
#import "PREDNetDiagResultPrivate.h"
#import "PREDTransactionPrivate.h"

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
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSString *_Nonnull obj, BOOL *_Nonnull stop) {
        XCTAssertTrue([[event1 valueForKey:key] isEqual:obj]);
    }];

    dic = [NSJSONSerialization JSONObjectWithData:[components[1] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(dic);
    XCTAssertNil(error);
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSString *_Nonnull obj, BOOL *_Nonnull stop) {
        XCTAssertTrue([[event2 valueForKey:key] isEqual:obj]);
    }];

    [_persistence purgeAllAppInfo];
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
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSString *_Nonnull obj, BOOL *_Nonnull stop) {
        if (![key isEqualToString:@"content"]) {
            XCTAssertTrue([[event1 valueForKey:key] isEqual:obj]);
        }
    }];

    [contentDic enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSString *_Nonnull obj, BOOL *_Nonnull stop) {
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
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSString *_Nonnull obj, BOOL *_Nonnull stop) {
        if (![key isEqualToString:@"content"]) {
            XCTAssertTrue([[event2 valueForKey:key] isEqual:obj]);
        }
    }];
    [contentDic enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSString *_Nonnull obj, BOOL *_Nonnull stop) {
        XCTAssertTrue([[event1 valueForKey:key] isEqual:obj]);
    }];

    [_persistence purgeFile:path];
}

- (void)testNetDiag {
    NSError *error;
    [_persistence purgeAllNetDiag];

    PREDNetDiagResult *event1 = [[PREDNetDiagResult alloc] initWithComplete:nil persistence:_persistence];
    [_persistence persistNetDiagResult:event1];

    PREDNetDiagResult *event2 = [[PREDNetDiagResult alloc] initWithComplete:nil persistence:_persistence];
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
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSString *_Nonnull obj, BOOL *_Nonnull stop) {
        if (![key isEqualToString:@"content"]) {
            XCTAssertTrue([[event1 valueForKey:key] isEqual:obj]);
        }
    }];

    [contentDic enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSString *_Nonnull obj, BOOL *_Nonnull stop) {
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
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSString *_Nonnull obj, BOOL *_Nonnull stop) {
        if (![key isEqualToString:@"content"]) {
            XCTAssertTrue([[event2 valueForKey:key] isEqual:obj]);
        }
    }];
    [contentDic enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSString *_Nonnull obj, BOOL *_Nonnull stop) {
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
            @"floatKey": @(arc4random_uniform(10000) / 100.0)
    };
    PREDCustomEvent *event1 = [PREDCustomEvent eventWithName:@"test\t_\nios\t_\nevent_1" contentDic:dict1];
    [_persistence persistCustomEvent:event1];

    NSDictionary *dict2 = @{
            @"stringKey": [NSString stringWithFormat:@"test\t_\n%d", arc4random_uniform(100)],
            @"longKey": @(arc4random_uniform(100)),
            @"floatKey": @(arc4random_uniform(10000) / 100.0)
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
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSString *_Nonnull obj, BOOL *_Nonnull stop) {
        XCTAssertTrue([[event1 valueForKey:key] isEqual:obj]);
    }];

    dic = [NSJSONSerialization JSONObjectWithData:[components[1] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(dic);
    XCTAssertNil(error);
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSString *_Nonnull obj, BOOL *_Nonnull stop) {
        XCTAssertTrue([[event2 valueForKey:key] isEqual:obj]);
    }];

    [_persistence purgeFile:path];
}

- (void)testTransaction {
    NSError *error;
    [_persistence purgeAllTransactions];

    PREDTransaction *event1 = [PREDTransaction transactionWithPersistence:_persistence];
    [_persistence persistTransaction:event1];

    PREDTransaction *event2 = [PREDTransaction transactionWithPersistence:_persistence];
    [_persistence persistTransaction:event2];

    NSString *path = [_persistence nextArchivedTransactionsPath];
    XCTAssertNotEqual(path.length, 0);
    NSData *data = [NSData dataWithContentsOfFile:path];
    XCTAssertNotEqual(data.length, 0);
    NSString *eventString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *components = [eventString componentsSeparatedByString:@"\n"];
    XCTAssertEqual(components.count, 3);

    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:[components[0] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(dic);
    XCTAssertNil(error);
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSString *_Nonnull obj, BOOL *_Nonnull stop) {
        if (![key isEqualToString:@"content"]) {
            XCTAssertTrue([[event1 valueForKey:key] isEqual:obj]);
        }
    }];

    NSString *content = dic[@"content"];
    XCTAssertNotNil(content);
    NSMutableDictionary *contentDic = [NSJSONSerialization JSONObjectWithData:[content dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
    XCTAssertNotNil(contentDic);
    XCTAssertNil(error);
    [contentDic enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSString *_Nonnull obj, BOOL *_Nonnull stop) {
        XCTAssertTrue([[event1 valueForKey:key] isEqual:obj]);
    }];

    dic = [NSJSONSerialization JSONObjectWithData:[components[1] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(dic);
    XCTAssertNil(error);
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSString *_Nonnull obj, BOOL *_Nonnull stop) {
        if (![key isEqualToString:@"content"]) {
            XCTAssertTrue([[event2 valueForKey:key] isEqual:obj]);
        }
    }];

    content = dic[@"content"];
    XCTAssertNotNil(content);
    contentDic = [NSJSONSerialization JSONObjectWithData:[content dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
    XCTAssertNotNil(contentDic);
    XCTAssertNil(error);
    [contentDic enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSString *_Nonnull obj, BOOL *_Nonnull stop) {
        XCTAssertTrue([[event2 valueForKey:key] isEqual:obj]);
    }];

    [_persistence purgeFile:path];
}

@end
