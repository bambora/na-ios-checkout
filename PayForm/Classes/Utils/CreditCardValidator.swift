//
//  CreditCardValidator.swift
//  PayForm
//
//  Created by Sven Resch on 2016-06-09.
//  Copyright © 2017 Bambora Inc. All rights reserved.
//
// Inspired by work seen here:
// - https://github.com/dhoerl18/CreditCard/blob/master/CreditCard/CreditCard.m
// - http://www.regular-expressions.info/creditcard.html
// - http://www.brainjar.com/js/validation/default2.asp
//

import Foundation

public enum CardType: Int {
    case visa = 0
    case masterCard
    case amex
    case discover
    case dinersClub
    case jcb
    case invalidCard
}

class CreditCardValidator {

    // Regex validation expressions
    let VISA                = "^4[0-9]{15}?"                        // VISA 16
    let MC                  = "^(?:5[1-5][0-9]{2}|222[1-9]|22[3-9][0-9]|2[3-6][0-9]{2}|27[01][0-9]|2720)[0-9]{12}$"                   // MC 16
    let AMEX                = "^3[47][0-9]{13}$"					// AMEX 15
    let DISCOVER            = "^6(?:011|5[0-9]{2})[0-9]{12}$"       // Discover 16
    let DINERS_CLUB         = "^3(?:0[0-5]|[68][0-9])[0-9]{11}$"	// DinersClub 14
    let JCB                 = "^(?:2131|1800|35[0-9]{3})[0-9]{11}$" // JCB cards beginning with 2131 or 1800 have 15 digits. JCB cards beginning with 35 have 16 digits
    
    let VISA_TYPE           = "^4[0-9]{3}?"                         // VISA
    let MC_TYPE             = "^5[1-5][0-9]{2}|222[1-9]|22[3-9][0-9]|2[3-6][0-9]{2}|27[01][0-9]|2720$"					// MC
    let AMEX_TYPE           = "^3[47][0-9]{2}$"                     // AMEX
    let DISCOVER_TYPE       = "^6(?:011|5[0-9]{2})$"				// Discover
    let DINERS_CLUB_TYPE    = "^3(?:0[0-5]|[68][0-9])[0-9]$"		// DinersClub
    let JCB_TYPE            = "^(?:2131|1800|35[0-9]{2})$"          // JCB
    
    let CC_LEN_FOR_TYPE = 4

    //
    // Check to make sure we are passed a cardNumber that:
    // - Has a known card type.
    // - Has a valid number of digits.
    // - Appears to potentially look valid.
    // - Is definitely Luhn valid.
    //
    func validate(_ cardNumber: String) -> Bool {
        let cardType = self.cardType(cardNumber)
        if cardType != .invalidCard {
            let cleanCard = cardNumber.replacingOccurrences(of: " ", with: "")
            let len = self.lengthOfStringForType(cardType)
            if len == cleanCard.characters.count {
                if self.isValidNumber(cardNumber) && self.isLuhnValid(cardNumber) {
                    return true
                }
            }
        }
        
        return false
    }
    
    func cardType(_ cardNumber: String) -> CardType {
        let ccnumber = cardNumber.replacingOccurrences(of: " ", with: "")
        
        if ccnumber.characters.count < CC_LEN_FOR_TYPE {
            return .invalidCard
        }
        
        var regex: String
        
        for cardType in CardType.visa.rawValue...CardType.invalidCard.rawValue {
            switch cardType {
            case CardType.visa.rawValue:
                regex = VISA_TYPE
            case CardType.masterCard.rawValue:
                regex = MC_TYPE
            case CardType.amex.rawValue:
                regex = AMEX_TYPE
            case CardType.discover.rawValue:
                regex = DISCOVER_TYPE
            case CardType.dinersClub.rawValue:
                regex = DINERS_CLUB_TYPE
            case CardType.jcb.rawValue:
                regex = JCB_TYPE
            default:
                regex = "fu"
            }

            let matches = ccnumber.range(of: regex, options: .regularExpression, range: ccnumber.startIndex..<ccnumber.characters.index(ccnumber.startIndex, offsetBy: CC_LEN_FOR_TYPE))
            if let _ = matches {
                if let type = CardType(rawValue: cardType) {
                    return type
                }
            }
        }
        
        return .invalidCard
    }

    func isValidNumber(_ cardNumber: String) -> Bool {
        let ccnumber = cardNumber.replacingOccurrences(of: " ", with: "")
        var regex: String
        
        for cardType in CardType.visa.rawValue...CardType.invalidCard.rawValue {
            switch cardType {
            case CardType.visa.rawValue:
                regex = VISA
            case CardType.masterCard.rawValue:
                regex = MC
            case CardType.amex.rawValue:
                regex = AMEX
            case CardType.discover.rawValue:
                regex = DISCOVER
            case CardType.dinersClub.rawValue:
                regex = DINERS_CLUB
            case CardType.jcb.rawValue:
                regex = JCB
            default:
                regex = "fu"
            }
            
            let matches = ccnumber.range(of: regex, options: .regularExpression)
            if let _ = matches {
                return true
            }
        }
        
        return false
    }
    
    func isLuhnValid(_ cardNumber: String) -> Bool {
        var ccnumber = cardNumber.replacingOccurrences(of: " ", with: "")
        ccnumber = String(ccnumber.characters.reversed())
        
        var luhn = ""
        for i in stride(from: 0, to: ccnumber.characters.count, by: 1) {
            let c = ccnumber[ccnumber.characters.index(ccnumber.startIndex, offsetBy: i)]
            if i % 2 == 0 {
                luhn += String(c)
            }
            else {
                if let val = Int(String(c)) {
                    luhn += String(val * 2)
                }
            }
        }
        
        var sum = 0
        for i in stride(from: 0, to: luhn.characters.count, by: 1) {
            let c = luhn[luhn.characters.index(luhn.startIndex, offsetBy: i)]
            if let val = Int(String(c)) {
                sum += val
            }
        }
        
        if sum != 0 && sum % 10 == 0 {
            return true
        }
        else {
            return false
        }
    }
    
    func lengthOfStringForType(_ cardType: CardType) -> Int {
        var length: Int
        
        switch(cardType) {
        case .visa, .masterCard, .discover, .jcb:
            // 4-4-4-4
            length = 16;
        case .amex:
            // 4-6-5
            length = 15;
            break;
        case .dinersClub:
            // 4-6-4
            length = 14;
            break;
        default:
            length = 0;
        }
        
        return length;
    }
    
    func lengthOfCvvForType(_ cardType: CardType) -> Int {
        return cardType == .amex ? 4 : 3
    }
    
}
