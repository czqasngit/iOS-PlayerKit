//
//  LabradorAudioPlayer.m
//  Labrador
//
//  Created by legendry on 2018/8/26.
//  Copyright © 2018 legendry. All rights reserved.
//

#import "LabradorAudioPlayer.h"
#import "LabradorProxyObject.h"

@interface LabradorAudioPlayer()<LabradorInnerPlayerDataProvider>
{
    float                               _seek_time ;
    float                               _timingOffset ;
    NSPort *                            _port ;
    NSThread *                          _decodeAndPlayThread ;
    NSRunLoop *                         _runloop ;
    dispatch_source_t                   _timer ;
    LabradorProxyObject *               _weakProxyObject ;
    BOOL                                _isPrepared ;
   
}
@end
@implementation LabradorAudioPlayer

#pragma mark - LifeCycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        _innerPlayer = [[LabradorInnerPlayer alloc] initWithProvider:self] ;
        _isPrepared = NO ;
        _weakProxyObject = [[LabradorProxyObject alloc] initWithTarget:self] ;
    }
    return self;
}

#pragma mark - Control
- (void)prepare {
    if(_port || _isPrepared) return ;
    _timingOffset = 0 ;
    _seek_time = 0 ;
    _port = [NSPort port] ;
    _decodeAndPlayThread = [[NSThread alloc] initWithTarget:_weakProxyObject selector:@selector(_start) object:nil] ;
    _decodeAndPlayThread.name = @"Play & Decode" ;
    [_decodeAndPlayThread start] ;
}
- (void)reset {
    [self prepare];
}

- (void)play{
    if(_isPrepared) {
        [self.innerPlayer play] ;
        self.playStatus = LabradorAudioPlayerPlayStatusPlaying ;
    }
}
- (void)pause {
    if(self.playStatus == LabradorAudioPlayerPlayStatusPlaying) {
        [self.innerPlayer pause] ;
        self.playStatus = LabradorAudioPlayerPlayStatusPause ;
    }
}
- (void)resume {
    if(self.playStatus == LabradorAudioPlayerPlayStatusPause) {
        [self.innerPlayer resume] ;
        self.playStatus = LabradorAudioPlayerPlayStatusPlaying ;
    }
}
- (void)seek:(float)duration {
    _seek_time = duration ;
    /*self.innerPlayer.playTime 是播放器从开始播放到现在的绝对时间
     每一次seek时要记录下seek的duration位置与当前已播放的绝对时间的差值
     需要注意的是:
     这个播放时间是指实际播放的时间和一般理解上的播放进度是有区别的。
     举个例子，开始播放8秒后用户操作slider把播放进度seek到了第20秒之后又播放了3秒钟，
     此时通常意义上播放时间应该是23秒，即播放进度；而用GetCurrentTime方法中获得的时间为11秒，
     即实际播放时间。
     所以每次seek时都必须保存seek的timingOffset
     */
    _timingOffset = duration - self.innerPlayer.playTime ;
    //decoder seek后,会从新的seek点获取数据
    //decoder可以多次频繁操作
    NSUInteger offset = [self.decoder seek: duration / self.audioInformation.duration * self.audioInformation.audioDataByteCount + self.audioInformation.dataOffset] ;
    //seeking 防止多次对self.innerPlayer进行 reset操作
    //当self.innerPlayer进行过reset并且未恢复正常播放时,没必要多次reset,因为此时播放器已经处理空数据等待状态
    if(!self.innerPlayer.seeking) {
        self.innerPlayer.seeking = YES ;
        //把reset操作交给Play & Decode线程执行,保证self.innerPlayer中的AudioQueueReset完成后才能重新将AudioQueueBufferRef Enqueue新的队列中
        [_runloop performSelector:@selector(reset) target:self.innerPlayer argument:nil order:0 modes:@[NSRunLoopCommonModes]] ;
    }
    //数据提供器才是seek的关键
    //data provider seek后,会生新的点开始下载数据
    //data provider 可以多次频繁操作
    [self.dataProvider seek:offset] ;
}
- (void)stop {
    dispatch_cancel(_timer);
    self.playStatus = LabradorAudioPlayerPlayStatusStop ;
    [self.innerPlayer stop] ;
    [self.dataProvider stop] ;
    [self.decoder stop] ;
    [_decodeAndPlayThread cancel] ;
    [self.innerPlayer dispose] ;
    if(_runloop) {
        [_runloop removePort:_port forMode:NSDefaultRunLoopMode] ;
        CFRunLoopStop([_runloop getCFRunLoop]) ;
    }
    _port = nil ;
    _runloop = nil ;
    _decodeAndPlayThread = nil ;
    
    _isPrepared = NO ;
    self.innerPlayer = [[LabradorInnerPlayer alloc] initWithProvider:self] ;
    _weakProxyObject = [[LabradorProxyObject alloc] initWithTarget:self] ;
    
}
#pragma mark - Property
- (float)duration {
    return self.audioInformation.duration;
}
- (float)currentPlayTime {
    //当前播放时间为播放器绝对播放时间与seek后的差值的和
    float _currentPlayTime = self.innerPlayer.playTime + _timingOffset;
    return _currentPlayTime;
}
- (void)playTime {
    if(self.playStatus != LabradorAudioPlayerPlayStatusPlaying ||
       self.innerPlayer.isSeeking) return ;
    float _current_play_time = ceilf([self currentPlayTime]) ;
    
    if(self.delegate &&
       [self.delegate respondsToSelector:@selector(labradorAudioPlayerPlaying:playTime:)] &&
       self.playStatus == LabradorAudioPlayerPlayStatusPlaying) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate labradorAudioPlayerPlaying:self playTime:_current_play_time] ;
        });
    }
    if(_current_play_time >= self.duration) {
        if(self.delegate && [self.delegate respondsToSelector:@selector(labradorAudioPlayerDidFinishPlaying:successful:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate labradorAudioPlayerDidFinishPlaying:self successful:YES] ;
            });
        }
        [self stop] ;
    }
}


