//
//  PREDConfig.m
//  PreDemSDK
//
//  Created by WangSiyu on 10/05/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDConfigManager.h"
#import "PREDLogger.h"
#import "PREDManagerPrivate.h"

@interface PREDConfigManager ()
<
NSURLSessionDelegate
>

@end

@implementation PREDConfigManager

+ (instancetype)sharedInstance {
    static PREDConfigManager *config;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        config = [[PREDConfigManager alloc] init];
    });
    return config;
}

- (PREDConfig *)getConfigWithAppKey:(NSString *)appKey {
    PREDConfig *defaultConfig;
    NSDictionary *dic = [NSUserDefaults.standardUserDefaults objectForKey:@"predem_app_config"];
    if (dic && [dic respondsToSelector:@selector(objectForKey:)]) {
        defaultConfig = [PREDConfig configWithDic:dic];
    } else {
        defaultConfig = PREDConfig.defaultConfig;
    }
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@app-config/i", [[PREDManager sharedPREDManager]baseUrl]]]];
    [NSURLProtocol setProperty:@YES
                        forKey:@"PREDInternalRequest"
                     inRequest:request];
    
    __weak typeof(self) wSelf = self;
    [[[NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration
                                    delegate:self
                               delegateQueue:[NSOperationQueue new]]
      dataTaskWithRequest:request
      completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
          if (error || httpResponse.statusCode != 200) {
              PREDLogError(@"%@", error.localizedDescription);
              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                  [self getConfigWithAppKey:appKey];
              });
          } else {
              __strong typeof(wSelf) strongSelf = wSelf;
              NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
              if ([dic respondsToSelector:@selector(objectForKey:)]) {
                  [NSUserDefaults.standardUserDefaults setObject:dic forKey:@"predem_app_config"];
                  PREDConfig *config = [PREDConfig configWithDic:dic];
                  [strongSelf.delegate configManager:strongSelf didReceivedConfig:config];
              } else {
                  PREDLogError(@"config received from server has a wrong type");
              }
          }
      }]
     resume];
    return defaultConfig;
}

@end
