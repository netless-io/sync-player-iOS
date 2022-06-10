//
//  HomeViewController.swift
//  SyncPlayer_Example
//
//  Created by xuyunshi on 2022/6/2.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import SyncPlayer
import AVFoundation
import Whiteboard

let exampleAppId = "283/VGiScM9Wiw2HJg"
let exampleRoomId = "65fc0e10e15511ec92dce3bcde27b589"
let exampleRoomToken = "WHITEcGFydG5lcl9pZD15TFExM0tTeUx5VzBTR3NkJnNpZz03YzQwZDZjNDVhY2NkMTJlN2IyYjg4OTYwM2UzZWZlNDMxZTE1NTk3OmFrPXlMUTEzS1N5THlXMFNHc2QmY3JlYXRlX3RpbWU9MTY1NDA1MTc0NDQyOSZleHBpcmVfdGltZT0xNjg1NTg3NzQ0NDI5Jm5vbmNlPTE2NTQwNTE3NDQ0MjkwMCZyb2xlPXJvb20mcm9vbUlkPTY1ZmMwZTEwZTE1NTExZWM5MmRjZTNiY2RlMjdiNTg5JnRlYW1JZD05SUQyMFBRaUVldTNPNy1mQmNBek9n"

class HomeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showLog = true
    }

    @IBAction func onVideos(_ sender: Any) {
        let urls = [URL(string: "https://convertcdn.netless.link/1.mp4")!,
                    URL(string: "https://convertcdn.netless.link/1.mp4")!]
        let items = urls.map {
            createUrlPlayer($0)
        }
        let vc = ExamplePlayerViewController(playerAndViews: items)
        present(vc, animated: true)
    }
    
    @IBAction func onOffsetVideos(_ sender: Any) {
        let items = [
            createUrlPlayer(URL(string: "https://convertcdn.netless.link/1.mp4")!),
            createUrlPlayer(URL(string: "https://convertcdn.netless.link/1.mp4")!, offset: .init(seconds: 3, preferredTimescale: 1000))
        ]
        let vc = ExamplePlayerViewController(playerAndViews: items)
        present(vc, animated: true)
    }
    
    @IBAction func onSelectionVideos(_ sender: Any) {
        let items = [
            createUrlPlayer(URL(string: "https://convertcdn.netless.link/1.mp4")!),
            createUrlPlayer(URL(string: "https://convertcdn.netless.link/1.mp4")!, ranges: [
                .init(start: .init(seconds: 3, preferredTimescale: 1000), end: .init(seconds: 7, preferredTimescale: 1000)),
                .init(start: .init(seconds: 8, preferredTimescale: 1000), end: .init(seconds: 15, preferredTimescale: 1000)),
                .init(start: .init(seconds: 20, preferredTimescale: 1000), end: .init(seconds: 23, preferredTimescale: 1000)),
            ])
        ]
        let vc = ExamplePlayerViewController(playerAndViews: items)
        present(vc, animated: true)
    }
    
    @IBAction func onWhiteVideos(_ sender: Any) {
        let activity = UIActivityIndicatorView(activityIndicatorStyle: .white)
        activity.startAnimating()
        view.addSubview(activity)
        activity.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(144)
        }
        createWhitePlayer { whitePlayer, whiteView in
            activity.removeFromSuperview()
            let items = [
                self.createUrlPlayer(URL(string: "https://convertcdn.netless.link/1.mp4")!),
                (whitePlayer, whiteView)
            ]
            let vc = ExamplePlayerViewController(playerAndViews: items)
            self.present(vc, animated: true)
        }
        
        // Delete Comment try OC
        // OCExample.startWhite(from: self)
    }
}

extension HomeViewController {
    func createWhitePlayer(_ completionHandler: ((AtomPlayer, UIView)->Void)?) {
        let whiteView = WhiteBoardView()
        view.addSubview(whiteView)
        let sdkConfig = WhiteSdkConfiguration(app: exampleAppId)
        let sdk = WhiteSDK(whiteBoardView: whiteView, config: sdkConfig, commonCallbackDelegate: nil)
        let config = WhitePlayerConfig(room: exampleRoomId,
                                       roomToken: exampleRoomToken)
        sdk.createReplayer(with: config, callbacks: self) { success, player, error in
            let selectionWhite = player!.selection(ranges: [
                .init(start: .init(seconds: 3, preferredTimescale: 1000), end: .init(seconds: 66, preferredTimescale: 1000))
            ])
            let playerView = VideoPlayerView(preview: whiteView)
            player!.addStatusListener { [weak playerView, weak player] status in
                guard let player = player else { return }
                guard let playerView = playerView else { return }
                if status == .error {
                    playerView.statusLabel.text = "player status: \(status.attributedLogIdentifier()), \(player.atomError!.localizedDescription)"
                } else {
                    playerView.statusLabel.text = "player status:  \(status.attributedLogIdentifier())"
                }
            }
            completionHandler?(selectionWhite, playerView)
        }
    }
    
    func createUrlPlayer(_ url: URL, offset: CMTime? = nil, ranges: [CMTimeRange]? = nil) -> (AtomPlayer, UIView) {
        let player = AVPlayer(url: url)
        let preview = VideoPreviewView()
        (preview.layer as? AVPlayerLayer)?.videoGravity = .resizeAspectFill
        (preview.layer as? AVPlayerLayer)?.player = player
        let playerView = VideoPlayerView(preview: preview)
        
        var atomPlayer: AtomPlayer = player
        if let offset = offset {
            atomPlayer = atomPlayer.offset(time: offset)
        }
        if let ranges = ranges {
            atomPlayer = atomPlayer.selection(ranges: ranges)
        }
        atomPlayer.addStatusListener { [weak playerView, weak player] status in
            guard let player = player else { return }
            guard let playerView = playerView else { return }
            if status == .error {
                guard let error = player.atomError else { return }
                playerView.statusLabel.text = "player status: \(status.attributedLogIdentifier()), \(error.localizedDescription)"
            } else {
                playerView.statusLabel.text = "player status:  \(status.attributedLogIdentifier())"
            }
        }
        
        return (atomPlayer, playerView)
    }
}

extension HomeViewController: WhitePlayerEventDelegate {
    func phaseChanged(_ phase: WhitePlayerPhase) {
        print("home white phase changed", String(describing: phase))
    }
}
