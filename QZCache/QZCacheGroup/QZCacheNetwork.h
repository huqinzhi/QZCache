//
//  QZCacheNetwork.h
//  QZCache
//
//  Created by 胡沁志 on 2020/8/11.
//  Copyright © 2020 胡沁志. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface QZCacheNetwork : NSObject
/*
 单个请求
 success：返回数据一般返回时nsdata
 failure：返回error
 */
+(void)requestDownLoadURL:(NSString *)url success:(nullable void (^)(_Nullable id responseObject))success
                                  failure:(nullable void (^)(NSError * _Nullable error))failure;
/*
 多个请求
 success：返回数据一般返回时nsdata，和请求成功的url
 failure：返回error
*/
+(void)requestDownLoadURLs:(NSArray<NSString*>*)urls success:(nullable void (^)(NSData * _Nullable responseObject , NSString * url))success
                                                     failure:(nullable void (^)(NSError * _Nullable error))failure;

@end


