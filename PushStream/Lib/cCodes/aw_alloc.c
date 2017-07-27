//
//  aw_alloc.c
//  PushStream
//
//  Created by 梁家章 on 2017/7/27.
//  Copyright © 2017年 liangjiazhang. All rights reserved.
//

#include "aw_alloc.h"
#include "aw_utils.h"
#include <stdlib.h>
#include <string.h>

struct aw_debug_alloc_list;

//分配的所有size
static size_t aw_static_debug_total_alloc_size = 0;
static size_t aw_static_debug_total_free_size = 0;
static struct aw_debug_alloc_list *aw_static_debug_alloc_list = NULL;
static int8_t aw_static_debug_alloc_inited = 0;

//辅助链表元素
typedef struct aw_debug_alloc_list_element{
    void *pointer;
    size_t size;
    struct aw_debug_alloc_list_element *pre;
    struct aw_debug_alloc_list_element *next;
}aw_debug_alloc_list_element;

static aw_debug_alloc_list_element * aw_alloc_debug_alloc_list_element(){
    aw_debug_alloc_list_element *element = malloc(sizeof(aw_debug_alloc_list_element));
    memset(element, 0, sizeof(aw_debug_alloc_list_element));
    return element;
}

static void aw_free_debug_alloc_list_element(aw_debug_alloc_list_element *ele){
    free(ele);
}

//辅助链表
typedef struct aw_debug_alloc_list{
    aw_debug_alloc_list_element *first;
    aw_debug_alloc_list_element *last;
}aw_debug_alloc_list;

static aw_debug_alloc_list *aw_alloc_debug_alloc_list(){
    aw_debug_alloc_list *list = malloc(sizeof(aw_debug_alloc_list));
    memset(list, 0, sizeof(aw_debug_alloc_list));
    return list;
}

static void aw_free_debug_alloc_list(aw_debug_alloc_list *list){
    aw_debug_alloc_list_element *ele = list->first;
    while (ele) {
        aw_debug_alloc_list_element *free_ele = ele;
        ele = ele->next;
        aw_free_debug_alloc_list_element(free_ele);
    }
    free(list);
}

//查找链表元素
static aw_debug_alloc_list_element * aw_find_element_in_debug_alloc_list(aw_debug_alloc_list *list, void * pointer){
    aw_debug_alloc_list_element *ele = list->first;
    while (ele) {
        if (ele->pointer == pointer) {
            return ele;
        }
        ele = ele->next;
    }
    return NULL;
}

//增加元素
static void aw_debug_alloc_list_add_ele(aw_debug_alloc_list *list, void * pointer, size_t size){
    aw_debug_alloc_list_element *find_ele = aw_find_element_in_debug_alloc_list(list, pointer);
    if (find_ele) {
        AWLog("[ERROR] in debug_alloc_list_add_ele repeat pointer!!!!");
        return;
    }
    aw_debug_alloc_list_element *ele = aw_alloc_debug_alloc_list_element();
    ele->pointer = pointer;
    ele->size = size;
    
    if (!list->first) {
        list->first = ele;
        list->last = list->first;
    }else{
        list->last->next = ele;
        ele->pre = list->last;
        list->last = ele;
    }
}

//删除元素
static void aw_debug_alloc_list_remove_ele(aw_debug_alloc_list *list, void * pointer){
    aw_debug_alloc_list_element *find_ele = aw_find_element_in_debug_alloc_list(list, pointer);
    if (!find_ele) {
        AWLog("[ERROR] in debug_alloc_list_remove_ele cant find pointer!!!!");
        return;
    }
    
    if (find_ele == list->first) {
        list->first = find_ele->next;
        if (list->first) {
            list->first->pre = NULL;
        }
    }else if(find_ele == list->last){
        list->last = find_ele->pre;
        list->last->next = NULL;
    }else{
        find_ele->pre->next = find_ele->next;
        find_ele->next->pre = find_ele->pre;
    }
    aw_free_debug_alloc_list_element(find_ele);
}

//关闭调试
void aw_uninit_debug_alloc(){
    aw_static_debug_total_alloc_size = 0;
    aw_static_debug_total_free_size = 0;
    if (aw_static_debug_alloc_list) {
        aw_free_debug_alloc_list(aw_static_debug_alloc_list);
    }
    aw_static_debug_alloc_list = NULL;
}

//开启调试
void aw_init_debug_alloc(){
    if (aw_static_debug_alloc_inited) {
        return;
    }
    aw_static_debug_alloc_inited = 1;
    aw_uninit_debug_alloc();
    aw_static_debug_alloc_list = aw_alloc_debug_alloc_list();
}

//纪录分配内存
static void aw_debug_alloc_do_alloc(void *pointer, size_t size){
    if (!aw_static_debug_alloc_list) {
        return;
    }
    aw_debug_alloc_list_add_ele(aw_static_debug_alloc_list, pointer, size);
    aw_static_debug_total_alloc_size += size;
    AWLog(" ---分配了%ld个字节 %p ", size, pointer);
}

//纪录释放内存
static void aw_debug_alloc_do_free(void *pointer){
    if (!aw_static_debug_alloc_list) {
        return;
    }
    aw_debug_alloc_list_element *free_ele = aw_find_element_in_debug_alloc_list(aw_static_debug_alloc_list, pointer);
    if (free_ele) {
        aw_static_debug_total_free_size += free_ele->size;
        aw_debug_alloc_list_remove_ele(aw_static_debug_alloc_list, pointer);
        AWLog(" ---释放了%ld个字节 %p ", free_ele->size, pointer);
    }else{
        AWLog("[ERROR] when debug_alloc_do_free cant find pointer(%p) in debug_alloc_list", pointer);
    }
}

//分配
void * aw_alloc(size_t size){
    void *pointer = malloc(size);
    memset(pointer, 0, size);
    
    //纪录分配的指针和大小
    aw_debug_alloc_do_alloc(pointer, size);
    
    return pointer;
}

//释放
void aw_free(void *p){
    //纪录释放的指针和大小
    aw_debug_alloc_do_free(p);
    
    free(p);
}

//分配总数
size_t aw_total_alloc_size(){
    return aw_static_debug_total_alloc_size;
}

//释放总数
size_t aw_total_free_size(){
    return aw_static_debug_total_free_size;
}

//打印
void aw_print_alloc_description(){
    AWLog("[debug alloc] total alloc size(%ld), total free size(%ld)", aw_total_alloc_size(), aw_total_free_size());
}
