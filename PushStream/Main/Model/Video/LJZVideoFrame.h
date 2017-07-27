//
//  LJZVideoFrame.h
//  PushStream
//
//  Created by 梁家章 on 2017/7/27.
//  Copyright © 2017年 liangjiazhang. All rights reserved.
//


//保存sample数据

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


@interface LJZVideoFrame : NSObject


@property (nonatomic, unsafe_unretained) CMSampleBufferRef sampleBuff;

@property (nonatomic, unsafe_unretained) BOOL isVideo;
@end
