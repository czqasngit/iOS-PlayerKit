# Labrador

[![Version](https://img.shields.io/cocoapods/v/Rambo.svg?style=flat)](https://cocoapods.org/pods/Labrador)
[![License](https://img.shields.io/cocoapods/l/Rambo.svg?style=flat)](https://cocoapods.org/pods/Labrador)
[![Platform](https://img.shields.io/cocoapods/p/Rambo.svg?style=flat)](https://cocoapods.org/pods/Labrador)

![timg](http://pba6dsu9x.bkt.clouddn.com/timg.jpeg)


A complete audio player with a modular design that can be replaced with different components to suit different needs. A decoder and two data providers have been implemented
一个完整的音频播放器,采用了组件化的设计,可按需要替换不同的组件以适应不同的需求。目前已经实现了一个解码器和两个数据提供器



## Extensions
1.The decoder can use FFmpeg to support more formats

2.Data provider can be based on Samba with FTP or more

1.解码器可以使用FFmpeg来支持更多格式

2.Data提供程序可以基于Samba和FTP或更多


## Futues
1.Local file play

2.Network stream play and cache

3.Segmentation cache

1.本地文件播放

2.网络文件播放

3.分段缓存

## Usage(Objective-C)

```
- (IBAction)play:(id)sender {
    if(_player) {
        [_player prepare] ;
    return;
    }
    _player = [[LabradorHTTPAudioPlayer alloc] initWithURLString:@""] ;
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
```

```
- (void)labradorAudioPlayerPrepared:(LabradorAudioPlayer *)player ;
- (void)labradorAudioPlayerWithError:(NSError *)error player:(LabradorAudioPlayer *)player ;
- (void)labradorAudioPlayerDidFinishPlaying:(LabradorAudioPlayer *)player successfully:(BOOL)successfully ;
- (void)labradorAudioPlayerPlaying:(LabradorAudioPlayer *)player playTime:(float)playTime ;
- (void)labradorAudioPlayerCachingPercent:(LabradorAudioPlayer *)player percent:(float)percent ;
- (void)labradorAudioPlayerLoading:(LabradorAudioPlayer *)player ;
- (void)labradorAudioPlayerResumePlayFromLoading:(LabradorAudioPlayer *)player ;
```
## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

Labrador is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Labrador'
```

## Author

czqasn, czqasn_6@163.com

## License

Labrador is available under the MIT license. See the LICENSE file for more info.


