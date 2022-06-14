# SyncPlayer

支持同时播放任意多个播放源的 iOS 协同播放器。

各个播放器的播放进度，播放速率会被同步。当最长的播放源播放结束时，协同播放器才结束。

<img src="./example.gif"></img>

## 概述

 `AtomPlayer` 是子播放器需要遵循的协议。
  
- 默认支持 `AVPlayer` 。
- 支持 Netless 白板播放器，如需使用可以通过 `pod 'Whiteboard/SyncPlayer'` 引入对应的代码。
- 支持自定义视频播放器的接入，只需播放器遵循 `AtomPlayer` 协议。

## 安装
cocoapods

```ruby
pod 'SyncPlayer'
```

## 使用方式
``` Swift
let someAVPlayer = AVPlayer(url: ...)
let otherAVPlayer = AVPlayer(url: ...)
let player = SyncPlayer(players: [someAVPlayer, otherAVPlayer])
player.play()
```

## 视频处理

允许对播放源进行额外处理，方便不同视频之间的内容协同。目前支持 Offset 与 selection 。

### Offset
在视频开始前，插入一段指定时长的空白内容。

`AtomPlayer` 调用 `offset(time:CMTime)` 方法即可生成一个带 Offset 的 `AtomPlayer`。

Swift
``` Swift
someAtomPlayer.offset(time: someOffsetTime)
```

Obejctive-C
``` Objective-C
[AtomPlayerOperation offset: someAtomPlayer time: someCMTime]
```

### Selection
节选视频的片段，只有节选片段中内容会被播放。

`AtomPlayer` 调用 `selection(ranges:[CMTimeRange])` 方法即可生成一个带 Selection 的 `AtomPlayer`。

Swift
``` Swift
someAtomPlayer.selection(ranges: someRanges)
```

Obejctive-C
``` Objective-C
[AtomPlayerOperation selectionWithPlayer:someAtomPlayer ranges: someRanges]
```

### 注意
offset 和 selection 每个视频源建议只操作一次。

对同一视频多次操作的情况暂不在考虑内。

offset只能为正数。
