//
//  LJZVideoCapture.h
//  PushStream
//
//  Created by 梁家章 on 2017/7/27.
//  Copyright © 2017年 liangjiazhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "aw_pushstream.h"
#import <AVFoundation/AVFoundation.h>
#import "LJZVideoMp4File.h"
#import <UIKit/UIKit.h>


@class LJZVideoCapture;


@protocol LJZVideoCaptureDelegate <NSObject>

@optional

-(void)videoCapture:(LJZVideoCapture *)capture
    stateChangeFrom:(aw_rtmp_state)fromState
            toState:(aw_rtmp_state) toState;


@end


@interface LJZVideoCapture : NSObject

@property (nonatomic, weak) id <LJZVideoCaptureDelegate> delegate;

@property (nonatomic, copy) NSString *rtmpUrl;

//是否将数据收集起来
@property (nonatomic, readonly, unsafe_unretained) BOOL isCapturing;

//预览view
@property (nonatomic, readonly, strong) UIView *preview;

//VideoFile
@property (nonatomic, readonly, strong) LJZVideoMp4File *videoMp4File;

//切换摄像头
- (void)switchCamera;

//停止capture
- (void)stopCapture;

//开始capture
- (BOOL)startCapture;

//开始capture
- (BOOL)startCaptureWithCMTime:(CMTime) time;

@end
