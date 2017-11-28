//
//  WebViewController.swift
//  PreDemSwiftDemo
//
//  Created by WangSiyu on 28/11/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, UITextFieldDelegate {
    var urlTextField = UITextField(frame: CGRect(x: 0, y: 0, width: 150, height: 30))
    var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView = WKWebView(frame: self.view.frame, configuration: WKWebViewConfiguration())
        self.view.addSubview(webView)
        urlTextField.placeholder = "请输入 URL"
        urlTextField.keyboardType = .URL
        urlTextField.returnKeyType = .go
        urlTextField.textContentType = UITextContentType.URL
        urlTextField.clearButtonMode = .whileEditing
        urlTextField.delegate = self
        self.navigationItem.titleView = urlTextField
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
    
    @objc func didPressedCancelButton() {
        urlTextField.resignFirstResponder()
        self.navigationItem.rightBarButtonItem = nil
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(didPressedCancelButton))
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text {
            if text.count == 0 {
                let controller = UIAlertController(title: "错误", message: "请输入您要访问的 url", preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: "好的", style: .default, handler: nil))
                return false
            }
            
            urlTextField.resignFirstResponder()
            self.navigationItem.rightBarButtonItem = nil
            var url = URL(string: text)
            if url?.scheme == nil {
                url = URL(string: "http://\(String(describing: url?.absoluteString))")
            }
            webView.load(URLRequest(url: url!))
            return true
        } else {
            return false
        }
    }
}
