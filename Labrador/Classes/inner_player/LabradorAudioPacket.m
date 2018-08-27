//
//  LabradorAudioPacket.m
//  Labrador
//
//  Created by legendry on 2018/8/8.
//  Copyright © 2018 legendry. All rights reserved.
//

#import "LabradorAudioPacket.h"

@implementation LabradorAudioPacket

- (void)dealloc
{
    free(self.packetDescription) ;
    free(self.data) ;
}
- (instancetype)initWithAudioData:(void const *)data
                     descriptions:(AudioStreamPacketDescription)packetDescriptions{
    self = [super init] ;
    if(self) {
        self.data = malloc(packetDescriptions.mDataByteSize) ;
        memcpy(self.data, data + packetDescriptions.mStartOffset, packetDescriptions.mDataByteSize) ;
        uint32_t descriptionsByteSize =  sizeof(AudioStreamPacketDescription) ;
        self.packetDescription = malloc(descriptionsByteSize);
        memcpy(self.packetDescription, &packetDescriptions, descriptionsByteSize) ;
        self.byteSize = packetDescriptions.mDataByteSize ;
    }
    return self ;
}

@end

@implementation LabradorAudioFrame

- (instancetype)initWithPackets:(NSArray<LabradorAudioPacket *> *)packets{
    self = [super init] ;
    if(self) {
        self.packetSize = (UInt32)packets.count ;
        self.packets = packets ;
        self.byteSize = 0 ;
        for(int i = 0; i < packets.count; i ++) {
            self.byteSize += packets[i].byteSize ;
        }
    }
    return self ;
}

@end
