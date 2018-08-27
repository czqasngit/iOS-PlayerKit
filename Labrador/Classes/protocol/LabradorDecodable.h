//
//  LABAudioDescpriptionProtocol.h
//  Labrador
//
//  Created by legendry on 2018/8/8.
//  Copyright © 2018 legendry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioQueue.h>
#import "configure.h"

@class LabradorAudioFrame ;

@protocol LabradorDecodable <NSObject>
- (void)initialize;
- (LabradorAudioInformation)audioInformation;
- (LabradorAudioFrame *)product:(BOOL)seeking;
- (NSUInteger)seek:(UInt32)seek ;
- (void)stop;
@end

