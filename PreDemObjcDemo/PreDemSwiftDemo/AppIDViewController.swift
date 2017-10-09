//
//  AppIDViewController.swift
//  PreDemSwiftDemo
//
//  Created by 王思宇 on 22/09/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

import UIKit
import PreDemObjc

let kPreviousAppId = "kPreviousAppId"

class AppIDViewController: UIViewController {
    
    @IBOutlet var textField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        if let prevID = UserDefaults.standard.string(forKey: kPreviousAppId) {
            textField.text = prevID;
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func tapped(sender: Any) {
        textField.resignFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        UserDefaults.standard.set(textField.text, forKey: kPreviousAppId)
        var error: NSError?
        #if DEBUG
            PREDManager.start(withAppKey: textField.text!, serviceDomain: "http://hriygkee.bq.cloudappl.com", complete: { (success, error) in
                if !success {
                    PREDLogError("start PREDManager error" + (error?.localizedDescription)!)
                }
            })
            PREDManager.tag = "userid_debug"
        #else
            PREDManager.start(withAppKey: textField.text!, serviceDomain: "http://jkbkolos.bq.cloudappl.com", complete: { (success, error) in
                if !success {
                    PREDLogError("start PREDManager error" + (error?.localizedDescription)!)
                }
            })
            PREDManager.tag = "userid_release"
        #endif
    }
    
}
