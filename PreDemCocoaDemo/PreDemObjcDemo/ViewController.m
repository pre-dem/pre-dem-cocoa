//
//  ViewController.m
//  PreDemObjcDemo
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "ViewController.h"
#import <PreDemCocoa/PreDemCocoa.h>

@interface ViewController ()

@property(nonatomic, strong) IBOutlet UILabel *versionLable;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view, typically from a nib.
  self.versionLable.text = [NSString
      stringWithFormat:@"%@(%@)", PREDManager.version, PREDManager.build];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.navigationController.navigationBarHidden = YES;
}

- (IBAction)sendHTTPRequest:(id)sender {
  NSArray *urls = @[
    @"http://www.baidu.com",
    @"https://www.163.com",
    @"http://www.qq.com",
    @"https://www.dehenglalala.com",
    @"http://www.balabalabalatest.com",
    @"http://www.alipay.com"
  ];
  for (NSString *urlString in urls) {
    dispatch_async(
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
          NSURL *url = [NSURL URLWithString:urlString];
          NSURLRequest *request = [NSURLRequest requestWithURL:url];
          NSURLSession *session = [NSURLSession sharedSession];
          NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
          [task resume];
        });
  }
}

- (IBAction)diagnoseNetwork:(id)sender {
  [PREDManager diagnose:@"www.qiniu.com"
               complete:^(PREDNetDiagResult *_Nonnull result) {
                 NSLog(@"new diagnose completed with result:\n %@", result);
               }];
}

- (IBAction)diyEvent:(id)sender {
  NSDictionary *dict = @{
    @"stringKey" :
        [NSString stringWithFormat:@"test\t_\n%d", arc4random_uniform(100)],
    @"longKey" : @(arc4random_uniform(100)),
    @"floatKey" : @(arc4random_uniform(10000) / 100.0)
  };
  PREDCustomEvent *event =
      [PREDCustomEvent eventWithName:@"test\t_\nios\t_\nevent_2"
                          contentDic:dict];
  [PREDManager trackCustomEvent:event];
}

- (IBAction)completeTransaction:(id)sender {
  PREDTransaction *transaction = [PREDManager transactionStart:@"test"];
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, arc4random() % 10 * NSEC_PER_SEC),
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [transaction complete];
      });
}

- (IBAction)failTransaction:(id)sender {
  PREDTransaction *transaction = [PREDManager transactionStart:@"test"];
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, arc4random() % 10 * NSEC_PER_SEC),
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [transaction failWithReason:@"test reason for failed transaction"];
      });
}

- (IBAction)calcelTransaction:(id)sender {
  PREDTransaction *transaction = [PREDManager transactionStart:@"test"];
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, arc4random() % 10 * NSEC_PER_SEC),
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [transaction cancelWithReason:@"test reason for cancelled transaction"];
      });
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

@end
