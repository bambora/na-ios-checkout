//
//  AddressViewController.swift
//  PayForm
//
//  Created by Sven Resch on 2016-06-02.
//  Copyright © 2016 Beanstream Internet Commerce, Inc. All rights reserved.
//

import UIKit

private enum Row: Int {
    case Name = 0
    case Street
    case ZipCity
    case ProvinceCountry
    case BillingSame
    case Error
}

// Handles either Shipping Address or Billing address interaction depending on the addressType 
// property that is setup before the view is loaded. This controller has an initial section 0 
// where most content is shown except for the Next Step "button" row that is section 1. The Next 
// Step button will have a title text that reads Billing Address (if billing address is required
// and if the user has set "Billing is not the same as Shipping" or otherwise will have a button 
// title text that read "Pay >".
public class AddressViewController: UITableViewController {
    
    // MARK: - Properties

    public var addressType: AddressType = .Shipping
    public var amountStr: String?
    
    private var billingAddressIsSame: Bool = false
    private var viewFields = [BorderedView: UITextField]()
    
    private let NUM_ROWS_OK     = 5
    private let NUM_ROWS_ERROR  = 6
    private var numRows = 5
    
    // MARK: - View controller methods

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        // Get rid of extra/unused cell separator lines
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if addressType == .Billing {
            self.title = NSLocalizedString("Billing Address", comment: "Address view title when used in Billing mode")
        }
        else {
            self.title = NSLocalizedString("Shipping Address", comment: "Address view title when used in Shipping mode")
        }
    }
    
    override public func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.title = ""
    }
    
    // MARK: - Table view delegate
    
    override public func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.section == 1 {
            // Next Step button
            self.view.endEditing(true)
            
            if self.validateTextFields() {
                if self.numRows == NUM_ROWS_ERROR {
                    self.numRows = NUM_ROWS_OK
                    self.tableView.deleteRowsAtIndexPaths([NSIndexPath.init(forRow: Row.Error.rawValue, inSection: 0)], withRowAnimation: .Automatic)
                }
                
                if addressType == .Shipping && !self.billingAddressIsSame {
                    if let controller = self.storyboard?.instantiateViewControllerWithIdentifier("AddressViewController") as? AddressViewController {
                        controller.addressType = .Billing
                        controller.amountStr = self.amountStr
                        self.navigationController?.pushViewController(controller, animated: true)
                    }
                }
                else {
                    self.performSegueWithIdentifier("payment", sender: self)
                }
            }
            else {
                if self.numRows == NUM_ROWS_OK {
                    self.numRows = NUM_ROWS_ERROR
                    self.tableView.insertRowsAtIndexPaths([NSIndexPath.init(forRow: Row.Error.rawValue, inSection: 0)], withRowAnimation: .Automatic)
                }
            }
        }
        return nil; // Disable cell selection
    }
    
    override public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if self.addressType == .Billing && indexPath.row == Row.BillingSame.rawValue {
            return 0
        }
        else {
            return self.tableView.rowHeight
        }
    }

    // MARK: - Table view data source
    
    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return numRows
        }
        else {
            return 1
        }
    }
    
    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell;
        
        if indexPath.section == 0 {
            switch indexPath.row {
            case Row.Name.rawValue:
                cell = tableView.dequeueReusableCellWithIdentifier("nameCell", forIndexPath: indexPath)
                if let borderedCell = self.setupBorderedCell(cell) {
                    borderedCell.drawTop(true) // needed for any row where a bordered row is not directly on top
                }
                
            case Row.Street.rawValue:
                cell = tableView.dequeueReusableCellWithIdentifier("streetCell", forIndexPath: indexPath)
                self.setupBorderedCell(cell)
                
            case Row.ZipCity.rawValue:
                cell = tableView.dequeueReusableCellWithIdentifier("zipCityCell", forIndexPath: indexPath)
                self.setupDualBorderedCell(cell)
                
            case Row.ProvinceCountry.rawValue:
                cell = tableView.dequeueReusableCellWithIdentifier("provinceCountryCell", forIndexPath: indexPath)
                self.setupDualBorderedCell(cell)
                
            case Row.BillingSame.rawValue:
                cell = tableView.dequeueReusableCellWithIdentifier("billingIsSameCell", forIndexPath: indexPath)
                if let billingIsSameCell = cell as? BillingIsSameViewCell {
                    billingIsSameCell.useShippingSwitch.addTarget(self, action: #selector(billingIsSameValueChanged(_:)), forControlEvents: .ValueChanged)
                    billingIsSameCell.useShippingSwitch.on = self.billingAddressIsSame
                }

            case Row.Error.rawValue:
                cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "error")
                cell.backgroundColor = UIColor.redColor().colorWithAlphaComponent(0.1)
                cell.textLabel?.text = "Please fill all fields."
                cell.textLabel?.textColor = "#b71c1c".hexColor
                cell.imageView?.tintColor = "#b71c1c".hexColor
                
                var image = UIImage.init(named: "ic_error_outline_black_48dp")
                let itemSize = CGSizeMake(24, 24)
                let imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height)
                
                UIGraphicsBeginImageContextWithOptions(itemSize, false, UIScreen.mainScreen().scale)
                image?.drawInRect(imageRect)
                image = UIGraphicsGetImageFromCurrentImageContext()
                cell.imageView?.image = image?.imageWithRenderingMode(.AlwaysTemplate)
                UIGraphicsEndImageContext()
                
            default:
                cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "fubar")
                cell.textLabel?.text = "fubar"
            }
        }
        else {
            cell = tableView.dequeueReusableCellWithIdentifier("nextStepCell", forIndexPath: indexPath)
            if let nextStepCell = cell as? NextStepCell {
                var title = ""
                if addressType == .Shipping && !self.billingAddressIsSame {
                    title = NSLocalizedString("BILLING ADDRESS >", comment: "Button title to use to enter Billing Address view")
                }
                else {
                    title = NSLocalizedString("PAY >", comment: "Button title to use to enter Payment view")
                }
                nextStepCell.setTitleText(title)
                nextStepCell.drawTop(true)
            }
        }
        
        return cell
    }
    
    // MARK: - Navigation
    
    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    // MARK: - Custom action methods
    
    func billingIsSameValueChanged(sender: UISwitch) {
        self.view.endEditing(true)
        self.billingAddressIsSame = sender.on
        let nextStepIndexPath = NSIndexPath(forRow: 0, inSection: 1)
        self.tableView.reloadRowsAtIndexPaths([nextStepIndexPath], withRowAnimation: .Automatic)
    }
    
    // MARK: - Private methods
    
    private func setupBorderedCell(cell: UITableViewCell) -> BorderedViewCell? {
        if let borderedCell = cell as? BorderedViewCell {
            if let textField = borderedCell.textField() {
                textField.delegate = self
                if let borderedView = textField.superview as? BorderedView {
                    viewFields[borderedView] = textField
                }
            }
            return borderedCell
        }
        
        return nil
    }

    private func setupDualBorderedCell(cell: UITableViewCell) -> DualBorderedViewCell? {
        if let dualBorderedCell = cell as? DualBorderedViewCell {
            if let textField = dualBorderedCell.textField(.Left) {
                textField.delegate = self
                if let borderedView = textField.superview as? BorderedView {
                    viewFields[borderedView] = textField
                }
            }
            if let textField = dualBorderedCell.textField(.Right) {
                textField.delegate = self
                if let borderedView = textField.superview as? BorderedView {
                    viewFields[borderedView] = textField
                }
            }
            return dualBorderedCell
        }
        
        return nil
    }

    private func validateTextFields() -> Bool {
        var valid = true
        
        for (borderedView, textField) in viewFields {
            if textField.text == nil ||
                textField.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) == ""
            {
                valid = false
                borderedView.innerBorderColor = UIColor.redColor().colorWithAlphaComponent(0.5)
            }
            else {
                borderedView.innerBorderColor = UIColor.clearColor()
            }
        }
        
        if valid && self.numRows == NUM_ROWS_ERROR {
            self.numRows = NUM_ROWS_OK
            self.tableView.deleteRowsAtIndexPaths([NSIndexPath.init(forRow: Row.Error.rawValue, inSection: 0)], withRowAnimation: .Automatic)
        }

        return valid
    }
    
}

extension AddressViewController: UITextFieldDelegate {
    
    public func textFieldDidBeginEditing(textField: UITextField) {
        if let borderedView = textField.superview as? BorderedView {
            //var highlightColor = borderedView.innerBorder?.borderColor
            borderedView.innerBorder?.borderColor = UIColor.blackColor().CGColor
            borderedView.setNeedsDisplay()
        }
    }
    
    public func textFieldDidEndEditing(textField: UITextField) {
        if let borderedView = textField.superview as? BorderedView {
            borderedView.innerBorder?.borderColor = UIColor.clearColor().CGColor
            borderedView.setNeedsDisplay()
        }
        
        // Re-check validation only when an error condidion pre-exists
        if self.tableView.numberOfRowsInSection(0) == NUM_ROWS_ERROR {
            self.validateTextFields()
        }
    }
    
}

