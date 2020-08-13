//
//  QZCacheNetwork.m
//  QZCache
//
//  Created by 胡沁志 on 2020/8/11.
//  Copyright © 2020 胡沁志. All rights reserved.
//

#import "QZCacheNetwork.h"
#import <Foundation/Foundation.h>
#import "QZCacheManager.h"

@implementation QZCacheNetwork


+(void)requestDownLoadURL:(NSString *)url success:(nullable void (^)(_Nullable id responseObject))success
                                          failure:(nullable void (^)(NSError * _Nullable error))failure{
    //请求数据
    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data.length > 0 && ((NSHTTPURLResponse *)response).statusCode == 200){
            [[QZCacheManager shareManager]storageDownLoadData:data withKey:url completion:^(NSError * _Nullable error) {
                if (error == nil) {
                    success(data);
                } else {
                    failure(error);
                }
            }];
            success(data);
        } else {
            if (error != nil) {
                failure(error);
            }
        }
    }]resume];
}

+(void)requestDownLoadURLs:(NSArray<NSString*>*)urls success:(nullable void (^)(NSData * _Nullable responseObject , NSString * url))success
                                                     failure:(nullable void (^)(NSError * _Nullable error))failure{
    
    //队列
    dispatch_queue_t download_completion_queue = dispatch_queue_create("qz.qzcache.QZResourceDownloadQueue", DISPATCH_QUEUE_SERIAL);
    [urls enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[QZCacheManager shareManager]readDataForKey:obj] != nil) {
            //如果缓存中有数据， 则直接取
            success([[QZCacheManager shareManager]readDataForKey:obj],obj);
        } else {
//            无则发起网络请求
           [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:obj] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
               dispatch_async(download_completion_queue, ^{
                   if (data.length > 0 && ((NSHTTPURLResponse *)response).statusCode == 200){
                       //处理数据存储
                       [[QZCacheManager shareManager]storageDownLoadData:data withKey:obj completion:^(NSError * _Nullable error) {
                           if (error == nil) {
                               success(data,obj);
                           } else {
                               failure(error);
                           }
                       }];
                   } else {
                       if (error != nil) {
                            failure(error);
                       }
                   }
               });
           }]resume];
        }
    }];
}
@end
