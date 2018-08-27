//
//  LabradorAudioPlayer.h
//  Labrador
//
//  Created by legendry on 2018/8/26.
//  Copyright © 2018 legendry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "configure.h"
#import "LabradorDataProviderDelegate.h"
#import "LabradorDecodableDelegate.h"
#import "LabradorInnerPlayer.h"
#import "LabradorDecodable.h"
#import "LabradorDataProvider.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LabradorAudioPlayerPlayStatus){
    LabradorAudioPlayerPlayStatusWaiting = 1,
    //stop
    LabradorAudioPlayerPlayStatusStop ,
    //playing
    LabradorAudioPlayerPlayStatusPlaying,
    //pause
    LabradorAudioPlayerPlayStatusPause,
};


@class LabradorAudioPlayer ;
@protocol LabradorAudioPlayerDelegate <NSObject>
@optional
- (void)labradorAudioPlayerPrepared:(LabradorAudioPlayer *)player ;
- (void)labradorAudioPlayerWithError:(NSError *)error player:(LabradorAudioPlayer *)player ;
- (void)labradorAudioPlayerDidFinishPlaying:(LabradorAudioPlayer *)player successful:(BOOL)successful ;
- (void)labradorAudioPlayerPlaying:(LabradorAudioPlayer *)player playTime:(float)playTime ;
- (void)labradorAudioPlayerCachingPercent:(LabradorAudioPlayer *)player percent:(float)percent ;
- (void)labradorAudioPlayerLoading:(LabradorAudioPlayer *)player ;
- (void)labradorAudioPlayerResumePlayFromLoading:(LabradorAudioPlayer *)player ;
@end

@interface LabradorAudioPlayer : NSObject<LabradorDataProviderDelegate, LabradorDecodableDelegate>
@property (nonatomic, weak)id<LabradorAudioPlayerDelegate> delegate ;
@property (nonatomic, assign)LabradorAudioPlayerPlayStatus playStatus ;
@property (nonatomic, assign)LabradorCacheStatus loadingStatus ;
@property(nonatomic,strong)id<LabradorDecodable> decoder ;
@property(nonatomic,strong)id<LabradorDataProvider> dataProvider ;
@property(nonatomic,strong)LabradorInnerPlayer *innerPlayer ;
/**
 Audio stream metadata
 */
@property(nonatomic,assign)LabradorAudioInformation audioInformation ;

#pragma mark - control
- (void)prepare;
/**
 For stop
 */
- (void)reset;
- (void)play ;
- (void)pause ;
- (void)resume ;
- (void)seek:(float)duration ;
- (void)stop ;

#pragma mark - property
- (float)duration ;
- (float)currentPlayTime;
@end

NS_ASSUME_NONNULL_END
