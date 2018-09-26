//
//  PREDCrashTests.m
//  PreDemObjcTests
//
//  Created by 王思宇 on 29/09/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDManagerPrivate.h"
#import "PREDPersistence.h"
#import "PREDSender.h"
#import "PREDTransactionPrivate.h"
#import <XCTest/XCTest.h>

@interface PREDSenderTests : XCTestCase

@end

@implementation PREDSenderTests {
  PREDPersistence *_persistence;
  PREDSender *_sender;
}

- (void)setUp {
  [super setUp];
  // Put setup code here. This method is called before the invocation of each
  // test method in the class.
  self.continueAfterFailure = NO;
  _sender = [[PREDSender alloc]
      initWithBaseUrl:[NSURL URLWithString:@"http://"
                                           @"bhk5aaghth5n.predem.qiniuapi."
                                           @"com/v2/A_5p9l3Z/"]];
  [PREDManager sharedPREDManager].appKey = @"A_5p9l3Z";
  PREDManager.tag = @"xcodetest";
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each
  // test method in the class.
  [super tearDown];
}

- (void)testAppSender {
  __block NSData *originalData;
  __block NSError *originalError;
  XCTestExpectation *expectation = [self expectationWithDescription:@"sending"];
  [_sender sendAppInfo:^(PREDHTTPOperation *operation, NSData *data,
                         NSError *error) {
    originalData = data;
    originalError = error;
    [expectation fulfill];
  }];
  [self waitForExpectationsWithTimeout:10
                               handler:^(NSError *error) {
                                 XCTAssertNil(error, @"%@", error);
                               }];
  XCTAssertNotNil(originalData);
  XCTAssertNil(originalError);
}

- (void)testCustomSender {
  [_sender purgeAll];
  [_sender persistCustomEvent:[PREDCustomEvent eventWithName:@"testName"
                                                  contentDic:nil]];
  __block NSData *originalData;
  __block NSError *originalError;
  XCTestExpectation *expectation = [self expectationWithDescription:@"sending"];
  [_sender sendCustomEvents:^(PREDHTTPOperation *operation, NSData *data,
                              NSError *error) {
    originalData = data;
    originalError = error;
    [expectation fulfill];
  }
                recursively:NO];
  [self waitForExpectationsWithTimeout:10
                               handler:^(NSError *error) {
                                 XCTAssertNil(error, @"%@", error);
                               }];
  XCTAssertNotNil(originalData);
  XCTAssertNil(originalError);
  [_sender purgeAll];
}

- (void)testTransactionSender {
  [_sender purgeAll];
  [_sender persistTransaction:[PREDTransaction transactionWithSender:_sender]];
  __block NSData *originalData;
  __block NSError *originalError;
  XCTestExpectation *expectation = [self expectationWithDescription:@"sending"];
  [_sender sendTransactions:^(PREDHTTPOperation *operation, NSData *data,
                              NSError *error) {
    originalData = data;
    originalError = error;
    [expectation fulfill];
  }
                recursively:NO];
  [self waitForExpectationsWithTimeout:10
                               handler:^(NSError *error) {
                                 XCTAssertNil(error, @"%@", error);
                               }];
  XCTAssertNotNil(originalData);
  XCTAssertNil(originalError);
  [_sender purgeAll];
}

@end
