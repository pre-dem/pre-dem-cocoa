//
//  PRESVersion.m
//  Pods
//
//  Created by WangSiyu on 22/05/2017.
//
//

#import "PRESVersion.h"

static NSString *version;
static NSString *build;

@implementation PRESVersion

+ (void)load {
    NSURL *bundleUrl = [[NSBundle mainBundle] URLForResource:@"PRESResources" withExtension:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithURL:bundleUrl];
    NSString *plistPath = [bundle pathForResource:@"Version" ofType:@"plist"];
    NSDictionary *data = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
    version = [data objectForKey:@"Version"];
    build = [data objectForKey:@"Build"];
}

+ (NSString *)getSDKVersion {
    return version.copy;
}

+ (NSString *)getSDKBuild {
    return build.copy;
}

@end
