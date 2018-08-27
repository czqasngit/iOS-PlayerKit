//
//  LabradorDecoder.m
//  Labrador
//
//  Created by legendry on 2018/8/8.
//  Copyright © 2018 legendry. All rights reserved.
//

#import "LabradorDecoder.h"
#import <AudioToolbox/AudioToolbox.h>
#import "LabradorAudioPacket.h"
#import "configure.h"
#import "LabradorQueue.h"

@interface LabradorDecoder()
{
    AudioFileStreamID _audioFileStreamID ;
    LabradorAudioInformation _audioInformation ;
    
}
@property(nonatomic, weak)id<LabradorDecodableDelegate> delegate ;
@property(nonatomic, assign)UInt32 dataOffset ;
@property(nonatomic, strong)LabradorQueue *frames ;
@property(nonatomic, assign)UInt32 frameByteSize ;
@property(nonatomic, assign)float duration;
@property(nonatomic, assign)SInt64 startOffset;
@property(nonatomic, assign)UInt32 bitRate ;
@property(nonatomic, assign)UInt64 totalByteSize ;

- (void)decodeForPropertyID:(AudioFilePropertyID)pid ;
- (void)decodePacketWithInNumberBytes:(UInt32)inNumberBytes
                          inNumberPackets:(UInt32)inNumberPackets
                              inInputData:(const void *)inInputData
                     inPacketDescriptions:(AudioStreamPacketDescription *)inPacketDescriptions ;
@end

NS_INLINE void _GetAudioFileStreamPropertyValue(AudioFileStreamID sid, AudioFileStreamPropertyID spid, void *pointer, UInt32 size) {
    AudioFileStreamGetProperty(sid, spid, &size, pointer) ;
}
/*
 AudioStreamBasicDescription description ;
 SInt64 dataOffset ;
 UInt64 audioDataByteCount ;
 UInt32 bitRate ;
 UInt64 audioDataPacketCount ;
 float duration ;
 */
NS_INLINE void _PrintLabradorAudioInformation(LabradorAudioInformation information){
    NSLog(@"") ;
    NSLog(@"===========================================================================") ;
    NSLog(@"") ;
    NSLog(@"-------------------- Audio Stream Basic Information -----------------------") ;
    NSLog(@"Druation: %f", information.duration) ;
    NSLog(@"BitRate: %u", information.bitRate) ;
    NSLog(@"Audio Data Start Offset: %lld", information.dataOffset) ;
    NSLog(@"Audio Data Total Size: %lld", information.audioDataByteCount + information.dataOffset) ;
    NSLog(@"Audio Data Packets Count: %lld", information.audioDataPacketCount) ;
    NSLog(@"") ;
    NSLog(@"===========================================================================") ;
    NSLog(@"") ;
}

NS_INLINE void _PropertyListenerProc(void *                             inClientData,
                                     AudioFileStreamID                  inAudioFileStream,
                                     AudioFileStreamPropertyID          inPropertyID,
                                     AudioFileStreamPropertyFlags       *ioFlags){
    LabradorDecoder *this = (__bridge LabradorDecoder *)inClientData ;
    [this decodeForPropertyID:inPropertyID] ;
}
NS_INLINE void _PacketsProc(void *                              inClientData,
                            UInt32                              inNumberBytes,
                            UInt32                              inNumberPackets,
                            const void *                        inInputData,
                            AudioStreamPacketDescription        *inPacketDescriptions){
    LabradorDecoder *this = (__bridge LabradorDecoder *)inClientData ;
    [this decodePacketWithInNumberBytes:inNumberBytes inNumberPackets:inNumberPackets inInputData:inInputData inPacketDescriptions:inPacketDescriptions] ;
}


@implementation LabradorDecoder

- (void)dealloc
{
    NSLog(@"LabradorDecoder") ;
    AudioFileStreamClose(_audioFileStreamID);
}

- (instancetype)init:(id<LabradorDecodableDelegate>)delegate
{
    self = [super init];
    if (self) {
        NSAssert(delegate != NULL, @"LABAudioDataProviderProtocol can't be NULL.") ;
        self.frameByteSize = 0 ;
        self.delegate = delegate ;
        self.dataOffset = 0 ;
        self.frames = [[LabradorQueue alloc] init];
        OSStatus status = AudioFileStreamOpen((__bridge void *)self,
                                              _PropertyListenerProc,
                                              _PacketsProc,
                                              kAudioFileMP3Type,
                                              &_audioFileStreamID) ;
        if(status != noErr) {
            NSLog(@"Error: %d", status) ;
            return nil ;
        }
        
    }
    return self;
}

