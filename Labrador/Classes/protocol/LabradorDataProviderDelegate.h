//
//  LabradorDataProviderDelegate.h
//  Labrador
//
//  Created by legendry on 2018/8/23.
//  Copyright © 2018 legendry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "configure.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LabradorDataProviderDelegate <NSObject>
- (void)statusChanged:(LabradorCacheStatus)newStatus ;
- (void)loadingPercent:(float)percent ;
- (void)onError:(NSError *)error ;
@end

NS_ASSUME_NONNULL_END
