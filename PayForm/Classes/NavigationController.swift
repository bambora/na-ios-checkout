//
//  NavigationController.swift
//  PayForm
//
//  Created by Sven Resch on 2016-06-03.
//  Copyright © 2016 Beanstream Internet Commerce, Inc. All rights reserved.
//

import UIKit

@IBDesignable
class NavigationController: UINavigationController {
    
    // MARK: - Properties
    
    @IBInspectable var titleColor: UIColor = UIColor.blackColor() {
        didSet {
            self.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:titleColor]
        }
    }
    
    // MARK: - View Controller methods

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupNavBar()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.setupNavBar()
    }
    
    // MARK: - Private methods
    
    private func setupNavBar() {
        self.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.translucent = true
    }
    
}
