//
//  LabradorProxyObject.h
//  Labrador
//
//  Created by legendry on 2018/8/17.
//  Copyright © 2018 legendry. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LabradorProxyObject : NSObject
- (instancetype)init NS_UNAVAILABLE ;
- (instancetype)initWithTarget:(id _Nonnull)target ;
@end

NS_ASSUME_NONNULL_END
