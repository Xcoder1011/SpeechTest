//
//  SpeechViewCell.swift
//  SpeechTest
//
//  Created by shangkun on 2019/3/13.
//  Copyright © 2019年 wushangkun. All rights reserved.
//

import UIKit


class SpeechContentCell: UITableViewCell {
    
    var content: Content?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}

class SpeechViewMyCell: SpeechContentCell {

    @IBOutlet weak var contenLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override var content: Content? {
        didSet {
            self.contenLabel.text = content?.string
        }
    }

}

class SpeechViewYouCell: SpeechContentCell {
    
    @IBOutlet weak var contentLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override var content: Content? {
        didSet {
            self.contentLabel.text = content?.string
        }
    }
}
