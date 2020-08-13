//
//  QZCacheManager.m
//  QZCache
//
//  Created by 胡沁志 on 2020/8/11.
//  Copyright © 2020 胡沁志. All rights reserved.
//

#import "QZCacheManager.h"
#import "QZCacheDataModel.h"
#import "GNThreadSafeAccessor.h"

static NSString *const kQZCacheDownLoadData = @"QZCache.QZStorage.QZDownLoadData";
static NSString *const kQZCacheLocalData = @"QZCache.QZStorage.QZLocalData";
static NSString *const kQZCacheDownLoadMaxSize = @"QZCache.QZStorage.QZDownLoadMaxSize";
static NSString *const kQZCacheLocalMaxSize = @"QZCache.QZStorage.QZLocalMaxSize";


@interface QZCacheManager ()
@property (nonatomic, strong)NSMutableDictionary<NSString *, NSDictionary *>* downLoadData;
@property (nonatomic, strong)NSMutableDictionary<NSString *, NSDictionary *>* localData;
@property (nonatomic, strong)GNThreadSafeAccessor *dataAccessor;
@property (nonatomic, assign)double maxDownLoadSize;
@property (nonatomic, assign)double maxLocalSize;
@end

@implementation QZCacheManager

+(instancetype)shareManager{
    static QZCacheManager * shareInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[QZCacheManager alloc]init];
    });
    return shareInstance;
}

-(instancetype)init{
    if (self = [super init]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[QZCacheManager pathOfQZCacheDownLoad]]) {
            _downLoadData = [[NSMutableDictionary alloc] initWithContentsOfFile:[QZCacheManager pathOfQZCacheDownLoad]];
        } else {
            _downLoadData = [NSMutableDictionary<NSString *, NSDictionary *> dictionary];
        }
        if ([[NSFileManager defaultManager]fileExistsAtPath:[QZCacheManager pathOfQZCacheLocal]]) {
            self.localData = [[NSMutableDictionary alloc]initWithContentsOfFile:[QZCacheManager pathOfQZCacheLocal]];
        } else {
            self.localData = [NSMutableDictionary<NSString *, NSDictionary *>dictionary];
        }
        if ([[NSUserDefaults standardUserDefaults]doubleForKey:kQZCacheDownLoadMaxSize] > 0) {
            self.maxDownLoadSize = [[NSUserDefaults standardUserDefaults]doubleForKey:kQZCacheDownLoadMaxSize];
        } else {
            self.maxDownLoadSize = 50.0;
            [[NSUserDefaults standardUserDefaults]setDouble:self.maxDownLoadSize forKey:kQZCacheDownLoadMaxSize];
        }
        if ([[NSUserDefaults standardUserDefaults]doubleForKey:kQZCacheLocalMaxSize] > 0) {
            self.maxLocalSize = [[NSUserDefaults standardUserDefaults]doubleForKey:kQZCacheLocalMaxSize];
        } else {
            self.maxLocalSize = 50.0;
            [[NSUserDefaults standardUserDefaults]setDouble:self.maxLocalSize forKey:kQZCacheLocalMaxSize];
        }
        
        self.dataAccessor = [[GNThreadSafeAccessor alloc]init];
    }
    return self;
}

-(void)configMaxDownLoadSizeOfMB:(double)max{
    [[NSUserDefaults standardUserDefaults]setDouble:max forKey:kQZCacheDownLoadMaxSize];
    self.maxDownLoadSize = max;
}

-(double)catMaxDownLoadSize{
    return self.maxDownLoadSize;
}

-(void)configMaxLocalSizeOfMB:(double)max{
    [[NSUserDefaults standardUserDefaults]setDouble:max forKey:kQZCacheLocalMaxSize];
    self.maxLocalSize = max;
}

-(double)catMaxLocalSize{
    return self.maxLocalSize;
}

-(id)readDataForKey:(NSString*)key{
    NSMutableDictionary *dataDic = self.downLoadData[key] != nil ? self.downLoadData : self.localData;
    id data = [self.dataAccessor readWithGCD:^id _Nonnull{
        QZCacheDataModel *model = [[QZCacheDataModel alloc]initWithDictionary:dataDic[key]];
        return model.data;
    }];
    [self.dataAccessor writeWithGCD:^{
        QZCacheDataModel *lastModel = [[QZCacheDataModel alloc]initWithDictionary:dataDic[key]];
        [lastModel updateUseDate];
        dataDic[key] = [lastModel dictionary];
        [dataDic writeToFile:[QZCacheManager pathOfQZCacheDownLoad] atomically:YES];
    }];
    return data;
}

-(void)storageDownLoadData:(NSData *)data withKey:(NSString *)key completion:(nullable void (^)(NSError * _Nullable error))completion {
    [self storageData:data withKey:key isDownLoad:YES completion:completion];
}

-(void)storageLocalData:(NSData *)data withKey:(NSString *)key completion:(nullable void (^)(NSError * _Nullable error))completion {
    [self storageData:data withKey:key isDownLoad:NO completion:completion];
}

