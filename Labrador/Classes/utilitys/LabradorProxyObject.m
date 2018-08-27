//
//  LabradorProxyObject.m
//  Labrador
//
//  Created by legendry on 2018/8/17.
//  Copyright © 2018 legendry. All rights reserved.
//

#import "LabradorProxyObject.h"

@interface LabradorProxyObject ()
@property (nonatomic, weak)id target ;
@end
@implementation LabradorProxyObject

- (instancetype)initWithTarget:(id)target {
    self = [super init] ;
    if(self) {
        _target = target ;
    }
    return self ;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [self.target respondsToSelector:aSelector] ;
}
- (id)forwardingTargetForSelector:(SEL)aSelector {
    return self.target ;
}

@end
