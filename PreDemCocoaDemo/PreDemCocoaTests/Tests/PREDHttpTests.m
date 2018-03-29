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

@end

@implementation PREDHttpTests {
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

- (void)testForSharedSessionHttps200 {
    [_persistence purgeAllHttpMonitor];
    [PREDURLProtocol setPersistence:_persistence];
    PREDURLProtocol.started = YES;
    NSURLSession *session = [NSURLSession sharedSession];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download predem page"];
    __block NSData *originalData;
    __block NSHTTPURLResponse *originalResponse;
    __block NSError *originalError;
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:[NSURL URLWithString:@"https://test.predem.qiniuapi.com"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        originalData = data;
        originalResponse = (NSHTTPURLResponse *) response;
        originalError = error;
        [expectation fulfill];
    }];
    [dataTask resume];
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNil(error, @"%@", error);
    }];
    NSString *filePath = [_persistence nextArchivedHttpMonitorPath];
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
    XCTAssertEqual([parsedContent respondsToSelector:@selector(objectForKey:)], YES);
    XCTAssertTrue([dataTask.originalRequest.URL.host isEqual:parsedContent[@"domain"]]);
    XCTAssertTrue([dataTask.originalRequest.HTTPMethod isEqual:parsedContent[@"method"]]);
    if (dataTask.originalRequest.URL.path.length == 0) {
        XCTAssertTrue([@"/" isEqual:parsedContent[@"path"]]);
    } else {
        XCTAssertTrue([dataTask.originalRequest.URL.path isEqual:parsedContent[@"path"]]);
    }

    XCTAssertNil(originalError);
    XCTAssertEqual(originalResponse.statusCode, 200);
    XCTAssertEqual([parsedContent[@"status_code"] intValue], 200);
    XCTAssertEqual(originalData.length, 168);
    XCTAssertEqual([parsedContent[@"data_length"] intValue], 168);
    XCTAssertNil(parsedContent[@"network_error_msg"]);
    XCTAssertEqual([parsedContent[@"network_error_code"] intValue], 0);
    XCTAssertTrue([parsedContent[@"start_timestamp"] intValue] > 0);
    XCTAssertTrue([parsedContent[@"response_time_stamp"] intValue] >= [parsedContent[@"start_timestamp"] intValue]);
    XCTAssertTrue([parsedContent[@"end_timestamp"] intValue] >= [parsedContent[@"start_timestamp"] intValue]);
    [_persistence purgeAllHttpMonitor];
}

- (void)testForSharedSessionHttp200 {
    [_persistence purgeAllHttpMonitor];
    [PREDURLProtocol setPersistence:_persistence];
    PREDURLProtocol.started = YES;
    NSURLSession *session = [NSURLSession sharedSession];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download predem page"];
    __block NSData *originalData;
    __block NSHTTPURLResponse *originalResponse;
    __block NSError *originalError;
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:[NSURL URLWithString:@"http://predem.qiniu.com"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        originalData = data;
        originalResponse = (NSHTTPURLResponse *) response;
        originalError = error;
        [expectation fulfill];
    }];
    [dataTask resume];
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNil(error, @"%@", error);
    }];
    NSString *filePath = [_persistence nextArchivedHttpMonitorPath];
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
    XCTAssertEqual([parsedContent respondsToSelector:@selector(objectForKey:)], YES);
    XCTAssertTrue([dataTask.originalRequest.URL.host isEqual:parsedContent[@"domain"]]);
    XCTAssertTrue([dataTask.originalRequest.HTTPMethod isEqual:parsedContent[@"method"]]);
    if (dataTask.originalRequest.URL.path.length == 0) {
        XCTAssertTrue([@"/" isEqual:parsedContent[@"path"]]);
    } else {
        XCTAssertTrue([dataTask.originalRequest.URL.path isEqual:parsedContent[@"path"]]);
    }

    XCTAssertNil(originalError);
    XCTAssertEqual(originalResponse.statusCode, 200);
    XCTAssertEqual([parsedContent[@"status_code"] intValue], 200);
    XCTAssertEqual(originalData.length, [parsedContent[@"data_length"] intValue]);
    XCTAssertNil(parsedContent[@"network_error_msg"]);
    XCTAssertEqual([parsedContent[@"network_error_code"] intValue], 0);
    XCTAssertTrue([parsedContent[@"start_timestamp"] intValue] > 0);
    XCTAssertTrue([parsedContent[@"response_time_stamp"] intValue] >= [parsedContent[@"start_timestamp"] intValue]);
    XCTAssertTrue([parsedContent[@"end_timestamp"] intValue] >= [parsedContent[@"start_timestamp"] intValue]);
    XCTAssertTrue([parsedContent[@"dns_time"] intValue] >= 0);
    XCTAssertNotEqual(((NSString *) parsedContent[@"host_ip"]).length, 0);
    [_persistence purgeAllHttpMonitor];
}

