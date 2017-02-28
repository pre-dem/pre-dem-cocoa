//
//  ViewController.m
//  PreSniffSDKDemo
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "ViewController.h"
#import <PreSniffSDK/PreSniffSDK.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.baidu.com"]];
    UIWebView *webView = [[UIWebView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.view addSubview:webView];
    [webView loadRequest:request];
    
    [self testEventTracking];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self forceCrashing];
//    });
}

- (void)testEventTracking {
    PRESMetricsManager *metricsManager = [PreSniffManager sharedPreSniffManager].metricsManager;
    
    [metricsManager trackEventWithName:@"viewDidLoadEvent" properties:@{@"helloKey": @"worldValue"} measurements:@{@"helloKey": @7}];
}

- (void)forceCrashing {
    @throw [NSException exceptionWithName:@"Manually Exception" reason:@"嗯，我是故意的" userInfo:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
