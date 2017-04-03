//
//  PaymentViewController.swift
//  PayForm
//
//  Created by Sven Resch on 2016-06-02.
//  Copyright © 2017 Bambora Inc. All rights reserved.
//

import UIKit

class PaymentViewController: UITableViewController {

    fileprivate enum Row: Int {
        case name = 0
        case card
        case expiryCvv
        case spacer
        case info
        case error
    }

    // MARK: - Properties
    
    fileprivate var billingAddressIsSame: Bool = false
    fileprivate var viewFields = [BorderedView: UITextField]()
    fileprivate var showingCvvInfo = false
    fileprivate var showingError = false
    fileprivate var doTableUpdatesWhenValidating = true
    
    fileprivate var emailTextField: UITextField?
    fileprivate var nameTextField: UITextField?
    fileprivate var cardTextField: UITextField?
    fileprivate var expiryTextField: UITextField?
    fileprivate var cvvTextField: UITextField?
    fileprivate var expiryPicker: UIPickerView?
    
    fileprivate var textFields = [UITextField]()
    
    // Used for CC number formatting
    fileprivate var previousTextFieldContent: String?
    fileprivate var previousSelection: UITextRange?

    fileprivate var errorMessages: [String]?
    fileprivate let messageIconWidth: CGFloat = 24.0
    fileprivate let ccValidator = CreditCardValidator()
    fileprivate let emailValidator = EmailValidator()
    
