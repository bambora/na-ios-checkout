//
//  PayFormTests.swift
//  PayFormTests
//
//  Created by Sven Resch on 2016-06-01.
//  Copyright © 2017 Bambora Inc. All rights reserved.
//

import XCTest
@testable import PayForm

class PayFormTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test1Luhn() {
        let ccValidator = CreditCardValidator()
        let luhn = "1234 5678 9012 3452"
        XCTAssertTrue(ccValidator.isLuhnValid(luhn), "Luhn test validation.")
    }
    
    func test2VisaValidation() {
        let ccValidator = CreditCardValidator()
        let dict: Dictionary<String, AnyObject> = ["name": "Visa" as AnyObject, "cardType": CardType.visa.rawValue, "cardLength": 16, "cvvLength": 3, "cards" : ["4012 8888 8888 1881", "3012888888881881", "3012888888881881", "4012888888882881"]]
        self.testCardDictionary(dict, withValidator: ccValidator)
    }
    
    func test3MasterCardValidation() {
        let ccValidator = CreditCardValidator()
        let dict: Dictionary<String, AnyObject> = ["name": "MasterCard" as AnyObject, "cardType": CardType.masterCard.rawValue, "cardLength": 16, "cvvLength": 3, "cards" : ["5555 5555 5555 4444", "6555 5555 5555 4444", "5555 5555 5555 44444", "5555 5555 5555 4443"]]
        self.testCardDictionary(dict, withValidator: ccValidator)
    }
    
    func test3MasterCardNewBinsValidationPasses() {
        let ccValidator = CreditCardValidator()
        
        let ccNumbers: [String] = ["5555 5555 5555 4444", "2221 0000 0000 0009", "2720 9999 9999 9996"]
        for cardNumber in ccNumbers {
            self.testGoodCard("MasterCard", cardType: CardType.masterCard, cardLength: 16, cvvLength: 3, cardNumber: cardNumber, ccValidator: ccValidator)
        }
    }
    
    func test3MasterCardNewBinsValidationCardTypeFails() {
        let ccValidator = CreditCardValidator()
        
        let ccNumbers: [String] = ["6555 5555 5555 4444"]
        for cardNumber in ccNumbers {
            XCTAssertFalse(ccValidator.cardType(cardNumber) == .masterCard, "Bad [\(cardNumber)] number type test.")
        }
    }
    
    func test3MasterCardNewBinsValidationValidNumberFails() {
        let ccValidator = CreditCardValidator()
        
        let ccNumbers: [String] = ["5555 5555 5555 44444", "2221 0000 0000 00090"]
        for cardNumber in ccNumbers {
            XCTAssertFalse(ccValidator.isValidNumber(cardNumber), "Bad [\(cardNumber)] number validation.")
        }
    }
    
    func test3MasterCardNewBinsValidationLuhnFails() {
        let ccValidator = CreditCardValidator()
        
        let ccNumbers: [String] = ["2720 9999 9999 9999", "2221 0000 0000 0000"]
        
        for cardNumber in ccNumbers {
             XCTAssertFalse(ccValidator.isLuhnValid(cardNumber), "Bad [\(cardNumber)] number Luhn validation.")
        }
    }
    
    func test4AMEXCardValidation() {
        let ccValidator = CreditCardValidator()
        let dict: Dictionary<String, AnyObject> = ["name": "AMEX" as AnyObject, "cardType": CardType.amex.rawValue, "cardLength": 15, "cvvLength": 4, "cards" : ["378282246310005", "328282246310005", "37828224631000555", "378282246310015"]]
        self.testCardDictionary(dict, withValidator: ccValidator)
    }

    func test5DiscoverCardValidation() {
        let ccValidator = CreditCardValidator()
        let dict: Dictionary<String, AnyObject> = ["name": "Discover" as AnyObject, "cardType": CardType.discover.rawValue, "cardLength": 16, "cvvLength": 3, "cards" : ["6011000990139424", "5011000990139424", "60110009901394244", "6011000990139434"]]
        self.testCardDictionary(dict, withValidator: ccValidator)
    }

    func test6DinersClubCardValidation() {
        let ccValidator = CreditCardValidator()
        let dict: Dictionary<String, AnyObject> = ["name": "Diners Club" as AnyObject, "cardType": CardType.dinersClub.rawValue, "cardLength": 14, "cvvLength": 3, "cards" : ["38520000023237", "48520000023237", "385200000232377", "38520000023247"]]
        self.testCardDictionary(dict, withValidator: ccValidator)
    }
    
    func test7EmailValidation() {
        let emailValidator = EmailValidator()
        XCTAssertTrue(emailValidator.validate("someone@testing.com"), "Valid email")
        XCTAssertFalse(emailValidator.validate("someone"), "Invalid email - no domain 1")
        XCTAssertFalse(emailValidator.validate("someone@"), "Invalid email - no domain 2")
        XCTAssertFalse(emailValidator.validate("someone@testing"), "Invalid email - no domain 3")
        XCTAssertFalse(emailValidator.validate("someone@testing."), "Invalid email - no domain 4")
        XCTAssertFalse(emailValidator.validate("someone@testing.c"), "Invalid email - no domain 5")
        XCTAssertFalse(emailValidator.validate("testing.com"), "Invalid email - no name 1")
        XCTAssertFalse(emailValidator.validate("@testing.com"), "Invalid email - no name 2")
    }

    /*
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    */
    
    // MARK: - Private methods
    
    fileprivate func testCardDictionary(_ dict: Dictionary<String, AnyObject>, withValidator ccValidator: CreditCardValidator) {
        let cardName = dict["name"] as! String
        let cardType = CardType(rawValue: (dict["cardType"] as! Int))
        let cardLength = dict["cardLength"] as! Int
        let cvvLength = dict["cvvLength"] as! Int
        let cards = dict["cards"] as! [String]
        
        let goodCard = cards[0]
        self.testGoodCard(cardName, cardType: cardType!, cardLength: cardLength, cvvLength: cvvLength, cardNumber: goodCard, ccValidator: ccValidator)
        
        let badCard1 = cards[1]
        XCTAssertFalse(ccValidator.cardType(badCard1) == .masterCard, "Bad \(cardName) number type test.")
        
        let badCard2 = cards[2]
        XCTAssertFalse(ccValidator.isValidNumber(badCard2), "Bad \(cardName) number validation.")
        
        let badCard3 = cards[3]
        XCTAssertFalse(ccValidator.isLuhnValid(badCard3), "Bad \(cardName) number Luhn validation.")
    }
    
    fileprivate func testGoodCard(_ cardName: String, cardType: CardType, cardLength: Int, cvvLength: Int, cardNumber: String, ccValidator: CreditCardValidator) {
        
        XCTAssertTrue(ccValidator.lengthOfStringForType(cardType) == cardLength, "\(cardName) type did not have length of \(cardLength).")
        XCTAssertTrue(ccValidator.lengthOfCvvForType(cardType) == cvvLength, "\(cardName) type does not have \(cvvLength) digit security code.")
        
        XCTAssertTrue(ccValidator.validate(cardNumber), "\(cardName) [\(cardNumber)] general card validation.")
        
        let cleanNumber = cardNumber.replacingOccurrences(of: " ", with: "")
        XCTAssertTrue(ccValidator.lengthOfStringForType(cardType) == cleanNumber.characters.count, "\(cardName):\(cardNumber)  did not have required length of \(cardLength).")
        
        XCTAssertTrue(ccValidator.cardType(cardNumber) == cardType, "\(cardName) [\(cardNumber)] number type test.")
        XCTAssertTrue(ccValidator.isValidNumber(cardNumber), "\(cardName) [\(cardNumber)] number validation.")
        XCTAssertTrue(ccValidator.isLuhnValid(cardNumber), "\(cardName) [\(cardNumber)] number Luhn validation.")
    }
    
}
