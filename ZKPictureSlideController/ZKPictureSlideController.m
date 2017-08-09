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
#import <MobileCoreServices/MobileCoreServices.h>
#import <Masonry/Masonry.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <AFNetworking/AFNetworking.h>


@interface ZKPictureSlideController ()<UIActionSheetDelegate>

@property (nonatomic,strong) NSMutableArray *contentViews;
@property (nonatomic,strong) NSMutableDictionary *plyersDics;
@property (nonatomic,strong) NSMutableArray *contentScrollViews;
@property (nonatomic,strong) UIPageControl *pageControl;
@property (nonatomic,strong) AVPlayer *currentPlayer;


@end

@implementation ZKPictureSlideController

- (instancetype)initWithPicturePaths:(NSArray *)paths currentIndex:(NSUInteger)currentIndex{
    if (self = [super init]) {
        if (currentIndex < paths.count) {
            self.paths = paths;
            self.currentIndex = currentIndex;
        }
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initUI];
    
    // Do any additional setup after loading the view.
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                           error:&error];
    if(!error) {
        [[AVAudioSession sharedInstance] setActive:YES error:&error];
        if(error) NSLog(@"Error while activating AudioSession : %@", error);
    } else {
        NSLog(@"Error while setting category of AudioSession : %@", error);
    }
}

- (void)initUI {
    self.view.backgroundColor = [UIColor blackColor];
    [self createUI];
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    [_contentScrollViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIImageView *contentView = _contentViews[idx];
        CALayer *playerLayer = [[contentView.layer sublayers] lastObject];
        playerLayer.frame = self.view.bounds;
    }];
    
//     _pageControl.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height - 50);
//    _containerScrollView.contentOffset = CGPointMake(_pageControl.currentPage * self.view.frame.size.width, 0);
    
}



-(BOOL)shouldAutorotate{
    return YES;
}




