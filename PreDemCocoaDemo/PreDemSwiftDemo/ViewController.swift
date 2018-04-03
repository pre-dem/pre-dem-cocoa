//
//  ViewController.swift
//  PreDemSwiftDemo
//
//  Created by 王思宇 on 05/09/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

import UIKit
import PreDemCocoa

class ViewController: UIViewController {

    enum CustomError: Error {
        case CustomError(String)
    }

    @IBOutlet var versionLable: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        versionLable.text = "\(PREDManager.version())(\(PREDManager.build()))"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
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
                URLSession.shared.dataTask(with: URLRequest.init(url: url), completionHandler: { (_, response, _) in
                    print("response \(response?.url?.absoluteString ?? "")")
                }).resume()
            } else {
                print("url not valid \(urlString)")
            }
        }
    }

    @IBAction func diagnoseNetwork(sender: Any) {
        PREDManager.diagnose("www.qiniu.com") { (result) in
            print("new diagnose completed with result:\n\(result)")
        }
    }

    @IBAction func diyEvent(sender: Any) {
        if let event = PREDCustomEvent(name: "viewDidLoadEvent", contentDic: ["helloKey": "worldValue", "hellonum": 7]) {
            PREDManager.trackCustomEvent(event)
        }
    }
}

