//
//  LABDownloader.m
//  Labrador
//
//  Created by legendry on 2018/8/6.
//  Copyright © 2018 legendry. All rights reserved.
//

#import "LabradorDownloader.h"
#import "NSString+Extensions.h"

@interface LabradorDownloader()<NSURLSessionDelegate, NSURLSessionDataDelegate>
{
    NSString *_urlString ;
    NSString *_path ;
    NSUInteger _start ;
    NSUInteger _length ;
    NSURLSession *_session ;
    NSUInteger _callBackDataLength ;
    NSMutableData *_data ;
    DownloadType _downloadType ;
    NSURLSessionTask *_task ;
    NSOperationQueue *_queue ;
}
@end

@implementation LabradorDownloader

#pragma mark - initialize

- (instancetype)initWithURLString:(NSString * _Nonnull)urlString
                        cachePath:(NSString *)cachePath
                            start:(NSUInteger)start
                           length:(NSUInteger)length
                   operationQueue:(NSOperationQueue *)queue
                     downloadType:(DownloadType)type
{
    self = [super init];
    if (self) {
        _queue = queue ;
        _urlString = urlString ;
        _downloadType = type ;
        _path = cachePath;
        _start = start ;
        _length = length ;
        _callBackDataLength = 0 ;
        _data = [[NSMutableData alloc] init] ;
        [self initializeURLSession] ;
    }
    return self;
}

- (NSUInteger)startLocation {
    return _start ;
}
- (NSUInteger)length {
    return _length ;
}
- (NSUInteger)endLocation {
    return _start + _callBackDataLength ;
}
- (DownloadType)downloadType {
    return _downloadType ;
}
- (NSUInteger)downloadSize {
    return _data.length ;
}
- (BOOL)downloadCompleted {
    return _data.length == _length ;
}
- (void)cancel {
    [_task cancel] ;
    [_session invalidateAndCancel] ;
}
#pragma mark -
- (void)initializeURLSession {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration] ;
    configuration.timeoutIntervalForRequest = 60.0f ;
    configuration.timeoutIntervalForResource = 60.0f ;
    _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:_queue] ;
}

- (void)start{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:_urlString]] ;
    NSString *rangString = [NSString stringWithFormat:@"bytes=%ld-%ld", _start,(_start + _length - 1)] ;
    [request setValue:rangString forHTTPHeaderField:@"Range"] ;
    _task = [_session dataTaskWithRequest:request] ;
    [_task resume] ;
}

#pragma mark - NSURLSessionDelegate


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSHTTPURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    if(response.statusCode != 200 &&
       response.statusCode != 206) {
        if(self.delegate && [self.delegate respondsToSelector:@selector(onError:)]) {
            [self.delegate onError:[NSError errorWithDomain:NSURLErrorDomain code:response.statusCode userInfo:@{@"Reason": [NSString stringWithFormat:@"URL Response error: %ld", response.statusCode]}]] ;
        }
        completionHandler(NSURLSessionResponseCancel) ;
    } else {
        completionHandler(NSURLSessionResponseAllow) ;
    }
}
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data{
    if(!data || data.length == 0) return ;
    [_data appendData:data] ;
    if(self.delegate && _data.length >= LabradorAudioQueueBufferCacheSize) {
        NSUInteger tmpCallBackLength = (_data.length - _callBackDataLength) / 1024 * 1024 ;
        [self.delegate receiveData:[_data subdataWithRange:NSMakeRange(_callBackDataLength, tmpCallBackLength)] start:_callBackDataLength + _start] ;
        _callBackDataLength += tmpCallBackLength ;
    }
}
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
    didCompleteWithError:(nullable NSError *)error {
    if(error) {
        if(self.delegate && [self.delegate respondsToSelector:@selector(onError:)]) {
            [self.delegate onError:error] ;
        }
    } else {
        if(self.delegate && [self.delegate respondsToSelector:@selector(receiveData:start:)] && [self.delegate respondsToSelector:@selector(completed:)]) {
            [self.delegate receiveData:[_data subdataWithRange:NSMakeRange(_callBackDataLength, _data.length - _callBackDataLength)] start:_callBackDataLength + _start] ;
            _callBackDataLength = _data.length ;
            [self.delegate completed:[self downloadCompleted]] ;
        }
    }
}

@end
