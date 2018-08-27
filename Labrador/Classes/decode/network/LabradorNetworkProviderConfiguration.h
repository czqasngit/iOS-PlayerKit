//
//  LabradorNetworkProviderConfiguration.h
//  Labrador
//
//  Created by legendry on 2018/8/24.
//  Copyright © 2018 legendry. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LabradorNetworkProviderConfiguration : NSObject

@property (nonatomic, strong)NSString *cacheDirectory ;

+ (instancetype)defaultConfiguration ;

@end

NS_ASSUME_NONNULL_END
