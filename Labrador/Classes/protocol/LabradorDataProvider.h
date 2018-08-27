//
//  LABAudioDataProviderProtocol.h
//  Labrador
//
//  Created by legendry on 2018/8/8.
//  Copyright © 2018 legendry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "configure.h"


@protocol LabradorDataProvider <NSObject>

/**
 Get Audio Data from DataProvider

 @param bytes the data pointer to be filled
 @param size size to fill
 @param offset offset
 @param type download type
 @return Actually filled size, end if -1
 */
- (NSInteger)getBytes:(void *)bytes
                  size:(NSUInteger)size
                offset:(NSUInteger)offset
                  type:(DownloadType)type;

@optional
/**
 Audio player is ready to play
 @param information audio information
 */
- (void)prepared:(LabradorAudioInformation)information;


/**
 seek

 @param offset 新的数据起始位置
 */
- (void)seek:(NSUInteger)offset;

- (void)stop;

@end
