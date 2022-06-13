//
//  DeallocTest.swift
//  SyncPlayer_Tests
//
//  Created by xuyunshi on 2022/6/13.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation
import XCTest
@testable import SyncPlayer

class DeallocTest: XCTestCase {
    var table = NSHashTable<NSObject>(options: .weakMemory)
    
    override func setUp() {
        XCTAssert(table.allObjects.isEmpty)
        super.setUp()
    }
    
    func testADealloc() {
        let exp = expectation(description: #function)
        let p1 = createExampleURLAtomPlayer()
        let p2 = createExampleURLAtomPlayer()
        let player = SyncPlayer(players: [p1, p2])
        var l: AtomListener?
        l = player.addStatusListener { [weak player, weak self] status in
            if status == .playing {
                l?.cancel()
                player?.destroy()
                exp.fulfill()
            }
        }
        table.add(p1 as! NSObject)
        table.add(p2 as! NSObject)
        table.add(player as! NSObject)
        player.play()
        waitForExpectations(timeout: timeout)
    }
    
    func testZDealloc() {
        // ZDealloc will be tested after ADealloc. Because of A~Z.
        // The real assert is in function `setUp`.
    }
}
