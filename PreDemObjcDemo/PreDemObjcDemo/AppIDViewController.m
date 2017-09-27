//
//  AppIDViewController.m
//  PreDemObjcDemo
//
//  Created by 王思宇 on 8/1/17.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "AppIDViewController.h"
#import <PreDemObjc/PREDemObjc.h>

#define kPreviousAppId  @"kPreviousAppId"

@interface AppIDViewController ()

@property (nonatomic, strong) IBOutlet UITextField *textField;

@end

@implementation AppIDViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSString *prevID = [[NSUserDefaults standardUserDefaults] stringForKey:kPreviousAppId];
    if (prevID) {
        _textField.text = prevID;
    }
    UITapGestureRecognizer *g = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRootview:)];
    [self.view addGestureRecognizer:g];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tapRootview:(UIView *)view {
    [_textField resignFirstResponder];
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if (_textField.text.length < 8) {
        [[[UIAlertView alloc] initWithTitle:@"出错啦" message:@"appID必须在8位以上才能继续哦" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil] show];
        return NO;
    } else {
        return YES;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [[NSUserDefaults standardUserDefaults] setObject:_textField.text forKey:kPreviousAppId];
#ifdef DEBUG
    [PREDManager startWithAppKey:_textField.text
                   serviceDomain:@"http://hriygkee.bq.cloudappl.com"
                        complete:^(BOOL succeess, NSError * _Nullable error) {
                            if (error) {
                                NSLog(@"initialize PREDManager error: %@", error);
                            }
                        }];
    PREDManager.tag = @"userid_debug";
#else
    [PREDManager startWithAppKey:_textField.text
                   serviceDomain:@"http://jkbkolos.bq.cloudappl.com"
                        complete:^(BOOL succeess, NSError * _Nullable error) {
                            if (error) {
                                NSLog(@"initialize PREDManager error: %@", error);
                            }
                        }];
    PREDManager.tag = @"userid_release";
#endif
}

@end
