//
//  EmailValidator.swift
//  Checkout
//
//  Created by Sven Resch on 2016-06-10.
//  Copyright © 2017 Bambora Inc. All rights reserved.
//

import Foundation

class EmailValidator {

    // http://stackoverflow.com/questions/25471114/how-to-validate-an-e-mail-address-in-swift
    let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
    
    func validate(_ email: String) -> Bool {
        let matches = email.range(of: regex, options: .regularExpression)
        if let _ = matches {
            return true
        }
        return false
    }
    
}
