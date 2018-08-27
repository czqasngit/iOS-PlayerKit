//
//  LABDownloader.h
//  Labrador
//
//  Created by legendry on 2018/8/6.
//  Copyright © 2018 legendry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "configure.h"

NS_ASSUME_NONNULL_BEGIN



@protocol LabradorDownloaderDelegate <NSObject>
- (void)receiveData:(NSData *)data start:(NSUInteger)start;
- (void)completed:(BOOL)isDownloadFullData;
- (void)onError:(NSError *)error ;
@end

@interface LabradorDownloader : NSObject

@property (nonatomic, weak)id<LabradorDownloaderDelegate> delegate ;

- (instancetype)init NS_UNAVAILABLE ;
- (instancetype)initWithURLString:(NSString * _Nonnull)urlString
                        cachePath:(NSString *)cachePath
                            start:(NSUInteger)start
                           length:(NSUInteger)length
                   operationQueue:(NSOperationQueue *)queue
                     downloadType:(DownloadType)type;
- (void)start ;
- (NSUInteger)startLocation;
- (NSUInteger)length;
- (NSUInteger)endLocation ;
- (DownloadType)downloadType;
- (NSUInteger)downloadSize;
- (BOOL)downloadCompleted;
- (void)cancel ;
@end

NS_ASSUME_NONNULL_END