-(void)createUI{
    [self.containerScrollView removeFromSuperview];
    [self.contentScrollViews removeAllObjects];
    [self.contentViews removeAllObjects];
    [self.plyersDics removeAllObjects];
    
    
    
    // 1
    _containerScrollView = [[UIScrollView alloc]init];
    //_containerScrollView.backgroundColor = [UIColor yellowColor];
    _containerScrollView.pagingEnabled = YES;
    _containerScrollView.delegate = self;
    [self.view addSubview:_containerScrollView];
    [_containerScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
        make.size.mas_equalTo(self.view);
    }];
   
    
    

    
    //宽度由内容确定
    [_containerScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
        make.height.mas_equalTo(_containerScrollView.mas_height);
    }];
    
    UIScrollView *lastScrollView = nil;
    for (int i = 0; i < self.paths.count; i++) {
        
        NSString *path =  self.paths[i];
        
        // 2
        UIScrollView *contentScrollView = [[UIScrollView alloc]init];
        //contentScrollView.backgroundColor = [UIColor blueColor];
        contentScrollView.tag = 1000 + i;
        contentScrollView.delegate = self;
        contentScrollView.minimumZoomScale = 1;
        contentScrollView.maximumZoomScale = 20;
        [self.containerScrollView addSubview:contentScrollView];
        [self.contentScrollViews addObject:contentScrollView];
        
        if (self.paths.count == 1) {
            [contentScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.edges.mas_equalTo(UIEdgeInsetsZero);
                make.size.mas_equalTo(self.containerScrollView);
            }];
        } else {
            if (i == 0) {
                [contentScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.left.and.top.and.bottom.mas_equalTo(0);
                    make.size.mas_equalTo(self.containerScrollView);
                }];
                
            } else if (i == self.paths.count - 1) { //最後一個
                [contentScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.top.and.right.and.bottom.mas_equalTo(0);
                    make.left.mas_equalTo(lastScrollView.mas_right);
                    make.size.mas_equalTo(self.containerScrollView);
                }];
            } else {
                [contentScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.left.mas_equalTo(lastScrollView.mas_right);
                    make.top.and.bottom.mas_equalTo(0);
                    make.size.mas_equalTo(self.containerScrollView);
                }];
                
            }
            
            lastScrollView = contentScrollView;
        }
        
        
        //双击放大
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapAction:)];
        tapGestureRecognizer.numberOfTapsRequired = 2;
        [contentScrollView addGestureRecognizer:tapGestureRecognizer];
        
        //单击关闭
        UITapGestureRecognizer *dismissTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapAction:)];
        dismissTap.numberOfTapsRequired = 1;
        [self.view addGestureRecognizer:dismissTap];
        
        //防止手势冲突
        [dismissTap requireGestureRecognizerToFail:tapGestureRecognizer];
        
        //长按保存
        UILongPressGestureRecognizer *longPressGR = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(showSaveAlert:)];
        [contentScrollView addGestureRecognizer:longPressGR];
        
        UIView *contentView;
        if ([path rangeOfString:@"http://"].location != NSNotFound || [path rangeOfString:@"https://"].location != NSNotFound) {
            //网络文件只能通過後綴判断类型
            
            contentView = [UIView new];
            if ([path hasSuffix:@".jpg"] || [path hasSuffix:@".png"]) {
                // 3
                UIImageView *imageView = [UIImageView new];
                imageView.contentMode = UIViewContentModeScaleAspectFit;
                imageView.userInteractionEnabled = YES;
                imageView.backgroundColor = [UIColor blackColor];
                contentView = imageView;

                MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:contentScrollView];
                [imageView sd_setImageWithURL:[NSURL URLWithString:path] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                    [hud hideAnimated:YES];
                }];
                
            }else if([path hasSuffix:@".mov"] || [path hasSuffix:@".MOV"] || [path hasSuffix:@".mp4"] || [path hasSuffix:@".MP4"]){
                
                
                [self requestDownloadVideoWithURL:path atView:contentView];
            }
            
            
        } else { //本地文件
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:path]) { //文件存在
                NSString *mineType = [self getMIMETypeWithCAPIAtFilePath:path];
                contentView = [UIView new];
                
                if ([mineType rangeOfString:@"image"].location != NSNotFound) { //图片
                    // 3
                    UIImageView *imageView = [UIImageView new];
                    imageView.contentMode = UIViewContentModeScaleAspectFit;
                    imageView.userInteractionEnabled = YES;
                    imageView.backgroundColor = [UIColor blackColor];

                    UIImage *image = [UIImage imageWithContentsOfFile:path];
                    imageView.image = image;
                    
                    contentView = imageView;
                    
                } else if ([mineType rangeOfString:@"video"].location != NSNotFound) { //視頻
                    
                    
                    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                        [self playerVideoAtView:contentView path:path];
                    }
                }
            }
            
            
        }
        //contentView.backgroundColor = [UIColor redColor];
        [contentScrollView addSubview:contentView];
        [_contentViews addObject:contentView];
        [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(UIEdgeInsetsZero);
            make.size.mas_equalTo(self.containerScrollView);
        }];
    }
    
    CGPoint offset = self.containerScrollView.contentOffset;
    offset.x = self.view.frame.size.width * self.currentIndex;
    [self.containerScrollView setContentOffset:offset];


    
    if (self.paths.count > 1 && !self.hiddenPage) {
        CGFloat pageWidth = 10;
        self.pageControl = [[UIPageControl alloc]initWithFrame:CGRectMake(0, 0, pageWidth * self.paths.count, pageWidth)];

        self.pageControl.numberOfPages = self.paths.count;
        self.pageControl.currentPage = self.currentIndex;
        
        [self.pageControl addTarget:self action:@selector(changePage:) forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:self.pageControl];
        [self.pageControl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.mas_equalTo(self.view.mas_centerX);
            make.bottom.mas_equalTo(self.view.mas_bottom).offset(-100);
        }];

    }
   


    
    [self viewDidLayoutSubviews];
}

- (NSString *)getMIMETypeWithCAPIAtFilePath:(NSString *)path {
    if (![[[NSFileManager alloc] init] fileExistsAtPath:path]) {
        return nil;
    }
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[path pathExtension], NULL);
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    NSString *type = (__bridge_transfer NSString *)(MIMEType);
    //CFRelease(MIMEType);
    if (type == nil) {
        type = @"application/octet-stream";
    }
    return type;
}

#pragma -mark- requst

- (void)requestDownloadVideoWithURL:(NSString *)urlSting atView:(UIView *)view {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlSting] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:20];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];

    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:view];
    hud.mode = MBProgressHUDModeDeterminate;
    [view addSubview:hud];
    [hud showAnimated:YES];
    

    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    [path stringByAppendingPathComponent:[urlSting lastPathComponent]];
    [[self.paths mutableCopy] replaceObjectAtIndex:[self.paths indexOfObject:urlSting] withObject:path];
    

    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:^(NSProgress * _Nonnull downloadProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            hud.progress = downloadProgress.fractionCompleted;
        });
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        [hud hideAnimated:YES];
        if (error == nil) {
            NSData *data = responseObject;
            if ([data writeToFile:path atomically:YES]) {
                [self playerVideoAtView:view path:path];
            }
        }else{
            NSLog(@"%@",error.localizedDescription);
        }
    }];
    [dataTask resume];
}

