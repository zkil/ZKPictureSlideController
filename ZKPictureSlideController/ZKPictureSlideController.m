//
//  ZKPictureSlideController.m
//  ZKPictureSlideController
//
//  Created by lee on 16/3/28.
//  Copyright (c) 2016年 sanchun. All rights reserved.
//

#import "ZKPictureSlideController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ZKPictureSlideController ()<UIActionSheetDelegate>
{
    NSMutableArray *_contentViews;
    NSMutableArray *_contentScrollViews;
    CGFloat lastOffsetX;
    
    UIActivityIndicatorView *_activityIndicatorView;
    
    NSMutableDictionary *_plyersDics;
    
    AVPlayer *_currentPlayer;
    
    UIPageControl *_pageControl;
}
@end

@implementation ZKPictureSlideController

-(id)initWithPicturePaths:(NSArray *)paths atShowIndex:(NSInteger)index{
    if (self = [super init]) {
        _paths = paths;
        if (index < paths.count) {
            _showIndex = index;
        }
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];
   
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:)name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    
    [self createUI];
}

-(void)playbackFinished:(NSNotification *)notification
{
    [_currentPlayer seekToTime:CMTimeMake(0, 1)];
    [_currentPlayer play];
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


-(void)createUI{
    
    
    self.containerScrollView.contentSize = CGSizeMake(self.view.frame.size.width * self.paths.count, self.view.frame.size.height);
    
     _contentViews = [NSMutableArray new];
    _contentScrollViews = [NSMutableArray new];
    _plyersDics = [NSMutableDictionary new];
    
    
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
        [_contentScrollViews addObject:contentScrollView];
        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapAction:)];
        tapGestureRecognizer.numberOfTapsRequired = 2;
        [contentScrollView addGestureRecognizer:tapGestureRecognizer];
        UILongPressGestureRecognizer *longPressGR = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(showSaveAlert:)];
        [contentScrollView addGestureRecognizer:longPressGR];
        
        UITapGestureRecognizer *dismissTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapAction:)];
        dismissTap.numberOfTapsRequired = 1;
        [contentScrollView addGestureRecognizer:dismissTap];
        
        [dismissTap requireGestureRecognizerToFail:tapGestureRecognizer];
        
        UIView *contentView;
        
        if ([path hasSuffix:@".jpg"] || [path hasSuffix:@".png"]) {
            UIImage *image = [UIImage imageWithContentsOfFile:path];
            UIImageView *imageView = [[UIImageView alloc]initWithImage:image];
            imageView.userInteractionEnabled = YES;
            CGFloat imgWidth = image.size.width;
            CGFloat imgHeight = image.size.height;
            CGFloat ratio = imgWidth/imgHeight;
            imageView.frame = CGRectMake(0, 0, self.view.frame.size.width,self.view.frame.size.width/ratio);
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            if (imgWidth > imgHeight || imageView.frame.size.height < self.view.frame.size.height) {
                imageView.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
            }
            contentView = imageView;
        }else if([path hasSuffix:@".mov"] || [path hasSuffix:@".MOV"] || [path hasSuffix:@".mp4"] || [path hasSuffix:@".MP4"]){
            contentView = [[UIView alloc]initWithFrame:CGRectMake(0, 0,self.view.frame.size.width, 500)];
            contentView.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
            
            NSURL *url = [[NSURL alloc]initFileURLWithPath:path];
            AVPlayerItem *playerItem = [[AVPlayerItem alloc]initWithURL:url];
            AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
            [_plyersDics setObject:player forKey:path];
            AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:player];
            layer.frame = contentView.bounds;
            layer.videoGravity =  AVLayerVideoGravityResizeAspectFill;
            [contentView.layer addSublayer:layer];
            contentView.backgroundColor = [UIColor yellowColor];
            if (i == 0) {
                _currentPlayer = player;
                [player play];
            }
        }
        
        contentScrollView.contentSize = CGSizeMake(contentView.frame.size.width, contentView.frame.size.height);
        [contentScrollView addSubview:contentView];
      
    
        [_contentViews addObject:contentView];
      
        
    }
    
    CGFloat pageWidth = 20;
    _pageControl = [[UIPageControl alloc]initWithFrame:CGRectMake(0, 0, pageWidth * self.paths.count, pageWidth)];
    _pageControl.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height - 100);
    _pageControl.numberOfPages = self.paths.count;
    _pageControl.currentPage = self.showIndex;
    //_pageControl.backgroundColor = [UIColor whiteColor];
    [_pageControl addTarget:self action:@selector(changePage:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_pageControl];
    
    CGPoint offset = _containerScrollView.contentOffset;
    offset.x = self.view.frame.size.width * self.showIndex;
    [self.containerScrollView setContentOffset:offset];
    
    lastOffsetX = offset.x;
    
    
    _activityIndicatorView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicatorView.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
    _activityIndicatorView.hidesWhenStopped = YES;
    [self.view addSubview:_activityIndicatorView];
}



