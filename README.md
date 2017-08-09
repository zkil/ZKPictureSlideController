# ZKPictureSlideController
## 簡介:
展示多张图片和视频的视图控制器，左右滑动切换图片，双击可放大，并可移动图片，长按保存到相册。支持网络图片和视频下载。

### 第三方依赖

```
  pod 'Masonry', '~> 1.0.1'   #约束
  pod 'AFNetworking', '~> 3.1.0'
  pod 'MBProgressHUD', '~> 1.0.0'
  pod 'SDWebImage', '~> 4.0.0'
```

### 导入
` #import "ZKPictureSlideController.h"`

### 使用
```
/**
 创建一个图片视频展示视图控制器

 @param paths   文件路径或网络地址
 @param current 首次显示的图片 index

 @return ZKPictureSlideController
 */
- (instancetype)initWithPicturePaths:(NSArray *)paths currentIndex:(NSUInteger)currentIndex;
```

### 效果演示
![演示]()