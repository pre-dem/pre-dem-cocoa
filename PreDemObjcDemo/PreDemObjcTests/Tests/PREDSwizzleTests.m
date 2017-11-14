//
//  PREDSwizzleTests.m
//  PRED
//
//  Created by Daniel Griesser on 06/06/2017.
//  Copyright © 2017 PRED. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PREDSwizzle.h"

#pragma mark - HELPER CLASSES -

@interface PREDTestsLog : NSObject
+ (void)log:(NSString *)string;

+ (void)clear;

+ (BOOL)is:(NSString *)compareString;

+ (NSString *)logString;
@end

@implementation PREDTestsLog

static NSMutableString *_logString = nil;

+ (void)log:(NSString *)string {
    if (!_logString) {
        _logString = [NSMutableString new];
    }
    [_logString appendString:string];
    NSLog(@"%@", string);
}

+ (void)clear {
    _logString = [NSMutableString new];
}

+ (BOOL)is:(NSString *)compareString {
    return [compareString isEqualToString:_logString];
}

+ (NSString *)logString {
    return _logString;
}

@end

#define ASSERT_LOG_IS(STRING) XCTAssertTrue([PREDTestsLog is:STRING], @"LOG IS @\"%@\" INSTEAD",[PREDTestsLog logString])
#define CLEAR_LOG() ([PREDTestsLog clear])
#define PREDTestsLog(STRING) [PREDTestsLog log:STRING]

@interface PREDSwizzleTestClass_A : NSObject
@end

@implementation PREDSwizzleTestClass_A
- (int)calc:(int)num {
    return num;
}

- (BOOL)methodReturningBOOL {
    return YES;
};
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"
- (void)methodWithArgument:(id)arg {
};
#pragma GCC diagnostic pop
- (void)methodForAlwaysSwizzling {
};

- (void)methodForSwizzlingOncePerClass {
};

- (void)methodForSwizzlingOncePerClassOrSuperClasses {
};

- (NSString *)string {
    return @"ABC";
}

+ (NSNumber *)sumFloat:(float)floatSummand withDouble:(double)doubleSummand {
    return @(floatSummand + doubleSummand);
}
@end

@interface PREDSwizzleTestClass_B : PREDSwizzleTestClass_A
@end

@implementation PREDSwizzleTestClass_B
@end

@interface PREDSwizzleTestClass_C : PREDSwizzleTestClass_B
@end

@implementation PREDSwizzleTestClass_C

- (void)dealloc {
    PREDTestsLog(@"C-");
};

- (int)calc:(int)num {
    return [super calc:num] * 3;
}
@end

@interface PREDSwizzleTestClass_D : PREDSwizzleTestClass_C
@end

@implementation PREDSwizzleTestClass_D
@end

@interface PREDSwizzleTestClass_D2 : PREDSwizzleTestClass_C
@end

@implementation PREDSwizzleTestClass_D2
@end

#pragma mark - HELPER FUNCTIONS -

static void swizzleVoidMethod(Class classToSwizzle,
        SEL selector,
        dispatch_block_t blockBefore,
        PREDSwizzleMode mode,
        const void *key) {
    PREDSwizzleInstanceMethod(classToSwizzle,
            selector,
            PREDSWReturnType(
            void),
            PREDSWArguments(),
            PREDSWReplacement(
                    {
                            blockBefore();
                            PREDSWCallOriginal();
                    }), mode, key);
}

static void swizzleDealloc(Class classToSwizzle, dispatch_block_t blockBefore) {
    SEL selector = NSSelectorFromString(@"dealloc");
    swizzleVoidMethod(classToSwizzle, selector, blockBefore, PREDSwizzleModeAlways, NULL);
}

static void swizzleNumber(Class classToSwizzle, int(^transformationBlock)(int)) {
    PREDSwizzleInstanceMethod(classToSwizzle,
            @selector(calc:),
            PREDSWReturnType(
            int),
            PREDSWArguments(
            int num),
            PREDSWReplacement(
                    {
                            int res = PREDSWCallOriginal(num);
                            return transformationBlock(res);
                    }), PREDSwizzleModeAlways, NULL);
}

