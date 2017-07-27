//
//  LiveController.m
//  PushStream
//
//  Created by 梁家章 on 2017/7/27.
//  Copyright © 2017年 liangjiazhang. All rights reserved.
//

#import "LiveController.h"

#import "LJZVideoCapture.h"
#import <Photos/Photos.h>


@interface LiveController ()  <LJZVideoCaptureDelegate> {
    
}


@property (nonatomic, strong) UIButton *startBtn;
@property (nonatomic, strong) UIButton *switchBtn;
@property (nonatomic, strong) UIButton *saveVideoBtn;

@property (nonatomic, strong) UIView *preview;
@property (nonatomic, strong) LJZVideoCapture *capture;


@end

@implementation LiveController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.preview addSubview: self.capture.preview];
    self.capture.preview.center = self.preview.center;
    [self createUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)videoCapture:(LJZVideoCapture *)capture
     stateChangeFrom:(aw_rtmp_state)fromState
             toState:(aw_rtmp_state)toState {
    
    switch (toState) {
        case aw_rtmp_state_idle: {
            self.startBtn.enabled = YES;
            [self.startBtn setTitle:@"开始直播" forState:UIControlStateNormal];
            break;
        }
        case aw_rtmp_state_connecting: {
            self.startBtn.enabled = NO;
            [self.startBtn setTitle:@"连接中" forState:UIControlStateNormal];
            break;
        }
        case aw_rtmp_state_opened: {
            self.startBtn.enabled = YES;
            break;
        }
        case aw_rtmp_state_closed: {
            self.startBtn.enabled = YES;
            break;
        }
        case aw_rtmp_state_error_write: {
            break;
        }
        case aw_rtmp_state_error_open: {
            break;
        }
        case aw_rtmp_state_error_net: {
            break;
        }
    }
}



- (LJZVideoCapture *) capture{
    if (!_capture) {
        _capture = [[LJZVideoCapture alloc]init];
        _capture.delegate = self;
    }
    return _capture;
}

- (UIView *)preview {
    
    if (!_preview) {
        _preview = [[UIView alloc]init];
        _preview.frame = self.view.bounds;
        [self.view addSubview:_preview];
        [self.view sendSubviewToBack:_preview];
    }
    return _preview;
}


- (void)createUI {

    self.startBtn = [[UIButton alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 70)/2, self.view.frame.size.height - 180, 70, 70)];
    [self.startBtn setTitle:@"开始直播！" forState:UIControlStateNormal];
    [self.startBtn addTarget:self action:@selector(onStartClick) forControlEvents:UIControlEventTouchUpInside];
    self.startBtn.layer.masksToBounds = YES;
    self.startBtn.layer.cornerRadius = self.startBtn.frame.size.height/2;
    self.startBtn.backgroundColor = [UIColor colorWithWhite:1 alpha:0.7];
    [self.view addSubview:self.startBtn];
    
    /*
    self.switchBtn = [[UIButton alloc] initWithFrame:CGRectMake(230, 100, 100, 30)];
    [self.switchBtn setTitle:@"换摄像头！" forState:UIControlStateNormal];
    [self.switchBtn addTarget:self action:@selector(onSwitchClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.switchBtn];
    
    self.saveVideoBtn = [[UIButton alloc] initWithFrame:CGRectMake(100, 150, 150, 30)];
    [self.saveVideoBtn setTitle:@"保存到相册！" forState:UIControlStateNormal];
    [self.saveVideoBtn addTarget:self action:@selector(onSaveVideo) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.saveVideoBtn];
     */
}

- (void)onStartClick {
    
    if (self.capture.isCapturing) {
        [self.startBtn setTitle:@"开始直播！" forState:UIControlStateNormal];
        [self.capture stopCapture];
    }else{
        self.capture.rtmpUrl = @"rtmp://192.168.22.72:1935/rtmplive/room";
        if ([self.capture startCapture]) {
            [self.startBtn setTitle:@"停止直播！" forState:UIControlStateNormal];
        }
    }
}

- (void)onSwitchClick {
    
    [self.capture switchCamera];
}

- (void)savePathToLibrary:(NSString *)path{
    NSURL *url = [NSURL fileURLWithPath:path];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:url];
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            NSLog(@"保存成功");
            [fileManager removeItemAtPath:path error:nil];
        }];
        
    }else{
        NSLog(@"没有找到文件！%@",path);
    }
}

-(void) onSaveVideo{
    [self savePathToLibrary:self.capture.videoMp4File.defaultPath];
}

@end
