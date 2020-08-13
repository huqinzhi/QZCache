//
//  ViewController.m
//  QZCache
//
//  Created by 胡沁志 on 2020/8/11.
//  Copyright © 2020 胡沁志. All rights reserved.
//

#import "ViewController.h"
#import "QZCacheNetwork.h"
#import "QZCacheManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self testData];
    // Do any additional setup after loading the view.
}

-(void)testData{
//    NSString *path = [[NSBundle mainBundle]pathForResource:@"testvideo1" ofType:@"mp4"];
//    NSData *testData = [NSData dataWithContentsOfFile:path];
//
    [[QZCacheManager shareManager]configMaxDownLoadSizeOfMB:2.4];
    NSArray<NSString *> *urls = [NSArray arrayWithObjects:@"http://io.xiaoyu233.xyz:10809/testvideo1.mp4",@"http://io.xiaoyu233.xyz:10809/testImage1.jpeg",@"http://io.xiaoyu233.xyz:10809/testImage2.jpeg",@"http://io.xiaoyu233.xyz:10809/testImage3.jpeg",@"http://io.xiaoyu233.xyz:10809/testvideo2.mp4", nil];
    
//    NSString *url = @"http://io.xiaoyu233.xyz:10809/testImage1.jpeg";
//    [QZCacheNetwork requestDownLoadURL:url success:^(id  _Nullable responseObject) {
//        NSData *data = (NSData *)responseObject;
//        NSLog(@"%@",data);
//    } failure:^(NSError * _Nullable error) {
//
//    }];
    [QZCacheNetwork requestDownLoadURLs:urls success:^(NSData * _Nullable responseObject, NSString *url) {
        NSLog(@"url:%@",url);
    } failure:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"%@",error);
        }
    }];
    
}

@end
