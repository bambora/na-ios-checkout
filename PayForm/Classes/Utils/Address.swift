//
//  Address.swift
//  PayForm
//
//  Created by Sven Resch on 2016-06-03.
//  Copyright © 2017 Bambora Inc. All rights reserved.
//

import Foundation

public enum AddressType {
    case shipping
    case billing
}

public struct Address {
    var name: String = ""
    var street: String = ""
    var city: String = ""
    var province: String = ""
    var postalCode: String = ""
    var country: String = ""
}
