//
//  ClusterPlayer.swift
//  SyncPlayer
//
//  Created by xuyunshi on 2022/5/31.
//

import CoreMedia

/// clusterEmitterReceptorMap[receptor][emitter]
let clusterEmitterReceptorMap: [[AtomPlayStatus?]] = [
    [.ready, nil, nil, nil, .ready, .error],
    [.pause, .pause, .pause, nil, .pause, .error],
    [.buffering, nil, .buffering, .buffering, .buffering, .error],
    [nil, nil, nil, .playing, .playing, .error],
    [.ready, .pause, .buffering, .playing, .ended, .error],
    [.error, .error, .error, .error, .error, .error]
]

func getAtomStatus(emitter: AtomPlayer, receptor: AtomPlayer) -> AtomPlayStatus? {
    clusterEmitterReceptorMap[receptor.atomStatus.rawValue][emitter.atomStatus.rawValue]
}

class ClusterPlayer: AtomPlayer {
    var readyToPlay: Bool { aPlayer.readyToPlay && bPlayer.readyToPlay }
    /// Indicate if syncing a b player
    var syncing = false
    
    var atomPlaybackRate: Float {
        get { aPlayer.atomPlaybackRate }
        set {
            aPlayer.atomPlaybackRate = newValue
            bPlayer.atomPlaybackRate = newValue
        }
    }
    
    var atomError: Error? {
        if let error = aPlayer.atomError { return error }
        if let error = bPlayer.atomError { return error }
        return nil
    }
    
    var atomStatus: AtomPlayStatus {
        didSet {
            guard atomStatus != oldValue else { return }
            listeners.forEach {$0.value(atomStatus)}
        }
    }
    
    lazy var nonClusterPlayers: [AtomPlayer] = {
        var r: [AtomPlayer] = []
        if let a = aPlayer as? ClusterPlayer {
            r.append(contentsOf: a.nonClusterPlayers)
        } else {
            r.append(aPlayer)
        }
        if let b = bPlayer as? ClusterPlayer {
            r.append(contentsOf: b.nonClusterPlayers)
        } else {
            r.append(bPlayer)
        }
        return r
    }()
    
    struct SyncInfo {
        let minTime: CMTime
        let maxTime: CMTime
        /// Max minus min
        let delta: CMTime
    }
    
    func getSyncInfo() -> SyncInfo {
        let playingPlayersCurrentTime = nonClusterPlayers
            .filter { $0.atomStatus == .playing }
            .filter { $0.atomCurrentTime() != $0.atomDuration()}
            .map { $0.atomCurrentTime() }
        guard let min = playingPlayersCurrentTime.min(),
              let max = playingPlayersCurrentTime.max()
        else { return .init(minTime: .zero, maxTime: .zero, delta: .zero)}
        return SyncInfo(minTime: min, maxTime: max, delta: max - min)
    }
    
    /// Sync only happen when playing, so it will continue play after syncing
    func syncTo(time: CMTime) {
        atomSeek(time: time) { [weak self] success in
            guard let self = self else { return }
            if success, self.syncing {
                log("finish syncing")
                self.syncing = false
                self.atomPlay()
            }
        }
        syncing = true
    }
    
    func atomPlay() {
        // Sync time
        if syncing {
            log("reject play when syncing")
            return
        }
        
        play(subPlayer: aPlayer)
        play(subPlayer: bPlayer)
    }
    
    func atomPause() {
        syncing = false
        func trySetPause(player: AtomPlayer) {
            guard player.atomStatus != .ended, player.atomStatus != .error else { return }
            player.atomPause()
        }
        trySetPause(player: aPlayer)
        trySetPause(player: bPlayer)
    }
    
    func atomReady() {
        // Ready wont trigger status
        func trySetReady(player: AtomPlayer) {
            guard player.atomStatus != .ended, player.atomStatus != .error else { return }
            player.atomReady()
        }
        trySetReady(player: aPlayer)
        trySetReady(player: bPlayer)
    }
    
    func atomSetup() {
        log(aPlayer, "source: \(source(for: aPlayer))")
        log(bPlayer, "source: \(source(for: bPlayer))")
        
        aPlayer.atomSetup()
        bPlayer.atomSetup()
        
        self.aPlayer.addStatusListener { [weak self] _ in
            guard let self = self else { return }
            self.synthesizeAction(emitter: self.aPlayer, receptor: self.bPlayer)
            if let new = getAtomStatus(emitter: self.aPlayer, receptor: self.bPlayer) {
                self.atomStatus = new
            }
        }

        self.bPlayer.addStatusListener { [weak self] _ in
            guard let self = self else { return }
            self.synthesizeAction(emitter: self.bPlayer, receptor: self.aPlayer)
            if let new = getAtomStatus(emitter: self.bPlayer, receptor: self.aPlayer) {
                self.atomStatus = new
            }
        }
    }
    
