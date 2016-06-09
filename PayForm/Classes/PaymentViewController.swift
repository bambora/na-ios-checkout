//
//  PaymentViewController.swift
//  PayForm
//
//  Created by Sven Resch on 2016-06-02.
//  Copyright © 2016 Beanstream Internet Commerce, Inc. All rights reserved.
//

import UIKit

class PaymentViewController: UITableViewController {

    private enum Row: Int {
        case Name = 0
        case Card
        case ExpiryCvv
        case Spacer
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Properties
    
    var amountStr: String?
    
    private var billingAddressIsSame: Bool = false
    private var viewFields = [BorderedView: UITextField]()
    private var showingCvvInfo = false
    private var showingError = false
    private var doTableUpdatesWhenValidating = true
    
    private var emailTextField: UITextField?
    private var cardTextField: UITextField?
    private var expiryTextField: UITextField?
    private var cvvTextField: UITextField?
    private var expiryPicker: UIPickerView?
    
    // Used for CC number formatting
    private var previousTextFieldContent: String?
    private var previousSelection: UITextRange?

    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.section == 2 {
            // Next Step (Pay) button
            doTableUpdatesWhenValidating = false
            self.view.endEditing(true)
            doTableUpdatesWhenValidating = true
            
            // endEditing will have indirectly causes validateTextFields to be called with updateTable:true.
            if self.validateTextFields() {
//                self.performSegueWithIdentifier("processing", sender: self)
            }
        }
        return nil; // Disable cell selection
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 1 && indexPath.row == Row.Spacer.rawValue {
            return 10
        }
        else {
            return self.tableView.rowHeight
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numRows: Int
        
        switch section {
        case 0:
            numRows = 1
        case 1:
            numRows = 3
            if showingCvvInfo || showingError { numRows += 1 }
            if showingCvvInfo { numRows += 1 }
            if showingError { numRows += 1 }
        case 2:
            numRows = 1
        default:
            numRows = 0
        }
        
        return numRows
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell;
        
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCellWithIdentifier("emailCell", forIndexPath: indexPath)
            if let borderedCell = self.setupBorderedCell(cell) {
                borderedCell.drawTop(true) // needed for any row where a bordered row is not directly on top
                if let textField = borderedCell.textField() {
                    self.emailTextField = textField
                }
            }
        }
        else if indexPath.section == 1 {
            switch indexPath.row {
            case Row.Name.rawValue:
                cell = tableView.dequeueReusableCellWithIdentifier("nameCell", forIndexPath: indexPath)
                if let borderedCell = self.setupBorderedCell(cell) {
                    borderedCell.drawTop(true)
                }
                
            case Row.Card.rawValue:
                cell = tableView.dequeueReusableCellWithIdentifier("cardCell", forIndexPath: indexPath)
                if let borderedCell = self.setupBorderedCell(cell) {
                    if let textField = borderedCell.textField() {
                        self.cardTextField = textField
                        textField.addTarget(self, action: #selector(reformatAsCardNumber(_:)), forControlEvents: .EditingChanged)
                    }
                }
                
            case Row.ExpiryCvv.rawValue:
                cell = tableView.dequeueReusableCellWithIdentifier("expiryCvvCell", forIndexPath: indexPath)
                if let dualBorderedCell = self.setupDualBorderedCell(cell) {
                    if let textField = dualBorderedCell.textField(.Left) {
                        self.expiryTextField = textField
                        
                        if self.expiryPicker == nil {
                            let picker = UIPickerView()
                            picker.delegate = self
                            picker.dataSource = self
                            
                            self.expiryPicker = picker
                            textField.inputView = picker
                        }
                    }
                    if let textField = dualBorderedCell.textField(.Right) {
                        self.cvvTextField = textField
                    }
                }
                
            case Row.Spacer.rawValue:
                cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "spacer")
                cell.selectionStyle = .None
                
            case (Row.Spacer.rawValue + 1):
                if showingCvvInfo {
                    cell = self.dequeueCvvInfoCell()
                }
                else {
                    cell = self.dequeueErrorCell()
                }
                
            case (Row.Spacer.rawValue + 2):
                cell = self.dequeueErrorCell()
                
            default:
                cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "fubar")
                cell.textLabel?.text = "fubar"
            }
        }
        else {
            cell = tableView.dequeueReusableCellWithIdentifier("payCell", forIndexPath: indexPath)
            if let payCell = cell as? NextStepCell {
                let title = NSLocalizedString("PAY >", comment: "Button title to used to enter Payment")
                payCell.setTitleText(title)
                payCell.drawTop(true)
            }
        }
        
