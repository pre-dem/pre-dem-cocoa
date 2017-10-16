//
//  ViewController.swift
//  PreDemSwiftDemo
//
//  Created by 王思宇 on 05/09/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

import UIKit
import PreDemObjc

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    enum CustomError: Error {
        case CustomError(String)
    }
    
    @IBOutlet var versionLable: UILabel!
    @IBOutlet var logLevelPicker: UIPickerView!
    
    let logPickerKeys = [
        "不上传 log",
        "PREDLogLevelOff",
        "PREDLogLevelError",
        "PREDLogLevelWarning",
        "PREDLogLevelInfo",
        "PREDLogLevelDebug",
        "PREDLogLevelVerbose",
        "PREDLogLevelAll"
    ]
    let logPickerValues = [
        PREDLogLevel.off,
        PREDLogLevel.error,
        PREDLogLevel.warning,
        PREDLogLevel.info,
        PREDLogLevel.debug,
        PREDLogLevel.verbose,
        PREDLogLevel.all,
        ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func sendHttpRequest(sender: Any) {
        let urls = [
            "http://www.baidu.com",
            "https://www.163.com",
            "http://www.qq.com",
            "https://www.dehenglalala.com",
            "http://www.balabalabalatest.com",
            "http://www.alipay.com",
            ]
        for urlString in urls {
            if let url = URL(string: urlString) {
                URLSession.shared.dataTask(with: URLRequest.init(url: url)).resume()
            } else {
                print("url not valid \(urlString)")
            }
        }
    }
    
    @IBAction func blockMainThread(sender: Any) {
        sleep(1)
    }
    
    @IBAction func forceCrash(sender: Any) {
        try!{throw CustomError.CustomError("嗯，我是故意的")}()
    }
    
    @IBAction func diagnoseNetwork(sender: Any) {
        PREDManager.diagnose("www.qiniu.com") { (result) in
            print("new diagnose completed with result:\n\(result)")
        }
    }
    
    @IBAction func diyEvent(sender: Any) {
        if let event = PREDEvent(name: "viewDidLoadEvent", contentDic: ["helloKey": "worldValue", "hellonum": 7]) {
            PREDManager.trackEvent(event)
        }
    }
    
    @IBAction func logTest(sender: Any) {
        PREDLogVerbose("verbose log test");
        PREDLogDebug("debug log test");
        PREDLogInfo("info log test");
        PREDLogWarn("warn log test");
        PREDLogError("error log test");
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return logPickerKeys.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return logPickerKeys[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row == 0 {
            PREDLogger.stopCaptureLog()
        } else {
            PREDLogger.startCaptureLog(with: logPickerValues[row-1])
        }
    }
    
    
}