    // MARK: - UIViewController
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if UIDevice.current.userInterfaceIdiom != .pad {
            let orient = UIApplication.shared.statusBarOrientation
            self.navigationController?.setNavigationBarHidden((orient == .landscapeLeft || orient == .landscapeRight) ? true : false, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if UIDevice.current.userInterfaceIdiom != .pad {
            let orient = UIApplication.shared.statusBarOrientation
            self.navigationController?.setNavigationBarHidden((orient == .landscapeLeft || orient == .landscapeRight) ? true : false, animated: true)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if UIDevice.current.userInterfaceIdiom != .pad {
            coordinator.animate(alongsideTransition: { (context) in
                let orient = UIApplication.shared.statusBarOrientation
                self.navigationController?.setNavigationBarHidden((orient == .landscapeLeft || orient == .landscapeRight) ? true : false, animated: true)
            }, completion: nil)
        }
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? ProcessingViewController {
            controller.name = nameTextField?.text
            controller.email = emailTextField?.text
            controller.number = cardTextField?.text
            controller.cvd = cvvTextField?.text

            let monthYear = self.getSelectedMonthYear()
            controller.expiryMonth = String(format: "%02d", monthYear.month)  // "06" == June
            
            var yearStr = String(monthYear.year)
            yearStr = yearStr.substring(from: yearStr.characters.index(yearStr.startIndex, offsetBy: 2))
            controller.expiryYear = yearStr  // "16" == current year == 2016
        }
    }

    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 2 {
            // Next Step (Pay) button
            doTableUpdatesWhenValidating = false
            self.view.endEditing(true)
            doTableUpdatesWhenValidating = true
            
            // endEditing will have indirectly causes validateTextFields to be called with updateTable:true.
            if self.validateTextFields() {
                self.performSegue(withIdentifier: "processing", sender: self)
            }
        }
        return nil; // Disable cell selection
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var h = tableView.rowHeight
        if indexPath.section == 1 {
            if indexPath.row == Row.spacer.rawValue {
                h = 10
            }
            else if indexPath.row == Row.info.rawValue || indexPath.row == Row.error.rawValue {
                let cell = self.tableView(self.tableView, cellForRowAt: indexPath)
                if let textLabel = cell.textLabel {
                    // The imageView doesn't have a size and label doesn't have a frame..
                    // seems that 64 works for the imageView width along with 10 pixels 
                    // at the end for padding.
                    let w = cell.bounds.size.width - (64 + 10)
                    let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: w, height: CGFloat.greatestFiniteMagnitude))
                    label.numberOfLines = 0
                    label.lineBreakMode = NSLineBreakMode.byWordWrapping
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
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell;
        
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: "emailCell", for: indexPath)
            if let borderedCell = self.setupBorderedCell(cell) {
                borderedCell.drawTop(true) // needed for any row where a bordered row is not directly on top
                if let textField = borderedCell.textField() {
                    self.emailTextField = textField
                    textField.tag = 0
                    textFields.append(textField)
                }
            }
        }
        else if indexPath.section == 1 {
            if let row = Row(rawValue: indexPath.row) {
                switch row {
                case Row.name:
                    cell = tableView.dequeueReusableCell(withIdentifier: "nameCell", for: indexPath)
                    if let borderedCell = self.setupBorderedCell(cell) {
                        borderedCell.drawTop(true)
                        if let textField = borderedCell.textField() {
                            self.nameTextField = textField
                            textField.tag = 1
                            textFields.append(textField)
                        }
                    }
                    
                case Row.card:
                    cell = tableView.dequeueReusableCell(withIdentifier: "cardCell", for: indexPath)
                    if let borderedCell = self.setupBorderedCell(cell) {
                        if let textField = borderedCell.textField() {
                            self.cardTextField = textField
                            textField.addTarget(self, action: #selector(reformatAsCardNumber(_:)), for: .editingChanged)
                            textField.tag = 2
                            textFields.append(textField)
                            self.checkAndSetupAccessoryViews()
                        }
                    }
                    
                case Row.expiryCvv:
                    cell = tableView.dequeueReusableCell(withIdentifier: "expiryCvvCell", for: indexPath)
                    if let dualBorderedCell = self.setupDualBorderedCell(cell) {
                        if let textField = dualBorderedCell.textField(.left) {
                            self.expiryTextField = textField
                            
                            if self.expiryPicker == nil {
                                let picker = UIPickerView()
                                picker.autoresizingMask = .flexibleHeight;
                                picker.delegate = self
                                picker.dataSource = self
                                
                                self.expiryPicker = picker
                                textField.inputView = picker
                                textField.tag = 3
                                textFields.append(textField)
                                self.checkAndSetupAccessoryViews()
                            }
                        }
                        if let textField = dualBorderedCell.textField(.right) {
                            self.cvvTextField = textField
                            textField.tag = 4
                            textFields.append(textField)
                            self.checkAndSetupAccessoryViews()
                        }
                    }
                    
                case Row.spacer:
                    cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "spacer")
                    cell.selectionStyle = .none
                    
                case Row.info:
                    if showingCvvInfo {
                        cell = self.dequeueCvvInfoCell()
                    }
                    else {
                        cell = self.dequeueErrorCell()
                    }
                    
                case Row.error:
                    cell = self.dequeueErrorCell()
                }
            }
            else {
                print(">>> Should not have happend. Have a wierd row!!! \(indexPath.row)")
                cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "fubar")
                cell.textLabel?.text = "Ooops!"
            }
        }
        else {
            cell = tableView.dequeueReusableCell(withIdentifier: "payCell", for: indexPath)
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
    
    fileprivate func dequeueCvvInfoCell() -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "CvvInfoCell")
        cell.selectionStyle = .none
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = emailTextField?.font
        cell.imageView?.image = UIImage.init(named: "cvc_hint_color")
        
        if let cardnumber = cardTextField?.text {
            if ccValidator.cardType(cardnumber) == .amex {
                cell.textLabel?.text = NSLocalizedString("The last 4 digits on the back of your card.", comment: "Info label for the 4 digit CVV field on the Payment view.")
            }
            else {
                cell.textLabel?.text = NSLocalizedString("The last 3 digits on the back of your card.", comment: "Info label for the 3 digit CVV field on the Payment view.")
            }
        }
        