@interface PREDSwizzleTests : XCTestCase

@end

@implementation PREDSwizzleTests

+ (void)setUp {
    [self swizzleDeallocs];
    [self swizzleCalc];
}

- (void)setUp {
    [super setUp];
    CLEAR_LOG();
}

+ (void)swizzleDeallocs {
    // 1) Swizzling a class that does not implement the method...
    swizzleDealloc([PREDSwizzleTestClass_D class], ^{
        PREDTestsLog(@"d-");
    });
    // ...should not break swizzling of its superclass.
    swizzleDealloc([PREDSwizzleTestClass_C class], ^{
        PREDTestsLog(@"c-");
    });
    // 2) Swizzling a class that does not implement the method
    // should not affect classes with the same superclass.
    swizzleDealloc([PREDSwizzleTestClass_D2 class], ^{
        PREDTestsLog(@"d2-");
    });

    // 3) We should be able to swizzle classes several times...
    swizzleDealloc([PREDSwizzleTestClass_D class], ^{
        PREDTestsLog(@"d'-");
    });
    // ...and nothing should be breaked up.
    swizzleDealloc([PREDSwizzleTestClass_C class], ^{
        PREDTestsLog(@"c'-");
    });

    // 4) Swizzling a class inherited from NSObject and does not
    // implementing the method.
    swizzleDealloc([PREDSwizzleTestClass_A class], ^{
        PREDTestsLog(@"a");
    });
}

- (void)testDeallocSwizzling {
    @autoreleasepool {
        id object = [PREDSwizzleTestClass_D new];
        object = nil;
    }
    ASSERT_LOG_IS(@"d'-d-c'-c-C-a");
}

#pragma mark - Calc: Swizzling

+ (void)swizzleCalc {

    swizzleNumber([PREDSwizzleTestClass_C class], ^int(int num) {
        return num + 17;
    });

    swizzleNumber([PREDSwizzleTestClass_D class], ^int(int num) {
        return num * 11;
    });
    swizzleNumber([PREDSwizzleTestClass_C class], ^int(int num) {
        return num * 5;
    });
    swizzleNumber([PREDSwizzleTestClass_D class], ^int(int num) {
        return num - 20;
    });

    swizzleNumber([PREDSwizzleTestClass_A class], ^int(int num) {
        return num * -1;
    });
}

- (void)testCalcSwizzling {
    PREDSwizzleTestClass_D *object = [PREDSwizzleTestClass_D new];
    int res = [object calc:2];
    XCTAssertTrue(res == ((2 * (-1) * 3) + 17) * 5 * 11 - 20, @"%d", res);
}

#pragma mark - String Swizzling

- (void)testStringSwizzling {
    SEL selector = @selector(string);
    PREDSwizzleTestClass_A *a = [PREDSwizzleTestClass_A new];

    PREDSwizzleInstanceMethod([a class],
            selector,
            PREDSWReturnType(NSString * ),
            PREDSWArguments(),
            PREDSWReplacement(
                    {
                            NSString * res = PREDSWCallOriginal();
                            return[res stringByAppendingString:@"DEF"];
                    }), PREDSwizzleModeAlways, NULL);

    XCTAssertTrue([[a string] isEqualToString:@"ABCDEF"]);
}

#pragma mark - Class Swizzling

