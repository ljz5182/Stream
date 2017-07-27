//
//  LJZVideoCapture.m
//  PushStream
//
//  Created by 梁家章 on 2017/7/27.
//  Copyright © 2017年 liangjiazhang. All rights reserved.
//

#import "LJZVideoCapture.h"
#import "LJZVideoFrame.h"
#import <UIKit/UIKit.h>
#import "LJZVideoInFoList.h"
#import "LJZVideoMp4File.h"




@interface LJZVideoCapture () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate> {
    
}


@property (nonatomic, strong) AVCaptureDeviceInput  * frontCamera;
@property (nonatomic, strong) AVCaptureDeviceInput  * backCamera;

@property (nonatomic, strong) AVCaptureDeviceInput * videoInputDevice;
@property (nonatomic, strong) AVCaptureDeviceInput * audioInputDevice;

@property (nonatomic, strong) AVCaptureVideoDataOutput * videoDataOutput;
@property (nonatomic, strong) AVCaptureAudioDataOutput * audioDataOutput;

@property (nonatomic, strong) AVCaptureSession *captureSession;


//处理videFile
@property (nonatomic, strong) dispatch_source_t videoFileSource;

//是否正在capture
@property (nonatomic, unsafe_unretained) BOOL isCapturing;


//保存sampleList
@property (nonatomic, strong) LJZVideoInFoList *sampleList;

//VideoFile
@property (nonatomic, strong) LJZVideoMp4File *videoMp4File;

//预览
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

//预览结果view
@property (nonatomic, strong) UIView *preview;





@end


__weak static LJZVideoCapture * ljzVideoCapture = nil;



@implementation LJZVideoCapture


//属性实现
- (LJZVideoInFoList *)sampleList{
    if (!_sampleList) {
        _sampleList = [[LJZVideoInFoList alloc]init];
    }
    return _sampleList;
}

- (LJZVideoMp4File *)videoMp4File{
    if (!_videoMp4File) {
        _videoMp4File = [[LJZVideoMp4File alloc]init];
    }
    return _videoMp4File;
}

- (dispatch_source_t)videoFileSource{
    
    if (!_videoFileSource) {
        [self createVideoFileSource];
    }
    return _videoFileSource;
}

-(void)setisCapturing:(BOOL)isCapturing{
    
    if (_isCapturing == isCapturing) {
        return;
    }
    
    if (!isCapturing) {
        [self onPauseCapture];
    }else{
        [self onStartCapture];
    }
    
    _isCapturing = isCapturing;
}

-(void)switchCamera{
    if ([self.videoInputDevice isEqual: self.frontCamera]) {
        self.videoInputDevice = self.backCamera;
    }else{
        self.videoInputDevice = self.frontCamera;
    }
}

-(UIView *)preview{
    if (!_preview) {
        _preview = [UIView new];
        _preview.bounds = [UIScreen mainScreen].bounds;
    }
    return _preview;
}



- (instancetype)init {
    
    self = [super init];
    
    if (self) {
        
        [self createCaptureDevice];
        
        [self createCaptureSession];
        
        [self createPreviewLayer];
        
        ljzVideoCapture = self;
    }
    
    return self;
}



//初始化视频设备
-(void)createCaptureDevice{
    //创建视频设备
    
    AVCaptureDeviceDiscoverySession * videoDevices = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
    
    NSArray *devicesIOS  = videoDevices.devices;
    
    for (AVCaptureDevice *device in devicesIOS) {
        
        //初始化摄像头
        if ([device position] == AVCaptureDevicePositionBack) {
            
            self.backCamera = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
            break;
        } else {
            
            self.frontCamera = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
            break;
        }
    }
    
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    self.audioInputDevice = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
    
    
    [self createOutput];
    
    self.videoInputDevice = self.backCamera;
}

//切换摄像头
-(void)setVideoInputDevice:(AVCaptureDeviceInput *)videoInputDevice{
    //modifyinput
    [self.captureSession beginConfiguration];
    if (_videoInputDevice) {
        [self.captureSession removeInput:_videoInputDevice];
    }
    if (videoInputDevice) {
        [self.captureSession addInput:videoInputDevice];
    }
    
    [self setVideoOutConfig];
    
    [self.captureSession commitConfiguration];
    
    _videoInputDevice = videoInputDevice;
}

