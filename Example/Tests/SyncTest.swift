//
//  SyncTest.swift
//  SyncPlayer_Tests
//
//  Created by xuyunshi on 2022/6/13.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation
import XCTest
@testable import SyncPlayer
import CoreMedia

let timeout: TimeInterval = 30
class SyncTest: XCTestCase {
    var player: SyncPlayer!
    
    override func setUp() {
        let exp = expectation(description: #function)
        let p1 = createExampleURLAtomPlayer()
        let p2 = createExampleURLAtomPlayer()
        let player = SyncPlayer(players: [p1, p2])
        var l: AtomListener?
        l = player.addStatusListener { [weak player] status in
            if status == .playing {
                player?.pause()
                l?.cancel()
                exp.fulfill()
                super.setUp()
            }
        }
        self.player = player
        player.play()
        waitForExpectations(timeout: timeout)
    }
    
    func testSync() {
        guard let cluster = player.player as? ClusterPlayer else { return }
        let cTime = cluster.bPlayer.atomCurrentTime()
        let nTime = cTime + CMTime(seconds: player.tolerance, preferredTimescale: 1000)
        let exp = expectation(description: #function)
        var didEnterSync = false
        cluster.bPlayer.atomSeek(time: nTime) { [weak self] success in
            XCTAssert(self?.player.player.atomCurrentTime() == nTime)
            self?.player.play()
            self?.player.addStatusListener({ status in
                if status == .ready {
                    didEnterSync = true
                }
                if didEnterSync, status == .playing {
                    exp.fulfill()
                }
            })
        }
        waitForExpectations(timeout: timeout)
    }
}