#pragma mark - LabradorInnerPlayerDataProvider
- (LabradorAudioFrame *)nextFrame:(BOOL)seeking {
    return [self.decoder product:seeking]  ;
}

#pragma mark - Private Method
- (void)_start {
    NSAssert(self.decoder && self.dataProvider, @"Decoder & Data Provider can't be nil,please call initializeWithDecoder:dataProvider: initialize") ;
    _runloop = [NSRunLoop currentRunLoop] ;
    [_runloop addPort:_port forMode:NSDefaultRunLoopMode] ;
    [self.decoder initialize] ;
    self.playStatus = LabradorAudioPlayerPlayStatusWaiting ;
    
    [self.innerPlayer configureDescription:[self.decoder audioInformation].description] ;
    __weak typeof(self) _weak_self = self ;
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(_timer, ^{
        __strong typeof(_weak_self) _strong_self = _weak_self ;
        [_strong_self playTime] ;
    });
    dispatch_resume(_timer);
    [self _prepareForPlay] ;
    
    [_runloop run] ;
}

- (void)_prepareForPlay {
    _isPrepared = YES ;
    if(self.delegate && [self.delegate respondsToSelector:@selector(labradorAudioPlayerPrepared:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self playTime] ;
            [self.delegate labradorAudioPlayerPrepared:self] ;
        });
    }
}

- (void)_someErrorHappend:(NSError *)error {
    if(self.delegate && [self.delegate respondsToSelector:@selector(labradorAudioPlayerWithError:player:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate labradorAudioPlayerWithError:error player:self] ;
        });
    }
}

#pragma mark - LabradorDataProviderDelegate
- (void)statusChanged:(LabradorCacheStatus)newStatus {
    self.loadingStatus = newStatus ;
    switch (newStatus) {
        case LabradorCacheStatusLoading:
            if(self.delegate && [self.delegate respondsToSelector:@selector(labradorAudioPlayerLoading:)]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate labradorAudioPlayerLoading:self] ;
                });
            }
            [self pause] ;
            break ;
        case LabradorCacheStatusEnough:
            if(self.delegate && [self.delegate respondsToSelector:@selector(labradorAudioPlayerResumePlayFromLoading:)]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate labradorAudioPlayerResumePlayFromLoading:self] ;
                });
            }
            [self resume] ;
            break ;
    }
}
- (void)loadingPercent:(float)percent {
    if(self.delegate && [self.delegate respondsToSelector:@selector(labradorAudioPlayerCachingPercent:percent:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate labradorAudioPlayerCachingPercent:self percent:percent] ;
        });
    }
}
- (void)onError:(NSError *)error {
    [self _someErrorHappend:error] ;
}
#pragma mark - LabradorDecodableDelegate
- (NSInteger)getBytes:(void *)bytes
                  size:(NSUInteger)size
                offset:(NSUInteger)offset
                  type:(DownloadType)type {
    return [_dataProvider getBytes:bytes size:size offset:offset type:type] ;
}
- (void)prepared:(LabradorAudioInformation)information {
    _audioInformation = information ;
    [_dataProvider prepared:information] ;
}

@end
