//
//  BorderedViewCell.swift
//  PayForm
//
//  Created by Sven Resch on 2016-06-03.
//  Copyright © 2016 Beanstream Internet Commerce, Inc. All rights reserved.
//

import UIKit

// Works when cell contentView has just a single BorderView based subview.
class BorderedViewCell: UITableViewCell {
    
    // MARK: - Public methods

    func setBorderColor(color: UIColor) {
        let view = self.contentView.subviews.first
        if let borderedView = view as? BorderedView {
            borderedView.borderColor = color
        }
    }

    func setHighlightColor(color: UIColor) {
        let view = self.contentView.subviews.first
        if let borderedView = view as? BorderedView {
            borderedView.innerBorderColor = color
        }
    }

    func drawLeft(draw: Bool) {
        let view = self.contentView.subviews.first
        if let borderedView = view as? BorderedView {
            borderedView.drawLeft = draw
        }
    }
    
    func drawTop(draw: Bool) {
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
    
}