- (NSInteger)currentIndex{
    return  _containerScrollView.contentOffset.x / self.view.frame.size.width;
}

-(void)tapAction:(UITapGestureRecognizer *)tapGestureRecognizer{
    if ([tapGestureRecognizer.view isKindOfClass:[UIScrollView class]]) {
        if (tapGestureRecognizer.numberOfTapsRequired == 2) {
            UIScrollView *contentScrollView = (UIScrollView *)tapGestureRecognizer.view;
            if (contentScrollView.zoomScale > 1) {
                [contentScrollView setZoomScale:1 animated:YES];
            }else{
                [contentScrollView setZoomScale:2 animated:YES];
            }
        }else if (tapGestureRecognizer.numberOfTapsRequired == 1){
            [self dismissViewControllerAnimated:YES completion:nil];
        }

        
    }
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    UIImageView *imageView = nil;
    if (scrollView != _containerScrollView) {
        
        NSInteger index = scrollView.tag - 1000;
        NSString *path = self.paths[index];
        
        if ([path hasSuffix:@".jpg"] || [path hasSuffix:@".png"]) {
            imageView = _contentViews[index];
         
        }
        
    }
    return imageView;
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    if (scrollView == _containerScrollView) {
        if (lastOffsetX != _containerScrollView.contentOffset.x) {
            NSInteger lastIndex = lastOffsetX / self.view.frame.size.width;
            NSInteger currentIndex = _containerScrollView.contentOffset.x / self.view.frame.size.width;
            
            NSString *lastPath = self.paths[lastIndex];
            NSString *currentPath = self.paths[currentIndex];
            
            if([lastPath hasSuffix:@".jpg"] || [lastPath hasSuffix:@".png"]) {
                UIScrollView *contentScrollView = _contentScrollViews[lastIndex];
                [contentScrollView setZoomScale:1];
                contentScrollView.contentOffset = CGPointZero;
            }else if([lastPath hasSuffix:@".mov"] || [lastPath hasSuffix:@".MOV"] || [lastPath hasSuffix:@".mp4"] || [lastPath hasSuffix:@".MP4"]){
                AVPlayer *player = (AVPlayer *)_plyersDics[lastPath];
                [player pause];
            }
            
            if ([currentPath hasSuffix:@".mov"] || [currentPath hasSuffix:@".MOV"] || [currentPath hasSuffix:@".mp4"] || [currentPath hasSuffix:@".MP4"]) {
                AVPlayer *player = (AVPlayer *)_plyersDics[currentPath];
                [player play];
                _currentPlayer = player;
            }else{
                _currentPlayer = nil;
            }
            
            _pageControl.currentPage = currentIndex;
            
            lastOffsetX = _containerScrollView.contentOffset.x;
        }
    }

}

