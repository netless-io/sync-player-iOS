//
//  AtomPlayerOperation.swift
//  SyncPlayer
//
//  Created by xuyunshi on 2022/6/10.
//

import Foundation
import CoreMedia

/// Class for Objective-C to generate OffsetPlayer or SelectionPlayer.
/// See AtomPlayer+Offset.swift and AtomPlayer+Selection.swift if you are using swift.
@objc
public class AtomPlayerOperation: NSObject {
    /// See [AtomPlayer+Offset](AtomPlayer+Offset)
    @objc
    public class func offset(player: AtomPlayer, time: CMTime) -> AtomPlayer {
        player.offset(time: time)
    }
    
    /// See [AtomPlayer+Selection](AtomPlayer+Selection)
    @objc
    public class func selection(player: AtomPlayer, ranges: [CMTimeRange]) -> AtomPlayer {
        player.selection(ranges: ranges)
    }
}
