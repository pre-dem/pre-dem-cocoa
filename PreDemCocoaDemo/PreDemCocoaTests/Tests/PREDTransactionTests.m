//
//  PREDCrashTests.m
//  PreDemObjcTests
//
//  Created by 王思宇 on 29/09/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDPersistence.h"
#import "PREDTransactionPrivate.h"
#import <XCTest/XCTest.h>

@interface PREDTransactionTests : XCTestCase

@end

@implementation PREDTransactionTests {
  PREDPersistence *_persistence;
}

- (void)setUp {
  [super setUp];
  // Put setup code here. This method is called before the invocation of each
  // test method in the class.
  self.continueAfterFailure = NO;
  _persistence = [[PREDPersistence alloc] init];
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each
  // test method in the class.
  [super tearDown];
}

- (void)testCompletedTransaction {
  [_persistence purgeAllTransactions];
  PREDTransaction *transaction =
      [PREDTransaction transactionWithPersistence:_persistence];
  [transaction complete];
  NSString *filePath = [_persistence nextArchivedTransactionsPath];
  XCTAssertNotEqual(filePath.length, 0);
  NSData *data = [NSData dataWithContentsOfFile:filePath];
  XCTAssertNotEqual(data.length, 0);
  NSError *error;
  NSDictionary *parsedData =
      [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
  XCTAssertNil(error, @"%@", error);
  XCTAssertNotNil(parsedData);
  XCTAssertEqual([parsedData respondsToSelector:@selector(objectForKey:)], YES);
  NSString *content = parsedData[@"content"];
  XCTAssertNotEqual([content length], 0);
  NSDictionary *parsedContent = [NSJSONSerialization
      JSONObjectWithData:[content dataUsingEncoding:NSUTF8StringEncoding]
                 options:0
                   error:&error];
  XCTAssertNil(error, @"%@", error);
  XCTAssertNotNil(parsedContent);
  [parsedContent[@"transaction_type"] isEqual:@(PREDTransactionTypeCompleted)];
}

- (void)testCancelledTransaction {
  [_persistence purgeAllTransactions];
  PREDTransaction *transaction =
      [PREDTransaction transactionWithPersistence:_persistence];
  NSString *reason = @"test reason";
  [transaction cancelWithReason:reason];
  NSString *filePath = [_persistence nextArchivedTransactionsPath];
  XCTAssertNotEqual(filePath.length, 0);
  NSData *data = [NSData dataWithContentsOfFile:filePath];
  XCTAssertNotEqual(data.length, 0);
  NSError *error;
  NSDictionary *parsedData =
      [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
  XCTAssertNil(error, @"%@", error);
  XCTAssertNotNil(parsedData);
  XCTAssertEqual([parsedData respondsToSelector:@selector(objectForKey:)], YES);
  NSString *content = parsedData[@"content"];
  XCTAssertNotEqual([content length], 0);
  NSDictionary *parsedContent = [NSJSONSerialization
      JSONObjectWithData:[content dataUsingEncoding:NSUTF8StringEncoding]
                 options:0
                   error:&error];
  XCTAssertNil(error, @"%@", error);
  XCTAssertNotNil(parsedContent);
  [parsedContent[@"transaction_type"] isEqual:@(PREDTransactionTypeCancelled)];
  [parsedContent[@"reason"] isEqual:reason];
}

- (void)testfailedTransaction {
  [_persistence purgeAllTransactions];
  PREDTransaction *transaction =
      [PREDTransaction transactionWithPersistence:_persistence];
  NSString *reason = @"test reason";
  [transaction failWithReason:reason];
  NSString *filePath = [_persistence nextArchivedTransactionsPath];
  XCTAssertNotEqual(filePath.length, 0);
  NSData *data = [NSData dataWithContentsOfFile:filePath];
  XCTAssertNotEqual(data.length, 0);
  NSError *error;
  NSDictionary *parsedData =
      [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
  XCTAssertNil(error, @"%@", error);
  XCTAssertNotNil(parsedData);
  XCTAssertEqual([parsedData respondsToSelector:@selector(objectForKey:)], YES);
  NSString *content = parsedData[@"content"];
  XCTAssertNotEqual([content length], 0);
  NSDictionary *parsedContent = [NSJSONSerialization
      JSONObjectWithData:[content dataUsingEncoding:NSUTF8StringEncoding]
                 options:0
                   error:&error];
  XCTAssertNil(error, @"%@", error);
  XCTAssertNotNil(parsedContent);
  [parsedContent[@"transaction_type"] isEqual:@(PREDTransactionTypeFailed)];
  [parsedContent[@"reason"] isEqual:reason];
}

@end
