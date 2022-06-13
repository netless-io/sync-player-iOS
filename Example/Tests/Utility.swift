import XCTest
import SyncPlayer
import AVFoundation

func createExampleURLAtomPlayer() -> AtomPlayer {
    AVPlayer(url: URL(string: "https://convertcdn.netless.link/1.mp4")!)
}
