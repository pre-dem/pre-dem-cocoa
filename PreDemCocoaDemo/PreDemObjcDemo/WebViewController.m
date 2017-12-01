//
//  WebViewController.m
//  PreDemObjcDemo
//
//  Created by WangSiyu on 02/11/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "WebViewController.h"
#import <WebKit/WebKit.h>

@interface WebViewController ()
<
UITextFieldDelegate
>

@property (strong, nonatomic) UITextField *urlTextField;
@property (strong, nonatomic) UIWebView *webView;

@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    WKWebViewConfiguration *config = [WKWebViewConfiguration new];
    _webView = [[UIWebView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:_webView];
    _urlTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 150, 30)];
    _urlTextField.placeholder = @"请输入 URL";
    _urlTextField.keyboardType = UIKeyboardTypeURL;
    _urlTextField.returnKeyType = UIReturnKeyGo;
    _urlTextField.textContentType = UITextContentTypeURL;
    _urlTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _urlTextField.delegate = self;
    self.navigationItem.titleView = _urlTextField;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didPressedCancelButton {
    [_urlTextField resignFirstResponder];
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(didPressedCancelButton)];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (!textField.text.length) {
        UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"错误" message:@"请输入您要访问的 url" preferredStyle:UIAlertControllerStyleAlert];
        [controller addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:controller animated:YES completion:nil];
        return NO;
    }
    [_urlTextField resignFirstResponder];
    self.navigationItem.rightBarButtonItem = nil;
    NSURL *url = [NSURL URLWithString:textField.text];
    if (!url.scheme) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", url.absoluteString]];
    }
    [_webView loadRequest:[NSURLRequest requestWithURL:url]];
    return YES;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
