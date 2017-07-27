//
//  LJZVideoInFoList.h
//  PushStream
//
//  Created by 梁家章 on 2017/7/27.
//  Copyright © 2017年 liangjiazhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LJZVideoInFoList : NSObject

//数量限制
@property (nonatomic, unsafe_unretained) NSInteger eleLimit;


- (void)addElement:(id)ele;

- (id)popElement;

- (void)addElementToHeader:(id)ele;

- (void)clean;

- (BOOL)empty;

- (NSInteger)count;


@end
