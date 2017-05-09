//
//  State.swift
//  Checkout
//
//  Created by Sven Resch on 2016-06-15.
//  Copyright © 2017 Bambora Inc. All rights reserved.
//

import Foundation

class State {
    
    static let sharedInstance = State()
    
    var amountStr: String?
    var processingClosure: ((_ result: Dictionary<String, AnyObject>?, _ error: NSError?) -> Void)?

    var shippingAddressRequired: Bool = true
    var shippingAddress: Address?

    var billingAddressRequired: Bool = true
    var billingAddress: Address?

    fileprivate init() {
        // Private initialization to ensure just one instance is created.
    }

    // Resets state to ensure starting state of all vars
    func reset() {
        amountStr = nil
        processingClosure = nil
        
        shippingAddressRequired = true
        shippingAddress = nil
        
        billingAddressRequired = true
        billingAddress = nil
    }
}
