//
//  AppIDViewController.swift
//  PreDemSwiftDemo
//
//  Created by 王思宇 on 22/09/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

import UIKit
import PreDemCocoa
import UICKeyChainStore

class AppIDViewController: UIViewController {
    
    @IBOutlet var appIdTextField: UITextField!
    @IBOutlet var domainTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let keychian = UICKeyChainStore(service: "com.qiniu.pre.demo")
        
        if let prevID = keychian["appid"] {
            appIdTextField.text = prevID
        }
        
        if let prevDomain = keychian["domain"] {
            domainTextField.text = prevDomain
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func tapped(sender: Any) {
        appIdTextField.resignFirstResponder()
        domainTextField.resignFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let keychian = UICKeyChainStore(service: "com.qiniu.pre.demo")
        keychian["appid"] = appIdTextField.text
        keychian["domain"] = domainTextField.text
        #if DEBUG
            PREDManager.start(withAppKey: appIdTextField.text!, serviceDomain: domainTextField.text!, complete: { (success, error) in
                if !success {
                    PREDLogError("start PREDManager error \(String(describing: error))")
                }
            })
            PREDManager.tag = "userid_debug"
        #else
            PREDManager.start(withAppKey: appIdTextField.text!, serviceDomain: domainTextField.text!, complete: { (success, error) in
                if !success {
                    PREDLogError("start PREDManager error \(String(describing: error))")
                }
            })
            PREDManager.tag = "userid_release"
        #endif
    }
    
}
