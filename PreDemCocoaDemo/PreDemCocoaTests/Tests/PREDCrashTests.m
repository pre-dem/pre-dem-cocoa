//
//  PREDCrashTests.m
//  PreDemObjcTests
//
//  Created by 王思宇 on 29/09/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CrashReporter/CrashReporter.h>
#import "PREDLagMeta.h"

@interface PREDCrashTests : XCTestCase

@end

@implementation PREDCrashTests

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
}

- (void)testLiveReportGenerator {
    PLCrashReporterSignalHandlerType signalHandlerType = PLCrashReporterSignalHandlerTypeBSD;
    PREDPLCrashReporterConfig *config = [[PREDPLCrashReporterConfig alloc] initWithSignalHandlerType:signalHandlerType
                                                                               symbolicationStrategy:PLCrashReporterSymbolicationStrategyNone];
    PREDPLCrashReporter *reporter = [[PREDPLCrashReporter alloc] initWithConfiguration:config];
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        NSError *error;
        NSData *data = [reporter generateLiveReportAndReturnError:&error];
        XCTAssertNil(error);
        XCTAssertNotNil(data);
        PREDPLCrashReport *report = [[PREDPLCrashReport alloc] initWithData:data error:&error];
        XCTAssertNil(error);
        XCTAssertNotNil(report);
        PREDLagMeta *meta = [[PREDLagMeta alloc] initWithReport:report];
        XCTAssertNotNil(meta);
    }];
}

@end
