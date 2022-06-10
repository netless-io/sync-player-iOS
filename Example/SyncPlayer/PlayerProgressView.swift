//
//  PlayerProgressView.swift
//  SyncPlayer_Example
//
//  Created by xuyunshi on 2022/5/30.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import SyncPlayer

class PlayerProgressView: UIView {
    var seekHandler: ((Float)->Void)?
    
    init() {
        super.init(frame: .zero)
        stackView.spacing = 8
        stackView.axis = .horizontal
        statusLabel.textColor = .white
        addSubview(stackView)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let p = touch.location(in: progressView).x / progressView.bounds.width
        seekHandler?(Float(p))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        stackView.frame = bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    lazy var progressView = UIProgressView()
    lazy var statusLabel = UILabel(frame: .zero)
    lazy var stackView = UIStackView(arrangedSubviews: [statusLabel, progressView])
}
