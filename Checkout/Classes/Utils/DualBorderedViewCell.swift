//
//  DualBorderedViewCell.swift
//  Checkout
//
//  Created by Sven Resch on 2016-06-03.
//  Copyright © 2017 Bambora Inc. All rights reserved.
//

import UIKit

enum Side {
    case left
    case right
}

// Works when cell contentView has just "left" and "right" BorderView based subviews.
class DualBorderedViewCell: UITableViewCell {

    // MARK: - UITableViewCell methods

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupLeftView()
        self.setupRightView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupLeftView()
        self.setupRightView()
    }
    
    // MARK: - Public methods

    func setBorderColor(_ color: UIColor, side: Side) {
        let view = (side == .left ? self.contentView.subviews.first : self.contentView.subviews.last)
        if let borderedView = view as? BorderedView {
            borderedView.borderColor = color
        }
    }
    
    func setHighlightColor(_ color: UIColor, side: Side) {
        let view = (side == .left ? self.contentView.subviews.first : self.contentView.subviews.last)
        if let borderedView = view as? BorderedView {
            borderedView.innerBorderColor = color
        }
    }
    
    func textField(_ side: Side) -> UITextField? {
        var borderedView: BorderedView? = nil
        if let view = self.contentView.subviews.first as? BorderedView, side == .left {
            borderedView = view;
        }
        else if let view = self.contentView.subviews.last as? BorderedView, side == .right {
            borderedView = view;
        }
        if let textField = borderedView?.subviews.first as? UITextField {
            return textField;
        }
        return nil
    }

    func embeddedImageView(_ side: Side) -> UIImageView? {
        var borderedView: BorderedView? = nil
        if let view = self.contentView.subviews.first as? BorderedView, side == .left {
            borderedView = view;
        }
        else if let view = self.contentView.subviews.last as? BorderedView, side == .right {
            borderedView = view;
        }
        if let imageView = borderedView?.subviews.last as? UIImageView {
            return imageView;
        }
        return nil
    }

    // MARK: - Private methods
    
    fileprivate func setupLeftView() {
        let view = self.contentView.subviews.first
        if let borderedView = view as? BorderedView {
            borderedView.drawLeft = true
        }
    }
    
    fileprivate func setupRightView() {
        let view = self.contentView.subviews.last
        if let borderedView = view as? BorderedView {
            borderedView.drawLeft = false
        }
    }

}