- (void)testForSharedSession404 {
    [_persistence purgeAllHttpMonitor];
    [PREDURLProtocol setPersistence:_persistence];
    PREDURLProtocol.started = YES;
    NSURLSession *session = [NSURLSession sharedSession];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download predem page"];
    __block NSData *originalData;
    __block NSHTTPURLResponse *originalResponse;
    __block NSError *originalError;
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:[NSURL URLWithString:@"https://test.predem.qiniuapi.com/404"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        originalData = data;
        originalResponse = (NSHTTPURLResponse *) response;
        originalError = error;
        [expectation fulfill];
    }];
    [dataTask resume];
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNil(error, @"%@", error);
    }];
    NSString *filePath = [_persistence nextArchivedHttpMonitorPath];
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
    XCTAssertEqual([parsedContent respondsToSelector:@selector(objectForKey:)], YES);
    XCTAssertTrue([dataTask.originalRequest.URL.host isEqual:parsedContent[@"domain"]]);
    XCTAssertTrue([dataTask.originalRequest.HTTPMethod isEqual:parsedContent[@"method"]]);
    if (dataTask.originalRequest.URL.path.length == 0) {
        XCTAssertTrue([@"/" isEqual:parsedContent[@"path"]]);
    } else {
        XCTAssertTrue([dataTask.originalRequest.URL.path isEqual:parsedContent[@"path"]]);
    }
    NSLog(@"%@", [[NSString alloc] initWithData:originalData encoding:NSUTF8StringEncoding]);
    XCTAssertNil(originalError);
    XCTAssertEqual(originalResponse.statusCode, 404);
    XCTAssertEqual([parsedContent[@"status_code"] intValue], 404);
    XCTAssertEqual(originalData.length, 18);
    XCTAssertEqual([parsedContent[@"data_length"] intValue], 18);
    XCTAssertNil(parsedContent[@"network_error_msg"]);
    XCTAssertEqual([parsedContent[@"network_error_code"] intValue], 0);
    XCTAssertTrue([parsedContent[@"start_timestamp"] intValue] > 0);
    XCTAssertTrue([parsedContent[@"response_time_stamp"] intValue] >= [parsedContent[@"start_timestamp"] intValue]);
    XCTAssertTrue([parsedContent[@"end_timestamp"] intValue] >= [parsedContent[@"start_timestamp"] intValue]);
    [_persistence purgeAllHttpMonitor];
}

- (void)testForSharedSessionNetworkError {
    [_persistence purgeAllHttpMonitor];
    [PREDURLProtocol setPersistence:_persistence];
    PREDURLProtocol.started = YES;
    NSURLSession *session = [NSURLSession sharedSession];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download predem page"];
    __block NSData *originalData;
    __block NSHTTPURLResponse *originalResponse;
    __block NSError *originalError;
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:[NSURL URLWithString:@"http://balabala.dem.bala"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        originalData = data;
        originalResponse = (NSHTTPURLResponse *) response;
        originalError = error;
        [expectation fulfill];
    }];
    [dataTask resume];
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNil(error, @"%@", error);
    }];
    NSString *filePath = [_persistence nextArchivedHttpMonitorPath];
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
    XCTAssertEqual([parsedContent respondsToSelector:@selector(objectForKey:)], YES);
    XCTAssertTrue([dataTask.originalRequest.URL.host isEqual:parsedContent[@"domain"]]);
    XCTAssertTrue([dataTask.originalRequest.HTTPMethod isEqual:parsedContent[@"method"]]);
    if (dataTask.originalRequest.URL.path.length == 0) {
        XCTAssertTrue([@"/" isEqual:parsedContent[@"path"]]);
    } else {
        XCTAssertTrue([dataTask.originalRequest.URL.path isEqual:parsedContent[@"path"]]);
    }

    XCTAssertNotNil(originalError);
    XCTAssertEqual(originalResponse.statusCode, 0);
    XCTAssertEqual(originalData.length, 0);
    XCTAssertTrue([originalError.localizedDescription isEqual:parsedContent[@"network_error_msg"]]);
    XCTAssertEqual(originalError.code, [parsedContent[@"network_error_code"] intValue]);
    XCTAssertTrue([parsedContent[@"start_timestamp"] intValue] > 0);
    XCTAssertTrue([parsedContent[@"response_time_stamp"] intValue] >= [parsedContent[@"start_timestamp"] intValue]);
    XCTAssertTrue([parsedContent[@"end_timestamp"] intValue] >= [parsedContent[@"start_timestamp"] intValue]);
    [_persistence purgeAllHttpMonitor];
}