    func atomDestroy() {
        aPlayer.atomDestroy()
        bPlayer.atomDestroy()
    }
    
    func atomCurrentTime() -> CMTime {
        max(aPlayer.atomCurrentTime(), bPlayer.atomCurrentTime())
    }
    
    func atomSeek(time: CMTime, _ completionHandler: @escaping ((Bool) -> Void)) {
        syncing = false
        
        // Ready, seek, resume
        let group = DispatchGroup()
        var groupSuccess = true
        let seekWhenPlaying = atomStatus == .buffering || atomStatus == .playing
        
        func seek(time: CMTime, player: AtomPlayer) {
            group.enter()
            log(player, ": start seek 🔍", time.seconds)
            let seekingFromEnd = player.atomStatus == .ended
            player.atomSeek(time: time) { success in
                guard success else {
                    groupSuccess = false
                    group.leave()
                    return
                }
                log(player, ": ☑️ end seek 🔍", player.atomCurrentTime().seconds)
                if seekingFromEnd {
                    player.atomReady()
                }
                group.leave()
            }
        }
        
        if seekWhenPlaying {
            atomReady()
        }
        
        seek(time: time, player: aPlayer)
        seek(time: time, player: bPlayer)
        
        group.notify(queue: .main) {
            // When syncing, call play by sync caller itself.
            if seekWhenPlaying, !self.syncing {
                self.atomPlay()
            }
            completionHandler(groupSuccess)
        }
    }
    
    func atomSeek(time: CMTime) {
        atomSeek(time: time, { _ in })
    }
    
    func atomDuration() -> CMTime {
        let a = aPlayer.atomDuration()
        let b = bPlayer.atomDuration()
        guard a.isValid, b.isValid
        else { return .invalid }
        return max(a, b)
    }
    
    var aPlayer: AtomPlayer
    var bPlayer: AtomPlayer
    
    var listeners: [Int: ((AtomPlayStatus) -> Void)] = [:]
    
    func addStatusListener(_ listener: @escaping ((AtomPlayStatus) -> Void)) -> AtomListener {
        let index = listeners.keys.max().map { $0 + 1 } ?? 0
        listeners[index] = listener
        listener(atomStatus)
        return AnyAtomListener { [weak self] in
            guard let self = self,
                    let removeIndex = self.listeners.index(forKey: index) else { return }
            self.listeners.remove(at: removeIndex)
        }
    }
    
    init(player: AtomPlayer, anotherPlayer: AtomPlayer) {
        self.aPlayer = player
        self.bPlayer = anotherPlayer
        
        let initialStatus = getAtomStatus(emitter: aPlayer, receptor: bPlayer)
        atomStatus = initialStatus ?? .ready
    }
    
    func synthesizeAction(emitter: AtomPlayer, receptor: AtomPlayer) {
        log(emitter, "emitter", emitter.atomStatus, "receptor", receptor, receptor.atomStatus)
        switch (emitter.atomStatus, receptor.atomStatus) {
        case (.pause, .buffering):
            log("to pause receptor")
            receptor.atomPause()
        case (.pause, .playing):
            log("to pause receptor")
            receptor.atomPause()
        case (.buffering, .playing):
            log("to ready receptor")
            receptor.atomReady()
        case (.playing, .ready):
            log("to play receptor")
            play(subPlayer: receptor)
        case (.playing, .pause):
            log("to play receptor")
            play(subPlayer: receptor)
        case (.playing, .buffering):
            log("to play receptor")
            log("to ready emitter")
            play(subPlayer: receptor)
            emitter.atomReady()
        case (.error, _):
            log("to pause receptor")
            receptor.atomPause()
        case (_, .error):
            log("to pause emitter")
            emitter.atomPause()
        default:
            break
        }
    }
    
    func play(subPlayer: AtomPlayer) {
        guard subPlayer.atomStatus != .error else { return }
        let totalTime = subPlayer.atomDuration()
        guard totalTime.isValid else { return }
        subPlayer.atomPlay()
    }
}
