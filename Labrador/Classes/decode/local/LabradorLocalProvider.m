//
//  LabradorLocalProvider.m
//  Labrador
//
//  Created by legendry on 2018/8/8.
//  Copyright © 2018 legendry. All rights reserved.
//

#import "LabradorLocalProvider.h"

@interface LabradorLocalProvider()
{
    NSFileHandle *_handle ;
    NSInteger _fileSize;
}
@end
@implementation LabradorLocalProvider

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"t" ofType:@"mp3"] ;
        _handle = [NSFileHandle fileHandleForReadingAtPath:path] ;
        _fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL][NSFileSize] integerValue] ;
    }
    return self;
}
- (NSInteger)getBytes:(void *)bytes
                  size:(NSUInteger)size
                offset:(NSUInteger)offset
                  type:(DownloadType)type{
    if(offset + size >= _fileSize && type == DownloadTypeAudioData) return -1 ;
    [_handle seekToFileOffset:offset] ;
    NSData *data = [_handle readDataOfLength:size] ;
    [data getBytes:bytes length:data.length] ;
    return (uint32_t)data.length ;
}


- (void)prepared:(LabradorAudioInformation)information {
    
}

- (void)seek:(NSUInteger)offset {
    
}
- (void)stop {
    
}

@end
