//
//  CreditCardValidator.swift
//  PayForm
//
//  Created by Sven Resch on 2016-06-09.
//  Copyright © 2016 Beanstream Internet Commerce, Inc. All rights reserved.
//
// Inspired by work seen here:
// - https://github.com/dhoerl18/CreditCard/blob/master/CreditCard/CreditCard.m
// - http://www.regular-expressions.info/creditcard.html
// - http://www.brainjar.com/js/validation/default2.asp
//

import Foundation

public enum CardType: Int {
    case Visa = 0
    case MasterCard
    case AMEX
    case Discover
    case DinersClub
    case JCB
    case InvalidCard
}

class CreditCardValidator {

    // Regex validation expressions
    let VISA                = "^4[0-9]{15}?"                        // VISA 16
    let MC                  = "^5[1-5][0-9]{14}$"                   // MC 16
    let AMEX                = "^3[47][0-9]{13}$"					// AMEX 15
    let DISCOVER            = "^6(?:011|5[0-9]{2})[0-9]{12}$"       // Discover 16
    let DINERS_CLUB         = "^3(?:0[0-5]|[68][0-9])[0-9]{11}$"	// DinersClub 14
    let JCB                 = "^(?:2131|1800|35[0-9]{3})[0-9]{11}$" // JCB cards beginning with 2131 or 1800 have 15 digits. JCB cards beginning with 35 have 16 digits
    
    let VISA_TYPE           = "^4[0-9]{3}?"                         // VISA
    let MC_TYPE             = "^5[1-5][0-9]{2}$"					// MC
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
    func validate(cardNumber: String) -> Bool {
        let cardType = self.cardType(cardNumber)
        if cardType != .InvalidCard {
            let cleanCard = cardNumber.stringByReplacingOccurrencesOfString(" ", withString: "")
            let len = self.lengthOfStringForType(cardType)
            if len == cleanCard.characters.count {
                if self.isValidNumber(cardNumber) && self.isLuhnValid(cardNumber) {
                    return true
                }
            }
        }
        
        return false
    }
    
    func cardType(cardNumber: String) -> CardType {
        let ccnumber = cardNumber.stringByReplacingOccurrencesOfString(" ", withString: "")
        
        if ccnumber.characters.count < CC_LEN_FOR_TYPE {
            return .InvalidCard
        }
        
        var regex: String
        
        for cardType in CardType.Visa.rawValue...CardType.InvalidCard.rawValue {
            switch cardType {
            case CardType.Visa.rawValue:
                regex = VISA_TYPE
            case CardType.MasterCard.rawValue:
                regex = MC_TYPE
            case CardType.AMEX.rawValue:
                regex = AMEX_TYPE
            case CardType.Discover.rawValue:
                regex = DISCOVER_TYPE
            case CardType.DinersClub.rawValue:
                regex = DINERS_CLUB_TYPE
            case CardType.JCB.rawValue:
                regex = JCB_TYPE
            default:
                regex = "fu"
            }

            let matches = ccnumber.rangeOfString(regex, options: .RegularExpressionSearch, range: ccnumber.startIndex..<ccnumber.startIndex.advancedBy(CC_LEN_FOR_TYPE))
            if let _ = matches {
                if let type = CardType(rawValue: cardType) {
                    return type
                }
            }
        }
        
        return .InvalidCard
    }

    func isValidNumber(cardNumber: String) -> Bool {
        let ccnumber = cardNumber.stringByReplacingOccurrencesOfString(" ", withString: "")
        var regex: String
        
        for cardType in CardType.Visa.rawValue...CardType.InvalidCard.rawValue {
            switch cardType {
            case CardType.Visa.rawValue:
                regex = VISA
            case CardType.MasterCard.rawValue:
                regex = MC
            case CardType.AMEX.rawValue:
                regex = AMEX
            case CardType.Discover.rawValue:
                regex = DISCOVER
            case CardType.DinersClub.rawValue:
                regex = DINERS_CLUB
            case CardType.JCB.rawValue:
                regex = JCB
            default:
                regex = "fu"
            }
            
            let matches = ccnumber.rangeOfString(regex, options: .RegularExpressionSearch)
            if let _ = matches {
                return true
            }
        }
        
        return false
    }
    
    func isLuhnValid(cardNumber: String) -> Bool {
        var ccnumber = cardNumber.stringByReplacingOccurrencesOfString(" ", withString: "")
        ccnumber = String(ccnumber.characters.reverse())
        
        var luhn = ""
        for i in 0.stride(to: ccnumber.characters.count, by: 1) {
            let c = ccnumber[ccnumber.startIndex.advancedBy(i)]
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
        for i in 0.stride(to: luhn.characters.count, by: 1) {
            let c = luhn[luhn.startIndex.advancedBy(i)]
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
    
    func lengthOfStringForType(cardType: CardType) -> Int {
        var length: Int
        
        switch(cardType) {
        case .Visa, .MasterCard, .Discover, .JCB:
            // 4-4-4-4
            length = 16;
        case .AMEX:
            // 4-6-5
            length = 15;
            break;
        case .DinersClub:
            // 4-6-4
            length = 14;
            break;
        default:
            length = 0;
        }
        
        return length;
    }
    
    func lengthOfCvvForType(cardType: CardType) -> Int {
        return cardType == .AMEX ? 4 : 3
    }
    
}
