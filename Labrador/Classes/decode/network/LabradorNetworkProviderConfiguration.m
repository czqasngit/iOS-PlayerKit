//
//  LabradorNetworkProviderConfiguration.m
//  Labrador
//
//  Created by legendry on 2018/8/24.
//  Copyright © 2018 legendry. All rights reserved.
//

#import "LabradorNetworkProviderConfiguration.h"

@implementation LabradorNetworkProviderConfiguration


+ (instancetype)defaultConfiguration {
    LabradorNetworkProviderConfiguration *configuration = [[LabradorNetworkProviderConfiguration alloc] init] ;
    configuration.cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                                        NSUserDomainMask,
                                                                        YES).firstObject stringByAppendingString:@"/labrador_cache"];
    return configuration ;
}

@end
