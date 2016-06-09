//
//  BorderedView.swift
//  PayForm
//
//  Created by Sven Resch on 2016-06-02.
//  Copyright © 2016 Beanstream Internet Commerce, Inc. All rights reserved.
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

    private var border: CALayer?
    private var innerBorder: CALayer?
    
    var drawLeft: Bool = true
    var drawTop: Bool = false

    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            self.border?.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        didSet {
            self.border?.borderColor = borderColor?.CGColor
        }
    }
    
    @IBInspectable var innerBorderColor: UIColor? {
        didSet {
            self.innerBorder?.borderColor = innerBorderColor?.CGColor
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
            rect = CGRectMake(x, y, w, h)
            border.frame = rect
        }
        if let innerBorder = self.innerBorder {
            innerBorder.frame = CGRectInset(rect, 1.0, 1.0)
        }
    }

    // MARK: - Private methods
    
    private func setup() {
        border = self.addBorder("outerBorder")
        innerBorder = self.addBorder("innerBorder", borderWidth: 1.0, borderColor: UIColor.clearColor())
        if let rect = innerBorder?.frame {
            innerBorder?.frame = CGRectInset(rect, 1.0, 1.0)
        }
    }

    private func addBorder(name: String, borderWidth: CGFloat = 1.0, borderColor: UIColor = UIColor.lightGrayColor()) -> CALayer {
        let border = CALayer()
        let x = (drawLeft ? 0 : -borderWidth)
        let y = (drawTop ? 0 : -borderWidth)
        let w = (drawLeft ? bounds.size.width : bounds.size.width+borderWidth)
        let h = (drawTop ? bounds.size.height : bounds.size.height+borderWidth)
        
        border.frame = CGRectMake(x, y, w, h)
        border.borderColor = borderColor.CGColor
        border.borderWidth = borderWidth
        border.name = name
        
        layer.insertSublayer(border, atIndex: 0)
        layer.masksToBounds = false
        
        return border
    }
}
