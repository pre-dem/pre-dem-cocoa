//
//  PRESConfig.m
//  PreSniffSDK
//
//  Created by WangSiyu on 10/05/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PRESConfigManager.h"
#import "PRESLogger.h"

#define PRESConfigServerDomain  @"http://localhost:8080"

@interface PRESConfigManager ()
<
NSURLSessionDelegate
>

@end

@implementation PRESConfigManager

+ (instancetype)sharedInstance {
    static PRESConfigManager *config;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        config = [[PRESConfigManager alloc] init];
    });
    return config;
}

- (PRESConfig *)getConfigWithAppKey:(NSString *)appKey {
    PRESConfig *defaultConfig;
    NSDictionary *dic = [NSUserDefaults.standardUserDefaults objectForKey:@"presniff_app_config"];
    if (dic && [dic respondsToSelector:@selector(objectForKey:)]) {
        defaultConfig = [PRESConfig configWithDic:dic];
    } else {
        defaultConfig = PRESConfig.defaultConfig;
    }
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/app_config?appkey=%@", PRESConfigServerDomain, appKey]]];
    [NSURLProtocol setProperty:@YES
                        forKey:@"PRESInternalRequest"
                     inRequest:request];
    
    __weak typeof(self) wSelf = self;
    [[[NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration
                                    delegate:self
                               delegateQueue:[NSOperationQueue new]]
      dataTaskWithRequest:request
      completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
          if (error || httpResponse.statusCode != 200) {
              PRESLogError(@"%@", error.localizedDescription);
              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                  [self getConfigWithAppKey:appKey];
              });
          } else {
              __strong typeof(wSelf) strongSelf = wSelf;
              NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
              if ([dic respondsToSelector:@selector(objectForKey:)]) {
                  [NSUserDefaults.standardUserDefaults setObject:dic forKey:@"presniff_app_config"];
                  PRESConfig *config = [PRESConfig configWithDic:dic];
                  [strongSelf.delegate configManager:strongSelf didReceivedConfig:config];
              } else {
                  PRESLogError(@"config received from server has a wrong type");
              }
          }
      }]
     resume];
    return defaultConfig;
}

@end
