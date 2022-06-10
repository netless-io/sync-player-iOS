//
//  VideoPreviewView.swift
//  SyncPlayer_Example
//
//  Created by xuyunshi on 2022/5/31.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import AVFoundation

class VideoPreviewView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
}
