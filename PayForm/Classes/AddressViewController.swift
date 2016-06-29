//
//  AddressViewController.swift
//  PayForm
//
//  Created by Sven Resch on 2016-06-02.
//  Copyright © 2016 Beanstream Internet Commerce, Inc. All rights reserved.
//

import UIKit

// Handles either Shipping Address or Billing address interaction depending on the addressType
// property that is setup before the view is loaded. This controller has an initial section 0 
// where most content is shown except for the Next Step "button" row that is section 1. The Next 
// Step button will have a title text that reads Billing Address (if billing address is required
// and if the user has set "Billing is not the same as Shipping" or otherwise will have a button 
// title text that read "Pay >".
class AddressViewController: UITableViewController {
    
    private enum Row: Int {
        case Name = 0
        case Street
        case PostalcodeCity
        case ProvinceCountry
        case BillingSame
        case Error
    }
    
    // MARK: - Properties

    var addressType: AddressType = .Shipping
    
    private var address: Address?
    private var billingAddressIsSame: Bool = true
    private var viewFields = [BorderedView: UITextField]()
    private var keyedFields = Dictionary<String, UITextField>()
    
    private let NUM_ROWS_OK     = 5
    private let NUM_ROWS_ERROR  = 6
    private var numRows = 5
    
    // MARK: - View controller methods
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if addressType == .Billing {
            self.title = NSLocalizedString("Billing", comment: "Address view title when used in Billing mode")
            self.address = State.sharedInstance.billingAddress
        }
        else {
            self.title = NSLocalizedString("Shipping", comment: "Address view title when used in Shipping mode")
            if !State.sharedInstance.billingAddressRequired {
                self.billingAddressIsSame = true // sets UI as needed
            }
            self.address = State.sharedInstance.shippingAddress
        }

