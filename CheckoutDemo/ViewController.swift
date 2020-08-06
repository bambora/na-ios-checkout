//
//  ViewController.swift
//  CheckoutDemo
//
//  Created by Sven Resch on 2016-06-03.
//  Copyright © 2017 Bambora Inc. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var statusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        statusLabel.text = ""
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Found on iOS 9 that this was needed in case Checkout completes in a different
        // orientation than was originally launched in (iOS 8.3 - 9.3 with iPhone 4).
        self.view.setNeedsLayout()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .default
    }

    @IBAction func payAction(_ sender: AnyObject) {
        let storyboard = UIStoryboard(name: "Checkout", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() as? CheckoutViewController {
            self.statusLabel.text = ""
            
            controller.name = "Lollipop Shop"
            controller.amount = NSDecimalNumber(value: 100.00 as Double)
            controller.currencyCode = "CAD"
            controller.purchaseDescription = "item, item, item..."
            //controller.image = UIImage(named: "icon")
            //controller.primaryColor = UIColor.blue        // default: "#8247B5" Bambora Purple
            //controller.shippingAddressRequired = true     // default: true
            //controller.billingAddressRequired = true      // default: true
            //controller.tokenRequestTimeoutSeconds = 6     // default: 6
            
            controller.processingClosure = { (result: Dictionary<String, AnyObject>?, error: NSError?) -> Void in
                if let error = error {
                    let msg  = "error (\(error.code)): \(error.localizedDescription)"
                    print(msg)
                    self.statusLabel.text = msg
                    self.statusLabel.textColor = UIColor.red
                }
                else if let result = result {
                    if let cardInfo = result["cardInfo"] as? Dictionary<String, String>, let token = cardInfo["code"] as String? {
                        print("cardInfo: \(cardInfo)")
                        self.statusLabel.text = "token: \(token)"
                        self.statusLabel.textColor = UIColor.black
                    }
                    else {
                        self.statusLabel.text = "No Token!"
                        self.statusLabel.textColor = UIColor.red
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
                    self.statusLabel.textColor = UIColor.red
                }
                
                self.dismiss(animated: true, completion: nil)
                self.view.setNeedsLayout() // Needed in case of view orientation change
            }
            
            self.present(controller, animated: true, completion: nil)
        }
    }
    
}
