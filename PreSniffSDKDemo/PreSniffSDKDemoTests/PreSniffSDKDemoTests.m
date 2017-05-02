//
//  PreSniffSDKDemoTests.m
//  PreSniffSDKDemoTests
//
//  Created by Troy on 2017/5/2.
//  Copyright © 2017年 pre-engineering. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface PreSniffSDKDemoTests : XCTestCase

@end

@implementation PreSniffSDKDemoTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    XCTAssert(TRUE, @"always true");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
