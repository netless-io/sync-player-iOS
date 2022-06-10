//
//  AtomPlayer+Selection.swift
//  SyncPlayer
//
//  Created by xuyunshi on 2022/6/1.
//

import CoreMedia

extension AtomPlayer {
    /// Return a atomPlayer was time picked.
    /// This player will only play the video in ranges.
    /// The duration of the new player will be the sum of the ranges durations.
    public func selection(ranges: [CMTimeRange]) -> AtomPlayer {
        SelectionPlayer(realPlayer: self, ranges: ranges)
    }
}
