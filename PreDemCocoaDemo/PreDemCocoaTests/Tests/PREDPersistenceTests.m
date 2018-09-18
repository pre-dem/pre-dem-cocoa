//
//  PREDPersistenceTests.m
//  PreDemObjcTests
//
//  Created by 王思宇 on 29/09/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDPersistence.h"
#import "PREDSender.h"
#import "PREDTransactionPrivate.h"
#import <XCTest/XCTest.h>

@interface PREDPersistenceTests : XCTestCase

@end

@implementation PREDPersistenceTests {
  PREDPersistence *_appPersistence;
  PREDPersistence *_customPersistence;
  PREDPersistence *_transactionPersistence;
  PREDSender *_sender;
}

- (void)setUp {
  [super setUp];
  // Put setup code here. This method is called before the invocation of each
  // test method in the class.
  _appPersistence = [[PREDPersistence alloc] initWithPath:@"appInfo"
                                                    queue:@"predem_app_info"];
  _customPersistence =
      [[PREDPersistence alloc] initWithPath:@"custom"
                                      queue:@"predem_custom_event"];
  _transactionPersistence =
      [[PREDPersistence alloc] initWithPath:@"transactions"
                                      queue:@"predem_transactions"];

  _sender = [[PREDSender alloc]
      initWithBaseUrl:[NSURL URLWithString:@"http://"
                                           @"bhk5aaghth5n.predem.qiniuapi."
                                           @"com/v2/A_5p9l3Z/"]];
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each
  // test method in the class.
  [super tearDown];
}

- (void)testAppInfo {
  NSError *error;
  [_appPersistence purgeAll];

  PREDAppInfo *event1 = [[PREDAppInfo alloc] init];
  [_appPersistence persist:event1];

  PREDAppInfo *event2 = [[PREDAppInfo alloc] init];
  [_appPersistence persist:event2];

  NSString *path = [_appPersistence nextArchivedPath];
  XCTAssertNotEqual(path.length, 0);
  NSData *data = [NSData dataWithContentsOfFile:path];
  XCTAssertNotEqual(data.length, 0);
  NSString *eventString =
      [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  NSArray *components = [eventString componentsSeparatedByString:@"\n"];
  XCTAssertEqual(components.count, 3);

  NSDictionary *dic = [NSJSONSerialization
      JSONObjectWithData:[components[0] dataUsingEncoding:NSUTF8StringEncoding]
                 options:0
                   error:&error];
  XCTAssertNotNil(dic);
  XCTAssertNil(error);
  [dic enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key,
                                           NSString *_Nonnull obj,
                                           BOOL *_Nonnull stop) {
    XCTAssertTrue([[event1 valueForKey:key] isEqual:obj]);
  }];

  dic = [NSJSONSerialization
      JSONObjectWithData:[components[1] dataUsingEncoding:NSUTF8StringEncoding]
                 options:0
                   error:&error];
  XCTAssertNotNil(dic);
  XCTAssertNil(error);
  [dic enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key,
                                           NSString *_Nonnull obj,
                                           BOOL *_Nonnull stop) {
    XCTAssertTrue([[event2 valueForKey:key] isEqual:obj]);
  }];

  [_appPersistence purgeAll];
}
- (void)testCustomEvent {
  NSError *error;
  [_customPersistence purgeAll];

  NSDictionary *dict1 = @{
    @"stringKey" :
        [NSString stringWithFormat:@"test\t_\n%d", arc4random_uniform(100)],
    @"longKey" : @(arc4random_uniform(100)),
    @"floatKey" : @(arc4random_uniform(10000) / 100.0)
  };
  PREDCustomEvent *event1 =
      [PREDCustomEvent eventWithName:@"test\t_\nios\t_\nevent_1"
                          contentDic:dict1];
  [_customPersistence persist:event1];

  NSDictionary *dict2 = @{
    @"stringKey" :
        [NSString stringWithFormat:@"test\t_\n%d", arc4random_uniform(100)],
    @"longKey" : @(arc4random_uniform(100)),
    @"floatKey" : @(arc4random_uniform(10000) / 100.0)
  };
  PREDCustomEvent *event2 =
      [PREDCustomEvent eventWithName:@"test\t_\nios\t_\nevent_2"
                          contentDic:dict2];
  [_customPersistence persist:event2];

  NSString *path = [_customPersistence nextArchivedPath];
  XCTAssertNotEqual(path.length, 0);
  NSData *data = [NSData dataWithContentsOfFile:path];
  XCTAssertNotEqual(data.length, 0);
  NSString *eventString =
      [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  NSArray *components = [eventString componentsSeparatedByString:@"\n"];
  XCTAssertEqual(components.count, 3);

  NSDictionary *dic = [NSJSONSerialization
      JSONObjectWithData:[components[0] dataUsingEncoding:NSUTF8StringEncoding]
                 options:0
                   error:&error];
  XCTAssertNotNil(dic);
  XCTAssertNil(error);
  [dic enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key,
                                           NSString *_Nonnull obj,
                                           BOOL *_Nonnull stop) {
    XCTAssertTrue([[event1 valueForKey:key] isEqual:obj]);
  }];

  dic = [NSJSONSerialization
      JSONObjectWithData:[components[1] dataUsingEncoding:NSUTF8StringEncoding]
                 options:0
                   error:&error];
  XCTAssertNotNil(dic);
  XCTAssertNil(error);
  [dic enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key,
                                           NSString *_Nonnull obj,
                                           BOOL *_Nonnull stop) {
    XCTAssertTrue([[event2 valueForKey:key] isEqual:obj]);
  }];
  [_customPersistence purgeAll];
}

