//
//  ZKPictureSlideController.h
//  ZKPictureSlideController
//
//  Created by lee on 16/3/28.
//  Copyright (c) 2016年 sanchun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZKPictureSlideController : UIViewController<UIScrollViewDelegate>

@property(nonatomic,strong)NSArray *paths;
@property(nonatomic)NSInteger showIndex;
@property(nonatomic)BOOL isRelativePaths;
@property(nonatomic)BOOL hiddenPage;

@property(nonatomic,strong)UIScrollView *containerScrollView;

-(id)initWithPicturePaths:(NSArray *)paths atShowIndex:(NSInteger)index;

@end
