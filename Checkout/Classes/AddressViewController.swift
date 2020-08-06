//
//  AddressViewController.swift
//  Checkout
//
//  Created by Sven Resch on 2016-06-02.
//  Copyright © 2017 Bambora Inc. All rights reserved.
//

import UIKit

// Handles either Shipping Address or Billing address interaction depending on the addressType
// property that is setup before the view is loaded. This controller has an initial section 0 
// where most content is shown except for the Next Step "button" row that is section 1. The Next 
// Step button will have a title text that reads Billing Address (if billing address is required
// and if the user has set "Billing is not the same as Shipping" or otherwise will have a button 
// title text that read "Pay >".
class AddressViewController: UITableViewController {
    
    fileprivate enum Row: Int {
        case name = 0
        case street
        case postalcodeCity
        case provinceCountry
        case billingSame
        case error
    }
    
    // MARK: - Properties

    var addressType: AddressType = .shipping
    
    fileprivate var address: Address?
    fileprivate var billingAddressIsSame: Bool = true
    fileprivate var viewFields = [BorderedView: UITextField]()
    fileprivate var keyedFields = Dictionary<String, UITextField>()
    
    fileprivate let NUM_ROWS_OK     = 5
    fileprivate let NUM_ROWS_ERROR  = 6
    fileprivate var numRows = 5
    
    // MARK: - View controller methods
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if addressType == .billing {
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateAddressInfo()
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 1 {
            // Next Step button
            self.view.endEditing(true)
            
            if self.validateTextFields() {
                if self.numRows == NUM_ROWS_ERROR {
                    self.numRows = NUM_ROWS_OK
                    self.tableView.deleteRows(at: [IndexPath.init(row: Row.error.rawValue, section: 0)], with: .automatic)
                }
                
                if addressType == .shipping && !self.billingAddressIsSame {
                    if let controller = self.storyboard?.instantiateViewController(withIdentifier: "AddressViewController") as? AddressViewController {
                        controller.addressType = .billing
                        self.navigationController?.pushViewController(controller, animated: true)
                    }
                }
                else {
                    self.performSegue(withIdentifier: "payment", sender: self)
                }
            }
            else {
                if self.numRows == NUM_ROWS_OK {
                    self.numRows = NUM_ROWS_ERROR
                    self.tableView.insertRows(at: [IndexPath.init(row: Row.error.rawValue, section: 0)], with: .automatic)
                }
            }
        }
        return nil; // Disable cell selection
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == Row.billingSame.rawValue && (self.addressType == .billing || !State.sharedInstance.billingAddressRequired) {
            return 0
        }
        else {
            return self.tableView.rowHeight
        }
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return numRows
        }
        else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell;
        
