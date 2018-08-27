//
//  LabradorAudioPacket.h
//  Labrador
//
//  Created by legendry on 2018/8/8.
//  Copyright © 2018 legendry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioQueue.h>

@interface LabradorAudioPacket : NSObject

- (instancetype)init NS_UNAVAILABLE ;
- (instancetype)initWithAudioData:(void const *)data
                     descriptions:(AudioStreamPacketDescription)packetDescriptions;

@property(nonatomic, assign)void *data ;
@property(nonatomic, assign)UInt32 byteSize;
@property(nonatomic, assign)AudioStreamPacketDescription *packetDescription;

@end

@interface LabradorAudioFrame : NSObject
@property(nonatomic, strong)NSArray<LabradorAudioPacket *> *packets ;
@property(nonatomic, assign)UInt32 packetSize ;
@property(nonatomic, assign)UInt32 byteSize ;
- (instancetype)init NS_UNAVAILABLE ;
- (instancetype)initWithPackets:(NSArray<LabradorAudioPacket *> *)packets;
@end
