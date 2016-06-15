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
        case Info
        case Error
    }

    // MARK: - Properties
    
    private var billingAddressIsSame: Bool = false
    private var viewFields = [BorderedView: UITextField]()
    private var showingCvvInfo = false
    private var showingError = false
    private var doTableUpdatesWhenValidating = true
    
    private var emailTextField: UITextField?
    private var nameTextField: UITextField?
    private var cardTextField: UITextField?
    private var expiryTextField: UITextField?
    private var cvvTextField: UITextField?
    private var expiryPicker: UIPickerView?
    
    // Used for CC number formatting
    private var previousTextFieldContent: String?
    private var previousSelection: UITextRange?

    private var errorMessages: [String]?
    private let messageIconWidth: CGFloat = 24.0
    private let ccValidator = CreditCardValidator()
    private let emailValidator = EmailValidator()
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let controller = segue.destinationViewController as? ProcessingViewController {
            controller.name = nameTextField?.text
            controller.email = emailTextField?.text
            controller.number = cardTextField?.text
            controller.cvd = cvvTextField?.text

            let monthYear = self.getSelectedMonthYear()
            controller.expiryMonth = String(format: "%02d", monthYear.month)  // "06" == June
            
            var yearStr = String(monthYear.year)
            yearStr = yearStr.substringFromIndex(yearStr.startIndex.advancedBy(2))
            controller.expiryYear = yearStr  // "16" == current year == 2016
        }
    }

    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.section == 2 {
            // Next Step (Pay) button
            doTableUpdatesWhenValidating = false
            self.view.endEditing(true)
            doTableUpdatesWhenValidating = true
            
            // endEditing will have indirectly causes validateTextFields to be called with updateTable:true.
            if self.validateTextFields() {
                self.performSegueWithIdentifier("processing", sender: self)
            }
        }
        return nil; // Disable cell selection
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        var h = tableView.rowHeight
        if indexPath.section == 1 {
            if indexPath.row == Row.Spacer.rawValue {
                h = 10
            }
            else if indexPath.row == Row.Info.rawValue || indexPath.row == Row.Error.rawValue {
                let cell = self.tableView(self.tableView, cellForRowAtIndexPath: indexPath)
                if let textLabel = cell.textLabel {
                    // The imageView doesn't have a size and label doesn't have a frame..
                    // seems that 64 works for the imageView width along with 10 pixels 
                    // at the end for padding.
                    let w = cell.bounds.size.width - (64 + 10)
                    let label:UILabel = UILabel(frame: CGRectMake(0, 0, w, CGFloat.max))
                    label.numberOfLines = 0
                    label.lineBreakMode = NSLineBreakMode.ByWordWrapping
                    label.font = textLabel.font
                    label.text = textLabel.text
                    label.sizeToFit()
                    h = label.frame.height + 20 // add a little space for top and bottom
                }
            }
        }
        return h
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
            if showingCvvInfo || showingError { numRows += 1 } // for the spacer
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
            if let row = Row(rawValue: indexPath.row) {
                switch row {
                case Row.Name:
                    cell = tableView.dequeueReusableCellWithIdentifier("nameCell", forIndexPath: indexPath)
                    if let borderedCell = self.setupBorderedCell(cell) {
                        borderedCell.drawTop(true)
                        if let textField = borderedCell.textField() {
                            self.nameTextField = textField
                        }
                    }
                    
                case Row.Card:
                    cell = tableView.dequeueReusableCellWithIdentifier("cardCell", forIndexPath: indexPath)
                    if let borderedCell = self.setupBorderedCell(cell) {
                        if let textField = borderedCell.textField() {
                            self.cardTextField = textField
                            textField.addTarget(self, action: #selector(reformatAsCardNumber(_:)), forControlEvents: .EditingChanged)
                        }
                    }
                    
                case Row.ExpiryCvv:
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
                    
                case Row.Spacer:
                    cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "spacer")
                    cell.selectionStyle = .None
                    
                case Row.Info:
                    if showingCvvInfo {
                        cell = self.dequeueCvvInfoCell()
                    }
                    else {
                        cell = self.dequeueErrorCell()
                    }
                    
                case Row.Error:
                    cell = self.dequeueErrorCell()
                }
            }
            else {
                print(">>> Should not have happend. Have a wierd row!!! \(indexPath.row)")
                cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "fubar")
                cell.textLabel?.text = "Ooops!"
            }
        }
        else {
            cell = tableView.dequeueReusableCellWithIdentifier("payCell", forIndexPath: indexPath)
            if let payCell = cell as? NextStepCell {
                var title = NSLocalizedString("PAY", comment: "Button title to used to enter Payment")
                
                if let amountStr = State.sharedInstance.amountStr {
                    title = String(format: NSLocalizedString("PAY %@", comment: "Button title to used to enter Payment"), amountStr)
                }
                
                payCell.setTitleText(title)
                payCell.drawTop(true)
                payCell.setBorderColor(Settings.primaryColor)
            }
        }
        
        return cell
    }
    
    // MARK: - Private methods
    
    private func dequeueCvvInfoCell() -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "CvvInfoCell")
        cell.selectionStyle = .None
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = emailTextField?.font
        cell.imageView?.image = UIImage.init(named: "cvc_hint_color")
        
        if let cardnumber = cardTextField?.text {
            if ccValidator.cardType(cardnumber) == .AMEX {
                cell.textLabel?.text = NSLocalizedString("The last 4 digits on the back of your card.", comment: "Info label for the 4 digit CVV field on the Payment view.")
            }
            else {
                cell.textLabel?.text = NSLocalizedString("The last 3 digits on the back of your card.", comment: "Info label for the 3 digit CVV field on the Payment view.")
            }
        }
        
        return cell
    }

    private func dequeueErrorCell() -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "error")
        cell.backgroundColor = UIColor.redColor().colorWithAlphaComponent(0.1)
        cell.selectionStyle = .None
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = emailTextField?.font
        cell.textLabel?.textColor = "#b71c1c".hexColor // deep red color
        cell.imageView?.tintColor = "#b71c1c".hexColor

        if let errorMessages = self.errorMessages where errorMessages.count > 0 {
            var text = ""
            for msg in errorMessages {
                text += msg
                if errorMessages.last != msg {
                    text += "\n"
                }
            }
            cell.textLabel?.text = text
        }
        
        var image = UIImage.init(named: "ic_error_outline_black_48dp")
        let imageRect = CGRectMake(0, 0, messageIconWidth, messageIconWidth)
        
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
        var errorMessages = [String]()
        
        for (borderedView, textField) in viewFields {
            if textField.text == nil ||
                textField.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) == ""
            {
                if errorMessages.count == 0 {
                    let msg = NSLocalizedString("Please fill all fields.", comment: "Validation statement used when all fields are not entered on Payment view.")
                    errorMessages.append(msg)
                }
                
                borderedView.innerBorderColor = UIColor.redColor().colorWithAlphaComponent(0.5)
            }
            else {
                borderedView.innerBorderColor = UIColor.clearColor()
            }
        }

        if let text = emailTextField?.text where text != "" {
            if emailValidator.validate(text) == false {
                // Setup a message and make sure its always presented as the first message
                let msg = NSLocalizedString("Please enter a valid email address.", comment: "Validation statement used when email entered is invalid.")
                errorMessages.insert(msg, atIndex: 0)
                
                if let borderedView = emailTextField?.superview as? BorderedView {
                    borderedView.innerBorderColor = UIColor.redColor().colorWithAlphaComponent(0.5)
                }
            }
        }
        
        var cardType = CardType.InvalidCard
        
        if let cardNumber = cardTextField?.text where cardNumber != "" {
            cardType = ccValidator.cardType(cardNumber)
            
            let cleanCard = cardNumber.stringByReplacingOccurrencesOfString(" ", withString: "")
            let minCardLength = ccValidator.lengthOfStringForType(cardType)
            var cardInvalid = false
            
            if cleanCard.characters.count < minCardLength {
                let msg = NSLocalizedString("Please enter a valid credit card number. The number entered is too short.", comment: "Validation statement used when credit card number entered is too short.")
                errorMessages.append(msg)
                cardInvalid = true
            }
            else if ccValidator.isValidNumber(cardNumber) == false || ccValidator.isLuhnValid(cardNumber) == false {
                let msg = NSLocalizedString("Please enter a valid credit card number.", comment: "Validation statement used when credit card number entered is invalid.")
                errorMessages.append(msg)
                cardInvalid = true
            }
            
            if cardInvalid {
                if let borderedView = cardTextField?.superview as? BorderedView {
                    borderedView.innerBorderColor = UIColor.redColor().colorWithAlphaComponent(0.5)
                }
            }
        }
        
        if let cvvNumber = cvvTextField?.text where cvvNumber != "" {
            let minCvvLength = ccValidator.lengthOfCvvForType(cardType)
            
            if cvvNumber.characters.count < minCvvLength {
                let msg = NSLocalizedString("Please enter a valid CVV number. The number entered is too short.", comment: "Validation statement used when CVV entered is too short.")
                errorMessages.append(msg)
                
                if let borderedView = cvvTextField?.superview as? BorderedView {
                    borderedView.innerBorderColor = UIColor.redColor().colorWithAlphaComponent(0.5)
                }
            }
        }
        
        var valid = true
        if errorMessages.count > 0 { valid = false }

        if self.doTableUpdatesWhenValidating {
            var numRows = self.tableView.numberOfRowsInSection(1)
            self.errorMessages = errorMessages
            
            if showingError {
                var indexPaths = [NSIndexPath]()
               
                if valid {
                    // Remove the error row
                    showingError = false
                    if !showingCvvInfo {
                        // Also remove the spacer
                        indexPaths.append(NSIndexPath.init(forRow: numRows-2, inSection: 1))
                    }
                    
                    indexPaths.append(NSIndexPath.init(forRow: numRows-1, inSection: 1))
                    self.tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
                }
                else {
                    self.tableView.reloadRowsAtIndexPaths([NSIndexPath.init(forRow: numRows-1, inSection: 1)], withRowAnimation: .Automatic)
                }
            }
            else if !valid {
                // Add an error row
                var indexPaths = [NSIndexPath]()
                showingError = true
                
                if showingCvvInfo == false {
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
    
}

extension PaymentViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if let borderedView = textField.superview as? BorderedView {
            borderedView.innerBorderColor = UIColor.blackColor()
            borderedView.setNeedsDisplay()

            if let imageView = borderedView.subviews.last as? UIImageView {
                imageView.highlighted = true
            }
        }

        if textField == cvvTextField && !showingCvvInfo {
            showingCvvInfo = true
            
            var row = Row.Spacer.rawValue
            var indexPaths = [NSIndexPath]()
            
            if !showingError {
                // Also add the spacer
                indexPaths.append(NSIndexPath.init(forRow: row, inSection: 1))
            }

            row += 1
            
            indexPaths.append(NSIndexPath.init(forRow: row, inSection: 1))
            
            self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
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
        if showingError || showingCvvInfo {
            self.validateTextFields()
        }
        
        if textField == cvvTextField && showingCvvInfo {
            showingCvvInfo = false
            
            var row = Row.Spacer.rawValue
            var indexPaths = [NSIndexPath]()
            
            if !showingError {
                // Also remove the spacer
                indexPaths.append(NSIndexPath.init(forRow: row, inSection: 1))
            }
            
            row += 1
            indexPaths.append(NSIndexPath.init(forRow: row, inSection: 1))
            
            self.tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
        }
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if textField == cvvTextField {
            guard let text = textField.text else { return true }
            
            // Ensure a number is typed even with an external non-numeric keyboard
            if string != "" && Int(string) == nil {
                return false
            }
            
            var minLength = 3;
            if let cardnumber = cardTextField?.text where ccValidator.cardType(cardnumber) == .AMEX {
                minLength = 4
            }
            
            let newLength = text.utf16.count + string.utf16.count - range.length
            return newLength <= minLength
        }
        else if textField == cardTextField {
            // Record the textField's current state before performing the change, in case
            // reformatAsCardNumber(_:) wants to revert it
            previousTextFieldContent = textField.text;
            previousSelection = textField.selectedTextRange;
        }

        return true
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
        
        self.updateCardImage()
    }
    
    /*
     Removes non-digits from the string, decrementing `cursorPosition` as
     appropriate so that, for instance, if we pass in `@"1111 1123 1111"`
     and a cursor position of `8`, the cursor position will be changed to
     `7` (keeping it between the '2' and the '3' after the spaces are removed).
     */
    private func removeNonDigits(string: String, inout andPreserveCursorPosition cursorPosition: Int) -> String {
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
    private func insertSpacesEveryFourDigitsIntoString(string: String, inout andPreserveCursorPosition cursorPosition: Int) -> String {
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

    private func updateCardImage() {
        let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath.init(forRow: Row.Card.rawValue, inSection: 1))
        if let borderedCell = cell as? BorderedViewCell {
            if let imageView = borderedCell.embeddedImageView() {
                if let cardNumber = self.cardTextField?.text {
                    let cardType = self.ccValidator.cardType(cardNumber)
                    var imageName = "ic_credit_card_black_48dp"
                    
                    switch cardType {
                    case .Visa:
                        imageName = "visa"
                    case .MasterCard:
                        imageName = "mastercard"
                    case .AMEX:
                        imageName = "amex"
                    case .Discover:
                        imageName = "discover"
                    case .DinersClub:
                        imageName = "dinersclub"
                    case .InvalidCard:
                        imageName = "ic_credit_card_black_48dp"
                    }
                    
                    imageView.image = UIImage(named: imageName)
                    if cardType == .InvalidCard {
                        imageView.image = imageView.image?.imageWithRenderingMode(.AlwaysTemplate)
                    }
                }
            }
        }
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
            
            let monthYear = getSelectedMonthYear()
            
            if let date = dateFormatter.dateFromString("\(monthYear.month)/\(monthYear.year)") {
                textField.text = dateFormatter.stringFromDate(date)
            }
        }
    }
    
    func getSelectedMonthYear() -> (month: Int, year: Int) {
        var monthYear: (month: Int, year: Int) = (0, 0)
        
        if let pickerView = self.expiryPicker {
            var monthOffset = 0
            if pickerView.selectedRowInComponent(1) == 0 {
                monthOffset = NSCalendar.currentCalendar().component(.Month, fromDate: NSDate.init()) - 1
            }
            
            let month = pickerView.selectedRowInComponent(0) + 1 + monthOffset
            var year = NSCalendar.currentCalendar().component(.Year, fromDate: NSDate.init())
            year += pickerView.selectedRowInComponent(1)
            
            monthYear = (month, year)
        }
        
        return monthYear
    }
}