- (void)playerVideoAtView:(UIView *)view path:(NSString *)path{
    NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
    AVPlayerItem *playerItem = [[AVPlayerItem alloc]initWithURL:url];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
    [_plyersDics setObject:player forKey:path];
    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:player];
    layer.frame = self.view.bounds;

    layer.videoGravity =  AVLayerVideoGravityResizeAspect;

    [view.layer addSublayer:layer];
    
    NSInteger index = [_paths indexOfObject:path];
    if (index == self.currentIndex) {
        [player play];
        self.currentPlayer = player;
    }
}

//- (NSInteger)currentIndex{
//    return  _containerScrollView.contentOffset.x / self.view.frame.size.width;
//}

#pragma -mark- UIScrollViewDelegate

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    
    if (scrollView != _containerScrollView) {
        NSInteger index = scrollView.tag - 1000;
        UIView *view = self.contentViews[index];
        if ([view isKindOfClass:[UIImageView class]]) {
            return view;
        }
    }
    return nil;
}


-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    if (scrollView == _containerScrollView) {
        NSInteger lastIndex = self.currentIndex;
        NSInteger currentIndex = _containerScrollView.contentOffset.x / self.view.frame.size.width;
        if (lastIndex != currentIndex) {
            
            NSString *lastPath = self.paths[lastIndex];
            UIScrollView *lastScrollView = self.contentScrollViews[lastIndex];
            UIView *lastContentView = self.contentViews[lastIndex];
            if ([lastContentView isKindOfClass:[UIImageView class]]) {
                [lastScrollView setZoomScale:1];
                lastScrollView.contentOffset = CGPointZero;

            } else {
                AVPlayer *player = (AVPlayer *)_plyersDics[lastPath];
                [player pause];
            }
            
            
            NSString *currentPath = self.paths[currentIndex];
            UIView *currentContentView = self.contentViews[currentIndex];
            
            if ([currentContentView isKindOfClass:[UIImageView class]]) {
                self.currentPlayer = nil;
            } else {
                AVPlayer *player = (AVPlayer *)self.plyersDics[currentPath];
                [player play];
                self.currentPlayer = player;
            }
            
            self.currentIndex = currentIndex;
        }
    }

}

#pragma -mark- pageControl

-(void)changePage:(UIPageControl *)pageControl{
    _containerScrollView.contentOffset = CGPointMake(pageControl.currentPage * self.view.frame.size.width, 0);
    NSInteger lastIndex = self.currentIndex;
    NSInteger currentIndex = _containerScrollView.contentOffset.x / self.view.frame.size.width;
    if (lastIndex != currentIndex) {
        
        NSString *lastPath = self.paths[lastIndex];
        UIScrollView *lastScrollView = self.contentScrollViews[lastIndex];
        UIView *lastContentView = self.contentViews[lastIndex];
        if ([lastContentView isKindOfClass:[UIImageView class]]) {
            [lastScrollView setZoomScale:1];
            lastScrollView.contentOffset = CGPointZero;
            
        } else {
            AVPlayer *player = (AVPlayer *)_plyersDics[lastPath];
            [player pause];
        }
        
        
        NSString *currentPath = self.paths[currentIndex];
        UIView *currentContentView = self.contentViews[currentIndex];
        
        if ([currentContentView isKindOfClass:[UIImageView class]]) {
            [self.currentPlayer pause];
            self.currentPlayer = nil;
        } else {
            AVPlayer *player = (AVPlayer *)self.plyersDics[currentPath];
            [player play];
            self.currentPlayer = player;
        }
        
        self.currentIndex = currentIndex;
    }
}

#pragma -mark- action

-(void)tapAction:(UITapGestureRecognizer *)tapGestureRecognizer{
    if ([tapGestureRecognizer.view isKindOfClass:[UIScrollView class]]) {
        if (tapGestureRecognizer.numberOfTapsRequired == 2) {
            UIScrollView *contentScrollView = (UIScrollView *)tapGestureRecognizer.view;
            if (contentScrollView.zoomScale > 1) {
                [contentScrollView setZoomScale:1 animated:YES];
            }else{
                [contentScrollView setZoomScale:2 animated:YES];
            }
        }
        
        
    }else if (tapGestureRecognizer.numberOfTapsRequired == 1){
        [self dismissViewControllerAnimated:YES completion:nil];

        //[_currentPlayer play];

    }
}

