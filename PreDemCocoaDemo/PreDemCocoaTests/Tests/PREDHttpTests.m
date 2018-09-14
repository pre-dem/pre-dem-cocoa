//
//  PREDCrashTests.m
//  PreDemObjcTests
//
//  Created by 王思宇 on 29/09/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDURLProtocol.h"
#import <XCTest/XCTest.h>

@interface PREDHttpTests : XCTestCase

@end

@implementation PREDHttpTests {
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

- (void)testForSharedSessionHttps200 {
  [_persistence purgeAllHttpMonitor];
  [PREDURLProtocol setPersistence:_persistence];
  PREDURLProtocol.started = YES;
  NSURLSession *session = [NSURLSession sharedSession];
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Download predem page"];
  __block NSData *originalData;
  __block NSHTTPURLResponse *originalResponse;
  __block NSError *originalError;
  NSURLSessionDataTask *dataTask =
      [session dataTaskWithURL:[NSURL URLWithString:@"https://"
                                                    @"test.predem.qiniuapi."
                                                    @"com?test_key=test_value"]
             completionHandler:^(NSData *data, NSURLResponse *response,
                                 NSError *error) {
               originalData = data;
               originalResponse = (NSHTTPURLResponse *)response;
               originalError = error;
               [expectation fulfill];
             }];
  [dataTask resume];
  [self waitForExpectationsWithTimeout:20
                               handler:^(NSError *error) {
                                 XCTAssertNil(error, @"%@", error);
                               }];
  NSString *filePath = [_persistence nextArchivedHttpMonitorPath];
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
  XCTAssertEqual([parsedContent respondsToSelector:@selector(objectForKey:)],
                 YES);
  XCTAssertTrue(
      [dataTask.originalRequest.URL.host isEqual:parsedContent[@"domain"]]);
  XCTAssertTrue(
      [dataTask.originalRequest.HTTPMethod isEqual:parsedContent[@"method"]]);
  if (dataTask.originalRequest.URL.path.length == 0) {
    XCTAssertTrue([@"/" isEqual:parsedContent[@"path"]]);
  } else {
    XCTAssertTrue(
        [dataTask.originalRequest.URL.path isEqual:parsedContent[@"path"]]);
  }

  XCTAssertNil(originalError);
  XCTAssertEqual(originalResponse.statusCode, 200);
  XCTAssertEqual([parsedContent[@"status_code"] longLongValue], 200);
  XCTAssertEqual(originalData.length, 168);
  XCTAssertEqual([parsedContent[@"data_length"] longLongValue], 168);
  XCTAssertNil(parsedContent[@"network_error_msg"]);
  XCTAssertEqual([parsedContent[@"network_error_code"] longLongValue], 0);
  XCTAssertTrue([parsedContent[@"start_timestamp"] longLongValue] > 0);
  XCTAssertTrue([parsedContent[@"response_time_stamp"] longLongValue] >=
                [parsedContent[@"start_timestamp"] longLongValue]);
  XCTAssertTrue([parsedContent[@"end_timestamp"] longLongValue] >=
                [parsedContent[@"start_timestamp"] longLongValue]);
  XCTAssertTrue(
      [parsedContent[@"query"] isEqual:@"{\"test_key\":\"test_value\"}"]);
  [_persistence purgeAllHttpMonitor];
}

- (void)testForSharedSessionHttp200 {
  [_persistence purgeAllHttpMonitor];
  [PREDURLProtocol setPersistence:_persistence];
  PREDURLProtocol.started = YES;
  NSURLSession *session = [NSURLSession sharedSession];
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Download predem page"];
  __block NSData *originalData;
  __block NSHTTPURLResponse *originalResponse;
  __block NSError *originalError;
  NSURLSessionDataTask *dataTask = [session
        dataTaskWithURL:[NSURL URLWithString:@"http://predem.qiniu.com?testkv"]
      completionHandler:^(NSData *data, NSURLResponse *response,
                          NSError *error) {
        originalData = data;
        originalResponse = (NSHTTPURLResponse *)response;
        originalError = error;
        [expectation fulfill];
      }];
  [dataTask resume];
  [self waitForExpectationsWithTimeout:20
                               handler:^(NSError *error) {
                                 XCTAssertNil(error, @"%@", error);
                               }];
  NSString *filePath = [_persistence nextArchivedHttpMonitorPath];
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
  XCTAssertEqual([parsedContent respondsToSelector:@selector(objectForKey:)],
                 YES);
  XCTAssertTrue(
      [dataTask.originalRequest.URL.host isEqual:parsedContent[@"domain"]]);
  XCTAssertTrue(
      [dataTask.originalRequest.HTTPMethod isEqual:parsedContent[@"method"]]);
  if (dataTask.originalRequest.URL.path.length == 0) {
    XCTAssertTrue([@"/" isEqual:parsedContent[@"path"]]);
  } else {
    XCTAssertTrue(
        [dataTask.originalRequest.URL.path isEqual:parsedContent[@"path"]]);
  }

  XCTAssertNil(originalError);
  XCTAssertEqual(originalResponse.statusCode, 200);
  XCTAssertEqual([parsedContent[@"status_code"] longLongValue], 200);
  XCTAssertEqual(originalData.length,
                 [parsedContent[@"data_length"] longLongValue]);
  XCTAssertNil(parsedContent[@"network_error_msg"]);
  XCTAssertEqual([parsedContent[@"network_error_code"] longLongValue], 0);
  XCTAssertTrue([parsedContent[@"start_timestamp"] longLongValue] > 0);
  XCTAssertTrue([parsedContent[@"response_time_stamp"] longLongValue] >=
                [parsedContent[@"start_timestamp"] longLongValue]);
  XCTAssertTrue([parsedContent[@"end_timestamp"] longLongValue] >=
                [parsedContent[@"start_timestamp"] longLongValue]);
  XCTAssertTrue([parsedContent[@"dns_time"] longLongValue] >= 0);
  XCTAssertNotEqual(((NSString *)parsedContent[@"host_ip"]).length, 0);
  XCTAssertTrue([parsedContent[@"query"] isEqual:@"{\"testkv\":\"testkv\"}"]);
  [_persistence purgeAllHttpMonitor];
}

- (void)testForSharedSession404 {
  [_persistence purgeAllHttpMonitor];
  [PREDURLProtocol setPersistence:_persistence];
  PREDURLProtocol.started = YES;
  NSURLSession *session = [NSURLSession sharedSession];
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Download predem page"];
  __block NSData *originalData;
  __block NSHTTPURLResponse *originalResponse;
  __block NSError *originalError;
  NSURLSessionDataTask *dataTask = [session
        dataTaskWithURL:[NSURL URLWithString:@"https://"
                                             @"test.predem.qiniuapi.com/404/"
                                             @"path2/path3/path4/path5/path6"]
      completionHandler:^(NSData *data, NSURLResponse *response,
                          NSError *error) {
        originalData = data;
        originalResponse = (NSHTTPURLResponse *)response;
        originalError = error;
        [expectation fulfill];
      }];
  [dataTask resume];
  [self waitForExpectationsWithTimeout:20
                               handler:^(NSError *error) {
                                 XCTAssertNil(error, @"%@", error);
                               }];
  NSString *filePath = [_persistence nextArchivedHttpMonitorPath];
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
  XCTAssertEqual([parsedContent respondsToSelector:@selector(objectForKey:)],
                 YES);
  XCTAssertTrue(
      [dataTask.originalRequest.URL.host isEqual:parsedContent[@"domain"]]);
  XCTAssertTrue(
      [dataTask.originalRequest.HTTPMethod isEqual:parsedContent[@"method"]]);
  if (dataTask.originalRequest.URL.path.length == 0) {
    XCTAssertTrue([@"/" isEqual:parsedContent[@"path"]]);
  } else {
    XCTAssertTrue(
        [dataTask.originalRequest.URL.path isEqual:parsedContent[@"path"]]);
  }
  XCTAssertNil(originalError);
  XCTAssertEqual(originalResponse.statusCode, 404);
  XCTAssertEqual([parsedContent[@"status_code"] longLongValue], 404);
  XCTAssertEqual(originalData.length, 18);
  XCTAssertEqual([parsedContent[@"data_length"] longLongValue], 18);
  XCTAssertNil(parsedContent[@"network_error_msg"]);
  XCTAssertEqual([parsedContent[@"network_error_code"] longLongValue], 0);
  XCTAssertTrue([parsedContent[@"start_timestamp"] longLongValue] > 0);
  XCTAssertTrue([parsedContent[@"response_time_stamp"] longLongValue] >=
                [parsedContent[@"start_timestamp"] longLongValue]);
  XCTAssertTrue([parsedContent[@"end_timestamp"] longLongValue] >=
                [parsedContent[@"start_timestamp"] longLongValue]);
  XCTAssertTrue([parsedContent[@"path1"] isEqual:@"404"]);
  XCTAssertTrue([parsedContent[@"path2"] isEqual:@"path2"]);
  XCTAssertTrue([parsedContent[@"path3"] isEqual:@"path3"]);
  XCTAssertTrue([parsedContent[@"path4"] isEqual:@"path4/path5/path6"]);
  [_persistence purgeAllHttpMonitor];
}

- (void)testForSharedSessionNetworkError {
  [_persistence purgeAllHttpMonitor];
  [PREDURLProtocol setPersistence:_persistence];
  PREDURLProtocol.started = YES;
  NSURLSession *session = [NSURLSession sharedSession];
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Download predem page"];
  __block NSData *originalData;
  __block NSHTTPURLResponse *originalResponse;
  __block NSError *originalError;
  NSURLSessionDataTask *dataTask =
      [session dataTaskWithURL:[NSURL URLWithString:@"http://balabala.dem.bala"]
             completionHandler:^(NSData *data, NSURLResponse *response,
                                 NSError *error) {
               originalData = data;
               originalResponse = (NSHTTPURLResponse *)response;
               originalError = error;
               [expectation fulfill];
             }];
  [dataTask resume];
  [self waitForExpectationsWithTimeout:20
                               handler:^(NSError *error) {
                                 XCTAssertNil(error, @"%@", error);
                               }];
  NSString *filePath = [_persistence nextArchivedHttpMonitorPath];
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
  XCTAssertEqual([parsedContent respondsToSelector:@selector(objectForKey:)],
                 YES);
  XCTAssertTrue(
      [dataTask.originalRequest.URL.host isEqual:parsedContent[@"domain"]]);
  XCTAssertTrue(
      [dataTask.originalRequest.HTTPMethod isEqual:parsedContent[@"method"]]);
  if (dataTask.originalRequest.URL.path.length == 0) {
    XCTAssertTrue([@"/" isEqual:parsedContent[@"path"]]);
  } else {
    XCTAssertTrue(
        [dataTask.originalRequest.URL.path isEqual:parsedContent[@"path"]]);
  }

  XCTAssertNotNil(originalError);
  XCTAssertEqual(originalResponse.statusCode, 0);
  XCTAssertEqual(originalData.length, 0);
  XCTAssertTrue([originalError.localizedDescription
      isEqual:parsedContent[@"network_error_msg"]]);
  XCTAssertEqual(originalError.code,
                 [parsedContent[@"network_error_code"] longLongValue]);
  XCTAssertTrue([parsedContent[@"start_timestamp"] longLongValue] > 0);
  XCTAssertTrue([parsedContent[@"response_time_stamp"] longLongValue] >=
                [parsedContent[@"start_timestamp"] longLongValue]);
  XCTAssertTrue([parsedContent[@"end_timestamp"] longLongValue] >=
                [parsedContent[@"start_timestamp"] longLongValue]);
  [_persistence purgeAllHttpMonitor];
}

- (void)testForSharedSessionNoProxy1 {
  [_persistence purgeAllHttpMonitor];
  [PREDURLProtocol setPersistence:_persistence];
  PREDURLProtocol.started = YES;
  NSURLSession *session = [NSURLSession sharedSession];
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Download predem page"];
  NSString *url;
  NSURLSessionDataTask *dataTask =
      [session dataTaskWithURL:[NSURL URLWithString:url]
             completionHandler:^(NSData *data, NSURLResponse *response,
                                 NSError *error) {
               [expectation fulfill];
             }];
  [dataTask resume];
  [self waitForExpectationsWithTimeout:20
                               handler:^(NSError *error) {
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
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Download predem page"];
  NSURLSessionDataTask *dataTask =
      [session dataTaskWithURL:[NSURL URLWithString:@"rtmp://test.qiniu.com"]
             completionHandler:^(NSData *data, NSURLResponse *response,
                                 NSError *error) {
               [expectation fulfill];
             }];
  [dataTask resume];
  [self waitForExpectationsWithTimeout:20
                               handler:^(NSError *error) {
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
  NSURLSession *session =
      [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration
                                                 defaultSessionConfiguration]];
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Download predem page"];
  __block NSData *originalData;
  __block NSHTTPURLResponse *originalResponse;
  __block NSError *originalError;
  NSURLSessionDataTask *dataTask = [session
        dataTaskWithURL:[NSURL
                            URLWithString:@"https://test.predem.qiniuapi.com"]
      completionHandler:^(NSData *data, NSURLResponse *response,
                          NSError *error) {
        originalData = data;
        originalResponse = (NSHTTPURLResponse *)response;
        originalError = error;
        [expectation fulfill];
      }];
  [dataTask resume];
  [self waitForExpectationsWithTimeout:20
                               handler:^(NSError *error) {
                                 XCTAssertNil(error, @"%@", error);
                               }];
  NSString *filePath = [_persistence nextArchivedHttpMonitorPath];
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
  XCTAssertEqual([parsedContent respondsToSelector:@selector(objectForKey:)],
                 YES);
  XCTAssertTrue(
      [dataTask.originalRequest.URL.host isEqual:parsedContent[@"domain"]]);
  XCTAssertTrue(
      [dataTask.originalRequest.HTTPMethod isEqual:parsedContent[@"method"]]);
  if (dataTask.originalRequest.URL.path.length == 0) {
    XCTAssertTrue([@"/" isEqual:parsedContent[@"path"]]);
  } else {
    XCTAssertTrue(
        [dataTask.originalRequest.URL.path isEqual:parsedContent[@"path"]]);
  }

  XCTAssertNil(originalError);
  XCTAssertEqual(originalResponse.statusCode, 200);
  XCTAssertEqual([parsedContent[@"status_code"] longLongValue], 200);
  XCTAssertEqual(originalData.length, 168);
  XCTAssertEqual([parsedContent[@"data_length"] longLongValue], 168);
  XCTAssertNil(parsedContent[@"network_error_msg"]);
  XCTAssertEqual([parsedContent[@"network_error_code"] longLongValue], 0);
  XCTAssertTrue([parsedContent[@"start_timestamp"] longLongValue] > 0);
  XCTAssertTrue([parsedContent[@"response_time_stamp"] longLongValue] >=
                [parsedContent[@"start_timestamp"] longLongValue]);
  XCTAssertTrue([parsedContent[@"end_timestamp"] longLongValue] >=
                [parsedContent[@"start_timestamp"] longLongValue]);
  [_persistence purgeAllHttpMonitor];
}

- (void)testForHttpURLConnectionHttps200 {
  [_persistence purgeAllHttpMonitor];
  [PREDURLProtocol setPersistence:_persistence];
  PREDURLProtocol.started = YES;
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Download predem page"];
  __block NSData *originalData;
  __block NSHTTPURLResponse *originalResponse;
  __block NSError *originalError;
  NSURLRequest *request = [NSURLRequest
      requestWithURL:[NSURL URLWithString:@"https://test.predem.qiniuapi.com"]];
  [NSURLConnection
      sendAsynchronousRequest:request
                        queue:[NSOperationQueue new]
            completionHandler:^(NSURLResponse *response, NSData *data,
                                NSError *connectionError) {
              originalData = data;
              originalResponse = (NSHTTPURLResponse *)response;
              originalError = connectionError;
              [expectation fulfill];
            }];
  [self waitForExpectationsWithTimeout:20
                               handler:^(NSError *error) {
                                 XCTAssertNil(error, @"%@", error);
                               }];
  NSString *filePath = [_persistence nextArchivedHttpMonitorPath];
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
  XCTAssertEqual([parsedContent respondsToSelector:@selector(objectForKey:)],
                 YES);
  XCTAssertTrue([request.URL.host isEqual:parsedContent[@"domain"]]);
  XCTAssertTrue([request.HTTPMethod isEqual:parsedContent[@"method"]]);
  if (request.URL.path.length == 0) {
    XCTAssertTrue([@"/" isEqual:parsedContent[@"path"]]);
  } else {
    XCTAssertTrue([request.URL.path isEqual:parsedContent[@"path"]]);
  }

  XCTAssertNil(originalError);
  XCTAssertEqual(originalResponse.statusCode, 200);
  XCTAssertEqual([parsedContent[@"status_code"] longLongValue], 200);
  XCTAssertEqual(originalData.length, 168);
  XCTAssertEqual([parsedContent[@"data_length"] longLongValue], 168);
  XCTAssertNil(parsedContent[@"network_error_msg"]);
  XCTAssertEqual([parsedContent[@"network_error_code"] longLongValue], 0);
  XCTAssertTrue([parsedContent[@"start_timestamp"] longLongValue] > 0);
  XCTAssertTrue([parsedContent[@"response_time_stamp"] longLongValue] >=
                [parsedContent[@"start_timestamp"] longLongValue]);
  XCTAssertTrue([parsedContent[@"end_timestamp"] longLongValue] >=
                [parsedContent[@"start_timestamp"] longLongValue]);
  [_persistence purgeAllHttpMonitor];
}

- (void)testForHttpURLConnectionHttp200 {
  [_persistence purgeAllHttpMonitor];
  [PREDURLProtocol setPersistence:_persistence];
  PREDURLProtocol.started = YES;
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Download predem page"];
  __block NSData *originalData;
  __block NSHTTPURLResponse *originalResponse;
  __block NSError *originalError;
  NSURLRequest *request = [NSURLRequest
      requestWithURL:[NSURL URLWithString:@"http://predem.qiniu.com"]];
  [NSURLConnection
      sendAsynchronousRequest:request
                        queue:[NSOperationQueue new]
            completionHandler:^(NSURLResponse *response, NSData *data,
                                NSError *connectionError) {
              originalData = data;
              originalResponse = (NSHTTPURLResponse *)response;
              originalError = connectionError;
              [expectation fulfill];
            }];
  [self waitForExpectationsWithTimeout:20
                               handler:^(NSError *error) {
                                 XCTAssertNil(error, @"%@", error);
                               }];
  NSString *filePath = [_persistence nextArchivedHttpMonitorPath];
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
  XCTAssertEqual([parsedContent respondsToSelector:@selector(objectForKey:)],
                 YES);
  XCTAssertTrue([request.URL.host isEqual:parsedContent[@"domain"]]);
  XCTAssertTrue([request.HTTPMethod isEqual:parsedContent[@"method"]]);
  if (request.URL.path.length == 0) {
    XCTAssertTrue([@"/" isEqual:parsedContent[@"path"]]);
  } else {
    XCTAssertTrue([request.URL.path isEqual:parsedContent[@"path"]]);
  }

  XCTAssertNil(originalError);
  XCTAssertEqual(originalResponse.statusCode, 200);
  XCTAssertEqual([parsedContent[@"status_code"] longLongValue], 200);
  XCTAssertEqual(originalData.length,
                 [parsedContent[@"data_length"] longLongValue]);
  XCTAssertNil(parsedContent[@"network_error_msg"]);
  XCTAssertEqual([parsedContent[@"network_error_code"] longLongValue], 0);
  XCTAssertTrue([parsedContent[@"start_timestamp"] longLongValue] > 0);
  XCTAssertTrue([parsedContent[@"response_time_stamp"] longLongValue] >=
                [parsedContent[@"start_timestamp"] longLongValue]);
  XCTAssertTrue([parsedContent[@"end_timestamp"] longLongValue] >=
                [parsedContent[@"start_timestamp"] longLongValue]);
  [_persistence purgeAllHttpMonitor];
}

- (void)testForHttpURLConnectionHttps404 {
  [_persistence purgeAllHttpMonitor];
  [PREDURLProtocol setPersistence:_persistence];
  PREDURLProtocol.started = YES;
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Download predem page"];
  __block NSData *originalData;
  __block NSHTTPURLResponse *originalResponse;
  __block NSError *originalError;
  NSURLRequest *request = [NSURLRequest
      requestWithURL:
          [NSURL URLWithString:@"https://test.predem.qiniuapi.com/404"]];
  [NSURLConnection
      sendAsynchronousRequest:request
                        queue:[NSOperationQueue new]
            completionHandler:^(NSURLResponse *response, NSData *data,
                                NSError *connectionError) {
              originalData = data;
              originalResponse = (NSHTTPURLResponse *)response;
              originalError = connectionError;
              [expectation fulfill];
            }];
  [self waitForExpectationsWithTimeout:20
                               handler:^(NSError *error) {
                                 XCTAssertNil(error, @"%@", error);
                               }];
  NSString *filePath = [_persistence nextArchivedHttpMonitorPath];
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
  XCTAssertEqual([parsedContent respondsToSelector:@selector(objectForKey:)],
                 YES);
  XCTAssertTrue([request.URL.host isEqual:parsedContent[@"domain"]]);
  XCTAssertTrue([request.HTTPMethod isEqual:parsedContent[@"method"]]);
  if (request.URL.path.length == 0) {
    XCTAssertTrue([@"/" isEqual:parsedContent[@"path"]]);
  } else {
    XCTAssertTrue([request.URL.path isEqual:parsedContent[@"path"]]);
  }

  XCTAssertNil(originalError);
  XCTAssertEqual(originalResponse.statusCode, 404);
  XCTAssertEqual([parsedContent[@"status_code"] longLongValue], 404);
  XCTAssertEqual(originalData.length, 18);
  XCTAssertEqual([parsedContent[@"data_length"] longLongValue], 18);
  XCTAssertNil(parsedContent[@"network_error_msg"]);
  XCTAssertEqual([parsedContent[@"network_error_code"] longLongValue], 0);
  XCTAssertTrue([parsedContent[@"start_timestamp"] longLongValue] > 0);
  XCTAssertTrue([parsedContent[@"response_time_stamp"] longLongValue] >=
                [parsedContent[@"start_timestamp"] longLongValue]);
  XCTAssertTrue([parsedContent[@"end_timestamp"] longLongValue] >=
                [parsedContent[@"start_timestamp"] longLongValue]);
  [_persistence purgeAllHttpMonitor];
}

- (void)testForHttpURLConnectionNetworkError {
  [_persistence purgeAllHttpMonitor];
  [PREDURLProtocol setPersistence:_persistence];
  PREDURLProtocol.started = YES;
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Download predem page"];
  __block NSData *originalData;
  __block NSHTTPURLResponse *originalResponse;
  __block NSError *originalError;
  NSURLRequest *request = [NSURLRequest
      requestWithURL:[NSURL URLWithString:@"http://balabala.dem.bala"]];
  [NSURLConnection
      sendAsynchronousRequest:request
                        queue:[NSOperationQueue new]
            completionHandler:^(NSURLResponse *response, NSData *data,
                                NSError *connectionError) {
              originalData = data;
              originalResponse = (NSHTTPURLResponse *)response;
              originalError = connectionError;
              [expectation fulfill];
            }];
  [self waitForExpectationsWithTimeout:20
                               handler:^(NSError *error) {
                                 XCTAssertNil(error, @"%@", error);
                               }];
  NSString *filePath = [_persistence nextArchivedHttpMonitorPath];
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
  XCTAssertEqual([parsedContent respondsToSelector:@selector(objectForKey:)],
                 YES);
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
  XCTAssertTrue([originalError.localizedDescription
      isEqual:parsedContent[@"network_error_msg"]]);
  XCTAssertEqual(originalError.code,
                 [parsedContent[@"network_error_code"] longLongValue]);
  XCTAssertTrue([parsedContent[@"start_timestamp"] longLongValue] > 0);
  XCTAssertTrue([parsedContent[@"response_time_stamp"] longLongValue] >=
                [parsedContent[@"start_timestamp"] longLongValue]);
  XCTAssertTrue([parsedContent[@"end_timestamp"] longLongValue] >=
                [parsedContent[@"start_timestamp"] longLongValue]);
  [_persistence purgeAllHttpMonitor];
}

@end
