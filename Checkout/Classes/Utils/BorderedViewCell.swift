//
//  BorderedViewCell.swift
//  Checkout
//
//  Created by Sven Resch on 2016-06-03.
//  Copyright © 2017 Bambora Inc. All rights reserved.
//

import UIKit

// Works when cell contentView has just a single BorderView based subview.
class BorderedViewCell: UITableViewCell {
    
    // MARK: - Public methods

    func setBorderColor(_ color: UIColor) {
        let view = self.contentView.subviews.first
        if let borderedView = view as? BorderedView {
            borderedView.borderColor = color
        }
    }

    func setHighlightColor(_ color: UIColor) {
        let view = self.contentView.subviews.first
        if let borderedView = view as? BorderedView {
            borderedView.innerBorderColor = color
        }
    }

    func drawLeft(_ draw: Bool) {
        let view = self.contentView.subviews.first
        if let borderedView = view as? BorderedView {
            borderedView.drawLeft = draw
        }
    }
    
    func drawTop(_ draw: Bool) {
        let view = self.contentView.subviews.first
        if let borderedView = view as? BorderedView {
            borderedView.drawTop = draw
        }
    }
    
    func textField() -> UITextField? {
        if let borderedView = self.contentView.subviews.first as? BorderedView {
            if let textField = borderedView.subviews.first as? UITextField {
                return textField;
            }
        }
        return nil
    }

    func embeddedImageView() -> UIImageView? {
        if let borderedView = self.contentView.subviews.first as? BorderedView {
            if let imageView = borderedView.subviews.last as? UIImageView {
                return imageView;
            }
        }
        return nil
    }

}
