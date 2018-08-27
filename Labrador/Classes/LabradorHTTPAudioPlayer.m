//
//  LABAudioPlayer.m
//  Labrador
//
//  Created by legendry on 2018/8/6.
//  Copyright © 2018 legendry. All rights reserved.
//

#import "LabradorHTTPAudioPlayer.h"
#import "LabradorDecoder.h"
#import "LabradorInnerPlayer.h"
#import "configure.h"
#import "LabradorNetworkProvider.h"

#import "LabradorLocalProvider.h"

@interface LabradorHTTPAudioPlayer()
{
    NSString *                          _urlString;
}
@end
@implementation LabradorHTTPAudioPlayer

- (instancetype)initWithURLString:(NSString *)urlString
{
    self = [super init];
    if (self) {
        _urlString = urlString ;
        self.decoder = [[LabradorDecoder alloc] init:self] ;
        self.dataProvider = [[LabradorNetworkProvider alloc] initWithURLString:urlString configuration:[LabradorNetworkProviderConfiguration defaultConfiguration] delegate:self] ;
    }
    return self;
}
#pragma mark - Music Control
- (void)stop {
    [super stop];
    self.decoder = [[LabradorDecoder alloc] init:self] ;
    self.dataProvider = [[LabradorNetworkProvider alloc] initWithURLString:_urlString configuration:[LabradorNetworkProviderConfiguration defaultConfiguration] delegate:self] ;
}
@end
