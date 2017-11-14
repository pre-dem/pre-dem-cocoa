//
//  PREDBreadCrumb.h
//  AFNetworking
//
//  Created by WangSiyu on 14/11/2017.
//

#import <PreDemObjc/PreDemObjc.h>

@interface PREDBreadcrumb : PREDEvent

+ (instancetype)breadcrumbWithName:(NSString *)name contentDic:(NSDictionary *)contentDic;

@end
