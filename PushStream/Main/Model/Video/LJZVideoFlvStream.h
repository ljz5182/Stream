//
//  LJZVideoFlvStream.h
//  PushStream
//
//  Created by 梁家章 on 2017/7/27.
//  Copyright © 2017年 liangjiazhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LJZVideoInFoList.h"

@interface LJZVideoFlvStream : NSObject


@property (nonatomic, copy) NSString *rtmpUrl;


- (void)notifyMp4FileListChanged:(LJZVideoInFoList *)list;

- (void)startStream;

- (void)stopStream;


@end
