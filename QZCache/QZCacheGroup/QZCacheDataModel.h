//
//  QZCacheDataModel.h
//  QZCache
//
//  Created by 胡沁志 on 2020/8/12.
//  Copyright © 2020 胡沁志. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface QZCacheDataModel : NSObject
@property (nonatomic, assign)NSUInteger length;
@property (nonatomic, strong)NSData *data;
@property (nonatomic, strong)NSDate *lastUseDate;

-(NSDictionary*)dictionary;
-(instancetype)initWithDictionary:(NSDictionary*)dictionary;
-(void)updateUseDate;
@end

NS_ASSUME_NONNULL_END
