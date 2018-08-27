//
//  LABStore.h
//  Labrador
//
//  Created by legendry on 2018/8/6.
//  Copyright © 2018 legendry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "configure.h"

NS_ASSUME_NONNULL_BEGIN

@interface LabradorCacheMapping : NSObject
- (instancetype)init NS_UNAVAILABLE ;
- (instancetype)initWithURLString:(NSString * _Nonnull)urlString cacheDirectory:(NSString *)cacheDirectory;

/**
 Configure Cache Mapping

 @param fileSize Stream data size
 */
- (void)configureCacheMappingWithFileSize:(NSUInteger)fileSize ;

/**
 A Fragment completed

 @param start start location
 @param length length
 */
- (void)completedFragment:(NSUInteger)start length:(NSUInteger)length;

/**
 Find next fragment for require download

 @param from start location
 @return Next fragment range for require download
 */
- (NSRange)findNextDownloadFragmentWithFrom:(NSUInteger)from maxLength:(NSUInteger)maxLength;

/**
 Is enough data to play

 @param minSize min size
 @param from start location
 @return true/false
 */
- (BOOL)hasEnoughData:(UInt32)minSize from:(UInt32)from ;

/**
 Cache percent
 */
- (float)cachePercent;
@end

NS_ASSUME_NONNULL_END
