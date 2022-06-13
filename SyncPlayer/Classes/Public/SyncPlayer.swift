//
//  SyncPlayer.swift
//  SyncPlayer
//
//  Created by xuyunshi on 2022/5/31.
//

import Foundation
import CoreMedia

/// Centralize multiple players, synchronize playback progress and status.
@objc
public class SyncPlayer: NSObject {
    var player: AtomPlayer
    
    var periodicTimeObserver: [String: (DispatchQueue, ((CMTime)->Void))] = [:]
    
    // MARK: - Public
    
    @objc
    public var status: AtomPlayStatus { player.atomStatus }
    
    /// Indicates the current difference tolerance between different videos.
    /// Default is 0.5 seconds.
    @objc
    public var tolerance: TimeInterval = 0.5
    
    /// Indicates the frequency of checking the difference between different videos.
    /// Default is 4 seconds.
    @objc
    public var syncInterval: TimeInterval = 4
    
    /// Indicates the play rate of playback.
    @objc
    public var playbackRate: Float {
        get {
            player.atomPlaybackRate
        }
        set {
            player.atomPlaybackRate = newValue
        }
    }
    
    @objc
    public var error: Error? { player.atomError }
    
    /// Return the maximum time value of subPlayers.
    @objc
    public var currentTime: CMTime { player.atomCurrentTime() }
    
    /// Indicate the longest video duration.
    /// When player is not ready to read info, it returns KCMTimeInvalid.
    @objc
    public var totalTime: CMTime { player.atomDuration() }
    
    @objc
    public init(players: [AtomPlayer]) {
        player = players.reduce(nil) { partialResult, item -> AtomPlayer in
            if let r = partialResult {
                let cluster = ClusterPlayer(player: item, anotherPlayer: r)
                return cluster
            } else {
                return item
            }
        }!
        super.init()
        player.atomSetup()
        initSyncTimer()
    }
    
    @objc
    public func play() {
        player.atomPlay()
    }
    
    @objc
    public func pause() {
        player.atomPause()
    }
    
    /// Destroy the player resource.
    @objc
    public func destroy() {
        pauseSyncTimer()
        timer.invalidate()
        removeAllTimeObserver()
        player.atomDestroy()
    }
    
    /// Add a status listener
    @objc
    @discardableResult
    public func addStatusListener(_ listener: @escaping ((AtomPlayStatus)->Void)) -> AtomListener {
        player.addStatusListener(listener)
    }
    
    @objc
    public func seek(time: CMTime, _ completionHandler: ((Bool)->Void)? = nil) {
        player.atomSeek(time: time, completionHandler ?? { _ in })
    }
    
    @objc
    public func addPeriodicTimeObserver(forInterval interval: CMTime, queue: DispatchQueue?, using block: @escaping (CMTime) -> Void) -> Any {
        let id = UUID().uuidString
        let timer = Timer(timeInterval: interval.seconds, target: self, selector: #selector(onPeriodicTimeObserver(timer:)), userInfo: ["uuid": id], repeats: true)
        timer.fireDate = Date()
        RunLoop.current.add(timer, forMode: .commonModes)
        periodicTimeObserver[id] = (queue ?? .main, block)
        return id
    }
    
    @objc
    public func removeTimeObserver(_ observer: Any) {
        guard let id = observer as? String else { return }
        periodicTimeObserver.removeValue(forKey: id)
    }
    
    func removeAllTimeObserver() {
        periodicTimeObserver.removeAll()
    }
    
    // MARK: - PeriodicTimeObserver
    @objc
    func onPeriodicTimeObserver(timer: Timer) {
        if let info = timer.userInfo as? [String: String] {
            if let id = info["uuid"] {
                if let observer = periodicTimeObserver[id] {
                    observer.0.async {
                        observer.1(self.currentTime)
                    }
                } else {
                    timer.invalidate()
                }
            }
        }
    }
    
    // MARK: - Sync Timer
    @objc
    func onSyncTimer() {
        log("on sync timer")
        guard
            let clusterPlayer = player as? ClusterPlayer,
                !clusterPlayer.syncing
        else { return }

        let info = clusterPlayer.getSyncInfo()
        guard info.delta.seconds >= tolerance else { return }
        log("start syncing", "delta", info.delta.seconds)

        clusterPlayer.syncTo(time: info.minTime)
    }
    
    func startSyncTimer() {
        timer.fireDate = Date()
    }
    
    func pauseSyncTimer() {
        timer.fireDate = .distantFuture
    }
    
    func initSyncTimer() {
        RunLoop.current.add(timer, forMode: .commonModes)
        pauseSyncTimer()
        player.addStatusListener { [weak self] status in
            switch status {
            case .playing:
                self?.startSyncTimer()
            default:
                self?.pauseSyncTimer()
            }
        }
    }
    
    lazy var timer = Timer(timeInterval: syncInterval, target: self, selector: #selector(onSyncTimer), userInfo: nil, repeats: true)
}
