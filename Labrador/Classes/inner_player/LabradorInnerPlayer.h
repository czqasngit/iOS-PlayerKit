//
//  LabradorInnerPlayer.h
//  Labrador
//
//  Created by legendry on 2018/8/8.
//  Copyright © 2018 legendry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioQueue.h>
#import "LabradorAudioPacket.h"
#import "LabradorDataProvider.h"




@protocol LabradorInnerPlayerDataProvider <NSObject>
- (LabradorAudioFrame *)nextFrame:(BOOL)seeking ;
@end

@interface LabradorInnerPlayer : NSObject
@property (nonatomic, assign,getter=isSeeking) BOOL seeking ;
- (instancetype)init NS_UNAVAILABLE ;
- (instancetype)initWithProvider:(id<LabradorInnerPlayerDataProvider>)provider;
- (void)configureDescription:(AudioStreamBasicDescription)description;
- (void)play ;
- (void)pause ;
- (void)resume ;
- (float)playTime ;
- (void)reset;
- (void)stop ;
- (void)dispose ;
@end