- (void)testForSharedSessionNoProxy1 {
    [_persistence purgeAllHttpMonitor];
    [PREDURLProtocol setPersistence:_persistence];
    PREDURLProtocol.started = YES;
    NSURLSession *session = [NSURLSession sharedSession];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download predem page"];
    NSString *url;
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        [expectation fulfill];
    }];
    [dataTask resume];
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNil(error, @"%@", error);
    }];
    NSString *filePath = [_persistence nextArchivedHttpMonitorPath];
    XCTAssertNil(filePath);
    [_persistence purgeAllHttpMonitor];
}

- (void)testForSharedSessionNoProxy2 {
    [_persistence purgeAllHttpMonitor];
    [PREDURLProtocol setPersistence:_persistence];
    PREDURLProtocol.started = YES;
    NSURLSession *session = [NSURLSession sharedSession];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download predem page"];
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:[NSURL URLWithString:@"rtmp://test.qiniu.com"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        [expectation fulfill];
    }];
    [dataTask resume];
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNil(error, @"%@", error);
    }];
    NSString *filePath = [_persistence nextArchivedHttpMonitorPath];
    XCTAssertNil(filePath);
    [_persistence purgeAllHttpMonitor];
}

- (void)testForCustomSession {
    [_persistence purgeAllHttpMonitor];
    [PREDURLProtocol setPersistence:_persistence];
    PREDURLProtocol.started = YES;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download predem page"];
    __block NSData *originalData;
    __block NSHTTPURLResponse *originalResponse;
    __block NSError *originalError;
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:[NSURL URLWithString:@"https://test.predem.qiniuapi.com"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        originalData = data;
        originalResponse = (NSHTTPURLResponse *) response;
        originalError = error;
        [expectation fulfill];
    }];
    [dataTask resume];
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNil(error, @"%@", error);
    }];
    NSString *filePath = [_persistence nextArchivedHttpMonitorPath];
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
    XCTAssertEqual([parsedContent respondsToSelector:@selector(objectForKey:)], YES);
    XCTAssertTrue([dataTask.originalRequest.URL.host isEqual:parsedContent[@"domain"]]);
    XCTAssertTrue([dataTask.originalRequest.HTTPMethod isEqual:parsedContent[@"method"]]);
    if (dataTask.originalRequest.URL.path.length == 0) {
        XCTAssertTrue([@"/" isEqual:parsedContent[@"path"]]);
    } else {
        XCTAssertTrue([dataTask.originalRequest.URL.path isEqual:parsedContent[@"path"]]);
    }

    XCTAssertNil(originalError);
    XCTAssertEqual(originalResponse.statusCode, 200);
    XCTAssertEqual([parsedContent[@"status_code"] intValue], 200);
    XCTAssertEqual(originalData.length, 168);
    XCTAssertEqual([parsedContent[@"data_length"] intValue], 168);
    XCTAssertNil(parsedContent[@"network_error_msg"]);
    XCTAssertEqual([parsedContent[@"network_error_code"] intValue], 0);
    XCTAssertTrue([parsedContent[@"start_timestamp"] intValue] > 0);
    XCTAssertTrue([parsedContent[@"response_time_stamp"] intValue] >= [parsedContent[@"start_timestamp"] intValue]);
    XCTAssertTrue([parsedContent[@"end_timestamp"] intValue] >= [parsedContent[@"start_timestamp"] intValue]);
    [_persistence purgeAllHttpMonitor];
}

