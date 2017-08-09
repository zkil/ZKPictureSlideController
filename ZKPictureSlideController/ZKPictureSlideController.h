//
//  ZKPictureSlideController.h
//  ZKPictureSlideController
//
//  Created by lee on 16/3/28.
//  Copyright (c) 2016年 sanchun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MBProgressHUD/MBProgressHUD.h>

@interface ZKPictureSlideController : UIViewController<UIScrollViewDelegate>

//路径
@property(nonatomic,strong)NSArray *paths;

//当前index
@property(nonatomic)NSUInteger currentIndex;

//显示圆点
@property(nonatomic)BOOL hiddenPage;
@property (nonatomic,strong) MBProgressHUD *hud;

@property(nonatomic,strong)UIScrollView *containerScrollView;


/**
 创建一个图片视频展示视图控制器

 @param paths   文件路径或网络地址
 @param current 首次显示的图片 index

 @return ZKPictureSlideController
 */
- (instancetype)initWithPicturePaths:(NSArray *)paths currentIndex:(NSUInteger)currentIndex;

@end
