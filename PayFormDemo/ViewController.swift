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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Found on iOS 9 that this was needed in case payform completes in a different
        // orientation than was originally launched in (iOS 8.3 - 9.3 with iPhone 4).
        self.view.setNeedsLayout()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    @IBAction func payAction(sender: AnyObject) {
        let storyboard = UIStoryboard(name: "PayForm", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() as? PayFormViewController {
            self.statusLabel.text = ""
            
            controller.name = "Lollipop Shop"
            controller.amount = NSDecimalNumber(double: 100.00)
            controller.currencyCode = "CAD"
            controller.purchaseDescription = "item, item, item..."
            //controller.primaryColor = UIColor.blueColor()       // default: "#067aed"
            //controller.shippingAddressRequired = true           // default: true
            //controller.billingAddressRequired = true            // default: true
            //controller.tokenRequestTimeoutSeconds = 6           // default: 6
            
            controller.processingClosure = { (result: Dictionary<String, AnyObject>?, error: NSError?) -> Void in
                if let error = error {
                    let msg  = "error (\(error.code)): \(error.localizedDescription)"
                    print(msg)
                    self.statusLabel.text = msg
                    self.statusLabel.textColor = UIColor.redColor()
                }
                else if let result = result {
                    if let cardInfo = result["cardInfo"] as? Dictionary<String, String>, let token = cardInfo["code"] as String! {
                        print("cardInfo: \(cardInfo)")
                        self.statusLabel.text = "token: \(token)"
                        self.statusLabel.textColor = UIColor.blackColor()
                    }
                    else {
                        self.statusLabel.text = "No Token!"
                        self.statusLabel.textColor = UIColor.redColor()
                    }
                    
                    if let shippingInfo = result["shippingAddress"] as? Dictionary<String, String> {
                        print("shipping: \(shippingInfo)")
                    }
                    
                    if let billingInfo = result["billingAddress"] as? Dictionary<String, String> {
                        print("billing: \(billingInfo)")
                    }
                }
                else {
                    let msg = "Yikes! No error and no result data!"
                    self.statusLabel.text = msg
                    self.statusLabel.textColor = UIColor.redColor()
                }
                
                self.dismissViewControllerAnimated(true, completion: nil)
                self.view.setNeedsLayout() // Needed in case of view orientation change
            }
            
            self.presentViewController(controller, animated: true, completion: nil)
        }
    }
    
}