- (void)testForHttpURLConnectionHttps200 {
    [_persistence purgeAllHttpMonitor];
    [PREDURLProtocol setPersistence:_persistence];
    PREDURLProtocol.started = YES;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download predem page"];
    __block NSData *originalData;
    __block NSHTTPURLResponse *originalResponse;
    __block NSError *originalError;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://test.predem.qiniuapi.com"]];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue new] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        originalData = data;
        originalResponse = (NSHTTPURLResponse *) response;
        originalError = connectionError;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNil(error, @"%@", error);
    }];
    NSString *filePath = [_persistence nextArchivedHttpMonitorPath];
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
    XCTAssertEqual([parsedContent respondsToSelector:@selector(objectForKey:)], YES);
    XCTAssertTrue([request.URL.host isEqual:parsedContent[@"domain"]]);
    XCTAssertTrue([request.HTTPMethod isEqual:parsedContent[@"method"]]);
    if (request.URL.path.length == 0) {
        XCTAssertTrue([@"/" isEqual:parsedContent[@"path"]]);
    } else {
        XCTAssertTrue([request.URL.path isEqual:parsedContent[@"path"]]);
    }

    XCTAssertNil(originalError);
    XCTAssertEqual(originalResponse.statusCode, 200);
    XCTAssertEqual([parsedContent[@"status_code"] intValue], 200);
    XCTAssertEqual(originalData.length, 168);
    XCTAssertEqual([parsedContent[@"data_length"] intValue], 168);
    XCTAssertNil(parsedContent[@"network_error_msg"]);
    XCTAssertEqual([parsedContent[@"network_error_code"] intValue], 0);
    XCTAssertTrue([parsedContent[@"start_timestamp"] intValue] > 0);
    XCTAssertTrue([parsedContent[@"response_time_stamp"] intValue] >= [parsedContent[@"start_timestamp"] intValue]);
    XCTAssertTrue([parsedContent[@"end_timestamp"] intValue] >= [parsedContent[@"start_timestamp"] intValue]);
    [_persistence purgeAllHttpMonitor];
}

- (void)testForHttpURLConnectionHttp200 {
    [_persistence purgeAllHttpMonitor];
    [PREDURLProtocol setPersistence:_persistence];
    PREDURLProtocol.started = YES;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download predem page"];
    __block NSData *originalData;
    __block NSHTTPURLResponse *originalResponse;
    __block NSError *originalError;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://predem.qiniu.com"]];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue new] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        originalData = data;
        originalResponse = (NSHTTPURLResponse *) response;
        originalError = connectionError;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNil(error, @"%@", error);
    }];
    NSString *filePath = [_persistence nextArchivedHttpMonitorPath];
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
    XCTAssertEqual([parsedContent respondsToSelector:@selector(objectForKey:)], YES);
    XCTAssertTrue([request.URL.host isEqual:parsedContent[@"domain"]]);
    XCTAssertTrue([request.HTTPMethod isEqual:parsedContent[@"method"]]);
    if (request.URL.path.length == 0) {
        XCTAssertTrue([@"/" isEqual:parsedContent[@"path"]]);
    } else {
        XCTAssertTrue([request.URL.path isEqual:parsedContent[@"path"]]);
    }

    XCTAssertNil(originalError);
    XCTAssertEqual(originalResponse.statusCode, 200);
    XCTAssertEqual([parsedContent[@"status_code"] intValue], 200);
    XCTAssertEqual(originalData.length, [parsedContent[@"data_length"] intValue]);
    XCTAssertNil(parsedContent[@"network_error_msg"]);
    XCTAssertEqual([parsedContent[@"network_error_code"] intValue], 0);
    XCTAssertTrue([parsedContent[@"start_timestamp"] intValue] > 0);
    XCTAssertTrue([parsedContent[@"response_time_stamp"] intValue] >= [parsedContent[@"start_timestamp"] intValue]);
    XCTAssertTrue([parsedContent[@"end_timestamp"] intValue] >= [parsedContent[@"start_timestamp"] intValue]);
    [_persistence purgeAllHttpMonitor];
}

