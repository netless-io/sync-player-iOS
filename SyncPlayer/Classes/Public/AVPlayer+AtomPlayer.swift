//
//  AVPlayer+AtomPlayer.swift
//  SyncPlayer
//
//  Created by xuyunshi on 2022/5/31.
//

import AVFoundation

private var atomStatusKey: String?
private var atomListenersKey: String?
private var atomRateKey: String?
private var atomAddObserverKey: String?
private var durationKey: String?
private var endingBoundaryObserverKey: String?
private let statusKey = "status"
private let bufferKeepUpKey = "playbackLikelyToKeepUp"
private let bufferFullKey = "playbackBufferFull"
private let bufferEmptyKey = "playbackBufferEmpty"

extension AVPlayer: AtomPlayer {
    fileprivate var _endingObserver: Any? {
        get {
            objc_getAssociatedObject(self, &endingBoundaryObserverKey)
        }
        set {
            objc_setAssociatedObject(self, &endingBoundaryObserverKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // Load duration only once to satisfy some broken m3u8 file
    fileprivate var _duration: CMTime {
        get {
            (objc_getAssociatedObject(self, &durationKey) as? CMTime) ?? .invalid
        }
        set {
            objc_setAssociatedObject(self, &durationKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    
    public var atomPlaybackRate: Float {
        get {
            (objc_getAssociatedObject(self, &atomRateKey) as? Float) ?? 1
        }
        set {
            guard newValue != atomPlaybackRate else { return }
            objc_setAssociatedObject(self, &atomRateKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
            if atomStatus == .playing || atomStatus == .buffering {
                rate = atomPlaybackRate
            }
        }
    }
    
    public var readyToPlay: Bool {
        currentItem?.isPlaybackLikelyToKeepUp == true
    }
    
    public var atomError: Error? {
        if let error = currentItem?.error { return error }
        return error
    }
    
    public var atomStatus: AtomPlayStatus {
        get {
            (objc_getAssociatedObject(self, &atomStatusKey) as? AtomPlayStatus) ?? .ready
        }
        set {
            guard newValue != atomStatus else { return }
            objc_setAssociatedObject(self, &atomStatusKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
            listeners.forEach { $0.value(newValue) }
        }
    }
    
    var didAddObserver: Bool {
        get {
            (objc_getAssociatedObject(self, &atomAddObserverKey) as? Bool) ?? false
        }
        set {
            objc_setAssociatedObject(self, &atomAddObserverKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    var listeners: [Int: ((AtomPlayStatus) -> Void)] {
        get {
            (objc_getAssociatedObject(self, &atomListenersKey) as? [Int: ((AtomPlayStatus) -> Void)]) ?? [:]
        }
        set {
            objc_setAssociatedObject(self, &atomListenersKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public func atomSetup() {
        guard let item = currentItem else { return }
        didAddObserver = true
        addObserve(item: item)
    }
    
    public func atomDestroy() {
        guard let item = currentItem else { return }
        guard didAddObserver else { return }
        didAddObserver = false
        remove(for: item)
    }
    
    @objc
    func respondToPlayToEnd(_ notification: Notification) {
        let obj = notification.object as AnyObject
        guard obj === currentItem else { return }
        rate = 0
        atomStatus = .ended
    }
    
    func addObserve(item: AVPlayerItem) {
        NotificationCenter.default.addObserver(self, selector: #selector(respondToPlayToEnd(_:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        let loadingItem = item
        item.asset.loadValuesAsynchronously(forKeys: ["duration"]) { [weak self] in
            guard let self = self, loadingItem === self.currentItem else { return }
            self._duration = loadingItem.asset.duration
            self._endingObserver = self.addBoundaryTimeObserver(forTimes: [NSValue(time: loadingItem.duration)], queue: nil) { [weak self] in
                let notification = Notification(name: .AVPlayerItemDidPlayToEndTime, object: loadingItem)
                self?.respondToPlayToEnd(notification)
            }
        }
        item.addObserver(self, forKeyPath: statusKey, context: nil)
        item.addObserver(self, forKeyPath: bufferKeepUpKey, context: nil)
        item.addObserver(self, forKeyPath: bufferFullKey, context: nil)
        item.addObserver(self, forKeyPath: bufferEmptyKey, context: nil)
    }
    
    func remove(for item: AVPlayerItem) {
        _duration = .invalid
        _endingObserver = nil
        item.removeObserver(self, forKeyPath: statusKey)
        item.removeObserver(self, forKeyPath: bufferKeepUpKey)
        item.removeObserver(self, forKeyPath: bufferFullKey)
        item.removeObserver(self, forKeyPath: bufferEmptyKey)
    }
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case statusKey:
            if status == .failed || currentItem?.status == .failed {
                atomStatus = .error
            }
        case bufferKeepUpKey:
            if readyToPlay {
                endBuffering()
            }
        case bufferFullKey:
            if readyToPlay {
                endBuffering()
            }
        case bufferEmptyKey:
            if currentItem?.isPlaybackBufferEmpty == false {
                indicateStartRealBuffering()
            }
        default:
            return
        }
    }
    
    public func addStatusListener(_ listener: @escaping ((AtomPlayStatus) -> Void)) -> AtomListener {
        listener(atomStatus)
        let index = listeners.keys.max().map { $0 + 1 } ?? 0
        listeners[index] = listener
        return AnyAtomListener { [weak self] in
            guard let self = self,
                    let removeIndex = self.listeners.index(forKey: index) else { return }
            self.listeners.remove(at: removeIndex)
        }
    }
    
    public func atomPlay() {
        rate = atomPlaybackRate
        if readyToPlay {
            atomStatus = .playing
        } else {
            atomStatus = .buffering
        }
    }

    public func atomPause() {
        atomStatus = .pause
        rate = 0
    }
    
    public func atomReady() {
        atomStatus = .ready
        rate = 0
    }
    
    public func atomCurrentTime() -> CMTime {
        currentTime()
    }
    
    public func atomDuration() -> CMTime {
        _duration
    }
    
    public func atomSeek(time: CMTime, _ completionHandler: @escaping ((Bool) -> Void)) {
        currentItem?.cancelPendingSeeks()
        seek(to: time,
             toleranceBefore: .init(seconds: 0.05, preferredTimescale: 1000),
             toleranceAfter: .init(seconds: 0.05, preferredTimescale: 1000),
             completionHandler: completionHandler)
    }
    
    public func atomSeek(time: CMTime) {
        atomSeek(time: time, { _ in })
    }
    
    // MARK: - Buffer
    
    func endBuffering() {
        // Buffering status can trigger by controller only.
        // When end buffering on buffering status, it playing immediately.
        // Report the playing status to controller.
        if atomStatus == .buffering {
            atomStatus = .playing
        }
    }
    
    func indicateStartRealBuffering() {
        // If status is playing, it means the status is trigger by controller.
        // It report buffering only in this situation.
        if atomStatus == .playing {
            atomStatus = .buffering
        }
    }
}