        if indexPath.section == 0 {
            if let row = Row(rawValue: indexPath.row) {
                switch row {
                case Row.name:
                    cell = tableView.dequeueReusableCell(withIdentifier: "nameCell", for: indexPath)
                    if let borderedCell = self.setupBorderedCell(cell, key: "name", tag: 0) {
                        borderedCell.drawTop(true) // needed for any row where a bordered row is not directly on top
                        borderedCell.textField()?.text = address?.name
                    }
                case Row.street:
                    cell = tableView.dequeueReusableCell(withIdentifier: "streetCell", for: indexPath)
                    if let borderedCell = self.setupBorderedCell(cell, key: "street", tag: 1) {
                        borderedCell.textField()?.text = address?.street
                    }
                    
                case Row.postalcodeCity:
                    cell = tableView.dequeueReusableCell(withIdentifier: "zipCityCell", for: indexPath)
                    if let dualBorderedCell = self.setupDualBorderedCell(cell, leftKey: "postalCode", leftTag: 2, rightKey: "city", rightTag: 3) {
                        dualBorderedCell.textField(.left)?.text = address?.postalCode
                        dualBorderedCell.textField(.right)?.text = address?.city
                    }
                    
                case Row.provinceCountry:
                    cell = tableView.dequeueReusableCell(withIdentifier: "provinceCountryCell", for: indexPath)
                    if let dualBorderedCell = self.setupDualBorderedCell(cell, leftKey: "province", leftTag: 4, rightKey: "country", rightTag: 5) {
                        dualBorderedCell.textField(.left)?.text = address?.province
                        dualBorderedCell.textField(.right)?.text = address?.country
                    }
                    
                case Row.billingSame:
                    cell = tableView.dequeueReusableCell(withIdentifier: "billingIsSameCell", for: indexPath)
                    if let billingIsSameCell = cell as? BillingIsSameViewCell {
                        billingIsSameCell.useShippingSwitch.addTarget(self, action: #selector(billingIsSameValueChanged(_:)), for: .valueChanged)
                        billingIsSameCell.useShippingSwitch.isOn = self.billingAddressIsSame
                    }

                case Row.error:
                    cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "error")
                    cell.backgroundColor = UIColor.red.withAlphaComponent(0.1)
                    cell.selectionStyle = .none
                    cell.textLabel?.text = NSLocalizedString("Please fill all fields.", comment: "Validation statement used when all fields are not entered on Address view.")
                    cell.textLabel?.textColor = "#b71c1c".hexColor
                    cell.imageView?.tintColor = "#b71c1c".hexColor
                    
                    var image = UIImage.init(named: "ic_error_outline_black_48dp")
                    let imageRect = CGRect(x: 0, y: 0, width: 24, height: 24)
                    
                    UIGraphicsBeginImageContextWithOptions(imageRect.size, false, UIScreen.main.scale)
                    image?.draw(in: imageRect)
                    image = UIGraphicsGetImageFromCurrentImageContext()
                    cell.imageView?.image = image?.withRenderingMode(.alwaysTemplate)
                    UIGraphicsEndImageContext()
                }
            }
            else {
                cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "fubar")
                cell.textLabel?.text = "fubar"
            }
        }
        else {
            cell = tableView.dequeueReusableCell(withIdentifier: "nextStepCell", for: indexPath)
            if let nextStepCell = cell as? NextStepCell {
                var title = ""
                if addressType == .shipping && !self.billingAddressIsSame {
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
    
    @objc func billingIsSameValueChanged(_ sender: UISwitch) {
        self.view.endEditing(true)
        self.billingAddressIsSame = sender.isOn
        let nextStepIndexPath = IndexPath(row: 0, section: 1)
        self.tableView.reloadRows(at: [nextStepIndexPath], with: .automatic)
    }
    
    // MARK: - Private methods
    
    fileprivate func setupBorderedCell(_ cell: UITableViewCell, key: String, tag: Int) -> BorderedViewCell? {
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

    fileprivate func setupDualBorderedCell(_ cell: UITableViewCell, leftKey: String, leftTag: Int, rightKey: String, rightTag: Int) -> DualBorderedViewCell? {
        if let dualBorderedCell = cell as? DualBorderedViewCell {
            if let textField = dualBorderedCell.textField(.left) {
                textField.delegate = self
                if let borderedView = textField.superview as? BorderedView {
                    viewFields[borderedView] = textField
                }
                self.keyedFields[leftKey] = textField
                textField.tag = leftTag
            }
            if let textField = dualBorderedCell.textField(.right) {
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

    fileprivate func validateTextFields() -> Bool {
        var valid = true
        
        for (borderedView, textField) in viewFields {
            if textField.text == nil ||
                textField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == ""
            {
                valid = false
                borderedView.innerBorderColor = UIColor.red.withAlphaComponent(0.5)
            }
            else {
                borderedView.innerBorderColor = UIColor.clear
            }
        }
        
        if valid && self.numRows == NUM_ROWS_ERROR {
            self.numRows = NUM_ROWS_OK
            self.tableView.deleteRows(at: [IndexPath.init(row: Row.error.rawValue, section: 0)], with: .automatic)
        }

        return valid
    }
    
    fileprivate func updateAddressInfo() {
        if self.addressType == .shipping {
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
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if let borderedView = textField.superview as? BorderedView {
            //var highlightColor = borderedView.innerBorder?.borderColor
            borderedView.innerBorderColor = UIColor.black
            borderedView.setNeedsDisplay()
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let borderedView = textField.superview as? BorderedView {
            borderedView.innerBorderColor = UIColor.clear
            borderedView.setNeedsDisplay()
        }
        
        // Re-check validation only when an error condidion pre-exists
        if self.tableView.numberOfRows(inSection: 0) == NUM_ROWS_ERROR {
            _ = self.validateTextFields()
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        var tag = textField.tag
        if let lastField = self.keyedFields["country"], tag < lastField.tag {
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