-(void)changePage:(UIPageControl *)pageControl{
    _containerScrollView.contentOffset = CGPointMake(pageControl.currentPage * self.view.frame.size.width, 0);
    if (lastOffsetX != _containerScrollView.contentOffset.x) {
        NSInteger lastIndex = lastOffsetX / self.view.frame.size.width;
        NSInteger currentIndex = _containerScrollView.contentOffset.x / self.view.frame.size.width;
        
        NSString *lastPath = self.paths[lastIndex];
        NSString *currentPath = self.paths[currentIndex];
        
        if([lastPath hasSuffix:@".jpg"] || [lastPath hasSuffix:@".png"]) {
            UIScrollView *contentScrollView = _contentScrollViews[lastIndex];
            [contentScrollView setZoomScale:1];
            contentScrollView.contentOffset = CGPointZero;
        }else if([lastPath hasSuffix:@".mov"] || [lastPath hasSuffix:@".MOV"] || [lastPath hasSuffix:@".mp4"] || [lastPath hasSuffix:@".MP4"]){
            AVPlayer *player = (AVPlayer *)_plyersDics[lastPath];
            [player pause];
        }
        
        if ([currentPath hasSuffix:@".mov"] || [currentPath hasSuffix:@".MOV"] || [currentPath hasSuffix:@".mp4"] || [currentPath hasSuffix:@".MP4"]) {
            AVPlayer *player = (AVPlayer *)_plyersDics[currentPath];
            [player play];
            _currentPlayer = player;
        }else{
            _currentPlayer = nil;
        }
        
        _pageControl.currentPage = currentIndex;
        
        lastOffsetX = _containerScrollView.contentOffset.x;
    }

    
}

- (void)showSaveAlert:(UILongPressGestureRecognizer*)longPressGR{
    
    if (longPressGR.state == UIGestureRecognizerStateEnded) {
#ifdef __IPHONE_8_0
        NSInteger Index = longPressGR.view.tag - 1000;
        NSString *path = _paths[Index];
        UIAlertControllerStyle style = UIAlertControllerStyleActionSheet;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            style = UIAlertControllerStyleAlert;
        }
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"保存" message:@"保存到相冊" preferredStyle:style];
        UIAlertAction *cacelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            
        }];
        UIAlertAction *submitAction = [UIAlertAction actionWithTitle:@"確定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
           [self saveFromPath:path];
        }];
        [alertC addAction:cacelAction];
        [alertC addAction:submitAction];
       
        [self presentViewController:alertC animated:YES completion:^{
            
        }];
#else
        UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:@"保存" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"確定" otherButtonTitles:nil];
        actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        [actionSheet showInView:self.view];
#endif
        
       
    }
    
    
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
        NSString *path = _paths[[self currentIndex]];
        [self saveFromPath:path];
    }
}


-(void)saveFromPath:(NSString *)path{
    [_activityIndicatorView startAnimating];
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc]init];
    if ([path hasSuffix:@".png"] || [path hasSuffix:@".jpg"]) {
        UIImage *image = [UIImage imageWithContentsOfFile:path];
        [library writeImageToSavedPhotosAlbum:image.CGImage orientation:(ALAssetOrientation)image.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error) {
            
            if (!error) {
                [self showAlertWithTitle:@"保存成功!" andMsg:nil];
            }else{
                [self showAlertWithTitle:@"保存失敗" andMsg:nil];
        
            }
            [_activityIndicatorView stopAnimating];
        }];
        
    }else if([path hasSuffix:@".mov"] || [path hasSuffix:@".MOV"] || [path hasSuffix:@".mp4"] || [path hasSuffix:@".MP4"]){
        NSURL *url = [[NSURL alloc]initFileURLWithPath:path];
        [library writeVideoAtPathToSavedPhotosAlbum:url completionBlock:^(NSURL *assetURL, NSError *error) {
            if (!error) {
                [self showAlertWithTitle:@"保存成功!" andMsg:nil];
            }else{
                [self showAlertWithTitle:@"保存失敗" andMsg:nil];
            }
            [_activityIndicatorView stopAnimating];
        }];
    }
    
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg {
#ifdef __IPHONE_8_0
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cacelAction = [UIAlertAction actionWithTitle:@"確定" style:UIAlertActionStyleCancel handler:nil];
    [alertC addAction:cacelAction];
    [self presentViewController:alertC animated:YES completion:nil];
#else
    UIAlertView *alertV = [[UIAlertView alloc]initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"確定" otherButtonTitles:nil];
    [alertV show];
#endif
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