//创建预览
-(void) createPreviewLayer{
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.previewLayer.frame = self.preview.bounds;
    [self.preview.layer addSublayer:self.previewLayer];
}

-(void) setVideoOutConfig{
    for (AVCaptureConnection *conn in self.videoDataOutput.connections) {
        if (conn.isVideoStabilizationSupported) {
            [conn setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeAuto];
        }
        if (conn.isVideoOrientationSupported) {
            [conn setVideoOrientation:AVCaptureVideoOrientationPortrait];
        }
        if (conn.isVideoMirrored) {
            [conn setVideoMirrored: YES];
        }
    }
}

//创建会话
-(void) createCaptureSession{
    self.captureSession = [AVCaptureSession new];
    
    [self.captureSession beginConfiguration];
    
    if ([self.captureSession canAddInput:self.videoInputDevice]) {
        [self.captureSession addInput:self.videoInputDevice];
    }
    
    if ([self.captureSession canAddInput:self.audioInputDevice]) {
        [self.captureSession addInput:self.audioInputDevice];
    }
    
    if([self.captureSession canAddOutput:self.videoDataOutput]){
        [self.captureSession addOutput:self.videoDataOutput];
        [self setVideoOutConfig];
    }
    
    if([self.captureSession canAddOutput:self.audioDataOutput]){
        [self.captureSession addOutput:self.audioDataOutput];
    }
    
    self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    
    [self.captureSession commitConfiguration];
    
    [self.captureSession startRunning];
}

//销毁会话
-(void) destroyCaptureSession{
    if (self.captureSession) {
        [self.captureSession removeInput:self.audioInputDevice];
        [self.captureSession removeInput:self.videoInputDevice];
        [self.captureSession removeOutput:self.self.videoDataOutput];
        [self.captureSession removeOutput:self.self.audioDataOutput];
    }
    self.captureSession = nil;
}

