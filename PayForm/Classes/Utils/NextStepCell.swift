//
//  NextStepCell.swift
//  PayForm
//
//  Created by Sven Resch on 2016-06-03.
//  Copyright © 2016 Beanstream Internet Commerce, Inc. All rights reserved.
//

import UIKit

class NextStepCell: BorderedViewCell {
    
    @IBOutlet weak var nextStepTitleLabel: UILabel!

    func setTitleText(text: String) {
        self.nextStepTitleLabel.text = text
    }
}
