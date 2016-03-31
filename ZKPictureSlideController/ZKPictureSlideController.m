//
//  ZKPictureSlideController.m
//  ZKPictureSlideController
//
//  Created by lee on 16/3/28.
//  Copyright (c) 2016年 sanchun. All rights reserved.
//

#import "ZKPictureSlideController.h"

@interface ZKPictureSlideController ()
{
    NSMutableArray *_imageViews;
    NSMutableArray *_contentScrollViews;
    CGFloat lastOffsetX;
}
@end

@implementation ZKPictureSlideController

-(id)initWithPicturePaths:(NSArray *)paths atShowIndex:(NSInteger)index{
    if (self = [super init]) {
        _paths = paths;
        if (index < paths.count) {
            _showIndex = index;
        }
        [self createViewByPaths];
    }
    return self;
}

-(id)initWithImages:(NSArray *)images atShowIndex:(NSInteger)index{
    if (self = [super init]) {
        _images = images;
        if (index < images.count) {
             _showIndex = index;
        }
        [self createViewByImages];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];
}

-(UIScrollView *)containerScrollView{
    if (_containerScrollView == nil) {
        _containerScrollView = [[UIScrollView alloc]initWithFrame:self.view.bounds];
        _containerScrollView.pagingEnabled = YES;
        _containerScrollView.delegate = self;
        [self.view addSubview:_containerScrollView];
    }
    return _containerScrollView;
}


-(void)createViewByPaths{
    self.containerScrollView.contentSize = CGSizeMake(self.view.frame.size.width * self.paths.count, self.view.frame.size.height);
    
     _imageViews = [NSMutableArray new];
    _contentScrollViews = [NSMutableArray new];
    
    for (int i = 0; i < self.paths.count; i++) {
        NSString *path = self.paths[i];
        
        UIScrollView *contentScrollView = [[UIScrollView alloc]init];
        contentScrollView.tag = 1000 + i;
        contentScrollView.delegate = self;
        CGRect rect = self.view.bounds;
        rect.origin.x += i * self.view.frame.size.width;
        contentScrollView.frame = rect;
        contentScrollView.minimumZoomScale = 1;
        contentScrollView.maximumZoomScale = 3;
        [self.containerScrollView addSubview:contentScrollView];
        
        UIImage *image = [UIImage imageWithContentsOfFile:path];
        UIImageView *imageView = [[UIImageView alloc]initWithImage:image];
      
    
        CGFloat imgWidth = image.size.width;
        CGFloat imgHeight = image.size.height;
        CGFloat ratio = imgWidth/imgHeight;
        imageView.frame = CGRectMake(0, 0, self.view.frame.size.width,self.view.frame.size.width/ratio);
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        if (imgWidth > imgHeight || imageView.frame.size.height < self.view.frame.size.height) {
            imageView.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
        }
        contentScrollView.contentSize = CGSizeMake(imageView.frame.size.width, imageView.frame.size.height);
        [contentScrollView addSubview:imageView];
        [_contentScrollViews addObject:contentScrollView];
      
        
        CGPoint offset = _containerScrollView.contentOffset;
        offset.x = self.view.frame.size.width * self.showIndex;
        [self.containerScrollView setContentOffset:offset];
        
          [_imageViews addObject:imageView];
        
        imageView.userInteractionEnabled = YES;
        
    }
}

-(void)createViewByImages{
    self.containerScrollView.contentSize = CGSizeMake(self.view.frame.size.width * self.images.count, self.view.frame.size.height);

    _imageViews = [NSMutableArray new];
    for (int i = 0; i < self.images.count; i++) {
        UIScrollView *contentScrollView = [[UIScrollView alloc]init];
        CGRect rect = self.view.bounds;
        rect.origin.x += i * self.view.frame.size.width;
        contentScrollView.frame = rect;
        [self.containerScrollView addSubview:contentScrollView];
        
        UIImage *image = self.images[i];
        UIImageView *imageView = [[UIImageView alloc]initWithImage:image];
         imageView.tag = 1000 + i;
        
        CGFloat imgWidth = image.size.width;
        CGFloat imgHeight = image.size.height;
        
        imageView.frame = self.view.bounds;
        if (imgWidth > imgHeight) {
            imageView.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
        }
        [contentScrollView addSubview:imageView];
         [_imageViews addObject:imageView];
        
        CGPoint offset = _containerScrollView.contentOffset;
        offset.x = self.view.frame.size.width * (self.showIndex + 1);
        [self.containerScrollView setContentOffset:offset];
        
          [_imageViews addObject:imageView];
        
    }

}


-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    UIImageView *imageView = nil;
    if (scrollView != _containerScrollView) {
        
        NSInteger index = scrollView.tag - 1000;
        imageView = _imageViews[index];
    }
    return imageView;
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    if (scrollView == _containerScrollView) {
        if (lastOffsetX != _containerScrollView.contentOffset.x) {
            NSInteger index = _containerScrollView.contentOffset.x / self.view.frame.size.width;
            UIScrollView *contentScrollView = _contentScrollViews[index];
            [contentScrollView setZoomScale:1];
            lastOffsetX = _containerScrollView.contentOffset.x;
        }
        
        
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