        return cell
    }
    
    // MARK: - Private methods
    
    private func dequeueCvvInfoCell() -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "CvvInfoCell")
        cell.selectionStyle = .None
        cell.textLabel?.text = NSLocalizedString("The last 3 digits on the back of your card.", comment: "Info label for the CVV field on the Payment viuw.")
        
        return cell
    }

    private func dequeueErrorCell() -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "error")
        cell.backgroundColor = UIColor.redColor().colorWithAlphaComponent(0.1)
        cell.selectionStyle = .None
        cell.textLabel?.text = "Please fill all fields."
        cell.textLabel?.textColor = "#b71c1c".hexColor
        cell.imageView?.tintColor = "#b71c1c".hexColor
        
        var image = UIImage.init(named: "ic_error_outline_black_48dp")
        let imageRect = CGRectMake(0, 0, 24, 24)
        
        UIGraphicsBeginImageContextWithOptions(imageRect.size, false, UIScreen.mainScreen().scale)
        image?.drawInRect(imageRect)
        image = UIGraphicsGetImageFromCurrentImageContext()
        cell.imageView?.image = image?.imageWithRenderingMode(.AlwaysTemplate)
        UIGraphicsEndImageContext()
        
        return cell
    }

    private func setupBorderedCell(cell: UITableViewCell) -> BorderedViewCell? {
        if let borderedCell = cell as? BorderedViewCell {
            if let textField = borderedCell.textField() {
                textField.delegate = self
                if let borderedView = textField.superview as? BorderedView {
                    viewFields[borderedView] = textField
                }
            }
            if let imageView = borderedCell.embeddedImageView() {
                imageView.tintColor = UIColor.lightGrayColor()
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
            
            if let imageView = dualBorderedCell.embeddedImageView(.Left) {
                imageView.tintColor = UIColor.lightGrayColor()
            }
            
            if let textField = dualBorderedCell.textField(.Right) {
                textField.delegate = self
                if let borderedView = textField.superview as? BorderedView {
                    viewFields[borderedView] = textField
                }
            }
            
            if let imageView = dualBorderedCell.embeddedImageView(.Right) {
                imageView.tintColor = UIColor.lightGrayColor()
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
        
        if self.doTableUpdatesWhenValidating {
            var numRows = self.tableView.numberOfRowsInSection(1)
            
            if valid && showingError {
                // Remove the error row
                var indexPaths = [NSIndexPath]()
                showingError = false
                
                if !showingCvvInfo {
                    // Also remove the spacer
                    indexPaths.append(NSIndexPath.init(forRow: numRows-2, inSection: 1))
                }
                
                indexPaths.append(NSIndexPath.init(forRow: numRows-1, inSection: 1))
                self.tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
            }
            else if !showingError {
                // Add an error row
                var indexPaths = [NSIndexPath]()
                showingError = true
                
                if !showingCvvInfo {
                    // Also add a spacer
                    indexPaths.append(NSIndexPath.init(forRow: numRows, inSection: 1))
                    numRows += 1
                }
                
                indexPaths.append(NSIndexPath.init(forRow: numRows, inSection: 1))
                self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
            }
        }
        
        return valid
    }
    
    private func shouldShowCvvInfo() -> Bool {
        return false // TODO
    }
    
}

extension PaymentViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if let borderedView = textField.superview as? BorderedView {
            //var highlightColor = borderedView.innerBorder?.borderColor
            borderedView.innerBorderColor = UIColor.blackColor()
            borderedView.setNeedsDisplay()

            if let imageView = borderedView.subviews.last as? UIImageView {
                imageView.highlighted = true
            }
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if let borderedView = textField.superview as? BorderedView {
            borderedView.innerBorderColor = UIColor.clearColor()
            borderedView.setNeedsDisplay()
            
            if let imageView = borderedView.subviews.last as? UIImageView {
                imageView.highlighted = false
            }
        }
        
        // Re-check validation only when an error condidion pre-exists
        if showingError {
            self.validateTextFields()
        }
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if textField == cvvTextField {
            guard let text = textField.text else { return true }
            let newLength = text.utf16.count + string.utf16.count - range.length
            return newLength <= 3
        }
        else if textField == cardTextField {
            // Record the textField's current state before performing the change, in case
            // reformatTextField wants to revert it
            previousTextFieldContent = textField.text;
            previousSelection = textField.selectedTextRange;
            return true
        }
        else {
            return true
        }
    }
    
    //
    // Found on http://stackoverflow.com/questions/12083605/formatting-a-uitextfield-for-credit-card-input-like-xxxx-xxxx-xxxx-xxxx
    //
    func reformatAsCardNumber(textField: UITextField) {
        // In order to make the cursor end up positioned correctly, we need to
        // explicitly reposition it after we inject spaces into the text.
        // targetCursorPosition keeps track of where the cursor needs to end up as
        // we modify the string, and at the end we set the cursor position to it.
        var targetCursorPosition = 0
        if let startPosition = textField.selectedTextRange?.start {
            targetCursorPosition = textField.offsetFromPosition(textField.beginningOfDocument, toPosition: startPosition)
        }
    
        var cardNumberWithoutSpaces = ""
        if let text = textField.text {
            cardNumberWithoutSpaces = self.removeNonDigits(text, andPreserveCursorPosition: &targetCursorPosition)
        }
    
        if cardNumberWithoutSpaces.characters.count > 19 {
            // If the user is trying to enter more than 19 digits, we prevent
            // their change, leaving the text field in  its previous state.
            // While 16 digits is usual, credit card numbers have a hard
            // maximum of 19 digits defined by ISO standard 7812-1 in section
            // 3.8 and elsewhere. Applying this hard maximum here rather than
            // a maximum of 16 ensures that users with unusual card numbers
            // will still be able to enter their card number even if the
            // resultant formatting is odd.
            textField.text = previousTextFieldContent
            textField.selectedTextRange = previousSelection
            return
        }
    
        let cardNumberWithSpaces = self.insertSpacesEveryFourDigitsIntoString(cardNumberWithoutSpaces, andPreserveCursorPosition: &targetCursorPosition)
        textField.text = cardNumberWithSpaces
        
        if let targetPosition = textField.positionFromPosition(textField.beginningOfDocument, offset: targetCursorPosition) {
            textField.selectedTextRange = textField.textRangeFromPosition(targetPosition, toPosition: targetPosition)
        }
    }
    
    /*
     Removes non-digits from the string, decrementing `cursorPosition` as
     appropriate so that, for instance, if we pass in `@"1111 1123 1111"`
     and a cursor position of `8`, the cursor position will be changed to
     `7` (keeping it between the '2' and the '3' after the spaces are removed).
     */
    func removeNonDigits(string: String, inout andPreserveCursorPosition cursorPosition: Int) -> String {
        var digitsOnlyString = ""
        let originalCursorPosition = cursorPosition
        
        for i in 0.stride(to: string.characters.count, by: 1) {
            let characterToAdd = string[string.startIndex.advancedBy(i)]
            if characterToAdd >= "0" && characterToAdd <= "9" {
                digitsOnlyString.append(characterToAdd)
            }
            else if i < originalCursorPosition {
                cursorPosition -= 1
            }
        }
        
        return digitsOnlyString
    }
    
    /*
     Inserts spaces into the string to format it as a credit card number,
     incrementing `cursorPosition` as appropriate so that, for instance, if we
     pass in `@"111111231111"` and a cursor position of `7`, the cursor position
     will be changed to `8` (keeping it between the '2' and the '3' after the
     spaces are added).
     */
    func insertSpacesEveryFourDigitsIntoString(string: String, inout andPreserveCursorPosition cursorPosition: Int) -> String {
        var stringWithAddedSpaces = ""
        let cursorPositionInSpacelessString = cursorPosition
        
        for i in 0.stride(to: string.characters.count, by: 1) {
            if i > 0 && (i % 4) == 0 {
                stringWithAddedSpaces.appendContentsOf(" ")
                if i < cursorPositionInSpacelessString {
                    cursorPosition += 1
                }
            }
            let characterToAdd = string[string.startIndex.advancedBy(i)]
            stringWithAddedSpaces.append(characterToAdd)
        }
        
        return stringWithAddedSpaces
    }

}

extension PaymentViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            var num = 12 // twelves months in a year
            if pickerView.numberOfComponents == 2 && pickerView.selectedRowInComponent(1) == 0 {
                // only show months available from current day onwards
                let month = NSCalendar.currentCalendar().component(.Month, fromDate: NSDate.init()) - 1
                num -= month
            }
            return num
        }
        else {
            return 20 // up to 20 years from the current year
        }
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            // Month
            var monthOffset = 0
            if pickerView.selectedRowInComponent(1) == 0 {
                monthOffset = NSCalendar.currentCalendar().component(.Month, fromDate: NSDate.init()) - 1
            }

            let df = NSDateFormatter.init()
            let monthName = df.monthSymbols[row + monthOffset]
            return monthName
        }
        else {
            // Year
            let year = NSCalendar.currentCalendar().component(.Year, fromDate: NSDate.init())
            return "\(year+row)"
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 1 {
            pickerView.reloadComponent(0)
        }
        
        if let textField = expiryTextField {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "MM/yy"
            
            var monthOffset = 0
            if pickerView.selectedRowInComponent(1) == 0 {
                monthOffset = NSCalendar.currentCalendar().component(.Month, fromDate: NSDate.init()) - 1
            }
            
            let month = pickerView.selectedRowInComponent(0) + 1 + monthOffset
            var year = NSCalendar.currentCalendar().component(.Year, fromDate: NSDate.init())
            year += pickerView.selectedRowInComponent(1)
            
            if let date = dateFormatter.dateFromString("\(month)/\(year)") {
                textField.text = dateFormatter.stringFromDate(date)
            }
        }
    }
}