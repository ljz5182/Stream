//
//  aw_file.h
//  PushStream
//
//  Created by 梁家章 on 2017/7/27.
//  Copyright © 2017年 liangjiazhang. All rights reserved.
//

#ifndef aw_file_h
#define aw_file_h

#include <stdio.h>
#include "aw_data.h"

//iOS无法读取 main bundle 中的文件

//文件是否存在
extern int8_t aw_is_file_exist(const char *file_path);

//文件尺寸
extern size_t aw_file_size(const char *file_path);

//文件移除
extern int8_t aw_remove_file(const char *file_path);

//文件夹移除
extern int8_t aw_remove_dir(const char *file_dir);

//读取数据
extern aw_data *aw_read_data_from_file(const char *file_path);

//写入数据
extern int8_t aw_write_data_to_file(const char *file_path, aw_data *data);

//测试本文件
extern void aw_test_file(const char *dir);

#endif /* aw_file_h */