//- (void)testTransaction {
//  NSError *error;
//  [_sender purgeAll];
//
//  PREDTransaction *event1 =
//      [PREDTransaction transactionWithSender:_sender];
//  [_transactionPersistence persist:event1];
//
//  PREDTransaction *event2 =
//      [PREDTransaction transactionWithSender:_sender];
//  [_transactionPersistence persist:event2];
//
//  NSString *path = [_transactionPersistence nextArchivedPath];
//  XCTAssertNotEqual(path.length, 0);
//  NSData *data = [NSData dataWithContentsOfFile:path];
//  XCTAssertNotEqual(data.length, 0);
//  NSString *eventString =
//      [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//  NSArray *components = [eventString componentsSeparatedByString:@"\n"];
//  XCTAssertEqual(components.count, 3);
//
//  NSDictionary *dic = [NSJSONSerialization
//      JSONObjectWithData:[components[0]
//      dataUsingEncoding:NSUTF8StringEncoding]
//                 options:0
//                   error:&error];
//  XCTAssertNotNil(dic);
//  XCTAssertNil(error);
//  [dic enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key,
//                                           NSString *_Nonnull obj,
//                                           BOOL *_Nonnull stop) {
//    if (![key isEqualToString:@"content"]) {
//      XCTAssertTrue([[event1 valueForKey:key] isEqual:obj]);
//    }
//  }];
//
//  NSString *content = dic[@"content"];
//  XCTAssertNotNil(content);
//  NSMutableDictionary *contentDic = [NSJSONSerialization
//      JSONObjectWithData:[content dataUsingEncoding:NSUTF8StringEncoding]
//                 options:NSJSONReadingMutableContainers
//                   error:&error];
//  XCTAssertNotNil(contentDic);
//  XCTAssertNil(error);
//  [contentDic enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key,
//                                                  NSString *_Nonnull obj,
//                                                  BOOL *_Nonnull stop) {
//    XCTAssertTrue([[event1 valueForKey:key] isEqual:obj]);
//  }];
//
//  dic = [NSJSONSerialization
//      JSONObjectWithData:[components[1]
//      dataUsingEncoding:NSUTF8StringEncoding]
//                 options:0
//                   error:&error];
//  XCTAssertNotNil(dic);
//  XCTAssertNil(error);
//  [dic enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key,
//                                           NSString *_Nonnull obj,
//                                           BOOL *_Nonnull stop) {
//    if (![key isEqualToString:@"content"]) {
//      XCTAssertTrue([[event2 valueForKey:key] isEqual:obj]);
//    }
//  }];
//
//  content = dic[@"content"];
//  XCTAssertNotNil(content);
//  contentDic = [NSJSONSerialization
//      JSONObjectWithData:[content dataUsingEncoding:NSUTF8StringEncoding]
//                 options:NSJSONReadingMutableContainers
//                   error:&error];
//  XCTAssertNotNil(contentDic);
//  XCTAssertNil(error);
//  [contentDic enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key,
//                                                  NSString *_Nonnull obj,
//                                                  BOOL *_Nonnull stop) {
//    XCTAssertTrue([[event2 valueForKey:key] isEqual:obj]);
//  }];
//
//  [_transactionPersistence purgeAll];
//}

@end
