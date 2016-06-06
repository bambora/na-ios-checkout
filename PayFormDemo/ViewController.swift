//
//  ViewController.swift
//  PayFormDemo
//
//  Created by Sven Resch on 2016-06-03.
//  Copyright © 2016 Beanstream Internet Commerce, Inc. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

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
            
            self.presentViewController(controller, animated: true, completion: nil)
        }
    }
    
}

