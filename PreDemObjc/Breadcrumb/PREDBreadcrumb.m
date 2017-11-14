//
//  PREDBreadCrumb.m
//  AFNetworking
//
//  Created by WangSiyu on 14/11/2017.
//

#import "PREDBreadcrumb.h"

#define BREADCRUMB_EVENT_TYPE @"breadcrumb"

// expose method to PREDBreadCrumb
@interface PREDEvent()

+ (instancetype)eventWithName:(NSString *)name type:(NSString *)type contentDic:(NSDictionary *)contentDic;

@end

@implementation PREDBreadcrumb

+ (instancetype)breadcrumbWithName:(NSString *)name contentDic:(NSDictionary *)contentDic {
    return [self eventWithName:name type:BREADCRUMB_EVENT_TYPE contentDic:contentDic];
}

@end
