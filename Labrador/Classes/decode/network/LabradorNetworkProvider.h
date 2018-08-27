//
//  LabradorNetworkProvider.h
//  Labrador
//
//  Created by legendry on 2018/8/13.
//  Copyright © 2018 legendry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LabradorDataProvider.h"
#import "LabradorDataProviderDelegate.h"
#import "LabradorNetworkProviderConfiguration.h"

NS_ASSUME_NONNULL_BEGIN



@interface LabradorNetworkProvider : NSObject<LabradorDataProvider>
@property (nonatomic, assign)LabradorCacheStatus cacheStatus ;

- (instancetype)init NS_UNAVAILABLE ;
- (instancetype)initWithURLString:(NSString * _Nonnull)urlString
                    configuration:(LabradorNetworkProviderConfiguration *)configuration
                         delegate:(id<LabradorDataProviderDelegate> _Nonnull)delegate;
@end

NS_ASSUME_NONNULL_END