-(void) createOutput{
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.videoDataOutput setSampleBufferDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [self.videoDataOutput setVideoSettings:@{
                                             (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
                                             }];
    
    self.audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    [self.audioDataOutput setSampleBufferDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
}

-(void) createVideoFileSource{
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    dispatch_source_set_event_handler(source, ^{
        @synchronized (_videoFileSource) {
            while (!self.sampleList.empty) {
                LJZVideoFrame *frame = self.sampleList.popElement;
                if (!self.videoMp4File.isWriting) {
                    if([self.videoMp4File startWritingWithTime:CMSampleBufferGetPresentationTimeStamp(frame.sampleBuff)]){
                        NSLog(@"start writing with time is succ!!!");
                    }else{
                        NSLog(@"start writing with time is Error!!!");
                    }
                }
                if (self.videoMp4File.isWriting) {
                    BOOL isSucc = NO;
                    if (frame.isVideo) {
                        isSucc = [self.videoMp4File writeVideoSample:frame.sampleBuff];
                    }else{
                        isSucc = [self.videoMp4File writeAudioSample:frame.sampleBuff];
                    }
                    if (isSucc) {
                        CFRelease(frame.sampleBuff);
                    }else{
                        //这么处理可能会丢帧，但是并不影响，最多少2秒
                        [self.sampleList addElementToHeader:frame];
                        [self.videoMp4File newFileAssetWriterWithOutSaveFile];
                        break;
                    }
                }else{
                    [self.sampleList addElementToHeader:frame];
                    [self.videoMp4File newFileAssetWriterWithOutSaveFile];
                }
            }
        }
    });
    
    _videoFileSource = source;
    
    [self resumeVideoFileSource];
}

-(void) resumeVideoFileSource{
    if (_videoFileSource) {
        dispatch_resume(_videoFileSource);
    }
}

-(void) pauseVideoFileSource{
    if (_videoFileSource) {
        dispatch_suspend(_videoFileSource);
    }
}

-(void) stopVideoFileSource{
    if (_videoFileSource) {
        dispatch_source_cancel(_videoFileSource);
    }
}

- (void)onPauseCapture{
    [self pauseVideoFileSource];
    [self.sampleList clean];
}

- (void)onStartCapture{
    [self resumeVideoFileSource];
}


#pragma mark - AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate

-(void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
      fromConnection:(AVCaptureConnection *)connection  {
    
    if (self.isCapturing) {
        LJZVideoFrame *frame = [LJZVideoFrame new];
        frame.sampleBuff = sampleBuffer;
        if ([self.videoDataOutput isEqual:captureOutput]) {
            frame.isVideo = YES;
        }else if([self.audioDataOutput isEqual:captureOutput]){
            frame.isVideo = NO;
        }else{
            NSLog(@"!!!!!!!!!!! is not video and not audio ");
        }
        
        CFRetain(frame.sampleBuff);
        [self.sampleList addElement:frame];
        
        dispatch_source_merge_data(self.videoFileSource, 1);
    }
}

// 丢失帧会调用这里
- (void)captureOutput:(AVCaptureOutput *)captureOutput
  didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection NS_AVAILABLE(10_7, 6_0) {
    
    NSLog(@"丢失帧");
}


static void aw_rtmp_state_changed_cb_in_oc(aw_rtmp_state old_state, aw_rtmp_state new_state){
    NSLog(@"[OC] rtmp state changed from(%d), to(%d)", old_state, new_state);
    [ljzVideoCapture.delegate videoCapture:ljzVideoCapture stateChangeFrom:old_state toState:new_state];
}

- (BOOL)startCapture {
    if (!self.rtmpUrl || self.rtmpUrl.length < 8) {
        NSLog(@"rtmpUrl is nil when start capture");
        return NO;
    }
    int retcode = aw_open_rtmp_context_for_parsed_mp4(self.rtmpUrl.UTF8String, aw_rtmp_state_changed_cb_in_oc);
    if(retcode){
        self.isCapturing = YES;
    }else{
        NSLog(@"startCapture rtmpOpen error!!! retcode=%d", retcode);
        return NO;
    }
    return YES;
}

-(void) stopCapture{
    self.isCapturing = NO;
    [self.videoMp4File stopWritingWithFinishHandler:^{
        NSLog(@"capture stoped");
    }];
    aw_close_rtmp_context_for_parsed_mp4();
}

-(BOOL) startCaptureWithCMTime:(CMTime) time{
    if([self.videoMp4File startWritingWithTime:time]){
        self.isCapturing = YES;
        return YES;
    }
    return NO;
}







/*



- (void)createVideoFileSource{
    
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    dispatch_source_set_event_handler(source, ^{
        @synchronized (_videoFileSource) {
            while (!self.sampleList.empty) {
                LJZVideoFrame *frame = self.sampleList.popElement;
                if (!self.videoMp4File.isWriting) {
                    if([self.videoMp4File startWritingWithTime:CMSampleBufferGetPresentationTimeStamp(frame.sampleBuff)]){
                        NSLog(@"start writing with time is succ!!!");
                    }else{
                        NSLog(@"start writing with time is Error!!!");
                    }
                }
                if (self.videoMp4File.isWriting) {
                    BOOL isSucc = NO;
                    if (frame.isVideo) {
                        isSucc = [self.videoMp4File writeVideoSample:frame.sampleBuff];
                    }else{
                        isSucc = [self.videoMp4File writeAudioSample:frame.sampleBuff];
                    }
                    if (isSucc) {
                        CFRelease(frame.sampleBuff);
                    }else{
                        //这么处理可能会丢帧，但是并不影响，最多少2秒
                        [self.sampleList addElementToHeader:frame];
                        [self.videoMp4File newFileAssetWriterWithOutSaveFile];
                        break;
                    }
                }else{
                    [self.sampleList addElementToHeader:frame];
                    [self.videoMp4File newFileAssetWriterWithOutSaveFile];
                }
            }
        }
    });
    
    _videoFileSource = source;
    
    [self resumeVideoFileSource];
}


- (void)createOutput {
    
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    [self.videoDataOutput setSampleBufferDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [self.videoDataOutput setVideoSettings:@{
                                             (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
                                             }];
    
    self.audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    [self.audioDataOutput setSampleBufferDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
}


//创建会话
- (void)createCaptureSession {
    
    self.captureSession = [[AVCaptureSession alloc]init];
    
    [self.captureSession beginConfiguration];
    
    if ([self.captureSession canAddInput:self.videoInputDevice]) {
        [self.captureSession addInput:self.videoInputDevice];
    }
    
    if ([self.captureSession canAddInput:self.audioInputDevice]) {
        [self.captureSession addInput:self.audioInputDevice];
    }
    
    if([self.captureSession canAddOutput:self.videoDataOutput]){
        [self.captureSession addOutput:self.videoDataOutput];
        [self setVideoOutConfig];
    }
    
    if([self.captureSession canAddOutput:self.audioDataOutput]){
        [self.captureSession addOutput:self.audioDataOutput];
    }
    
    self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    
    [self.captureSession commitConfiguration];
    
    [self.captureSession startRunning];
}


- (void)setVideoOutConfig {
    
    for (AVCaptureConnection *conn in self.videoDataOutput.connections) {
        
        if (conn.isVideoStabilizationSupported) {
            [conn setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeAuto];
        }
        if (conn.isVideoOrientationSupported) {
            [conn setVideoOrientation:AVCaptureVideoOrientationPortrait];
        }
        if (conn.isVideoMirrored) {
            [conn setVideoMirrored: YES];
        }
    }
}

//销毁会话
-(void) destroyCaptureSession{
    if (self.captureSession) {
        [self.captureSession removeInput:self.audioInputDevice];
        [self.captureSession removeInput:self.videoInputDevice];
        [self.captureSession removeOutput:self.self.videoDataOutput];
        [self.captureSession removeOutput:self.self.audioDataOutput];
    }
    self.captureSession = nil;
}


//创建预览
- (void)createPreviewLayer{
    
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.previewLayer.frame = self.preview.bounds;
    [self.preview.layer addSublayer:self.previewLayer];
}


-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    if (self.isCapturing) {
        LJZVideoFrame *frame = [[LJZVideoFrame alloc]init];
        frame.sampleBuff = sampleBuffer;
        if ([self.videoDataOutput isEqual:captureOutput]) {
            frame.isVideo = YES;
        }else if([self.audioDataOutput isEqual:captureOutput]){
            frame.isVideo = NO;
        }else{
            NSLog(@"!!!!!!!!!!! is not video and not audio ");
        }
        
        CFRetain(frame.sampleBuff);
        [self.sampleList addElement:frame];
        
        dispatch_source_merge_data(self.videoFileSource, 1);
    }
}


static void aw_rtmp_state_changed_cb_in_oc(aw_rtmp_state old_state, aw_rtmp_state new_state) {
    NSLog(@"[OC] rtmp state changed from(%d), to(%d)", old_state, new_state);
    [ljzVideoCapture.delegate videoCapture:ljzVideoCapture stateChangeFrom:old_state toState:new_state];
}

- (BOOL)startCapture {
    
    if (!self.rtmpUrl || self.rtmpUrl.length < 8) {
        NSLog(@"rtmpUrl is nil when start capture");
        return NO;
    }
    int retcode = aw_open_rtmp_context_for_parsed_mp4(self.rtmpUrl.UTF8String, aw_rtmp_state_changed_cb_in_oc);
    if(retcode){
        self.isCapturing = YES;
    }else{
        NSLog(@"startCapture rtmpOpen error!!! retcode=%d", retcode);
        return NO;
    }
    return YES;
}


- (void)stopCapture {
    
    self.isCapturing = NO;
    [self.videoMp4File stopWritingWithFinishHandler:^{
        NSLog(@"capture stoped");
    }];
    aw_close_rtmp_context_for_parsed_mp4();
}

- (BOOL)startCaptureWithCMTime:(CMTime)time {
    
    if([self.videoMp4File startWritingWithTime:time]){
        self.isCapturing = YES;
        return YES;
    }
    return NO;
}


- (void)switchCamera{
    
    if ([self.videoInputDevice isEqual: self.frontCamera]) {
        self.videoInputDevice = self.backCamera;
    }else{
        self.videoInputDevice = self.frontCamera;
    }
}
 
 */
@end
