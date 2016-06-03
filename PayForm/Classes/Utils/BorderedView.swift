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
    
    var border: CALayer?
    var drawLeft: Bool = false
    var drawTop: Bool = false
    
    // MARK: - View controller methods

    override init(frame: CGRect) {
        super.init(frame: frame)
        border = self.addBorder()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        border = self.addBorder()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let border = self.border {
            let borderWidth = border.borderWidth
            let x = (drawLeft ? 0 : -borderWidth)
            let y = (drawTop ? 0 : -borderWidth)
            let w = (drawLeft ? bounds.size.width : bounds.size.width+borderWidth)
            let h = (drawTop ? bounds.size.height : bounds.size.height+borderWidth)
            border.frame = CGRectMake(x, y, w, h)
        }
    }

    // MARK: - Private methods

    private func addBorder(borderWidth: CGFloat = 1.0, borderColor: UIColor = UIColor.lightGrayColor()) -> CALayer {
        let border = CALayer()
        let x = (drawLeft ? 0 : -borderWidth)
        let y = (drawTop ? 0 : -borderWidth)
        let w = (drawLeft ? bounds.size.width : bounds.size.width+borderWidth)
        let h = (drawTop ? bounds.size.height : bounds.size.height+borderWidth)
        
        border.frame = CGRectMake(x, y, w, h)
        border.borderColor = borderColor.CGColor
        border.borderWidth = borderWidth
        border.name = "externalBorder"
        
        layer.insertSublayer(border, atIndex: 0)
        layer.masksToBounds = false
        
        return border
    }
}
