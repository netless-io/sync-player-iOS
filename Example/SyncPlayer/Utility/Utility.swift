//
//  Utility.swift
//  SyncPlayer_Example
//
//  Created by xuyunshi on 2022/6/6.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import SyncPlayer

extension String {
    func alignTo(num: Int) -> Self {
        if count >= num { return self }
        return self + String(repeating: " ", count: num - count)
    }
}

extension AtomPlayStatus {
    public func attributedLogIdentifier() -> String {
        switch self {
        case .ready:
            return "🟢 ready".alignTo(num: 10)
        case .pause:
            return "⏸ pause".alignTo(num: 10)
        case .buffering:
            return "🌀 buffer".alignTo(num: 10)
        case .playing:
            return "▶️ playing".alignTo(num: 10)
        case .ended:
            return "🟨 ended".alignTo(num: 10)
        case .error:
            return "🔴 error".alignTo(num: 10)
        }
    }
}
