//
//  PREDBreadCrumb.h
//  AFNetworking
//
//  Created by WangSiyu on 14/11/2017.
//

#import <PreDemObjc/PreDemObjc.h>

@interface PREDBreadcrumb : PREDCustomEvent

+ (instancetype)breadcrumbWithName:(NSString *)name contentDic:(NSDictionary *)contentDic;

@end
