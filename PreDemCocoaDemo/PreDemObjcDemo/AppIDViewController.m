//
//  AppIDViewController.m
//  PreDemObjcDemo
//
//  Created by 王思宇 on 8/1/17.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "AppIDViewController.h"
#import "PREDemCocoa.h"
#import <UICKeyChainStore/UICKeyChainStore.h>

@interface AppIDViewController ()

@property (nonatomic, strong) IBOutlet UITextField *appIdTextField;
@property (nonatomic, strong) IBOutlet UITextField *domainTextField;

@end

@implementation AppIDViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:@"com.qiniu.pre.demo"];
    NSString *prevID = keychain[@"appid"];
    NSString *prevDomain = keychain[@"domain"];
    if (prevID) {
        _appIdTextField.text = prevID;
    }
    if (prevDomain) {
        _domainTextField.text = prevDomain;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)tapped:(id)sender {
    [_appIdTextField resignFirstResponder];
    [_domainTextField resignFirstResponder];
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if (_appIdTextField.text.length < 8 || _domainTextField.text.length == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"出错啦" message:@"appID 必须在8位以上，domain 不能为空，才能继续哦" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return NO;
    } else {
        return YES;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:@"com.qiniu.pre.demo"];
    keychain[@"appid"] = _appIdTextField.text;
    keychain[@"domain"] = _domainTextField.text;
#ifdef DEBUG
    [PREDManager startWithAppKey:_appIdTextField.text
                   serviceDomain:_domainTextField.text
                        complete:^(BOOL succeess, NSError * _Nullable error) {
                            if (error) {
                                NSLog(@"initialize PREDManager error: %@", error);
                            }
                        }];
    PREDManager.tag = @"userid_debug";
    PREDLog.ttyLogLevel = DDLogLevelAll;
#else
    [PREDManager startWithAppKey:_appIdTextField.text
                   serviceDomain:_domainTextField.text
                        complete:^(BOOL succeess, NSError * _Nullable error) {
                            if (error) {
                                NSLog(@"initialize PREDManager error: %@", error);
                            }
                        }];
    PREDManager.tag = @"userid_release";
#endif
}

@end