        if self.address == nil {
            address = Address()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(animated)
        self.updateAddressInfo()
    }
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
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
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == Row.BillingSame.rawValue && (self.addressType == .Billing || !State.sharedInstance.billingAddressRequired) {
            return 0
        }
        else {
            return self.tableView.rowHeight
        }
    }

    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return numRows
        }
        else {
            return 1
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell;
        
        if indexPath.section == 0 {
            if let row = Row(rawValue: indexPath.row) {
                switch row {
                case Row.Name:
                    cell = tableView.dequeueReusableCellWithIdentifier("nameCell", forIndexPath: indexPath)
                    if let borderedCell = self.setupBorderedCell(cell, key: "name", tag: 0) {
                        borderedCell.drawTop(true) // needed for any row where a bordered row is not directly on top
                        borderedCell.textField()?.text = address?.name
                    }
                case Row.Street:
                    cell = tableView.dequeueReusableCellWithIdentifier("streetCell", forIndexPath: indexPath)
                    if let borderedCell = self.setupBorderedCell(cell, key: "street", tag: 1) {
                        borderedCell.textField()?.text = address?.street
                    }
                    
                case Row.PostalcodeCity:
                    cell = tableView.dequeueReusableCellWithIdentifier("zipCityCell", forIndexPath: indexPath)
                    if let dualBorderedCell = self.setupDualBorderedCell(cell, leftKey: "postalCode", leftTag: 2, rightKey: "city", rightTag: 3) {
                        dualBorderedCell.textField(.Left)?.text = address?.postalCode
                        dualBorderedCell.textField(.Right)?.text = address?.city
                    }
                    
                case Row.ProvinceCountry:
                    cell = tableView.dequeueReusableCellWithIdentifier("provinceCountryCell", forIndexPath: indexPath)
                    if let dualBorderedCell = self.setupDualBorderedCell(cell, leftKey: "province", leftTag: 4, rightKey: "country", rightTag: 5) {
                        dualBorderedCell.textField(.Left)?.text = address?.province
                        dualBorderedCell.textField(.Right)?.text = address?.country
                    }
                    
                case Row.BillingSame:
                    cell = tableView.dequeueReusableCellWithIdentifier("billingIsSameCell", forIndexPath: indexPath)
                    if let billingIsSameCell = cell as? BillingIsSameViewCell {
                        billingIsSameCell.useShippingSwitch.addTarget(self, action: #selector(billingIsSameValueChanged(_:)), forControlEvents: .ValueChanged)
                        billingIsSameCell.useShippingSwitch.on = self.billingAddressIsSame
                    }

                case Row.Error:
                    cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "error")
                    cell.backgroundColor = UIColor.redColor().colorWithAlphaComponent(0.1)
                    cell.selectionStyle = .None
                    cell.textLabel?.text = NSLocalizedString("Please fill all fields.", comment: "Validation statement used when all fields are not entered on Address view.")
                    cell.textLabel?.textColor = "#b71c1c".hexColor
                    cell.imageView?.tintColor = "#b71c1c".hexColor
                    
                    var image = UIImage.init(named: "ic_error_outline_black_48dp")
                    let imageRect = CGRectMake(0, 0, 24, 24)
                    
                    UIGraphicsBeginImageContextWithOptions(imageRect.size, false, UIScreen.mainScreen().scale)
                    image?.drawInRect(imageRect)
                    image = UIGraphicsGetImageFromCurrentImageContext()
                    cell.imageView?.image = image?.imageWithRenderingMode(.AlwaysTemplate)
                    UIGraphicsEndImageContext()
                }
            }
            else {
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
                nextStepCell.setBorderColor(Settings.primaryColor)
            }
        }
        
        return cell
    }
    
    // MARK: - Custom action methods
    
    func billingIsSameValueChanged(sender: UISwitch) {
        self.view.endEditing(true)
        self.billingAddressIsSame = sender.on
        let nextStepIndexPath = NSIndexPath(forRow: 0, inSection: 1)
        self.tableView.reloadRowsAtIndexPaths([nextStepIndexPath], withRowAnimation: .Automatic)
    }
    
    // MARK: - Private methods
    
    private func setupBorderedCell(cell: UITableViewCell, key: String, tag: Int) -> BorderedViewCell? {
        if let borderedCell = cell as? BorderedViewCell {
            if let textField = borderedCell.textField() {
                textField.delegate = self
                if let borderedView = textField.superview as? BorderedView {
                    viewFields[borderedView] = textField
                }
                self.keyedFields[key] = textField
                textField.tag = tag
            }
            return borderedCell
        }
        
        return nil
    }

    private func setupDualBorderedCell(cell: UITableViewCell, leftKey: String, leftTag: Int, rightKey: String, rightTag: Int) -> DualBorderedViewCell? {
        if let dualBorderedCell = cell as? DualBorderedViewCell {
            if let textField = dualBorderedCell.textField(.Left) {
                textField.delegate = self
                if let borderedView = textField.superview as? BorderedView {
                    viewFields[borderedView] = textField
                }
                self.keyedFields[leftKey] = textField
                textField.tag = leftTag
            }
            if let textField = dualBorderedCell.textField(.Right) {
                textField.delegate = self
                if let borderedView = textField.superview as? BorderedView {
                    viewFields[borderedView] = textField
                }
                self.keyedFields[rightKey] = textField
                textField.tag = rightTag
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
    
    private func updateAddressInfo() {
        if self.addressType == .Shipping {
            State.sharedInstance.shippingAddress = address
            if self.billingAddressIsSame {
                State.sharedInstance.billingAddress = address
            }
        }
        else {
            State.sharedInstance.billingAddress = address
        }
    }
}

extension AddressViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if let borderedView = textField.superview as? BorderedView {
            //var highlightColor = borderedView.innerBorder?.borderColor
            borderedView.innerBorderColor = UIColor.blackColor()
            borderedView.setNeedsDisplay()
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if let borderedView = textField.superview as? BorderedView {
            borderedView.innerBorderColor = UIColor.clearColor()
            borderedView.setNeedsDisplay()
        }
        
        // Re-check validation only when an error condidion pre-exists
        if self.tableView.numberOfRowsInSection(0) == NUM_ROWS_ERROR {
            self.validateTextFields()
        }
        
        // Update address
        if self.address != nil, let text = textField.text {
            if textField == self.keyedFields["name"] { self.address!.name = text }
            else if textField == self.keyedFields["street"] { self.address!.street = text }
            else if textField == self.keyedFields["postalCode"] { self.address!.postalCode = text }
            else if textField == self.keyedFields["city"] { self.address!.city = text }
            else if textField == self.keyedFields["province"] { self.address!.province = text }
            else if textField == self.keyedFields["country"] { self.address!.country = text }
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        var tag = textField.tag
        if let lastField = self.keyedFields["country"] where tag < lastField.tag {
            tag += 1
            for nextField in self.keyedFields.values {
                if nextField.tag == tag {
                    nextField.becomeFirstResponder()
                    break
                }
            }
        }
        else {
            textField.resignFirstResponder()
        }
        return false
    }
    
}
