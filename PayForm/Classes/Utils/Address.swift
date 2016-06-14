//
//  Address.swift
//  PayForm
//
//  Created by Sven Resch on 2016-06-03.
//  Copyright © 2016 Beanstream Internet Commerce, Inc. All rights reserved.
//

import Foundation

public enum AddressType {
    case Shipping
    case Billing
}

public struct Address {
    var name: String
    var street: String
    var city: String
    var province: String
    var postalCode: String
    var country: String
}
