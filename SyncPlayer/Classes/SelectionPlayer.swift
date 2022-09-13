//
//  SelectionPlayer.swift
//  SyncPlayer
//
//  Created by xuyunshi on 2022/6/1.
//

import CoreMedia

class SelectionPlayer: AtomPlayer {
    var realPlayer: AtomPlayer
    let ranges: [CMTimeRange]
    let totalTime: CMTime
    
    init(realPlayer: AtomPlayer, ranges: [CMTimeRange]) {
        self.atomStatus = realPlayer.atomStatus
        self.realPlayer = realPlayer
        self.ranges = ranges
        totalTime = ranges.reduce(into: .zero) { partialResult, range in
            partialResult = partialResult + range.duration
        }
    }
    
    var atomError: Error? { realPlayer.atomError }
    var readyToPlay: Bool { realPlayer.readyToPlay }
    var atomPlaybackRate: Float {
        get { realPlayer.atomPlaybackRate }
        set { realPlayer.atomPlaybackRate = newValue }
    }
    
    var atomStatus: AtomPlayStatus {
        didSet {
            if atomStatus != oldValue {
                listeners.forEach { $0.value(atomStatus) }
            }
        }
    }
    
    func atomPlay() {
        realPlayer.atomPlay()
        onProgressCheck()
    }
    
    func rangeInfoFor(selectionTime: CMTime) -> (rangeIndex: Int, realOffset: CMTime)? {
        for index in ranges.indices {
            let lastDurationTime = (0..<index).map { ranges[$0].duration }.reduce(.zero, +)
            let meet = selectionTime >= lastDurationTime && selectionTime < lastDurationTime + ranges[index].duration
            if meet {
                return (index, ranges[index].start + selectionTime - lastDurationTime)
            }
        }
        return nil
    }
    
    /// Result for fetch range info with player real time
    enum RealTimeRangeResult {
        /// Time in specific range, and selectionTime
        case range(index: Int, selectionTime: CMTime)
        /// Not in any range. return the latest last range index and the selectionTime represent the end of last range
        case lastRange(index: Int, selectionTime: CMTime)
        case beforeFirstRange
        case invalidInfo
    }
    /// - Returns: success: range Index, failure: last range index
    func rangeIndexFor(realTime: CMTime) -> RealTimeRangeResult {
        if let firstRange = ranges.first, realTime < firstRange.start {
            return .beforeFirstRange
        }
        
        if let index = ranges.firstIndex(where: { $0.containsTime(realTime)}) {
            let lastTotal = (0..<index).map { ranges[$0].duration }.reduce(.zero, +)
            return .range(index: index, selectionTime: lastTotal + realTime - ranges[index].start)
        }
        
        if let index = ranges.lastIndex(where: { $0.end < realTime }) {
            let lastTotal = (0...index).map { ranges[$0].duration }.reduce(.zero, +)
            let isLastIndex = index == ranges.count - 1
            if isLastIndex {
                return .lastRange(index: index, selectionTime: lastTotal)
            }
            let next = ranges[index + 1]
            let delta = realTime - next.start
            if delta > .zero {
                return .lastRange(index: index, selectionTime: lastTotal + delta)
            } else {
                // In valid range
                return .lastRange(index: index, selectionTime: lastTotal)
            }
        }
        
        return .invalidInfo
    }
    
    func atomSeek(time: CMTime, _ completionHandler: @escaping ((Bool) -> Void)) {
        guard time <= totalTime else {
            completionHandler(false)
            return
        }
        
        guard let rangeInfo = rangeInfoFor(selectionTime: time) else {
            completionHandler(false)
            return
        }
        
        realPlayer.atomSeek(time: rangeInfo.realOffset, completionHandler)
    }
    
    let progressCheckInterval: TimeInterval = 0.5
    lazy var timer = Timer(timeInterval: progressCheckInterval, target: self, selector: #selector(onProgressCheck), userInfo: nil, repeats: true)
    
    @objc
    func onProgressCheck() {
        func seekToRangeStart(index: Int) {
            let start = (0..<index).map { ranges[$0].duration }.reduce(.zero, +)
            atomSeek(time: start)
        }
        
        let result = rangeIndexFor(realTime: realPlayer.atomCurrentTime())
        switch result {
        case .beforeFirstRange:
            seekToRangeStart(index: 0)
        case .range, .invalidInfo:
            return
        case .lastRange(index: let lastIndex, _):
            if lastIndex >= ranges.count - 1 {
                realPlayer.atomReady()
                // Stop on the last range
                atomStatus = .ended
            } else {
                seekToRangeStart(index: lastIndex + 1)
            }
        }
    }
    
    func startTimer() {
        timer.fireDate = Date()
    }
    
    func pauseTimer() {
        timer.fireDate = .distantFuture
    }
    
    func atomSetup() {
        RunLoop.current.add(timer, forMode: .common)
        pauseTimer()
        realPlayer.addStatusListener { [weak self] status in
            self?.atomStatus = status
        }
        addStatusListener { [weak self] status in
            switch status {
            case .playing:
                self?.startTimer()
            default:
                self?.pauseTimer()
            }
        }
        realPlayer.atomSetup()
    }

    func atomPause() {
        realPlayer.atomPause()
    }
    
    func atomReady() {
        realPlayer.atomReady()
    }
    
    func atomDestroy() {
        realPlayer.atomDestroy()
    }
    
    func atomCurrentTime() -> CMTime {
        let result = rangeIndexFor(realTime: realPlayer.atomCurrentTime())
        switch result {
        case .range(_, selectionTime: let selectionTime):
            return selectionTime
        case .lastRange(_, selectionTime: let lastRangeSelectionTime):
            return lastRangeSelectionTime
        case .invalidInfo, .beforeFirstRange:
            return .zero
        }
    }
    
    func atomSeek(time: CMTime) {
        atomSeek(time: time, { _ in })
    }
    
    func atomDuration() -> CMTime {
        totalTime
    }
    
    var listeners: [Int: ((AtomPlayStatus) -> Void)] = [:]
    
    @discardableResult
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
}
