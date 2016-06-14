//
//  ViewController.swift
//  PayFormDemo
//
//  Created by Sven Resch on 2016-06-03.
//  Copyright © 2016 Beanstream Internet Commerce, Inc. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var statusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        statusLabel.text = ""
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    @IBAction func payAction(sender: AnyObject) {
        let storyboard = UIStoryboard(name: "PayForm", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() as? PayFormViewController {
            controller.name = "Lollipop Shop"
            controller.amount = NSDecimalNumber(double: 100.00)
            controller.currencyCode = "CAD"
            controller.purchaseDescription = "item, item, item..."
            controller.primaryColor = "#067aed".hexColor
            
            controller.processingClosure = { (jsonToken: Dictionary<String, AnyObject>?, error: NSError?) -> Void in
                if let error = error {
                    let msg  = "error (\(error.code)): \(error.localizedDescription)"
                    print(msg)
                    self.statusLabel.text = msg
                    self.statusLabel.textColor = UIColor.redColor()
                }
                else if let json = jsonToken, let token = json["token"] as? String {
                    print("jsonToken: \(json)")
                    self.statusLabel.text = "token: \(token)"
                    self.statusLabel.textColor = UIColor.blackColor()
                }
                else {
                    let msg = "Yikes! No error and no JSON token!"
                    self.statusLabel.text = msg
                    self.statusLabel.textColor = UIColor.redColor()
                }
            }
            
            self.presentViewController(controller, animated: true, completion: nil)
        }
    }
    
}
