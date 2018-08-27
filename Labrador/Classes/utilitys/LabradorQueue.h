//
//  LabradorQueue.h
//  Labrador
//
//  Created by legendry on 2018/8/24.
//  Copyright © 2018 legendry. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LabradorQueue : NSObject

- (void)push:(id)obj;
- (__kindof id)pop;
- (uint64_t)size;
- (uint64_t)capacity;
- (void)removeAll;
@end

NS_ASSUME_NONNULL_END
