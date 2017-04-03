//
//  NextStepCell.swift
//  PayForm
//
//  Created by Sven Resch on 2016-06-03.
//  Copyright © 2017 Bambora Inc. All rights reserved.
//

import UIKit

class NextStepCell: BorderedViewCell {
    
    @IBOutlet fileprivate weak var nextStepTitleLabel: UILabel!

    func setTitleText(_ text: String) {
        if let label = self.nextStepTitleLabel {
            label.text = text
        }
    }
    
}
