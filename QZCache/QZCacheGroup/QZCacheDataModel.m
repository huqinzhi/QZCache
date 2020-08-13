//
//  QZCacheDataModel.m
//  QZCache
//
//  Created by 胡沁志 on 2020/8/12.
//  Copyright © 2020 胡沁志. All rights reserved.
//

#import "QZCacheDataModel.h"

static NSString *const kLastUseDateKey = @"lastUseDate";
static NSString *const kDataKey = @"data";
static NSString *const kLengthKey = @"length";

@implementation QZCacheDataModel

-(instancetype)initWithDictionary:(NSDictionary*)dictionary {
    if (self = [super init]) {
        self.data = (NSData *)dictionary[kDataKey];
        self.lastUseDate = (NSDate *)dictionary[kLastUseDateKey];
        self.length = [dictionary[kLengthKey]integerValue];
    }
    return self;
}
-(NSDictionary *)dictionary {
    return @{
             kLastUseDateKey:_lastUseDate != nil ? _lastUseDate : [NSDate date],
             kDataKey:[_data isKindOfClass:[NSData class]] ? _data : @{},
             kLengthKey:@(_length)
             };
}

-(void)updateUseDate{
    self.lastUseDate = [NSDate date];
}
@end