        return cell
    }

    fileprivate func dequeueErrorCell() -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "error")
        cell.backgroundColor = UIColor.red.withAlphaComponent(0.1)
        cell.selectionStyle = .none
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = emailTextField?.font
        cell.textLabel?.textColor = "#b71c1c".hexColor // deep red color
        cell.imageView?.tintColor = "#b71c1c".hexColor

        if let errorMessages = self.errorMessages, errorMessages.count > 0 {
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
        let imageRect = CGRect(x: 0, y: 0, width: messageIconWidth, height: messageIconWidth)
        
        UIGraphicsBeginImageContextWithOptions(imageRect.size, false, UIScreen.main.scale)
        image?.draw(in: imageRect)
        image = UIGraphicsGetImageFromCurrentImageContext()
        cell.imageView?.image = image?.withRenderingMode(.alwaysTemplate)
        UIGraphicsEndImageContext()
        
        return cell
    }

    fileprivate func setupBorderedCell(_ cell: UITableViewCell) -> BorderedViewCell? {
        if let borderedCell = cell as? BorderedViewCell {
            if let textField = borderedCell.textField() {
                textField.delegate = self
                if let borderedView = textField.superview as? BorderedView {
                    viewFields[borderedView] = textField
                }
            }
            if let imageView = borderedCell.embeddedImageView() {
                imageView.tintColor = UIColor.lightGray
            }
            return borderedCell
        }
        
        return nil
    }
    
    fileprivate func setupDualBorderedCell(_ cell: UITableViewCell) -> DualBorderedViewCell? {
        if let dualBorderedCell = cell as? DualBorderedViewCell {
            if let textField = dualBorderedCell.textField(.left) {
                textField.delegate = self
                if let borderedView = textField.superview as? BorderedView {
                    viewFields[borderedView] = textField
                }
            }
            
            if let imageView = dualBorderedCell.embeddedImageView(.left) {
                imageView.tintColor = UIColor.lightGray
            }
            
            if let textField = dualBorderedCell.textField(.right) {
                textField.delegate = self
                if let borderedView = textField.superview as? BorderedView {
                    viewFields[borderedView] = textField
                }
            }
            
            if let imageView = dualBorderedCell.embeddedImageView(.right) {
                imageView.tintColor = UIColor.lightGray
            }
            
            return dualBorderedCell
        }
        
        return nil
    }
    
    fileprivate func validateTextFields() -> Bool {
        var errorMessages = [String]()
        
        for (borderedView, textField) in viewFields {
            if textField.text == nil ||
                textField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == ""
            {
                if errorMessages.count == 0 {
                    let msg = NSLocalizedString("Please fill all fields.", comment: "Validation statement used when all fields are not entered on Payment view.")
                    errorMessages.append(msg)
                }
                
                borderedView.innerBorderColor = UIColor.red.withAlphaComponent(0.5)
            }
            else {
                borderedView.innerBorderColor = UIColor.clear
            }
        }

        if let text = emailTextField?.text, text != "" {
            if emailValidator.validate(text) == false {
                // Setup a message and make sure its always presented as the first message
                let msg = NSLocalizedString("Please enter a valid email address.", comment: "Validation statement used when email entered is invalid.")
                errorMessages.insert(msg, at: 0)
                
                if let borderedView = emailTextField?.superview as? BorderedView {
                    borderedView.innerBorderColor = UIColor.red.withAlphaComponent(0.5)
                }
            }
        }
        
        var cardType = CardType.invalidCard
        
        if let cardNumber = cardTextField?.text, cardNumber != "" {
            cardType = ccValidator.cardType(cardNumber)
            
            let cleanCard = cardNumber.replacingOccurrences(of: " ", with: "")
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
                    borderedView.innerBorderColor = UIColor.red.withAlphaComponent(0.5)
                }
            }
        }
        
        if let expiryDateText = expiryTextField?.text, expiryDateText != "" {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/yy"
            
            if let date = dateFormatter.date(from: expiryDateText) {
                let year = (Calendar.current as NSCalendar).component(.year, from: date)
                let currentYear = (Calendar.current as NSCalendar).component(.year, from: Date.init())
                let month = (Calendar.current as NSCalendar).component(.month, from: date)
                let currentMonth = (Calendar.current as NSCalendar).component(.month, from: Date.init())
                
                if year < currentYear || (year == currentYear && month < currentMonth) {
                    let msg = NSLocalizedString("Expiry Month/Year must be greater than, or equal to, current date.", comment: "Validation statement used when Expiry Month/Year is less than current date.")
                    errorMessages.append(msg)
                    
                    if let borderedView = expiryTextField?.superview as? BorderedView {
                        borderedView.innerBorderColor = UIColor.red.withAlphaComponent(0.5)
                    }
                }
            }
        }
        
        if let cvvNumber = cvvTextField?.text, cvvNumber != "" {
            let minCvvLength = ccValidator.lengthOfCvvForType(cardType)
            
            if cvvNumber.characters.count < minCvvLength {
                let msg = NSLocalizedString("Please enter a valid CVV number. The number entered is too short.", comment: "Validation statement used when CVV entered is too short.")
                errorMessages.append(msg)
                
                if let borderedView = cvvTextField?.superview as? BorderedView {
                    borderedView.innerBorderColor = UIColor.red.withAlphaComponent(0.5)
                }
            }
        }
        
        var valid = true
        if errorMessages.count > 0 { valid = false }

        if self.doTableUpdatesWhenValidating {
            var numRows = self.tableView.numberOfRows(inSection: 1)
            self.errorMessages = errorMessages
            
            if showingError {
                var indexPaths = [IndexPath]()
               
                if valid {
                    // Remove the error row
                    showingError = false
                    if !showingCvvInfo {
                        // Also remove the spacer
                        indexPaths.append(IndexPath.init(row: numRows-2, section: 1))
                    }
                    
                    indexPaths.append(IndexPath.init(row: numRows-1, section: 1))
                    self.tableView.deleteRows(at: indexPaths, with: .automatic)
                }
                else {
                    self.tableView.reloadRows(at: [IndexPath.init(row: numRows-1, section: 1)], with: .automatic)
                }
            }
            else if !valid {
                // Add an error row
                var indexPaths = [IndexPath]()
                showingError = true
                
                if showingCvvInfo == false {
                    // Also add a spacer
                    indexPaths.append(IndexPath.init(row: numRows, section: 1))
                    numRows += 1
                }
                
                indexPaths.append(IndexPath.init(row: numRows, section: 1))
                self.tableView.insertRows(at: indexPaths, with: .automatic)
            }
        }
        
        return valid
    }
    
    fileprivate func checkAndSetupAccessoryViews() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return
        }
        
        if let cardTextField = cardTextField, let expiryTextField = expiryTextField, let cvvTextField =  cvvTextField, cvvTextField.inputAccessoryView == nil {
            self.addInputAccessoryFor(cardTextField, nextField: expiryTextField)
            self.addInputAccessoryFor(expiryTextField, nextField: cvvTextField)
            self.addInputAccessoryFor(cvvTextField, dismissable: true, nextField: nil)
        }
    }
    
    fileprivate func addInputAccessoryFor(_ textField: UITextField, dismissable: Bool = false, nextField: UITextField?) {
        let toolbar: UIToolbar = UIToolbar()
        toolbar.sizeToFit()
        
        var items = [UIBarButtonItem]()
        if let nextField = nextField {
            let nextTitle = NSLocalizedString("Next", comment: "Title to use for Next button on text field accessory views.")
            let nextButton = UIBarButtonItem(title: nextTitle, style: .plain, target: nil, action: nil)
            nextButton.width = 30
            nextButton.target = nextField
            nextButton.action = #selector(UITextField.becomeFirstResponder)
            
            items.append(nextButton)
        }
        
        if dismissable {
            let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: view, action: #selector(UIView.endEditing))
            items.append(contentsOf: [spacer, doneButton])
        }
        
        toolbar.setItems(items, animated: false)
        textField.inputAccessoryView = toolbar
    }
    
}

