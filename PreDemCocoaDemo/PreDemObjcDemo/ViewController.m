//
//  ViewController.m
//  PreDemObjcDemo
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "ViewController.h"
#import <PreDemCocoa/PREDemCocoa.h>


@interface ViewController ()
<
UIPickerViewDataSource,
UIPickerViewDelegate,
PREDLogDelegate
>

@property (nonatomic, strong) IBOutlet UILabel *versionLable;
@property (nonatomic, strong) IBOutlet UIPickerView *logLevelPicker;
@property (nonatomic, strong) IBOutlet UITextView *logTextView;
@property (nonatomic, strong) NSArray *logPickerKeys;
@property (nonatomic, strong) NSArray *logPickerValues;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.versionLable.text = [NSString stringWithFormat:@"%@(%@)", PREDManager.version, PREDManager.build];
    PREDLog.delegate = self;
    self.logPickerKeys = @[
                               @"不上传 log",
                               @"PREDLogLevelOff",
                               @"PREDLogLevelError",
                               @"PREDLogLevelWarning",
                               @"PREDLogLevelInfo",
                               @"PREDLogLevelDebug",
                               @"PREDLogLevelVerbose",
                               @"PREDLogLevelAll"
                               ];
    self.logPickerValues = @[
                           @(PREDLogLevelOff),
                           @(PREDLogLevelError),
                           @(PREDLogLevelWarning),
                           @(PREDLogLevelInfo),
                           @(PREDLogLevelDebug),
                           @(PREDLogLevelVerbose),
                           @(PREDLogLevelAll)
                           ];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

- (IBAction)viewTapped:(id)sender {
    PREDLogVerbose(@"verbose log test");
    PREDLogDebug(@"debug log test");
    PREDLogInfo(@"info log test");
    PREDLogWarn(@"warn log test");
    PREDLogError(@"error log test");
}

- (IBAction)viewLongPressed:(id)sender {
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"调试菜单" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    NSString *actionName;
    if (!_logTextView.delegate) {
        actionName = @"开启将 log 输出到界面";
    } else {
        actionName = @"关闭将 log 输出到界面";
    }
    [controller addAction:[UIAlertAction actionWithTitle:actionName style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (!_logTextView.delegate) {
            _logTextView.delegate = self;
        } else {
            _logTextView.delegate = nil;
        }
    }]];
    
    [controller addAction:[UIAlertAction actionWithTitle:@"清空界面 log" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        _logTextView.text = @"";
    }]];
    
    [controller addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:controller animated:YES completion:nil];
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
    [PREDManager  diagnose:@"www.qiniu.com"
                  complete:^(PREDNetDiagResult * _Nonnull result) {
        NSLog(@"new diagnose completed with result:\n %@", result);
    }];
}

- (IBAction)forceCrash:(id)sender {
    @throw [NSException exceptionWithName:@"Manually Exception" reason:@"嗯，我是故意的" userInfo:nil];
}

- (IBAction)diyEvent:(id)sender {
    NSDictionary *dict = @{
                           @"stringKey": [NSString stringWithFormat:@"test\t_\n%d", arc4random_uniform(100)],
                           @"longKey": @(arc4random_uniform(100)),
                           @"floatKey": @(arc4random_uniform(10000)/100.0)
                           };
    PREDCustomEvent *event = [PREDCustomEvent eventWithName:@"test\t_\nios\t_\nevent_2" contentDic:dict];
    [PREDManager trackCustomEvent:event];
}

- (IBAction)blockMainThread:(id)sender {
    sleep(1);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)log:(PREDLog *)log didReceivedLogMessage:(DDLogMessage *)message formattedLog:(NSString *)formattedLog {
    dispatch_async(dispatch_get_main_queue(), ^{
        _logTextView.text = [NSString stringWithFormat:@"%@%@\n", _logTextView.text, formattedLog];
        _logTextView.layoutManager.allowsNonContiguousLayout = NO;
        [_logTextView scrollRangeToVisible:NSMakeRange(0, _logTextView.text.length)];
    });
}

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.logPickerKeys.count;
}

- (nullable NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component __TVOS_PROHIBITED {
    return self.logPickerKeys[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component __TVOS_PROHIBITED; {
    if (row == 0) {
        [PREDLog stopCaptureLog];
    } else {
        NSError *error;
        BOOL success = [PREDLog startCaptureLogWithLevel:(PREDLogLevel)[self.logPickerValues[row-1] intValue] error:&error];
        if (!success) {
            UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"错误" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
            [controller addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:controller animated:YES completion:nil];
        }
    }
}


@end
