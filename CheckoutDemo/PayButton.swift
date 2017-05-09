//
//  PayButton.swift
//  CheckoutDemo
//
//  Created by Sven Resch on 2016-06-03.
//  Copyright © 2017 Bambora Inc. All rights reserved.
//

import UIKit

@IBDesignable
class PayButton: UIButton {

    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }

}
