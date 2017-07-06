//
//  PREDURLSessionSwizzler.m
//  PreDemObjc
//
//  Created by WangSiyu on 14/03/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDURLSessionSwizzler.h"
#import <objc/runtime.h>
#import "PREDURLProtocol.h"

@implementation PREDURLSessionSwizzler

+ (PREDURLSessionSwizzler *)defaultSwizzler {
    static PREDURLSessionSwizzler *staticSwizzler;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        staticSwizzler = [[PREDURLSessionSwizzler alloc] init];
    });
    
    return staticSwizzler;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.isSwizzle = NO;
    }
    return self;
}


- (void)load {
    self.isSwizzle=YES;
    Class cls = NSClassFromString(@"__NSCFURLSessionConfiguration") ?: NSClassFromString(@"NSURLSessionConfiguration");
    [self swizzleSelector:@selector(protocolClasses) fromClass:cls toClass:[self class]];
    
}

- (void)unload {
    self.isSwizzle=NO;
    Class cls = NSClassFromString(@"__NSCFURLSessionConfiguration") ?: NSClassFromString(@"NSURLSessionConfiguration");
    [self swizzleSelector:@selector(protocolClasses) fromClass:cls toClass:[self class]];
    
}

- (void)swizzleSelector:(SEL)selector fromClass:(Class)original toClass:(Class)stub {
    Method originalMethod = class_getInstanceMethod(original, selector);
    Method stubMethod = class_getInstanceMethod(stub, selector);
    if (!originalMethod || !stubMethod) {
        [NSException raise:NSInternalInconsistencyException format:@"Couldn't load NEURLSessionConfiguration."];
    }
    method_exchangeImplementations(originalMethod, stubMethod);
}

- (NSArray *)protocolClasses {
    return @[[PREDURLProtocol class]];
}

@end
