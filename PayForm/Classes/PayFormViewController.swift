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
    @IBOutlet private weak var footerView: UIView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var amountLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    
    // Either an AddressViewController (billing or shipping) or a 
    // PaymentViewController will be loaded as the root controller.
    private weak var addressController: AddressViewController?
    private weak var paymentController: PaymentViewController?
    
    // MARK: - Public properties
    
    public var amount: NSDecimalNumber = NSDecimalNumber(double:1.0)
    public var currencyCode: String = "CAD"
    public var name: String?
    public var image: UIImage?
    public var purchaseDescription: String?
    
    public var shippingAddressRequired: Bool = true
    public var billingAddressRequired: Bool = true
    public var shippingAddress: Address?
    public var billingAddress: Address?
    
    public var primaryColor: UIColor = Settings.primaryColor {
        didSet {
            Settings.primaryColor = primaryColor
        }
    }
    
    public var processingClosure: ((result: Dictionary<String, AnyObject>?, error: NSError?) -> Void)?
    
    public var tokenRequestTimeoutSeconds = Settings.tokenRequestTimeout {
        didSet {
            Settings.tokenRequestTimeout = tokenRequestTimeoutSeconds
        }
    }
    
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
        
        self.headerView.backgroundColor = self.primaryColor
        
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
        
        if let controller = self.addressController {
            controller.amountStr = self.amountLabel.text
            controller.processingClosure = self.processingClosure
            controller.billingAddressRequired = self.billingAddressRequired
            controller.shippingAddress = self.shippingAddress
            controller.billingAddress = self.billingAddress
        }
        else if let controller = self.paymentController {
            controller.amountStr = self.amountLabel.text
            controller.processingClosure = self.processingClosure
            controller.shippingAddress = self.shippingAddress
            controller.billingAddress = self.billingAddress
        }
        
        self.footerView.alpha = 0
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(showFooter),
            name: "ShowFooter",
            object: nil)

        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(hideFooter),
            name: "HideFooter",
            object: nil)
    }

    override public func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    // MARK: - Navigation
    
    // This method is executed before viewDidLoad.
    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let navController = segue.destinationViewController as? UINavigationController where segue.identifier == "navController" {
            if !self.billingAddressRequired && !self.shippingAddressRequired {
                // Re-jig the nav controller to have a PaymentViewController as its root
                let storyboard = UIStoryboard(name: "PayForm", bundle: nil)
                if let paymentController = storyboard.instantiateViewControllerWithIdentifier("PaymentViewController") as? PaymentViewController {
                    self.paymentController = paymentController
                    navController.viewControllers = [paymentController]
                }
            }
            else {
                // Figure out what root view controller we are dealing with and set
                // it as an instance var so that it can be further setup in viewDidLoad.
                if let addressController = navController.viewControllers.first as? AddressViewController {
                    self.addressController = addressController
                } else if let paymentController = navController.viewControllers.first as? PaymentViewController {
                    self.paymentController = paymentController
                }
            }
        }
    }
    
    // MARK: - Custom action methods
    
    @IBAction func closeButtonAction(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func showFooter() {
        UILabel.beginAnimations(nil, context: nil)
        UILabel.setAnimationDuration(0.25)
        self.footerView.alpha = 1
        UILabel.commitAnimations()
    }

    func hideFooter() {
        UILabel.beginAnimations(nil, context: nil)
        UILabel.setAnimationDuration(0.25)
        self.footerView.alpha = 0
        UILabel.commitAnimations()
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