- (void)initialize {
    uint32_t byte_size = LabradorAudioHeaderInputSize ;
    void *bytes = malloc(byte_size) ;
    //从数据提供器中读取指定的字节来解析头信息
    NSUInteger read_size = [self.delegate getBytes:bytes size:byte_size offset:0 type:DownloadTypeHeader] ;
    OSStatus status = AudioFileStreamParseBytes(_audioFileStreamID, (UInt32)read_size, bytes, 0) ;
    free(bytes) ;
    self.dataOffset += (UInt32)read_size ;
    if(status != noErr) {
        NSLog(@"Error: %d", status) ;
//        return nil ;
    }
}

- (void)decodeForPropertyID:(AudioFilePropertyID)pid {
    switch (pid) {
        case kAudioFileStreamProperty_DataFormat:
            _GetAudioFileStreamPropertyValue(_audioFileStreamID, pid, &_audioInformation.description, sizeof(AudioStreamBasicDescription)) ;
            break;
        case kAudioFileStreamProperty_ReadyToProducePackets:
        {
            //音频播放器需要的数据信息已经准备完成
            _audioInformation.duration = _audioInformation.audioDataByteCount * 8 / _audioInformation.bitRate ;
            _audioInformation.totalSize = _audioInformation.audioDataByteCount + _audioInformation.dataOffset ;
            if(self.delegate && [self.delegate respondsToSelector:@selector(prepared:)]) {
                [self.delegate prepared:_audioInformation] ;
            }
            _PrintLabradorAudioInformation(_audioInformation) ;
        }
            break ;
        case kAudioFileStreamProperty_DataOffset:
            _GetAudioFileStreamPropertyValue(_audioFileStreamID, pid, &_audioInformation.dataOffset, sizeof(SInt64)) ;
            break ;
        case kAudioFileStreamProperty_AudioDataByteCount:
            _GetAudioFileStreamPropertyValue(_audioFileStreamID, pid, &_audioInformation.audioDataByteCount, sizeof(UInt64)) ;
            break ;
        case kAudioFileStreamProperty_BitRate:
            _GetAudioFileStreamPropertyValue(_audioFileStreamID, pid, &_audioInformation.bitRate, sizeof(UInt32)) ;
            break ;
        case kAudioFileStreamProperty_AudioDataPacketCount:
            _GetAudioFileStreamPropertyValue(_audioFileStreamID, pid, &_audioInformation.audioDataPacketCount, sizeof(UInt64)) ;
            break ;
        default:
            break;
    }
}

- (void)decodePacketWithInNumberBytes:(UInt32)inNumberBytes
                      inNumberPackets:(UInt32)inNumberPackets
                          inInputData:(const void *)inInputData
                 inPacketDescriptions:(AudioStreamPacketDescription *)inPacketDescriptions {
    NSMutableArray<LabradorAudioPacket *> *tmps = [[NSMutableArray<LabradorAudioPacket *> alloc] init] ;
    for(int i = 0; i < inNumberPackets; i ++) {
        AudioStreamPacketDescription tmp = inPacketDescriptions[i] ;
        LabradorAudioPacket *packet = [[LabradorAudioPacket alloc] initWithAudioData:inInputData
                                                                        descriptions:tmp] ;
        [tmps addObject:packet] ;
    }
    LabradorAudioFrame *frame = [[LabradorAudioFrame alloc] initWithPackets:tmps]  ;
    [self.frames push:frame];
    self.frameByteSize += frame.byteSize ;
}

- (LabradorAudioFrame *)product:(BOOL)seeking {
    while (self.frames.size <= 0) {
        NSUInteger byte_size = LabradorAudioQueueBufferCacheSize  ;
        void *bytes = malloc(byte_size) ;
        NSUInteger size = [self.delegate getBytes:bytes size:byte_size offset:self.dataOffset type:DownloadTypeAudioData] ;
        if(size == -1) {
            break ;
        }
        AudioFileStreamParseBytes(_audioFileStreamID, (UInt32)size, bytes, seeking ? kAudioFileStreamParseFlag_Discontinuity : 0) ;
        self.dataOffset += (UInt32)size ;
        free(bytes) ;
    }
    LabradorAudioFrame *frame = [self.frames pop] ;
    if(frame) {
        self.frameByteSize -= frame.byteSize ;
    }
    return frame ;
}

- (NSUInteger)seek:(UInt32)offset {
    SInt64 inPacketOffset = ceil(offset * 1.0 / _audioInformation.audioDataByteCount * _audioInformation.audioDataPacketCount) ;
    SInt64 outDataByteOffset = 0 ;
    AudioFileStreamSeekFlags flags  ;
    AudioFileStreamSeek(_audioFileStreamID, inPacketOffset, &outDataByteOffset, &flags);
    self.dataOffset = (UInt32)MIN((UInt32)outDataByteOffset, _audioInformation.audioDataByteCount + _audioInformation.dataOffset) ;
    return self.dataOffset ;
}

- (LabradorAudioInformation)audioInformation {
    return _audioInformation ;
}

- (void)stop {
    self.dataOffset = 0 ;
    [self.frames removeAll];
    
}

@end
