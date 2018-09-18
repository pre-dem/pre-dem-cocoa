//
//  PREDPersistence.h
//  Pods
//
//  Created by 王思宇 on 14/09/2017.
//
//

#import "PREDAppInfo.h"
#import "PREDCustomEvent.h"
#import <Foundation/Foundation.h>

@class PREDTransaction;

@interface PREDPersistence : NSObject

- (void)persist:(id<PREDSerializeData>)data;

// 将收集到的相关数据序列化并持久化到本地
- (void)persistSave:(NSData *)data;

// 获取持久化在本地的各种数据文件地址
- (NSString *)nextArchivedPath;

// 清除缓存文件相关方法
- (void)purgeFile:(NSString *)filePath;

- (void)purgeFiles:(NSArray<NSString *> *)filePaths;

- (void)purgeAll;

- (instancetype)initWithPath:(NSString *)path queue:(NSString *)queue;

@end