- (void)showSaveAlert:(UILongPressGestureRecognizer*)longPressGR{
    
    if (longPressGR.state == UIGestureRecognizerStateEnded) {
#ifdef __IPHONE_8_0
        NSInteger Index = longPressGR.view.tag - 1000;
        NSString *path = self.paths[Index];
        UIAlertControllerStyle style = UIAlertControllerStyleActionSheet;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            style = UIAlertControllerStyleAlert;
        }
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"保存", nil) message:NSLocalizedString(@"保存到相冊?", nil)  preferredStyle:style];
        UIAlertAction *cacelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"取消", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            
        }];
        UIAlertAction *submitAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"确定", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self saveFromPath:path];
        }];
        [alertC addAction:cacelAction];
        [alertC addAction:submitAction];
       
        [self presentViewController:alertC animated:YES completion:^{
            
        }];
#else
        UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:NSLocalizedString(@"保存", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"取消", nil) destructiveButtonTitle:NSLocalizedString(@"确定", nil) otherButtonTitles:nil];
        actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        [actionSheet showInView:self.view];
#endif
        
       
    }
    
    
    
}

#pragma -mark- UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
        NSString *path = self.paths[[self currentIndex]];
        [self saveFromPath:path];
    }
}

#pragma -mark-保存到相册

- (void)saveFromPath:(NSString *)path{
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return;
    }

    [self.hud showAnimated:YES];
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc]init];
    NSString *mineType = [self getMIMETypeWithCAPIAtFilePath:path];
    if ([mineType rangeOfString:@"image"].location != NSNotFound) { //图片
        UIImage *image = [UIImage imageWithContentsOfFile:path];
        [library writeImageToSavedPhotosAlbum:image.CGImage orientation:(ALAssetOrientation)image.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error) {
            
            if (!error) {
                [self showAlertWithTitle:@"保存成功!" andMsg:nil];
            }else{
                [self showAlertWithTitle:@"保存失敗" andMsg:nil];
                
            }
            [self.hud hideAnimated:YES];
        }];
        
    } else if ([mineType rangeOfString:@"video"].location != NSNotFound) { //視頻
        
        NSURL *url = [[NSURL alloc]initFileURLWithPath:path];
        [library writeVideoAtPathToSavedPhotosAlbum:url completionBlock:^(NSURL *assetURL, NSError *error) {
            if (!error) {
                [self showAlertWithTitle:NSLocalizedString(@"保存成功!", nil) andMsg:nil];
            }else{
                [self showAlertWithTitle:NSLocalizedString(@"保存失败!", nil) andMsg:nil];
            }
            [self.hud hideAnimated:YES];
        }];
    }
}

#pragma -mark- noyofication

-(void)playbackFinished:(NSNotification *)notification {
    if (notification.object == self.currentPlayer.currentItem) {
        [self.currentPlayer seekToTime:kCMTimeZero];
        [self.currentPlayer play];
    }
    
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg {
#ifdef __IPHONE_8_0
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cacelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"确定", nil) style:UIAlertActionStyleCancel handler:nil];
    [alertC addAction:cacelAction];
    [self presentViewController:alertC animated:YES completion:nil];
#else
    UIAlertView *alertV = [[UIAlertView alloc]initWithTitle:title message:msg delegate:nil cancelButtonTitle:NSLocalizedString(@"确定", nil) otherButtonTitles:nil];
    [alertV show];
#endif
}

#pragma -mark- getter

- (NSMutableArray *)contentViews {
    if (_contentViews == nil) {
        _contentViews = [NSMutableArray new];
    }
    return _contentViews;
}

- (NSMutableArray *)contentScrollViews {
    if (_contentScrollViews == nil) {
        _contentScrollViews = [NSMutableArray new];
    }
    return _contentScrollViews;
}

- (NSMutableDictionary *)plyersDics {
    if (_plyersDics == nil) {
        _plyersDics = [NSMutableDictionary new];
    }
    return _plyersDics;
}

- (MBProgressHUD *)hud {
    if (_hud == nil) {
        _hud = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:_hud];
    }
    [self.view bringSubviewToFront:_hud];
    return _hud;
}

- (void)setCurrentPlayer:(AVPlayer *)currentPlayer {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_currentPlayer.currentItem];
    _currentPlayer = currentPlayer;
    if (currentPlayer != nil) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:)name:AVPlayerItemDidPlayToEndTimeNotification object:currentPlayer.currentItem];
    }
}

- (void)setCurrentIndex:(NSUInteger)currentIndex {
    _currentIndex = currentIndex;
    self.pageControl.currentPage = currentIndex;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
