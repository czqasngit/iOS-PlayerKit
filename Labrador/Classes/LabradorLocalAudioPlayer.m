//
//  LabradorLocalAudioPlayer.m
//  Labrador
//
//  Created by legendry on 2018/8/26.
//  Copyright © 2018 legendry. All rights reserved.
//

#import "LabradorLocalAudioPlayer.h"
#import "LabradorDecoder.h"
#import "LabradorLocalProvider.h"

@implementation LabradorLocalAudioPlayer

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.decoder = [[LabradorDecoder alloc] init:self] ;
        self.dataProvider = [[LabradorLocalProvider alloc] init];
    }
    return self;
}
#pragma mark - Music Control
- (void)stop {
    [super stop] ;
    self.decoder = [[LabradorDecoder alloc] init:self] ;
    self.dataProvider = [[LabradorLocalProvider alloc] init];
}

@end
