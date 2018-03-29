//
//  PREDCrashTests.m
//  PreDemObjcTests
//
//  Created by 王思宇 on 29/09/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PREDPersistence.h"
#import "PREDSender.h"
#import "PREDManagerPrivate.h"
#import "PREDTransactionPrivate.h"

@interface PREDSenderTests : XCTestCase

@end

@implementation PREDSenderTests {
    PREDPersistence *_persistence;
    PREDSender *_sender;
}

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.continueAfterFailure = NO;
    _persistence = [[PREDPersistence alloc] init];
    _sender = [[PREDSender alloc] initWithPersistence:_persistence baseUrl:[NSURL URLWithString:@"http://bhk5aaghth5n.predem.qiniuapi.com/v2/A_5p9l3Z/"]];
    [PREDManager sharedPREDManager].appKey = @"A_5p9l3Z";
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAppSender {
    [_persistence purgeAllAppInfo];
    [_persistence persistAppInfo:[[PREDAppInfo alloc] init]];
    __block NSData *originalData;
    __block NSError *originalError;
    XCTestExpectation *expectation = [self expectationWithDescription:@"sending"];
    [_sender sendAppInfo:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
        originalData = data;
        originalError = error;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNil(error, @"%@", error);
    }];
    XCTAssertNotNil(originalData);
    XCTAssertNil(originalError);
    [_persistence purgeAllAppInfo];
}

- (void)testHttpSender {
    [_persistence purgeAllHttpMonitor];
    [_persistence persistHttpMonitor:[[PREDHTTPMonitorModel alloc] init]];
    __block NSData *originalData;
    __block NSError *originalError;
    XCTestExpectation *expectation = [self expectationWithDescription:@"sending"];
    [_sender sendHttpMonitor:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
        originalData = data;
        originalError = error;
        [expectation fulfill];
    } recursively:NO];
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNil(error, @"%@", error);
    }];
    XCTAssertNotNil(originalData);
    XCTAssertNil(originalError);
    [_persistence purgeAllHttpMonitor];
}

- (void)testNetDiagSender {
    [_persistence purgeAllNetDiag];
    [_persistence persistNetDiagResult:[[PREDNetDiagResult alloc] init]];
    __block NSData *originalData;
    __block NSError *originalError;
    XCTestExpectation *expectation = [self expectationWithDescription:@"sending"];
    [_sender sendNetDiag:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
        originalData = data;
        originalError = error;
        [expectation fulfill];
    } recursively:NO];
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNil(error, @"%@", error);
    }];
    XCTAssertNotNil(originalData);
    XCTAssertNil(originalError);
    [_persistence purgeAllNetDiag];
}

- (void)testCustomSender {
    [_persistence purgeAllCustom];
    [_persistence persistCustomEvent:[PREDCustomEvent eventWithName:@"testName" contentDic:nil]];
    __block NSData *originalData;
    __block NSError *originalError;
    XCTestExpectation *expectation = [self expectationWithDescription:@"sending"];
    [_sender sendCustomEvents:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
        originalData = data;
        originalError = error;
        [expectation fulfill];
    } recursively:NO];
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNil(error, @"%@", error);
    }];
    XCTAssertNotNil(originalData);
    XCTAssertNil(originalError);
    [_persistence purgeAllCustom];
}

- (void)testTransactionSender {
    [_persistence purgeAllTransactions];
    [_persistence persistTransaction:[PREDTransaction transactionWithPersistence:_persistence]];
    __block NSData *originalData;
    __block NSError *originalError;
    XCTestExpectation *expectation = [self expectationWithDescription:@"sending"];
    [_sender sendTransactions:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
        originalData = data;
        originalError = error;
        [expectation fulfill];
    } recursively:NO];
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNil(error, @"%@", error);
    }];
    XCTAssertNotNil(originalData);
    XCTAssertNil(originalError);
    [_persistence purgeAllTransactions];
}

@end
