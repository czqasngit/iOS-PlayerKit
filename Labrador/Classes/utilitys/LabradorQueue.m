//
//  LabradorQueue.m
//  Labrador
//
//  Created by legendry on 2018/8/24.
//  Copyright © 2018 legendry. All rights reserved.
//

#import "LabradorQueue.h"

@interface LabradorQueue()
{
    CFTypeRef *_storage ;
    uint64_t _capacity;
    uint64_t _size;
}
@end
@implementation LabradorQueue

#pragma mark - Lifecycle

- (void)dealloc {
    free(_storage) ;
}
- (instancetype)init
{
    self = [super init] ;
    if(self) {
        _capacity = 10 ;
        _size = 0 ;
        _storage = malloc(sizeof(CFTypeRef) * _capacity) ;
    }
    return self ;
}

#pragma mark - Inner Method

- (void)extensionStorageIfNeed:(uint64_t)size {
    if(size < _capacity) return ;
    void *tmp = _storage ;
    _storage = malloc(sizeof(CFTypeRef) * size) ;
    memcpy(_storage, tmp, sizeof(CFTypeRef) * _capacity) ;
    free(tmp) ;
    _capacity = size ;
}

#pragma mark - Method
- (void)push:(id)obj {
    if(_size >= _capacity) [self extensionStorageIfNeed:_capacity + 10] ;
    CFTypeRef cfTypeObj = (__bridge_retained CFTypeRef)obj ;
    _storage[_size] = cfTypeObj ;
    _size ++ ;
}
- (id)pop {
    if(_size == 0) return nil;
    CFTypeRef cfTypeObj = _storage[0] ;
    if(_size == 1) {
        _storage[0] = nil ;
    } else {
        memcpy(_storage, _storage + 1, _capacity - 1) ;
        memset(_storage + _capacity - 1, 0, 1) ;
    }
    _size -- ;
    
    return (__bridge_transfer id)cfTypeObj ;
}
- (uint64_t)size {
    return _size ;
}

- (uint64_t)capacity {
    return _capacity ;
}

- (void)removeAll {
    for(int i = 0; i < _size; i ++) {
        CFTypeRef objRef = _storage[i];
        CFRelease(objRef);
    }
    memset(_storage, 0x00, _capacity);
}
@end
