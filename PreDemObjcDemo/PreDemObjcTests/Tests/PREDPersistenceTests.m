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
    PREDAppInfo *appinfo = [[PREDAppInfo alloc] init];
    [_persistence persistAppInfo:appinfo];
    NSString *path = [_persistence nextAppInfoPath];
    XCTAssertNotNil(path);
    NSMutableDictionary *dic = [_persistence getStoredMeta:path error:&error];
    XCTAssertNotNil(dic);
    XCTAssertNil(error);
    unsigned int count, count1, count2;
    class_copyPropertyList(PREDAppInfo.class, &count1);
    class_copyPropertyList(PREDAppInfo.superclass, &count2);
    count = count1 + count2;
    XCTAssertEqual(count, dic.count);
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        XCTAssertTrue([[appinfo valueForKey:key] isEqualToString:obj]);
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
    unsigned int count, count1, count2;
    class_copyPropertyList(PREDCrashMeta.class, &count1);
    class_copyPropertyList(PREDCrashMeta.superclass, &count2);
    count = count1 + count2;
    XCTAssertEqual(count, dic.count);
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
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
    unsigned int count, count1, count2;
    class_copyPropertyList(PREDLagMeta.class, &count1);
    class_copyPropertyList(PREDLagMeta.superclass, &count2);
    count = count1 + count2;
    XCTAssertEqual(count, dic.count);
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
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
    unsigned int count, count1, count2;
    class_copyPropertyList(PREDLagMeta.class, &count1);
    class_copyPropertyList(PREDLagMeta.superclass, &count2);
    count = count1 + count2;
    XCTAssertEqual(count, dic.count);
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
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
