//
//  NavigationController.swift
//  Checkout
//
//  Created by Sven Resch on 2016-06-03.
//  Copyright © 2017 Bambora Inc. All rights reserved.
//

import UIKit

@IBDesignable
class NavigationController: UINavigationController {
    
    // MARK: - Properties
    
    @IBInspectable var titleColor: UIColor = UIColor.black {
        didSet {
        }
    }
    
    // MARK: - View Controller methods

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupNavBar()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.setupNavBar()
    }
    
    // MARK: - Private methods
    
    fileprivate func setupNavBar() {
        self.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true
        self.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: Settings.primaryColor]
        self.navigationBar.tintColor = Settings.primaryColor
    }
    
}
