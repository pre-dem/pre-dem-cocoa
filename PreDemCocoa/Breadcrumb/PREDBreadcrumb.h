//
//  PREDBreadCrumb.h
//  AFNetworking
//
//  Created by WangSiyu on 14/11/2017.
//

#import "PreDemCocoa.h"

@interface PREDBreadcrumb : PREDCustomEvent

+ (instancetype)breadcrumbWithName:(NSString *)name contentDic:(NSDictionary *)contentDic;

@end
