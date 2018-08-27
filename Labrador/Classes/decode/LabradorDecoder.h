//
//  LabradorDecoder.h
//  Labrador
//
//  Created by legendry on 2018/8/8.
//  Copyright © 2018 legendry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LabradorDecodable.h"
#import "LabradorDecodableDelegate.h"


@interface LabradorDecoder : NSObject <LabradorDecodable>

- (instancetype)init NS_UNAVAILABLE ;;
- (instancetype)init:(id<LabradorDecodableDelegate>)delegate ;
@end
