//
//  ViewController.m
//  PreDemSDKDemo
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "ViewController.h"
#import "PreDemObjc/PreDemObjc.h"

@interface ViewController ()

@property (nonatomic, strong) IBOutlet UILabel *versionLable;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    self.versionLable.text = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
}

- (IBAction)sendHTTPRequest:(id)sender {
    NSArray *urls = @[@"http://www.baidu.com", @"https://www.163.com", @"http://www.qq.com", @"https://www.dehenglalala.com", @"http://www.balabalabalatest.com", @"http://www.alipay.com"];
    for (NSString *urlString in urls) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSURL *url = [NSURL URLWithString:urlString];
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            NSURLSession *session = [NSURLSession sharedSession];
            NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
            [task resume];
        });
    }
}

- (IBAction)diagnoseNetwork:(id)sender {
    [PREDManager  diagnose:@"www.baidu.com" complete:^(PREDNetDiagResult * _Nonnull result) {
        NSLog(@"new diagnose completed with result:\n %@", result);
    }];
}

- (IBAction)forceCrash:(id)sender {
    @throw [NSException exceptionWithName:@"Manually Exception" reason:@"嗯，我是故意的" userInfo:nil];
}

- (IBAction)diyEvent:(id)sender {
    [PREDManager trackEventWithName:@"viewDidLoadEvent" event:@{@"helloKey": @"worldValue", @"hellonum": @7}];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
