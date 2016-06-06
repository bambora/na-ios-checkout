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
    case NextStep
}

public class AddressViewController: UITableViewController {
    
    // MARK: - Properties

    var addressType: AddressType = .Shipping
    var billingAddressIsSame: Bool = false
    var amountStr: String?
    
    // MARK: - View controller methods

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        if addressType == .Billing {
            self.title = NSLocalizedString("Billing Address", comment: "Address view title when used in Billing mode")
        }
        else {
            self.title = NSLocalizedString("Shipping Address", comment: "Address view title when used in Shipping mode")
        }
        
        // Get rid of extra/unused cell separator lines
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
    }
    
    // MARK: - Table view delegate
    
    override public func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.row == Row.NextStep.rawValue {
            self.view.endEditing(true)
            
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
        return 1
    }
    
    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell;
        
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
            
        case Row.NextStep.rawValue:
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
            
        default:
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "fubar")
            cell.textLabel?.text = "fubar"
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
        let nextStepIndexPath = NSIndexPath(forRow: Row.NextStep.rawValue, inSection: 0)
        self.tableView.reloadRowsAtIndexPaths([nextStepIndexPath], withRowAnimation: .Automatic)
    }
    
    // MARK: - Private methods
    
    private func setupBorderedCell(cell: UITableViewCell ) -> BorderedViewCell? {
        if let borderedCell = cell as? BorderedViewCell {
            if let textField = borderedCell.textField() {
                textField.delegate = self
            }
            return borderedCell
        }
        
        return nil
    }

    private func setupDualBorderedCell(cell: UITableViewCell ) -> DualBorderedViewCell? {
        if let dualBorderedCell = cell as? DualBorderedViewCell {
            if let textField = dualBorderedCell.textField(.Left) {
                textField.delegate = self
            }
            if let textField = dualBorderedCell.textField(.Right) {
                textField.delegate = self
            }
            return dualBorderedCell
        }
        
        return nil
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
    }
}

