//
//  OffsetPlayer.swift
//  SyncPlayer
//
//  Created by xuyunshi on 2022/6/1.
//

import CoreMedia
import AVFoundation

class OffsetPlayer: AtomPlayer {
    var realPlayer: AtomPlayer
    var fakePlayer: AtomPlayer!
    var fakePlayerUrl: URL!
    let offset: CMTime
    
    var didSetupFakeVideo = false
    var isFakeVideoEnded = false
    var isCurrentInFake = true
    
    init(realPlayer: AtomPlayer, offset: CMTime) {
        self.offset = offset
        self.realPlayer = realPlayer
        self.atomStatus = .ready
        self.generateFakeVideo()
    }
    
    func generateFakeVideo() {
        self.fakePlayerUrl = generateEmptyVideo(time: offset, completionHandler: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let url):
                self.fakePlayer = AVPlayer(url: url)
                self.delayedSetup()
            case .failure(let error):
                self.atomError = error
                self.atomStatus = .error
            }
        })
    }
    
    func deleteFakeVideo() {
        if FileManager.default.fileExists(atPath: fakePlayerUrl.path) {
            do {
                log("remove offset url")
                try FileManager.default.removeItem(at: fakePlayerUrl)
            }
            catch {
                log("remove offset url fail")
            }
        }
    }
    
    var atomStatus: AtomPlayStatus {
        didSet {
            if atomStatus != oldValue {
                listeners.forEach { $0.value(atomStatus) }
            }
        }
    }
    
    var listeners: [Int: ((AtomPlayStatus) -> Void)] = [:]

    var atomError: Error?

    var readyToPlay: Bool {
        guard didSetupFakeVideo else {
            return false
        }
        if atomCurrentTime() < offset { return fakePlayer.readyToPlay }
        return realPlayer.readyToPlay
    }

    var atomPlaybackRate: Float {
        get { realPlayer.atomPlaybackRate }
        set {
            fakePlayer.atomPlaybackRate = newValue
            realPlayer.atomPlaybackRate = newValue
        }
    }
    
    var workAfterFakeVideoSetup: (()->Void)?

    func atomPlay() {
        guard didSetupFakeVideo else {
            atomStatus = .buffering
            workAfterFakeVideoSetup = atomPlay
            return
        }
        if isCurrentInFake {
            fakePlayer.atomPlay()
        } else {
            realPlayer.atomPlay()
        }
    }

    func atomPause() {
        guard didSetupFakeVideo else {
            atomStatus = .pause
            workAfterFakeVideoSetup = atomPause
            return
        }
        if isCurrentInFake {
            fakePlayer.atomPause()
        } else {
            realPlayer.atomPause()
        }
    }
    
    func atomReady() {
        guard didSetupFakeVideo else {
            atomStatus = .ready
            workAfterFakeVideoSetup = atomReady
            return
        }
        if isCurrentInFake {
            fakePlayer.atomReady()
        } else {
            realPlayer.atomReady()
        }
    }

    func atomSetup() {
        // Do nothing on sync setup
    }
    
    func delayedSetup() {
        fakePlayer.atomSetup()
        realPlayer.atomSetup()
        realPlayer.addStatusListener { [weak self] status in
            guard let self = self else { return }
            switch status {
            case .ready, .pause, .buffering, .playing, .ended:
                self.atomStatus = status
            case .error:
                self.atomError = self.realPlayer.atomError
                self.atomStatus = .error
            }
        }
        
        fakePlayer.addStatusListener { [weak self] status in
            guard let self = self else { return }
            switch status {
            case .ready, .pause, .buffering, .playing:
                self.atomStatus = status
            case .ended:
                self.atomSeek(time: self.offset)
                self.realPlayer.atomPlay()
            case .error:
                self.atomError = self.fakePlayer.atomError
                self.atomStatus = .error
            }
        }
        didSetupFakeVideo = true
        workAfterFakeVideoSetup?()
    }

    func atomDestroy() {
        deleteFakeVideo()
        realPlayer.atomDestroy()
    }

    func atomCurrentTime() -> CMTime {
        guard didSetupFakeVideo else { return kCMTimeZero }
        return isCurrentInFake ? fakePlayer.atomCurrentTime() : realPlayer.atomCurrentTime() + offset
    }

    func atomDuration() -> CMTime {
        let time = realPlayer.atomDuration()
        if time.isValid {
            return time + offset
        }
        return kCMTimeInvalid
    }

    func atomSeek(time: CMTime) {
        atomSeek(time: time, { _ in})
    }

    func atomSeek(time: CMTime, _ completionHandler: @escaping ((Bool) -> Void)) {
        guard didSetupFakeVideo else {
            workAfterFakeVideoSetup = { [weak self] in
                self?.atomSeek(time: time, completionHandler)
            }
            return
        }
        
        let isSeekingToReal = time >= offset
        switch (isCurrentInFake, isSeekingToReal) {
        case (true, false):
            // fake to fake
            fakePlayer.atomSeek(time: time, completionHandler)
        case (false, true):
            // real to real
            realPlayer.atomSeek(time: time - offset, completionHandler)
        case (true, true):
            // fake to real
            fakePlayer.atomReady()
            realPlayer.atomSeek(time: time - offset, completionHandler)
            isCurrentInFake = false
        case (false, false):
            // real to fake
            realPlayer.atomReady()
            fakePlayer.atomSeek(time: time, completionHandler)
            isCurrentInFake = true
        }
    }

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

fileprivate func generateEmptyVideo(time: CMTime, completionHandler: @escaping ((Result<URL, Error>)->Void)) -> URL {
    var path = URL(fileURLWithPath: NSTemporaryDirectory())
    path.appendPathComponent(UUID().uuidString + ".mov")
    let writer = try! AVAssetWriter(url: path, fileType: .mov)
    let outputSettings = AVOutputSettingsAssistant(preset: .preset640x480)?.videoSettings
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input)
    writer.add(input)
    writer.startWriting()
    writer.startSession(atSourceTime: kCMTimeZero)
    var pixelBuffer: CVPixelBuffer?
    let pixelCreateReturn = CVPixelBufferCreate(kCFAllocatorDefault,
                                                640,
                                                480,
                                                kCVPixelFormatType_24RGB,
                                                nil,
                                                &pixelBuffer)
    guard let pixelBuffer = pixelBuffer else {
        DispatchQueue.main.async {
            completionHandler(.failure(NSError(domain: "offSetPlayer.createPixelBuffer", code: Int(pixelCreateReturn))))
        }
        return path
    }
    adaptor.append(pixelBuffer, withPresentationTime: time)
    input.markAsFinished()
    writer.finishWriting {
        if writer.status == .completed {
            completionHandler(.success(path))
        } else {
            completionHandler(.failure(NSError(domain: "offSetPlayer.finishWriting", code: writer.status.rawValue)))
        }
    }
    return path
}
