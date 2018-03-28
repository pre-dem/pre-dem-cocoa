//
//  PREDCrashTests.m
//  PreDemObjcTests
//
//  Created by 王思宇 on 29/09/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PREDNetDiag.h"

@interface PREDNetDiagTests : XCTestCase

@end

@implementation PREDNetDiagTests {
    PREDPersistence *_persistence;
}

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.continueAfterFailure = NO;
    _persistence = [[PREDPersistence alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testNetDiag {
    [_persistence purgeAllNetDiag];
    __block PREDNetDiagResult *originalResult;
    XCTestExpectation *expectation = [self expectationWithDescription:@"diagnosing"];
    [PREDNetDiag diagnose:@"http://predem.qiniu.com" persistence:_persistence complete:^(PREDNetDiagResult *result) {
        originalResult = result;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:60 handler:^(NSError *error) {
        XCTAssertNil(error, @"%@", error);
    }];
    NSString *filePath = [_persistence nextArchivedNetDiagPath];
    XCTAssertNotEqual(filePath.length, 0);
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    XCTAssertNotEqual(data.length, 0);
    NSError *error;
    NSDictionary *parsedData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    XCTAssertNil(error, @"%@", error);
    XCTAssertNotNil(parsedData);
    XCTAssertEqual([parsedData respondsToSelector:@selector(objectForKey:)], YES);
    NSString *content = parsedData[@"content"];
    XCTAssertNotEqual([content length], 0);
    NSDictionary *parsedContent = [NSJSONSerialization JSONObjectWithData:[content dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNil(error, @"%@", error);
    XCTAssertNotNil(parsedContent);
    [parsedContent enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSString *_Nonnull obj, BOOL *_Nonnull stop) {
        XCTAssertTrue([[originalResult valueForKey:key] isEqual:obj]);
    }];
    [_persistence purgeAllNetDiag];
}

@end
