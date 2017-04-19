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
}

- (IBAction)sendHTTPRequest:(id)sender {
    NSURL *url = [NSURL URLWithString:@"http://www.baidu.com"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration];
    //    session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
    [task resume];
}

- (IBAction)forceCrash:(id)sender {
    @throw [NSException exceptionWithName:@"Manually Exception" reason:@"嗯，我是故意的" userInfo:nil];
}

- (IBAction)diyEvent:(id)sender {
    PRESMetricsManager *metricsManager = [PreSniffManager sharedPreSniffManager].metricsManager;
    
    [metricsManager trackEventWithName:@"viewDidLoadEvent" properties:@{@"helloKey": @"worldValue"} measurements:@{@"helloKey": @7}];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
