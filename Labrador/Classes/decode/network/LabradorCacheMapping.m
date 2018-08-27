//
//  LABStore.m
//  Labrador
//
//  Created by legendry on 2018/8/6.
//  Copyright © 2018 legendry. All rights reserved.
//

#import "LabradorCacheMapping.h"
#import "NSString+Extensions.h"

@interface LabradorCacheMapping()
{
    NSString *_urlString ;
    NSString *_name;
    NSString *_path ;
    LabradorCacheMappingInformation _cacheMapping;
    size_t _headerLength ;
    UInt32 _cacheMappingCount ;
}
@end

@implementation LabradorCacheMapping

#pragma mark - initialize

- (void)dealloc
{
    if(_cacheMapping.data) free(_cacheMapping.data) ;
}
- (instancetype)initWithURLString:(NSString *)urlString cacheDirectory:(nonnull NSString *)cacheDirectory
{
    self = [super init];
    if (self) {
        _urlString = urlString ;
        _name = [[urlString md5] stringByAppendingString:@"_info"] ;
        _path = [cacheDirectory stringByAppendingPathComponent:_name] ;
        _headerLength = 32 + sizeof(UInt32) + sizeof(bool) ;
        [self initializeCacheMapping] ;
    }
    return self;
}

- (void)initializeCacheMapping {
    if([[NSFileManager defaultManager] fileExistsAtPath:_path]){
        NSFileHandle* handle = [NSFileHandle fileHandleForReadingAtPath:_path] ;
        NSData *data = [handle readDataOfLength:_headerLength] ;
        if(_headerLength == data.length) {
            [data getBytes:&_cacheMapping length:_headerLength] ;
            [handle seekToFileOffset:_headerLength] ;
            NSData *tmpData = [handle readDataOfLength:_cacheMapping.length] ;
            if(tmpData.length == _cacheMapping.length) {
                _cacheMapping.data = malloc(_cacheMapping.length) ;
                [tmpData getBytes:_cacheMapping.data length:_cacheMapping.length] ;
            } else {
                _cacheMapping.is_initialized = false ;
            }
            [self initializeCacheMappingCount] ;
        }
    }
}

- (void)initializeCacheMappingCount {
    int index = 0 ;
    while (index < _cacheMapping.length) {
        if(*(_cacheMapping.data + index) == 0xFF) _cacheMappingCount ++ ;
        index ++ ;
    }
}

- (void)configureCacheMappingWithFileSize:(NSUInteger)fileSize {
    if(!_cacheMapping.is_initialized){
        [[_name dataUsingEncoding:NSUTF8StringEncoding] getBytes:_cacheMapping.name length:32];
        _cacheMapping.length = (UInt32)ceil(fileSize * 1.0f / 1024) ;
        _cacheMapping.data = malloc(_cacheMapping.length) ;
        memset(_cacheMapping.data, 0, _cacheMapping.length) ;
        _cacheMapping.is_initialized = true ;
        [self synchronize] ;
        _cacheMappingCount = 0 ;
    }
}
- (void)synchronize {
    if(_cacheMapping.is_initialized) {
        NSMutableData *data = [[NSMutableData alloc] initWithCapacity:_headerLength + _cacheMapping.length] ;
        [data appendBytes:&_cacheMapping length:_headerLength] ;
        [data appendBytes:_cacheMapping.data length:_cacheMapping.length] ;
        [data writeToFile:_path atomically:YES] ;
    }
}
- (void)completedFragment:(NSUInteger)start length:(NSUInteger)length {
    if(start + length >= _cacheMapping.length * 1024 || length == 0) return ;
    size_t _s = start / 1024 ;
    NSUInteger _l = ceil(length * 1.0f / 1024) ;
    memset(_cacheMapping.data + _s, 0xFF, _l) ;
    [self synchronize] ;
    _cacheMappingCount += _l ;
}


- (NSRange)findNextDownloadFragmentWithFrom:(NSUInteger)from maxLength:(NSUInteger)maxLength {
    if(!_cacheMapping.is_initialized) return NSMakeRange(0, 0) ;
    NSUInteger start = from / 1024 ;
    NSUInteger max = maxLength / 1024 ;
    NSUInteger length = 0 ;
    //find start location
    while (*(_cacheMapping.data + start) != 0x00) {
        start ++ ;
    }
    //find fragment length
    if(start < _cacheMapping.length) {
        while (*(_cacheMapping.data + start + length) == 0x00 && start + length < _cacheMapping.length) {
            length ++ ;
            if(length == max) break ;
        }
    }
    return NSMakeRange(start * 1024, MIN(length, _cacheMapping.length) * 1024) ;
}

- (BOOL)hasEnoughData:(UInt32)minSize from:(UInt32)from {
    NSUInteger start = from / 1024 ;
    NSUInteger length = 0 ;
    BOOL success = NO ;
    if(start < _cacheMapping.length) {
        while (*(_cacheMapping.data + start + length) == 0xFF) {
            length ++ ;
            if(length * 1024 >= minSize || start + length >= _cacheMapping.length) {
                success = YES ;
                break ;
            }
        }
    }
    return success ;
}

- (float)cachePercent {
    if(_cacheMapping.length == 0) return 0 ;
    return _cacheMappingCount * 1.0 / _cacheMapping.length ;
}


@end
