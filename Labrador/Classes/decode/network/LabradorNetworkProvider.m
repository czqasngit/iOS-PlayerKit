//
//  LabradorNetworkProvider.m
//  Labrador
//
//  Created by legendry on 2018/8/13.
//  Copyright © 2018 legendry. All rights reserved.
//

#import "LabradorNetworkProvider.h"
#import "LabradorCacheMapping.h"
#import "LabradorDownloader.h"
#import "configure.h"
#import "NSString+Extensions.h"
#import "configure.h"

@interface LabradorNetworkProvider()<LabradorDownloaderDelegate>
{
    //data url
    NSString *_urlString ;
    //min size for play
    UInt32 _minSize;
    //cache manager for mapping
    LabradorCacheMapping *_cache ;
    //download audio header and data from network
    LabradorDownloader *_downloader ;
    //lock for read & write cache file
    NSCondition *_lock ;
    //lock position,在getBytes方法中等待需要足够多的数据的起始位置
    long _lock_position ;
    //write data when receive from network
    NSFileHandle *_fileWriteHandle ;
    //read data from cache file for play
    NSFileHandle *_fileReadHandle ;
    NSOperationQueue *_downloadQueue ;
    LabradorNetworkProviderConfiguration *  _configuration ;
    NSString *_cachePath ;
    LabradorAudioInformation _audioInformation;
}
@property (nonatomic, weak)id<LabradorDataProviderDelegate> delegate ;
@end

@implementation LabradorNetworkProvider

- (void)dealloc
{
    NSLog(@"LabradorNetworkProvider") ;
}
- (instancetype)initWithURLString:(NSString * _Nonnull)urlString
                    configuration:(LabradorNetworkProviderConfiguration *)configuration
                         delegate:(nonnull id<LabradorDataProviderDelegate>)delegate
{
    self = [super init];
    if (self) {
        NSAssert(configuration != nil, @"LabradorNetworkProviderConfiguration can't be nil.") ;
        _configuration = configuration ;
        NSAssert(configuration.cacheDirectory != nil, @"LabradorNetworkProviderConfiguration.cacheDirectory can't be nil.") ;
        _minSize = 1024 * 128 ;
        _lock = [[NSCondition alloc] init] ;
        NSAssert(urlString != nil, @"URL String can't be nil.") ;
        _urlString = urlString ;
        _delegate = delegate ;
        _lock_position = -1 ;
        _downloadQueue = [[NSOperationQueue alloc] init] ;
        _downloadQueue.maxConcurrentOperationCount = 1 ;
        _cache = [[LabradorCacheMapping alloc] initWithURLString:_urlString cacheDirectory:_configuration.cacheDirectory] ;
        [self initializeFileHandle] ;
    }
    return self;
}
- (void)initializeFileHandle {
    NSFileManager *defaultManager = [NSFileManager defaultManager] ;
    if(![defaultManager fileExistsAtPath:_configuration.cacheDirectory]) {
        [defaultManager createDirectoryAtPath:_configuration.cacheDirectory withIntermediateDirectories:YES attributes:NULL error:NULL] ;
    }
    _cachePath = [_configuration.cacheDirectory stringByAppendingPathComponent:[_urlString md5]] ;
    if(![[NSFileManager defaultManager] fileExistsAtPath:_cachePath]) {
        [[NSFileManager defaultManager] createFileAtPath:_cachePath contents:NULL attributes:NULL] ;
    }
    _fileWriteHandle = [NSFileHandle fileHandleForWritingAtPath:_cachePath] ;
    _fileReadHandle = [NSFileHandle fileHandleForReadingAtPath:_cachePath] ;
}
#pragma mark - Download Control