extension PaymentViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if let borderedView = textField.superview as? BorderedView {
            borderedView.innerBorderColor = UIColor.black
            borderedView.setNeedsDisplay()

            if let imageView = borderedView.subviews.last as? UIImageView {
                imageView.isHighlighted = true
            }
        }

        if textField == cvvTextField && !showingCvvInfo {
            showingCvvInfo = true
            
            var row = Row.spacer.rawValue
            var indexPaths = [IndexPath]()
            
            if !showingError {
                // Also add the spacer
                indexPaths.append(IndexPath.init(row: row, section: 1))
            }

            row += 1
            indexPaths.append(IndexPath.init(row: row, section: 1))
            self.tableView.insertRows(at: indexPaths, with: .automatic)
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let borderedView = textField.superview as? BorderedView {
            borderedView.innerBorderColor = UIColor.clear
            borderedView.setNeedsDisplay()
            
            if let imageView = borderedView.subviews.last as? UIImageView {
                imageView.isHighlighted = false
            }
        }
        
        // Re-check validation only when an error condidion pre-exists
        if showingError || showingCvvInfo {
            _ = self.validateTextFields()
        }
        
        if textField == cvvTextField && showingCvvInfo {
            showingCvvInfo = false
            
            var row = Row.spacer.rawValue
            var indexPaths = [IndexPath]()
            
            if !showingError {
                // Also remove the spacer
                indexPaths.append(IndexPath.init(row: row, section: 1))
            }
            
            row += 1
            indexPaths.append(IndexPath.init(row: row, section: 1))
            self.tableView.deleteRows(at: indexPaths, with: .automatic)
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == cvvTextField {
            guard let text = textField.text else { return true }
            
            // Ensure a number is typed even with an external non-numeric keyboard
            if string != "" && Int(string) == nil {
                return false
            }
            
            var minLength = 3;
            if let cardnumber = cardTextField?.text, ccValidator.cardType(cardnumber) == .amex {
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        var tag = textField.tag
        if let lastField = self.cvvTextField, tag < lastField.tag {
            tag += 1
            for nextField in self.textFields {
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
    
    //
    // Found on http://stackoverflow.com/questions/12083605/formatting-a-uitextfield-for-credit-card-input-like-xxxx-xxxx-xxxx-xxxx
    // --> Enhanced to follow a cardFormat string rather than just space every 4 digits.
    //
    func reformatAsCardNumber(_ textField: UITextField) {
        // In order to make the cursor end up positioned correctly, we need to
        // explicitly reposition it after we inject spaces into the text.
        // targetCursorPosition keeps track of where the cursor needs to end up as
        // we modify the string, and at the end we set the cursor position to it.
        var targetCursorPosition = 0
        if let startPosition = textField.selectedTextRange?.start {
            targetCursorPosition = textField.offset(from: textField.beginningOfDocument, to: startPosition)
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
    
        let cardType = self.ccValidator.cardType(cardNumberWithoutSpaces)
        let cardFormat = self.cardFormat(cardType)
        let cardNumberWithSpaces = self.insertSpacesIntoCCString(cardNumberWithoutSpaces, cardFormat: cardFormat, andPreserveCursorPosition: &targetCursorPosition)
        textField.text = cardNumberWithSpaces
        
        if let targetPosition = textField.position(from: textField.beginningOfDocument, offset: targetCursorPosition) {
            textField.selectedTextRange = textField.textRange(from: targetPosition, to: targetPosition)
        }
        
        self.updateCardImage(cardType)
    }
    
    /*
     Removes non-digits from the string, decrementing `cursorPosition` as
     appropriate so that, for instance, if we pass in `@"1111 1123 1111"`
     and a cursor position of `8`, the cursor position will be changed to
     `7` (keeping it between the '2' and the '3' after the spaces are removed).
     */
    fileprivate func removeNonDigits(_ string: String, andPreserveCursorPosition cursorPosition: inout Int) -> String {
        var digitsOnlyString = ""
        let originalCursorPosition = cursorPosition
        
        for i in stride(from: 0, to: string.characters.count, by: 1) {
            let characterToAdd = string[string.characters.index(string.startIndex, offsetBy: i)]
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
    fileprivate func insertSpacesIntoCCString(_ string: String, cardFormat: String, andPreserveCursorPosition cursorPosition: inout Int) -> String {
        var stringWithAddedSpaces = ""
        var formatIndex = cardFormat.startIndex
        let cursorPositionInSpacelessString = cursorPosition
        
        for i in stride(from: 0, to: string.characters.count, by: 1) {
            if formatIndex != cardFormat.endIndex && cardFormat.characters[formatIndex] == " " {
                stringWithAddedSpaces.append(" ")
                if i < cursorPositionInSpacelessString {
                    cursorPosition += 1
                }
                formatIndex = cardFormat.index(formatIndex, offsetBy: 1)
            }
            
            if formatIndex != cardFormat.endIndex {
                formatIndex = cardFormat.index(formatIndex, offsetBy: 1)
            }
            
            let characterToAdd = string[string.characters.index(string.startIndex, offsetBy: i)]
            stringWithAddedSpaces.append(characterToAdd)
        }
        
        return stringWithAddedSpaces
    }

    fileprivate func updateCardImage(_ cardType: CardType) {
        let cell = self.tableView.cellForRow(at: IndexPath.init(row: Row.card.rawValue, section: 1))
        guard let borderedCell = cell as? BorderedViewCell else { return }
        guard let imageView = borderedCell.embeddedImageView() else { return }
        
        var imageName = "ic_credit_card_black_48dp"
        
        switch cardType {
        case .visa:
            imageName = "visa"
        case .masterCard:
            imageName = "mastercard"
        case .amex:
            imageName = "amex"
        case .discover:
            imageName = "discover"
        case .dinersClub:
            imageName = "dinersclub"
        case .jcb:
            imageName = "jcb"
        case .invalidCard:
            imageName = "ic_credit_card_black_48dp"
        }
        
        imageView.image = UIImage(named: imageName)
        if cardType == .invalidCard {
            imageView.image = imageView.image?.withRenderingMode(.alwaysTemplate)
        }
    }
    
    fileprivate func cardFormat(_ cardType: CardType) -> String {
        var format = ""
        
        switch cardType {
        case .visa, .masterCard, .discover, .jcb, .invalidCard:
            // {4-4-4-4}
            format = "XXXX XXXX XXXX XXXX "
        case .amex:
            // {4-6-5}
            format = "XXXX XXXXXX XXXXX "
        case .dinersClub:
            // {4-6-4}
            format = "XXXX XXXXXX XXXX "
        }
        
        return format
    }
    
}

extension PaymentViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return 12 // twelves months in a year
        }
        else {
            return 20 // up to 20 years from the current year
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            let df = DateFormatter.init()
            let monthName = df.monthSymbols[row]
            return monthName
        }
        else {
            let year = (Calendar.current as NSCalendar).component(.year, from: Date.init())
            return "\(year+row)"
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 1 {
            pickerView.reloadComponent(0)
        }
        
        if let textField = expiryTextField {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/yy"
            
            let monthYear = getSelectedMonthYear()
            
            if let date = dateFormatter.date(from: "\(monthYear.month)/\(monthYear.year)") {
                textField.text = dateFormatter.string(from: date)
            }
        }
    }
    
    func getSelectedMonthYear() -> (month: Int, year: Int) {
        var monthYear: (month: Int, year: Int) = (0, 0)
        
        if let pickerView = self.expiryPicker {
            let month = pickerView.selectedRow(inComponent: 0) + 1
            let year = (Calendar.current as NSCalendar).component(.year, from: Date.init()) + pickerView.selectedRow(inComponent: 1)
            monthYear = (month, year)
        }
        
        return monthYear
    }
    
}
