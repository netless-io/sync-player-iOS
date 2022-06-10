//
//  AtomPlayer+Offset.swift
//  SyncPlayer
//
//  Created by xuyunshi on 2022/6/1.
//

import CoreMedia

extension AtomPlayer {
    /// Only positive value is acceptable
    /// Negative value will leading to undefined behavior
    public func offset(time: CMTime) -> AtomPlayer {
        OffsetPlayer(realPlayer: self, offset: time)
    }
}
