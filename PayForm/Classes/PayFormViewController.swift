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
   primaryColor: the primary header color of the form. Default is blue.
 */
public class PayFormViewController: UIViewController {
    
    // MARK: - Private properties

    @IBOutlet private weak var headerView: UIView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var amountLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    
    private weak var shippingAddressController: AddressViewController?
    
    // MARK: - Public properties
    
    public var amount: NSDecimalNumber = NSDecimalNumber(double:1.0)
    public var currencyCode: String = "CAD"
    public var name: String?
    public var image: UIImage?
    public var purchaseDescription: String?
    public var shippingAddressRequired: Bool?
    public var billingAddressRequired: Bool?
    public var shippingAddress: Address?
    public var billingAddress: Address?
    public var primaryColor: UIColor?
    
    // MARK: - View controller methods
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.modalPresentationStyle = .FormSheet
        }
    }
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.modalPresentationStyle = .FormSheet
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        if self.primaryColor != nil {
            self.headerView.backgroundColor = self.primaryColor
        }
        
        if self.image == nil {
            // Set the default image to use template coloring
            if let _ = self.imageView.image {
                let color = self.headerView.backgroundColor
                self.imageView.tintColor = color
            }
        }
        else {
            self.imageView.image = self.image
        }
        
        self.nameLabel.text = self.name
        self.amountLabel.text = PayFormViewController.localizedCurrencyAmount(self.amount, currencyCode: self.currencyCode)
        self.descriptionLabel.text = self.purchaseDescription
        
        if let controller = self.shippingAddressController {
            controller.amountStr = self.amountLabel.text
        }
    }

    override public func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    // MARK: - Navigation

    // This method is executed before viewDidLoad.
    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let controller = segue.destinationViewController as? UINavigationController where segue.identifier == "navController" {
            if let addressController = controller.viewControllers.first as? AddressViewController {
                self.shippingAddressController = addressController
            }
        }
    }
    
    // MARK: - Custom action methods
    
    @IBAction func closeButtonAction(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Private methods
    
    private static func localizedCurrencyAmount(amount:NSDecimalNumber, currencyCode:String) -> String {
        let formatter = NSNumberFormatter()
        formatter.currencyCode = currencyCode
        formatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
        if let localized = formatter.stringFromNumber(amount) {
            return localized
        }
        else {
            return "0.0"
        }
    }

}
