//
//  PREDCrashTests.m
//  PreDemObjcTests
//
//  Created by 王思宇 on 29/09/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PREDURLProtocol.h"

@interface PREDHttpTests : XCTestCase
        <
        UIWebViewDelegate
        >

@end

@implementation PREDHttpTests {
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

- (void)testForSharedSession {
    [_persistence purgeAllHttpMonitor];
    [PREDURLProtocol setPersistence:_persistence];
    PREDURLProtocol.started = YES;
    NSURLSession *session = [NSURLSession sharedSession];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download predem page"];
    __block NSData *originalData;
    __block NSHTTPURLResponse *originalResponse;
    __block NSError *originalError;
    [[session dataTaskWithURL:[NSURL URLWithString:@"http://predem.qiniu.com"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        originalData = data;
        originalResponse = (NSHTTPURLResponse *) response;
        originalError = error;
        [expectation fulfill];
    }] resume];
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNil(error, @"%@", error);
    }];
    NSString *filePath = [_persistence nextArchivedHttpMonitorPath];
    XCTAssertNotEqual(filePath.length, 0);
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    XCTAssertNotEqual(data.length, 0);
    NSString *test = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(test);
}

- (void)testForCustomSession {
    [_persistence purgeAllHttpMonitor];
    [PREDURLProtocol setPersistence:_persistence];
    PREDURLProtocol.started = YES;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download predem page"];
    [[session dataTaskWithURL:[NSURL URLWithString:@"http://predem.qiniu.com"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"%@, %@, %@", nil, response, error);
        [expectation fulfill];
    }] resume];
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNil(error, @"%@", error);
    }];
    NSString *filePath = [_persistence nextArchivedHttpMonitorPath];
    XCTAssertNotEqual(filePath.length, 0);
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    XCTAssertNotEqual(data.length, 0);
    NSString *test = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(test);
}

- (void)testForHttpURLConnection {
    [_persistence purgeAllHttpMonitor];
    [PREDURLProtocol setPersistence:_persistence];
    PREDURLProtocol.started = YES;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download predem page"];
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://predem.qiniu.com"]] queue:[NSOperationQueue new] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSLog(@"%@, %@, %@", nil, response, connectionError);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNil(error, @"%@", error);
    }];
    NSString *filePath = [_persistence nextArchivedHttpMonitorPath];
    XCTAssertNotEqual(filePath.length, 0);
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    XCTAssertNotEqual(data.length, 0);
    NSString *test = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(test);
}

@end
