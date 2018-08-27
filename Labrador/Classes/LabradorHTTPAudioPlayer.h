//
//  LABAudioPlayer.h
//  Labrador
//
//  Created by legendry on 2018/8/6.
//  Copyright © 2018 legendry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "configure.h"
#import "LabradorDecodable.h"
#import "LabradorDataProvider.h"
#import "LabradorAudioPlayer.h"

NS_ASSUME_NONNULL_BEGIN



@class LabradorHTTPAudioPlayer ;


@interface LabradorHTTPAudioPlayer : LabradorAudioPlayer

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithURLString:(NSString *)urlString;


@end

NS_ASSUME_NONNULL_END
