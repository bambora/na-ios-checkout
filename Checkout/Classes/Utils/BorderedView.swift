//
//  BorderedView.swift
//  Checkout
//
//  Created by Sven Resch on 2016-06-02.
//  Copyright © 2017 Bambora Inc. All rights reserved.
//
// Wasn't able to get a more simple drawing working due to layer/view clipping. In order to 
// not see double width borders we will draw overlapping rects and adjust frames as needed
// based on the table view knowing exactly what should, or should not, be seen depending
// on actual cell placement and composition.
//

import UIKit

@IBDesignable
class BorderedView: UIView {
    
    // MARK: - Properties

    fileprivate var border: CALayer?
    fileprivate var innerBorder: CALayer?
    
    var drawLeft: Bool = true
    var drawTop: Bool = false

    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            self.border?.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        didSet {
            self.border?.borderColor = borderColor?.cgColor
        }
    }
    
    @IBInspectable var innerBorderColor: UIColor? {
        didSet {
            self.innerBorder?.borderColor = innerBorderColor?.cgColor
        }
    }
    
    // MARK: - View controller methods

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        var rect: CGRect = self.bounds
        if let border = self.border {
            let borderWidth = border.borderWidth
            let x = (drawLeft ? 0 : -borderWidth)
            let y = (drawTop ? 0 : -borderWidth)
            let w = (drawLeft ? bounds.size.width : bounds.size.width+borderWidth)
            let h = (drawTop ? bounds.size.height : bounds.size.height+borderWidth)
            rect = CGRect(x: x, y: y, width: w, height: h)
            border.frame = rect
        }
        if let innerBorder = self.innerBorder {
            innerBorder.frame = rect.insetBy(dx: 1.0, dy: 1.0)
        }
    }

    // MARK: - Private methods
    
    fileprivate func setup() {
        border = self.addBorder("outerBorder")
        innerBorder = self.addBorder("innerBorder", borderWidth: 1.0, borderColor: UIColor.clear)
        if let rect = innerBorder?.frame {
            innerBorder?.frame = rect.insetBy(dx: 1.0, dy: 1.0)
        }
    }

    fileprivate func addBorder(_ name: String, borderWidth: CGFloat = 1.0, borderColor: UIColor = UIColor.lightGray) -> CALayer {
        let border = CALayer()
        let x = (drawLeft ? 0 : -borderWidth)
        let y = (drawTop ? 0 : -borderWidth)
        let w = (drawLeft ? bounds.size.width : bounds.size.width+borderWidth)
        let h = (drawTop ? bounds.size.height : bounds.size.height+borderWidth)
        
        border.frame = CGRect(x: x, y: y, width: w, height: h)
        border.borderColor = borderColor.cgColor
        border.borderWidth = borderWidth
        border.name = name
        
        layer.insertSublayer(border, at: 0)
        layer.masksToBounds = false
        
        return border
    }
}
