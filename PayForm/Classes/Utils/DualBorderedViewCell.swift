//
//  DualBorderedViewCell.swift
//  PayForm
//
//  Created by Sven Resch on 2016-06-03.
//  Copyright © 2016 Beanstream Internet Commerce, Inc. All rights reserved.
//

import UIKit

enum Side {
    case Left
    case Right
}

// Works when cell contentView has just "left" and "right" BorderView based subviews.
class DualBorderedViewCell: UITableViewCell {

    // MARK: - UITableViewCell methods

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupLeftView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupLeftView()
    }
    
    // MARK: - Public methods

    func setupLeftView() {
        let view = self.contentView.subviews.first
        if let borderedView = view as? BorderedView {
            borderedView.drawLeft = true
        }
    }
    
    func setBorderColor(color: UIColor, side: Side) {
        let view = (side == .Left ? self.contentView.subviews.first : self.contentView.subviews.last)
        if let borderedView = view as? BorderedView {
            borderedView.borderColor = color
        }
    }

}
