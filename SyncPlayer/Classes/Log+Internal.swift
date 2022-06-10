//
//  Log+Internal.swift
//  SyncPlayer
//
//  Created by xuyunshi on 2022/5/31.
//

import AVFoundation

var ids: [UnsafeMutableRawPointer: String] = [:]

func log(_ items: Any...) {
    if !showLog { return }
    let str = items.reduce(into: "--- sync-player ---") { partialResult, item in
        let itemString: String
        if let player = item as? AtomPlayer {
            itemString = getId(for: player)
        } else if let status = item as? AtomPlayStatus {
            itemString = status.attributedLogIdentifier()
        } else {
            itemString = String(describing: item)
        }
        return partialResult = partialResult + " " + itemString
    }
    print(str)
}

private let emojis = ["0️⃣","1️⃣","2️⃣","3️⃣","4️⃣","5️⃣","6️⃣","7️⃣","8️⃣","9️⃣"]

func getPointer(player: AtomPlayer) -> UnsafeMutableRawPointer {
    Unmanaged<AnyObject>.passUnretained(player as AnyObject).toOpaque()
}

func source(for player: AtomPlayer) -> String {
    if let cluster = player as? ClusterPlayer {
        return "cluster: " + getId(for: cluster.aPlayer) + " & " + getId(for: cluster.bPlayer)
    } else if let player  = player as? AVPlayer,
       let urlAsset = player.currentItem?.asset as? AVURLAsset
       {
        return urlAsset.url.absoluteString
    } else if let offset = player as? OffsetPlayer {
        return "🏖 offset: " + source(for: offset.realPlayer)
    } else if let selection = player as? SelectionPlayer {
        return "✂️ selection: " + source(for: selection.realPlayer)
    }
    return "unknown source"
}

// TBD:
// 这里有内存泄漏
fileprivate func getId(for player: AtomPlayer) -> String {
    let pointer = getPointer(player: player)
    let r = ids[pointer]
    if let r = r { return r }
    
    var count = ids.count
    var str = ""
    while count / 10 > 0 {
        str += emojis[count / 10]
        count /= 10
    }
    str += emojis[ids.count % 10]
    ids[pointer] = str
    return str
}

extension String {
    fileprivate func alignTo(num: Int) -> Self {
        if count >= num { return self }
        return self + String(repeating: " ", count: num - count)
    }
}

extension AtomPlayStatus {
    fileprivate func attributedLogIdentifier() -> String {
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
