//
//  PayFormViewController.swift
//  PayForm
//
//  Created by Sven Resch on 2016-06-01.
//  Copyright © 2016 Beanstream Internet Commerce, Inc. All rights reserved.
//

import UIKit

/*
 Adding PayForm to your app could not be easier. You simply create and display this 
 view controller. PayForm is configured by setting data attributes on this view
 controller. It can be configured to collect shipping and billing addresses in 
 addition to the card details.
 
 The required parameters are:
   amount: the amount you are going to charge the customer
   currency: the currency
 
 The optional parameters are:
   name: your company name
   image: your company logo
   purchaseDescription: a description of the purchase
   shippingAddress: if the shipping address is required – true/false
   billingAddress: if the billing address is required – true/false
-->   submitForm: if the form’s default action should be executed – true/false
   primaryColor: the highlight color of the form. Default is blue.
 */
public class PayFormViewController: UIViewController {

    public var amount: NSDecimalNumber = NSDecimalNumber(double:1.0)
    public var currency: String = "CAD"
    
    public var name: String?
    public var image: UIImage?
    public var purchaseDescription: String?
    public var shippingAddressRequired: Bool?
    public var billingAddressRequired: Bool?
    
    public var shippingAddress: Address?
    public var billingAddress: Address?
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
