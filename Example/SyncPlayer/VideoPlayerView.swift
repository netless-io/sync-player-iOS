//
//  VideoPlayerView.swift
//  SyncPlayer_Example
//
//  Created by xuyunshi on 2022/5/31.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

class VideoPlayerView: UIView {
    @objc
    public init(preview: UIView) {
        self.preview = preview
        super.init(frame: .zero)
        addSubview(stackView)
        stackView.spacing = 8
        stackView.axis = .vertical
        stackView.distribution = .fill
        
        statusLabel.textColor = .white
        statusLabel.font = .preferredFont(forTextStyle: .body, compatibleWith: nil)
        timeLabel.textColor = .white
    }
    
    override func layoutSubviews() {
        stackView.frame = bounds
        super.layoutSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let preview: UIView
    @objc
    public lazy var stackView = UIStackView(arrangedSubviews: [preview, timeLabel, statusLabel])
    
    @objc
    public lazy var timeLabel = UILabel(frame: .zero)
    
    @objc
    public lazy var statusLabel = UILabel(frame: .zero)
}