- (void)testClassSwizzling {
    PREDSwizzleClassMethod([PREDSwizzleTestClass_B class],
            @selector(sumFloat:withDouble:),
            PREDSWReturnType(NSNumber * ),
            PREDSWArguments(
            float floatSummand,
            double doubleSummand),
            PREDSWReplacement(
                    {
                            NSNumber * result = PREDSWCallOriginal(floatSummand, doubleSummand);
                            return @([result doubleValue]* 2.);
                    }));
    
    XCTAssertEqualObjects(@(2.), [PREDSwizzleTestClass_A sumFloat:0.5 withDouble:1.5]);
    XCTAssertEqualObjects(@(4.), [PREDSwizzleTestClass_B sumFloat:0.5 withDouble:1.5]);
    XCTAssertEqualObjects(@(4.), [PREDSwizzleTestClass_C sumFloat:0.5 withDouble:1.5]);
}

#pragma mark - Test Assertions
#if !defined(NS_BLOCK_ASSERTIONS)

- (void)testThrowsOnSwizzlingNonexistentMethod {
    SEL selector = NSSelectorFromString(@"nonexistent");
    PREDSwizzleImpFactoryBlock factoryBlock = ^id(PREDSwizzleInfo *swizzleInfo) {
        return ^(__unsafe_unretained id self) {
            void (*originalIMP)(__unsafe_unretained id, SEL);
            originalIMP = (__typeof(originalIMP)) [swizzleInfo getOriginalImplementation];
            originalIMP(self, selector);
        };
    };
    XCTAssertThrows([PREDSwizzle
            swizzleInstanceMethod:selector
                          inClass:[PREDSwizzleTestClass_A class]
                    newImpFactory:factoryBlock
                             mode:PREDSwizzleModeAlways
                              key:NULL]);
}

#endif

#pragma mark - Mode tests

- (void)testAlwaysSwizzlingMode {
    for (int i = 3; i > 0; --i) {
        swizzleVoidMethod([PREDSwizzleTestClass_A class],
                @selector(methodForAlwaysSwizzling), ^{
                    PREDTestsLog(@"A");
                },
                PREDSwizzleModeAlways,
                NULL);
        swizzleVoidMethod([PREDSwizzleTestClass_B class],
                @selector(methodForAlwaysSwizzling), ^{
                    PREDTestsLog(@"B");
                },
                PREDSwizzleModeAlways,
                NULL);
    }

    PREDSwizzleTestClass_B *object = [PREDSwizzleTestClass_B new];
    [object methodForAlwaysSwizzling];
    ASSERT_LOG_IS(@"BBBAAA");
}

- (void)testSwizzleOncePerClassMode {
    static void *key = &key;
    for (int i = 3; i > 0; --i) {
        swizzleVoidMethod([PREDSwizzleTestClass_A class],
                @selector(methodForSwizzlingOncePerClass), ^{
                    PREDTestsLog(@"A");
                },
                PREDSwizzleModeOncePerClass,
                key);
        swizzleVoidMethod([PREDSwizzleTestClass_B class],
                @selector(methodForSwizzlingOncePerClass), ^{
                    PREDTestsLog(@"B");
                },
                PREDSwizzleModeOncePerClass,
                key);
    }
    PREDSwizzleTestClass_B *object = [PREDSwizzleTestClass_B new];
    [object methodForSwizzlingOncePerClass];
    ASSERT_LOG_IS(@"BA");
}

- (void)testSwizzleOncePerClassOrSuperClassesMode {
    static void *key = &key;
    for (int i = 3; i > 0; --i) {
        swizzleVoidMethod([PREDSwizzleTestClass_A class],
                @selector(methodForSwizzlingOncePerClassOrSuperClasses), ^{
                    PREDTestsLog(@"A");
                },
                PREDSwizzleModeOncePerClassAndSuperclasses,
                key);
        swizzleVoidMethod([PREDSwizzleTestClass_B class],
                @selector(methodForSwizzlingOncePerClassOrSuperClasses), ^{
                    PREDTestsLog(@"B");
                },
                PREDSwizzleModeOncePerClassAndSuperclasses,
                key);
    }
    PREDSwizzleTestClass_B *object = [PREDSwizzleTestClass_B new];
    [object methodForSwizzlingOncePerClassOrSuperClasses];
    ASSERT_LOG_IS(@"A");
}

@end
