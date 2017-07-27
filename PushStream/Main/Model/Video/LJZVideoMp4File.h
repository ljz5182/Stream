//
//  LJZVideoMp4File.h
//  PushStream
//
//  Created by 梁家章 on 2017/7/27.
//  Copyright © 2017年 liangjiazhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


@interface LJZVideoMp4File : NSObject


@property (nonatomic, readonly, unsafe_unretained) BOOL isWriting;


//视频属性：
@property (nonatomic, unsafe_unretained) NSInteger vWidth;

@property (nonatomic, unsafe_unretained) NSInteger vHeight;

@property (nonatomic, copy) NSString *vCodec;

@property (nonatomic, unsafe_unretained) NSInteger vBitRate;

@property (nonatomic, unsafe_unretained) NSInteger vMaxFrames;

//音频属性
@property (nonatomic, unsafe_unretained) NSInteger aCodec;

@property (nonatomic, unsafe_unretained) CGFloat aSampleRate;

@property (nonatomic, unsafe_unretained) NSInteger aBitRate;

@property (nonatomic, unsafe_unretained) NSInteger aChanlesNum;

@property (nonatomic, copy) NSData *aChannelLayoutData;

//视频写入
@property (nonatomic, readonly, strong) AVAssetWriter *fileAssetWriter;
//video 输入
@property (nonatomic, readonly, strong) AVAssetWriterInput *videoAssetWriterInput;
//audio 输入
@property (nonatomic, readonly, strong) AVAssetWriterInput *audioAssetWriterInput;

//当前文件路径
@property (nonatomic, readonly, copy) NSString *currentFilePath;

- (BOOL)startWritingWithTime:(CMTime)time;

- (void)stopWritingWithFinishHandler:(void(^)())finishHandler;

- (BOOL)writeAudioSample:(CMSampleBufferRef)audioSample;

- (BOOL)writeVideoSample:(CMSampleBufferRef)videoSample;

- (NSString *)defaultPath;

//重建一个新的fileAssetWriter
- (void)newFileAssetWriter:(void (^)())preFileFinishHandler;

- (void)newFileAssetWriterWithOutSaveFile;

- (void)clean;


@end
