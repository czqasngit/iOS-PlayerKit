//
//  LabradorInnerPlayer.m
//  Labrador
//
//  Created by legendry on 2018/8/8.
//  Copyright © 2018 legendry. All rights reserved.
//

#import "LabradorInnerPlayer.h"
#import "configure.h"

@interface LabradorInnerPlayer()
{
    AudioStreamBasicDescription _asbd ;
    AudioQueueRef _aqr;
    CFMutableArrayRef _buffers ;
    NSRunLoop *_runloop;
}

@property (nonatomic, weak)id<LabradorInnerPlayerDataProvider> dataProvider ;


- (void)_enqueue:(AudioQueueBufferRef)inBuffer seeking:(BOOL)seeking;
- (void)_enqueue:(AudioQueueBufferRef)inBuffer ;
- (void)_audioQueueOutputCallback:(AudioQueueBufferRef)inBuffer;
@end


static void Labrador_AudioQueueOutputCallback(void * __nullable       inUserData,
                                       AudioQueueRef           inAQ,
                                       AudioQueueBufferRef     inBuffer){
    LabradorInnerPlayer *this = (__bridge LabradorInnerPlayer *)inUserData ;
    [this _audioQueueOutputCallback:inBuffer] ;
}

@implementation LabradorInnerPlayer

- (void)dealloc
{
    [self dispose] ;
    NSLog(@"LabradorInnerPlayer") ;
}
- (instancetype)initWithProvider:(id<LabradorInnerPlayerDataProvider>)provider
{
    self = [super init];
    if (self) {
        _dataProvider = provider ;
        self.seeking = false ;
    }
    return self;
}

- (void)configureDescription:(AudioStreamBasicDescription)description {
    _buffers = CFArrayCreateMutable(CFAllocatorGetDefault(), 0, NULL) ;
    _asbd = description ;
    [self initializeAudioQueue] ;
}

- (void)initializeAudioQueue {
    _runloop = [NSRunLoop currentRunLoop] ;
    OSStatus status = AudioQueueNewOutput(&_asbd,
                                          Labrador_AudioQueueOutputCallback,
                                          (__bridge void *)self,
                                          [_runloop getCFRunLoop],
                                          kCFRunLoopCommonModes,
                                          0,
                                          &_aqr);
    if(status != noErr) {
        NSLog(@"AudioQueueNewOutput error: %d", (int)status) ;
        AudioQueueDispose(_aqr, YES) ;
        return ;
    }
    
    for(int i = 0; i < 3; i ++) {
        AudioQueueBufferRef buffer = NULL ;
        status = AudioQueueAllocateBuffer(_aqr, LabradorAudioQueueBufferCacheSize * 2, &buffer) ;
        if(status != noErr) {
            NSLog(@"AudioQueueAllocateBuffer error: %d", (int)status) ;
            AudioQueueDispose(_aqr, YES) ;
            break ;
        }
        CFArrayAppendValue(_buffers, buffer) ;
        [self _enqueue:buffer] ;
    }
}


#pragma mark - Control
- (void)play{
    AudioQueueStart(_aqr, NULL) ;
}
- (void)pause {
    AudioQueuePause(_aqr) ;
}
- (void)resume {
    AudioQueueStart(_aqr, NULL) ;
}
- (void)stop {
    AudioQueueStop(_aqr, YES) ;
}
- (void)dispose {
    if(!_aqr) return ;
    for(int i = 0; i < CFArrayGetCount(_buffers); i ++) {
        AudioQueueFreeBuffer(_aqr, (AudioQueueBufferRef)CFArrayGetValueAtIndex(_buffers, i));
    }
    CFArrayRemoveAllValues(_buffers) ;
    CFRelease(_buffers);
    AudioQueueDispose(_aqr, YES) ;
    _aqr = nil ;
    
}
- (void)reset {
    AudioQueueStop(_aqr, YES) ;
    //重置
    AudioQueueReset(self->_aqr) ;
    //将Buffer 重新 Enqueue(必须保证AudioQueueReset操作完成并完全回收Buffer后再可以进行)
    for(int i = 0; i < 3; i ++) {
        [self _enqueue:(AudioQueueBufferRef)CFArrayGetValueAtIndex(self->_buffers, i) seeking: i == 0] ;
    }
    //重新恢复播放状态
    AudioQueueStart(_aqr, NULL) ;
    //重置seeking状态
    self.seeking = NO ;
}

#pragma mark - AudioQueue Callback
- (void)_audioQueueOutputCallback:(AudioQueueBufferRef)inBuffer {
    if(!self.isSeeking) {
        [self _enqueue:inBuffer] ;
    }
}

#pragma mark - Private Method
- (void)_enqueue:(AudioQueueBufferRef)inBuffer {
    [self _enqueue:inBuffer seeking:NO] ;
}
- (void)_enqueue:(AudioQueueBufferRef)inBuffer seeking:(BOOL)seeking {
    LabradorAudioFrame *frame = [self.dataProvider nextFrame:seeking] ;
    if(frame) {
        UInt32 offset = 0 ;
        AudioStreamPacketDescription *aspds = (AudioStreamPacketDescription *)malloc(sizeof(AudioStreamPacketDescription) * frame.packets.count) ;
        for(int i = 0; i < frame.packets.count; i ++) {
            LabradorAudioPacket *packet = frame.packets[i] ;
            memcpy(inBuffer->mAudioData + offset,
                   packet.data,
                   packet.byteSize) ;
            memcpy(aspds + i, packet.packetDescription, sizeof(AudioStreamPacketDescription)) ;
            offset += packet.byteSize ;
        }
        inBuffer->mAudioDataByteSize = offset ;
        inBuffer->mPacketDescriptionCount = (UInt32)frame.packets.count ;
        OSStatus status = AudioQueueEnqueueBuffer(_aqr,
                                                  inBuffer,
                                                  (UInt32)frame.packets.count,
                                                  aspds) ;
        if(status != noErr) {
            NSLog(@"AudioQueueEnqueueBuffer error: %d", (int)status) ;
        }
        free(aspds) ;
    }
}

#pragma mark - Property
- (float)playTime {
    AudioTimeStamp stamp;
    AudioQueueGetCurrentTime(_aqr, NULL, &stamp, NULL);
    float time = stamp.mSampleTime / _asbd.mSampleRate ;
    return time ;
}
@end