- (void)startNextFragmentDownload:(NSUInteger)start {
    
    if([_cache hasEnoughData:_minSize from:(UInt32)start]) {
        //判断是否有足够多的数据
        //如果有当_lock_position不为-1时,需要通知getBytes中的等待
        //当seek频繁调用时,可能getBytes会处于上一次seek后的等待中
        //当下一个新的seek执行时,可能已经不需要再次下载了,此时需要单独通知getBytes的等待
        if(_lock_position != -1) {
            [_lock signal] ;
        }
    }
    
    //查找下一个需要下载的片段
    NSRange range = [_cache findNextDownloadFragmentWithFrom:start maxLength:_minSize] ;
//    NSLog(@"[下载]查找下一个需要下载的片段: %ld        %@, %@", start, NSStringFromRange(range), [NSThread currentThread]) ;
    
    //如果range.length 为0 表示已经下载到文件末尾
    if(range.length != 0) {
        _downloader = [[LabradorDownloader alloc] initWithURLString:_urlString
                                                          cachePath:_cachePath
                                                              start:range.location
                                                             length:range.length
                                                     operationQueue:_downloadQueue
                                                       downloadType:DownloadTypeAudioData] ;
        _downloader.delegate = self ;
        [_downloader start] ;
    } else {
        //判断是否还有未下载完成的片段
        if(_cache.cachePercent < 1.0) {
            //从头下载一个新的未完成的片段
            [self startNextFragmentDownload:0] ;
        }
    }
}
#pragma mark - LabradorDataProvider Delegate
- (NSInteger)getBytes:(void *)bytes
                  size:(NSUInteger)size
                offset:(NSUInteger)offset
                  type:(DownloadType)type{
    if(size + offset >= _audioInformation.totalSize && type == DownloadTypeAudioData) return -1;
    NSAssert(size <= _minSize, @"_minSize must be >= size") ;
    NSUInteger length = 0 ;
     [_lock lock] ;
    if(type == DownloadTypeHeader) {
        if(![_cache hasEnoughData:(UInt32)size from:0]) {
            _downloader = [[LabradorDownloader alloc] initWithURLString:_urlString
                                                              cachePath:_cachePath
                                                                  start:0
                                                                 length:LabradorAudioHeaderInputSize
                                                         operationQueue:_downloadQueue
                                                           downloadType:type] ;
            _downloader.delegate = self ;
            [self notifyPercent] ;
            [_downloader start] ;
            [_lock wait] ;
        }
        [_fileReadHandle seekToFileOffset:0] ;
        NSData *data = [_fileReadHandle readDataOfLength:size] ;
        [data getBytes:bytes range:NSMakeRange(0, data.length)] ;
        length = data.length ;
    } else {
        //判断从给定的点是否有大小_minSize的数据缓存可以使用
        if(![_cache hasEnoughData:_minSize from:(UInt32)offset]) {
            //如果没有足够的数据,就等待...
            _lock_position = offset ;
            [self notifyStatus:LabradorCacheStatusLoading] ;
            [_lock wait] ;
        }
        //已经有足够的数据可以使用了
        _lock_position = -1 ;//表示没有锁定等待
        [_fileReadHandle seekToFileOffset:offset] ;
        NSData *data = [_fileReadHandle readDataOfLength:size] ;
        [data getBytes:bytes range:NSMakeRange(0, data.length)] ;
        length = data.length ;
       
    }
    [_lock unlock] ;
    return length ;
}
- (void)prepared:(LabradorAudioInformation)information{
    _audioInformation = information;
    if(_downloader.downloadType == DownloadTypeHeader) {
        _downloader = nil ;
        [_cache configureCacheMappingWithFileSize:information.totalSize] ;
    }
    [self notifyPercent] ;
    [self startNextFragmentDownload:0] ;
}
- (void)seek:(NSUInteger)offset {
    __weak typeof(self) _weak_self = self ;
    [_downloadQueue addOperationWithBlock:^{
        __strong typeof(_weak_self) _strong_self = _weak_self ;
        //取消当前正进行的下载
        [_strong_self->_downloader cancel] ;
        //reset _lock_position(因为:lock 在wait的时候记录了一个判断缓存是否可以播放的起始值,如果不重置,在receiveData时判断缓存是否足够时就会有问题)
        //getBytes在等待时会记录一个等待起始位置,getBytes受到线程的影响,只会记录一次,如果多次seek则会导致新的下载器的起始位置
        //与等待数据返回的位置不同(如果不同,则当receiveData判断数据是否足够时,使用的起始点就有异常,导致判断一直失败)
        _strong_self->_lock_position = offset ;
        //用新的seek位置开始一个新的下载
        [_strong_self startNextFragmentDownload:offset] ;
    }];
}

#pragma mark - Downloader Delegate
//receive from current downloader
- (void)receiveData:(NSData *)data start:(NSUInteger)start{
    //receive data from network
    if(data && data.length > 0) {
        [_lock lock] ;
        //将数据写入到文件
        [_fileWriteHandle seekToFileOffset:start] ;
        [_fileWriteHandle writeData:data] ;
        //同时同步cache mapping
        [_cache completedFragment:start length:data.length] ;
        if(_downloader.downloadType == DownloadTypeHeader) {
            // download header information data
            if([_downloader downloadCompleted]) {
                [_lock signal] ;
            }
        } else {
            //判断是否有锁定,如果没有锁定不再判断是否有足够的数据可以使用
            if(_lock_position != -1) {
                //如果_lock_position的值不是-1,则表明getBytes时处于等待状态
                //此时需要用锁定的值来判断是否足够多的数据可以让getBytes继续执行
                if([_cache hasEnoughData:_minSize from:(UInt32)_lock_position]) {
                    [_lock signal] ;
                    [self notifyStatus:LabradorCacheStatusEnough] ;
                }
            }
        }
        [self notifyPercent] ;
        [_lock unlock] ;
    }
}
//current downloader completed
- (void)completed:(BOOL)isDownloadFullData {
    [_lock lock] ;
    if(_downloader.downloadType == DownloadTypeAudioData) {
        NSUInteger endLocation = _downloader.endLocation ;
        [self startNextFragmentDownload:endLocation] ;
    }
    [_lock unlock] ;
}
- (void)onError:(NSError *)error {
    //下载超时了,继续下载(如果一次性下载的数据太多,在规定时间未下载完成,则会返回超时)
    if(error.code == -1001) {
        [self startNextFragmentDownload:_downloader.endLocation] ;
    } else {
        if(_delegate && [_delegate respondsToSelector:@selector(onError:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate onError:error] ;
            }) ;
        }
    }
    
}

#pragma mark - Notify
- (void)notifyStatus:(LabradorCacheStatus)status{
    if(_cacheStatus == status) return ;
    _cacheStatus = status ;
    dispatch_async(dispatch_get_main_queue(), ^{
         if(self.delegate && [self.delegate respondsToSelector:@selector(statusChanged:)]) [self.delegate statusChanged:self.cacheStatus] ;
    });
}
- (void)notifyPercent {
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.delegate && [self.delegate respondsToSelector:@selector(loadingPercent:)]) [self.delegate loadingPercent:self->_cache.cachePercent] ;
    });
}



- (void)stop {
    [_lock signal] ;
}
@end
