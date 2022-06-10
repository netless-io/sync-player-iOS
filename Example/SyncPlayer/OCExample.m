//
//  OC.m
//  SyncPlayer_Example
//
//  Created by xuyunshi on 2022/6/10.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "OCExample.h"
#import "WhitePlayer.h"
#import "SyncPlayer_Example-Swift.h"

@import SyncPlayer;

@implementation OCExample

+ (void)startOCWhiteFrom:(UIViewController *)from {
    WhiteBoardView *view = [[WhiteBoardView alloc] init];
    WhiteSdkConfiguration *config = [[WhiteSdkConfiguration alloc] initWithApp:@"283/VGiScM9Wiw2HJg"];
    WhiteSDK *sdk = [[WhiteSDK alloc] initWithWhiteBoardView:view config:config commonCallbackDelegate:nil];
    WhitePlayerConfig *playConfig = [[WhitePlayerConfig alloc] initWithRoom:@"65fc0e10e15511ec92dce3bcde27b589" roomToken:@"WHITEcGFydG5lcl9pZD15TFExM0tTeUx5VzBTR3NkJnNpZz03YzQwZDZjNDVhY2NkMTJlN2IyYjg4OTYwM2UzZWZlNDMxZTE1NTk3OmFrPXlMUTEzS1N5THlXMFNHc2QmY3JlYXRlX3RpbWU9MTY1NDA1MTc0NDQyOSZleHBpcmVfdGltZT0xNjg1NTg3NzQ0NDI5Jm5vbmNlPTE2NTQwNTE3NDQ0MjkwMCZyb2xlPXJvb20mcm9vbUlkPTY1ZmMwZTEwZTE1NTExZWM5MmRjZTNiY2RlMjdiNTg5JnRlYW1JZD05SUQyMFBRaUVldTNPNy1mQmNBek9n"];
    [sdk createReplayerWithConfig:playConfig callbacks:nil completionHandler:^(BOOL success, WhitePlayer * _Nullable player, NSError * _Nullable error) {
        
        
        AVPlayer *avPlayer = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:@"https://convertcdn.netless.link/1.mp4"]];
        VideoPreviewView *preView = [[VideoPreviewView alloc] init];
        ((AVPlayerLayer *)preView.layer).videoGravity = AVVideoScalingModeResizeAspectFill;
        ((AVPlayerLayer *)preView.layer).player = avPlayer;
        VideoPlayerView *playerView = [[VideoPlayerView alloc] initWithPreview:preView];
        
        __weak typeof(avPlayer) weakPlayer = avPlayer;
        __weak typeof(playerView) weakPlayerView = playerView;
        [player addStatusListener:^(enum AtomPlayStatus status) {
            if (status == AtomPlayStatusError) {
                weakPlayerView.statusLabel.text = [NSString stringWithFormat:@"player status: %@", weakPlayer.atomError.localizedDescription];
            } else {
                weakPlayerView.statusLabel.text = [NSString stringWithFormat:@"player status: %ld", (long)status];
            }
        }];
        
        player = (WhitePlayer *)[AtomPlayerOperation selectionWithPlayer:player ranges:@[
            [NSValue valueWithCMTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(3.5, 1000), CMTimeMakeWithSeconds(20, 1000))]
        ]];
        VideoPlayerView *whitePreview = [[VideoPlayerView alloc] initWithPreview:view];
        __weak typeof(whitePreview) weakWhitePreview = whitePreview;
        __weak typeof(player) weakWhite = player;
        [player addStatusListener:^(enum AtomPlayStatus status) {
            if (status == AtomPlayStatusError) {
                weakWhitePreview.statusLabel.text = [NSString stringWithFormat:@"player status: %@", weakWhite.atomError.localizedDescription];
            } else {
                weakWhitePreview.statusLabel.text = [NSString stringWithFormat:@"player status: %ld", (long)status];
            }
        }];
        
        ExamplePlayerViewController *vc = [[ExamplePlayerViewController alloc] initWithPlayer1:avPlayer view1:playerView player2:player view2:whitePreview];
        [from presentViewController:vc animated:YES completion:nil];
    }];
}

@end
