//
//  aw_utils.h
//  PushStream
//
//  Created by 梁家章 on 2017/7/27.
//  Copyright © 2017年 liangjiazhang. All rights reserved.
//

#ifndef aw_utils_h
#define aw_utils_h

#include <stdio.h>
#include "aw_alloc.h"

#define AWLog(...)  \
do{ \
printf(__VA_ARGS__); \
printf("\n");\
}while(0)

#endif /* aw_utils_h */
