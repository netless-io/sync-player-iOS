//
//  AtomPlayer.swift
//  SyncPlayer
//
//  Created by xuyunshi on 2022/5/31.
//

import CoreMedia

/// Abstract for players in SyncPlayer.
/// Any `AtomPlayer` instance can be added to syncPlayer.
///
/// See [AVPlayer + AtomPlayer](AVPlayer + AtomPlayer) to get more about how to adapt your player to `AtomPlayer`
@objc
public protocol AtomPlayer {
    var atomStatus: AtomPlayStatus { get }
    var atomError: Error? { get }
    var readyToPlay: Bool { get }
    var atomPlaybackRate: Float { get set }
    
    func atomPlay()
    func atomPause()
    func atomReady()
    func atomSetup()
    func atomDestroy()
    func atomCurrentTime() -> CMTime
    func atomDuration() -> CMTime
    func atomSeek(time: CMTime)
    func atomSeek(time: CMTime, _ completionHandler: @escaping ((Bool)->Void))
    
    @discardableResult
    func addStatusListener(_ listener: @escaping ((AtomPlayStatus)->Void)) -> AtomListener
}

@objc
public enum AtomPlayStatus: Int {
    /// Video pause.
    /// triggered by program. Indicates the player is ready for other command.
    case ready
    /// User pausing.
    /// Will pauses other players immediately.
    case pause
    /// When player receive play command and start buffering can turn to this status.
    case buffering
    /// Playing now.
    case playing
    /// Player play to end.
    case ended
    /// Some error happened. See atomError to get more information.
    case error
}

@objc
public protocol AtomListener {
    /// Cancel the listening
    func cancel()
}