- (void)testForHttpURLConnectionHttps404 {
    [_persistence purgeAllHttpMonitor];
    [PREDURLProtocol setPersistence:_persistence];
    PREDURLProtocol.started = YES;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download predem page"];
    __block NSData *originalData;
    __block NSHTTPURLResponse *originalResponse;
    __block NSError *originalError;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://test.predem.qiniuapi.com/404"]];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue new] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        originalData = data;
        originalResponse = (NSHTTPURLResponse *) response;
        originalError = connectionError;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNil(error, @"%@", error);
    }];
    NSString *filePath = [_persistence nextArchivedHttpMonitorPath];
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
    XCTAssertEqual([parsedContent respondsToSelector:@selector(objectForKey:)], YES);
    XCTAssertTrue([request.URL.host isEqual:parsedContent[@"domain"]]);
    XCTAssertTrue([request.HTTPMethod isEqual:parsedContent[@"method"]]);
    if (request.URL.path.length == 0) {
        XCTAssertTrue([@"/" isEqual:parsedContent[@"path"]]);
    } else {
        XCTAssertTrue([request.URL.path isEqual:parsedContent[@"path"]]);
    }

    XCTAssertNil(originalError);
    XCTAssertEqual(originalResponse.statusCode, 404);
    XCTAssertEqual([parsedContent[@"status_code"] intValue], 404);
    XCTAssertEqual(originalData.length, 18);
    XCTAssertEqual([parsedContent[@"data_length"] intValue], 18);
    XCTAssertNil(parsedContent[@"network_error_msg"]);
    XCTAssertEqual([parsedContent[@"network_error_code"] intValue], 0);
    XCTAssertTrue([parsedContent[@"start_timestamp"] intValue] > 0);
    XCTAssertTrue([parsedContent[@"response_time_stamp"] intValue] >= [parsedContent[@"start_timestamp"] intValue]);
    XCTAssertTrue([parsedContent[@"end_timestamp"] intValue] >= [parsedContent[@"start_timestamp"] intValue]);
    [_persistence purgeAllHttpMonitor];
}

- (void)testForHttpURLConnectionNetworkError {
    [_persistence purgeAllHttpMonitor];
    [PREDURLProtocol setPersistence:_persistence];
    PREDURLProtocol.started = YES;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download predem page"];
    __block NSData *originalData;
    __block NSHTTPURLResponse *originalResponse;
    __block NSError *originalError;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://balabala.dem.bala"]];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue new] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        originalData = data;
        originalResponse = (NSHTTPURLResponse *) response;
        originalError = connectionError;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNil(error, @"%@", error);
    }];
    NSString *filePath = [_persistence nextArchivedHttpMonitorPath];
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
    XCTAssertEqual([parsedContent respondsToSelector:@selector(objectForKey:)], YES);
    XCTAssertTrue([request.URL.host isEqual:parsedContent[@"domain"]]);
    XCTAssertTrue([request.HTTPMethod isEqual:parsedContent[@"method"]]);
    if (request.URL.path.length == 0) {
        XCTAssertTrue([@"/" isEqual:parsedContent[@"path"]]);
    } else {
        XCTAssertTrue([request.URL.path isEqual:parsedContent[@"path"]]);
    }

    XCTAssertNotNil(originalError);
    XCTAssertEqual(originalResponse.statusCode, 0);
    XCTAssertEqual(originalData.length, 0);
    XCTAssertTrue([originalError.localizedDescription isEqual:parsedContent[@"network_error_msg"]]);
    XCTAssertEqual(originalError.code, [parsedContent[@"network_error_code"] intValue]);
    XCTAssertTrue([parsedContent[@"start_timestamp"] intValue] > 0);
    XCTAssertTrue([parsedContent[@"response_time_stamp"] intValue] >= [parsedContent[@"start_timestamp"] intValue]);
    XCTAssertTrue([parsedContent[@"end_timestamp"] intValue] >= [parsedContent[@"start_timestamp"] intValue]);
    [_persistence purgeAllHttpMonitor];
}

@end