-(void)storageData:(NSData *)data withKey:(NSString *)key isDownLoad:(BOOL)isDownLoad completion:(nullable void (^)(NSError * _Nullable error))completion{
    NSMutableDictionary * dataDic = isDownLoad ? self.downLoadData : self.localData;
    [self.dataAccessor writeWithGCD:^{
        //如果数据存在则修改最后使用时间
        if ([dataDic valueForKey:key] != nil) {
            QZCacheDataModel *lastModel = [[QZCacheDataModel alloc]initWithDictionary:dataDic[key]];
            [lastModel updateUseDate];
            dataDic[key] = [lastModel dictionary];
            [dataDic writeToFile:[QZCacheManager pathOfQZCacheDownLoad] atomically:YES];
            completion(nil);
            return;
        }
        QZCacheDataModel *model = [QZCacheDataModel new];
        model.data = data;
        model.length = data.length;
        model.lastUseDate = [NSDate date];
        NSUInteger allBytes = [[[dataDic allValues]valueForKeyPath:@"@sum.length"]unsignedIntegerValue];;
        NSUInteger max = isDownLoad ? self.maxDownLoadSize * 1024 * 1024 : self.maxLocalSize * 1024 * 1024;
        if (data.length > max) {
            NSError *error = [NSError errorWithDomain:@"The data exceeds the maximum limit" code:5001 userInfo:nil];
            completion(error);
            return;
        }
        if (allBytes + data.length < max) {
            //小于直接存
            dataDic[key] = [model dictionary];
        } else {
            NSUInteger removeSize = data.length - (max - allBytes); // 需要删除的数据大小
            //根据最后使用时间把key排序
            NSArray<NSString*> *arrangement = [dataDic keysSortedByValueUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
                QZCacheDataModel *m1 = [[QZCacheDataModel alloc]initWithDictionary:obj1];
                QZCacheDataModel *m2 = [[QZCacheDataModel alloc]initWithDictionary:obj2];
                return [m1.lastUseDate compare:m2.lastUseDate];
            }];
            __block NSUInteger removeCurrentSize = 0;
            NSMutableArray<NSString *> *removeKeyArr = [NSMutableArray new];
            [arrangement enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (removeCurrentSize < removeSize) {
                    QZCacheDataModel *currentModel = [[QZCacheDataModel alloc]initWithDictionary:self.downLoadData[obj]];
                    removeCurrentSize += currentModel.length;
                    [removeKeyArr addObject:obj];
                } else {
                    *stop = YES;
                }
            }];
            [removeKeyArr enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [dataDic removeObjectForKey:obj];
            }];
            //存储
            dataDic[key] = [model dictionary];
        }
        //写入本地缓存
        [dataDic writeToFile:[QZCacheManager pathOfQZCacheDownLoad] atomically:YES];
        completion(nil);
    }];
}

+(NSString *)pathOfQZCacheDownLoad{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:kQZCacheDownLoadData];
}

+(NSString *)pathOfQZCacheLocal{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:kQZCacheLocalData];
}

@end
//    [self.dataAccessor writeWithGCD:^{
//        //如果数据存在则修改最后使用时间
//        if ([self.downLoadData valueForKey:key] != nil) {
//            QZCacheDataModel *lastModel = [[QZCacheDataModel alloc]initWithDictionary:self.downLoadData[key]];
//            [lastModel updateUseDate];
//            self.downLoadData[key] = [lastModel dictionary];
//            [self.downLoadData writeToFile:[QZCacheManager pathOfQZCacheDownLoad] atomically:YES];
//            completion(nil);
//            return;
//        }
//        QZCacheDataModel *model = [QZCacheDataModel new];
//        model.data = data;
//        model.length = data.length;
//        model.lastUseDate = [NSDate date];
//        NSUInteger allBytes = [[[self.downLoadData allValues]valueForKeyPath:@"@sum.length"]unsignedIntegerValue];;
//        NSUInteger max = self.maxDownLoadSize * 1024 * 1024;
//        if (data.length > max) {
//            NSError *error = [NSError errorWithDomain:@"The data exceeds the maximum limit" code:5001 userInfo:nil];
//            completion(error);
//            return;
//        }
//        if (allBytes + data.length < max) {
//            //小于直接存
//            [self.dataAccessor writeWithGCD:^{
//                self.downLoadData[key] = [model dictionary];
//            }];
//        } else {
//            NSUInteger removeSize = data.length - (max - allBytes); // 需要删除的数据大小
//            //根据最后使用时间把key排序
//            NSArray<NSString*> *arrangement = [self.downLoadData keysSortedByValueUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
//                QZCacheDataModel *m1 = [[QZCacheDataModel alloc]initWithDictionary:obj1];
//                QZCacheDataModel *m2 = [[QZCacheDataModel alloc]initWithDictionary:obj2];
//                return [m1.lastUseDate compare:m2.lastUseDate];
//            }];
//            __block NSUInteger removeCurrentSize = 0;
//            NSMutableArray<NSString *> *removeKeyArr = [NSMutableArray new];
//            [arrangement enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//                if (removeCurrentSize < removeSize) {
//                    QZCacheDataModel *currentModel = [[QZCacheDataModel alloc]initWithDictionary:self.downLoadData[obj]];
//                    removeCurrentSize += currentModel.length;
//                    [removeKeyArr addObject:obj];
//                } else {
//                    *stop = YES;
//                }
//            }];
//            [removeKeyArr enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//                [self.downLoadData removeObjectForKey:obj];
//            }];
//            //存储
//            self.downLoadData[key] = [model dictionary];
//        }
//        //写入本地缓存
//        [self.downLoadData writeToFile:[QZCacheManager pathOfQZCacheDownLoad] atomically:YES];
//        completion(nil);
//    }];
