//
//  ExamplePlayerViewController.swift
//  SyncPlayer_Example
//
//  Created by xuyunshi on 2022/6/2.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import SnapKit
import SyncPlayer

class ExamplePlayerViewController: UIViewController {
    let player: SyncPlayer
    let subPlayers: [AtomPlayer]
    let playersViews: [UIView]

    @objc
    convenience public init (player1: AtomPlayer, view1: UIView, player2: AtomPlayer, view2: UIView) {
        self.init(playerAndViews: [(player1, view1), (player2, view2)]);
    }
    
    init(playerAndViews: [(AtomPlayer, UIView)]) {
        subPlayers = playerAndViews.map { $0.0 }
        player = SyncPlayer(players: playerAndViews.map { $0.0 })
        playersViews = playerAndViews.map { $0.1 }
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .formSheet
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var observer: Any?
    deinit {
        player.destroy()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        observer = player.addPeriodicTimeObserver(forInterval: .init(seconds: 0.5, preferredTimescale: 1000), queue: nil) { [weak self] time in
            guard let self = self else { return }
            self.progressView.statusLabel.text = String(format: "%.1f", time.seconds)
            let p = Float(time.seconds / self.player.totalTime.seconds)
            self.progressView.progressView.setProgress(p, animated: true)
            self.subPlayers.indices.forEach { index in
                let view = self.stack.arrangedSubviews[index] as! VideoPlayerView
                let str = String(format: "%.1f", self.subPlayers[index].atomCurrentTime().seconds)
                view.timeLabel.text = str
            }
        }
        preferredContentSize = UIScreen.main.bounds.insetBy(dx: 0, dy: 88).size
    }

    @IBAction func onReset(_ sender: Any) {
        player.seek(time: .init(seconds: 0, preferredTimescale: 1000))
    }
    
    @IBAction func onClickPlay(_ sender: Any) {
        player.play()
    }
    
    @IBAction func onClickPause(_ sender: Any) {
        player.pause()
    }
    
    @IBAction func rateUpdate(_ sender: Any) {
        let rate = min(max(0.25, (1 + 0.25 * rateStep.value)), 3)
        player.playbackRate = Float(rate)
        rateItemLabel.title = rate.description
    }
    
    @IBAction func onClickDelay(_ sender: Any) {
        let s = subPlayers[0].atomCurrentTime().seconds
        subPlayers[1].atomSeek(time: .init(seconds: s + 1, preferredTimescale: 1000))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if view.bounds.width > view.bounds.height {
            stack.axis = .horizontal
        } else {
            stack.axis = .vertical
        }
    }
    
    func setupViews() {
        progressViewContainer.addSubview(progressView)
        progressView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0))
        }
        
        stack.spacing = 14
        stack.distribution = .fillEqually
        playerContainer.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        playersViews.forEach { stack.addArrangedSubview($0) }
        progressView.seekHandler = { [weak self] progress in
            guard let self = self else { return }
            let s = self.player.totalTime.seconds * Double(progress)
            self.player.seek(time: .init(seconds: s, preferredTimescale: self.player.totalTime.timescale))
        }
    }

    lazy var stack = UIStackView(arrangedSubviews: [])
    lazy var progressView = PlayerProgressView()
    
    @IBOutlet weak var playerContainer: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var rateStep: UIStepper!
    @IBOutlet weak var rateItemLabel: UIBarButtonItem!
    @IBOutlet weak var progressViewContainer: UIView!
}
