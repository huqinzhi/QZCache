//
//  QZCacheManager.h
//  QZCache
//
//  Created by 胡沁志 on 2020/8/11.
//  Copyright © 2020 胡沁志. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface QZCacheManager : NSObject
+(instancetype)shareManager;


/*
 设置最大下载缓存 单位为MB
 默认为50MB
 */
-(void)configMaxDownLoadSizeOfMB:(double)max;
/*
 查看当前设置的最大下载缓存
 */
-(double)catMaxDownLoadSize;
/*
 存储下载数据
 */
-(void)storageDownLoadData:(NSData *)data withKey:(NSString *)key completion:(nullable void (^)(NSError * _Nullable error))completion;

-(void)storageLocalData:(NSData *)data withKey:(NSString *)key completion:(nullable void (^)(NSError * _Nullable error))completion;
/*
 读取数据
 */
-(id)readDataForKey:(NSString*)key;
/*
 设置最大本地缓存 单位为MB
 默认为50MB
 */
-(void)configMaxLocalSizeOfMB:(double)max;
/*
 查看当前设置的最大本地缓存
*/
-(double)catMaxLocalSize;


@end


