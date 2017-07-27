//
//  LJZVideoInFoList.m
//  PushStream
//
//  Created by 梁家章 on 2017/7/27.
//  Copyright © 2017年 liangjiazhang. All rights reserved.
//

#import "LJZVideoInFoList.h"


@interface LJZVideoInFoList () {
    
}


@property (nonatomic, strong) NSMutableArray *mutableArray;



@end

@implementation LJZVideoInFoList


- (NSMutableArray *)mutableArray {
    
    if (!_mutableArray) {
        _mutableArray = [NSMutableArray new];
    }
    return _mutableArray;
}

- (NSInteger)eleLimit {
    
    if (!_eleLimit) {
        _eleLimit = 8 * 25;
    }
    return _eleLimit;
}

- (void)addElement:(id)ele {
    
    @synchronized (self) {
        if (self.mutableArray.count >= self.eleLimit) {
            NSLog(@"drop one frame!!!!");
            [self popElement];
        }
        [self.mutableArray addObject:ele];
    }
}

- (void)addElementToHeader:(id)ele{
    
    [self.mutableArray insertObject:ele atIndex:0];
}


- (id)popElement {
    
    id ret = nil;
    @synchronized (self) {
        ret = self.mutableArray.firstObject;
        [self.mutableArray removeObjectAtIndex:0];
    }
    return ret;
}

- (void)clean {
    
    @synchronized (self) {
        self.mutableArray = nil;
    }
}

- (BOOL)empty {
    return self.mutableArray.count == 0;
}

- (NSInteger)count {
    return self.mutableArray.count;
}

- (NSString *)description{
     
    return _mutableArray.description;
}
@end
