//
//  LabradorViewController.m
//  Labrador
//
//  Created by czqasngit on 08/27/2018.
//  Copyright (c) 2018 czqasngit. All rights reserved.
//

#import "LabradorViewController.h"
#import <Labrador/Labrarod.h>

@interface LabradorViewController ()
{
    LabradorAudioPlayer *_player ;
}
@end

@implementation LabradorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor orangeColor] ;
}

- (IBAction)play:(id)sender {
    if(_player) {
        [_player reset] ;
        return;
    }
    _player = [[LabradorHTTPAudioPlayer alloc] initWithURLString:@"http://audio01.dmhmusic.com/133_48_T10022565790_320_1_1_0_sdk-cpm/0105/M00/67/84/ChR45FmNKxKAMbUaAKtt4_FdDfk806.mp3?xcode=2644ab9d7ace31a031b92b02616b9f0ad6c8eef"] ;
    //    _player = [[LabradorLocalAudioPlayer alloc] init] ;
    _player.delegate = self ;
    [_player prepare] ;
}
- (IBAction)pause:(id)sender {
    [_player pause] ;
}
- (IBAction)resume:(id)sender {
    [_player resume] ;
}

- (IBAction)stop:(id)sender {
    [_player stop] ;
}



- (void)sliderValueChanged:(UISlider *)slider {
    [_player seek:slider.value] ;
}

#pragma mark -
- (void)labradorAudioPlayerPrepared:(LabradorHTTPAudioPlayer *)player {
    NSLog(@"-------------准备完成,可以播放了") ;
    _slider.minimumValue = 0 ;
    _slider.maximumValue = player.duration ;
    [_player play] ;
}
- (void)labradorAudioPlayerWithError:(NSError *)error player:(LabradorHTTPAudioPlayer *)player {
    NSLog(@"[使用]发生错误: %@", error) ;
}
- (void)labradorAudioPlayerPlaying:(LabradorHTTPAudioPlayer *)player playTime:(float)playTime {
    NSLog(@"播放时间: %f", playTime) ;
    _slider.value = playTime ;
}
- (void)labradorAudioPlayerCachingPercent:(LabradorHTTPAudioPlayer *)player percent:(float)percent {
    NSLog(@"缓存百分比: %f", percent) ;
}

- (void)labradorAudioPlayerLoading:(LabradorHTTPAudioPlayer *)player {
    NSLog(@"[使用]正在加载...") ;
}

- (void)labradorAudioPlayerResumePlayFromLoading:(LabradorHTTPAudioPlayer *)player {
    NSLog(@"[使用]从加载中恢复播放...") ;
}

- (void)labradorAudioPlayerDidFinishPlaying:(LabradorHTTPAudioPlayer *)player successful:(BOOL)successful {
    NSLog(@"播放完成: %d", successful) ;
}
@end
