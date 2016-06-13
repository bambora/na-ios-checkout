//
//  NextStepCell.swift
//  PayForm
//
//  Created by Sven Resch on 2016-06-03.
//  Copyright © 2016 Beanstream Internet Commerce, Inc. All rights reserved.
//

import UIKit

class NextStepCell: BorderedViewCell {
    
    @IBOutlet private weak var nextStepTitleLabel: UILabel!

    func setTitleText(text: String) {
        if let label = self.nextStepTitleLabel {
            label.text = text
        }
    }
    
}
