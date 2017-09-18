//
//  PREDBaseModel.h
//  Pods
//
//  Created by 王思宇 on 15/09/2017.
//
//

#import <Foundation/Foundation.h>

@interface PREDBaseModel : NSObject

@property (nonatomic, strong) NSString *app_bundle_id;
@property (nonatomic, strong) NSString *app_name;
@property (nonatomic, strong) NSString *app_version;
@property (nonatomic, strong) NSString *device_model;
@property (nonatomic, strong) NSString *os_platform;
@property (nonatomic, strong) NSString *os_version;
@property (nonatomic, strong) NSString *os_build;
@property (nonatomic, strong) NSString *sdk_version;
@property (nonatomic, strong) NSString *sdk_id;
@property (nonatomic, strong) NSString *tag;
@property (nonatomic, strong) NSString *manufacturer;

@end
