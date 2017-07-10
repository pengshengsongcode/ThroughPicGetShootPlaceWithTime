# ThroughPicGetShootPlaceWithTime
根据图片获取拍照时间和拍照地点
![效果图.gif](http://upload-images.jianshu.io/upload_images/1505288-78d9b8f676a4ac7e.gif?imageMogr2/auto-orient/strip)

参考
[iOS 获得图片的时间（通过拍照和取出）](http://blog.csdn.net/li1990101010/article/details/50462331)
[如何获取iPhone拍摄的png照片的拍摄时间,位置信息等图片属性?  ](http://www.cocoachina.com/bbs/read.php?tid=103913png)

###简单理念
>1. 拍照获取
拍照即可通过CoreLocation获取当前位置和当前时间。
>2. 相册获取
相册即可通过ALAssetsLibrary来获取拍摄时间和拍摄地点。

本软件是通过imagePicker的代理回调中获取info，并从info中获取大量有关的信息，部分图片没有是因为拍照时没有录入信息，存在无网络和关闭权限功能。

-----

###引入头文件

```
#import <MobileCoreServices/MobileCoreServices.h>

#import <ImageIO/CGImageProperties.h>

#import <AssetsLibrary/AssetsLibrary.h>

#import <CoreLocation/CoreLocation.h>

#import "NSDictionary+CLLocation.h"
```

###定义属性

```
@property (nonatomic, strong) UIImagePickerController *imagePickerVC;

@property (nonatomic, strong) CLLocationManager *locationmanager;//拍照定位

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *time;
@property (weak, nonatomic) IBOutlet UILabel *jingdu;
@property (weak, nonatomic) IBOutlet UILabel *weidu;
@property (weak, nonatomic) IBOutlet UILabel *location;

@property (nonatomic, copy) NSString *locationFormat;
```


###懒加载

```
#pragma mark 懒加载
- (UIImagePickerController *)imagePickerVC {
    if (!_imagePickerVC) {
        _imagePickerVC = [[UIImagePickerController alloc] init];
        // 设置资源来源（相册、相机、图库之一）
        //        imagePickerVC.sourceType = UIImagePickerControllerSourceTypeCamera;
        // 设置可用的媒体类型、默认只包含kUTTypeImage，如果想选择视频，请添加kUTTypeMovie
        // 如果选择的是视屏，允许的视屏时长为20秒
        _imagePickerVC.videoMaximumDuration = 20;
        // 允许的视屏质量（如果质量选取的质量过高，会自动降低质量）
        _imagePickerVC.videoQuality = UIImagePickerControllerQualityTypeHigh;
        _imagePickerVC.mediaTypes = @[(NSString *)kUTTypeMovie, (NSString *)kUTTypeImage];
        // 设置代理，遵守UINavigationControllerDelegate, UIImagePickerControllerDelegate 协议
        _imagePickerVC.delegate = self;
        // 是否允许编辑（YES：图片选择完成进入编辑模式）
//        _imagePickerVC.allowsEditing = YES;
        
    }
    return _imagePickerVC;
}


-(CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationManager.distanceFilter = 1000.0f;
    }
    return _locationManager;
}
```


###拍照相关代码

```


-(void)getLocation
{
    //判断定位功能是否打开
    if ([CLLocationManager locationServicesEnabled]) {
        self.locationManager = [[CLLocationManager alloc]init];
        self.locationManager.delegate = self;
        [self.locationManager requestAlwaysAuthorization];
        
        [self.locationManager requestWhenInUseAuthorization];
        
        //设置寻址精度
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locationManager.distanceFilter = 5.0;
        [self.locationManager startUpdatingLocation];
    }
}

//定位失败后调用此代理方法
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{}

//获取一次定位，然后关掉manager
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    //防止多次调用
    
    CLLocation *currentLocation = [locations lastObject];
    
    NSTimeInterval locationAge = -[currentLocation.timestamp timeIntervalSinceNow];
    
    if (locationAge > 5.0) return;
    
    if (currentLocation.horizontalAccuracy < 0) return;
    
    //当前经纬度
    self.jingdu.text = [NSString stringWithFormat:@"%f", currentLocation.coordinate.longitude];
    self.weidu.text = [NSString stringWithFormat:@"%f", currentLocation.coordinate.latitude];
    
    CLGeocoder *clGeoCoder = [[CLGeocoder alloc] init];
    
    CLLocation *newLocation = [[CLLocation alloc] initWithLatitude:currentLocation.coordinate.latitude longitude:currentLocation.coordinate.longitude];
    
    __weak typeof(self)weakSelf = self;
    
    //反向地理编码的请求 -> 根据经纬度 获取 位置
    [clGeoCoder reverseGeocodeLocation:newLocation completionHandler: ^(NSArray *placemarks,NSError *error) {
        
        for (CLPlacemark *placeMark in placemarks)
        {
            NSDictionary *addressDic=placeMark.addressDictionary;
            
            NSArray *location_Arr = [addressDic objectForKey:@"FormattedAddressLines"];//系统格式化后的位置
            
            weakSelf.location.text = [location_Arr firstObject];
        }
    }];
    
    [self.locationManager stopUpdatingLocation];

}


```

###相册相关代码

```

{//相册
        
        NSURL *assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];
        
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        
        __block NSMutableDictionary *imageMetadata_GPS = nil;
        
        __weak typeof(self)weakSelf = self;
        
        [library assetForURL:assetURL resultBlock:^(ALAsset *asset) {
            
             //获取时间
             NSDate* pictureDate = [asset valueForProperty:ALAssetPropertyDate];
             NSDateFormatter * formatter = [[NSDateFormatter alloc]init];
             formatter.dateFormat = @"yyyy:MM:dd HH:mm:ss";
             formatter.timeZone = [NSTimeZone localTimeZone];
             NSString * pictureTime = [formatter stringFromDate:pictureDate];
             weakSelf.time.text = pictureTime;
             
             //获取GPS
             imageMetadata_GPS = [[NSMutableDictionary alloc] initWithDictionary:asset.defaultRepresentation.metadata];
             
             NSDictionary *GPSDict=[imageMetadata_GPS objectForKey:(NSString*)kCGImagePropertyGPSDictionary];
             
             if (GPSDict!=nil) {
                 
                 CLLocation *loc=[GPSDict locationFromGPSDictionary];
                 
                 weakSelf.weidu.text = [NSString stringWithFormat:@"%f", loc.coordinate.latitude];
                 weakSelf.jingdu.text = [NSString stringWithFormat:@"%f", loc.coordinate.longitude];
                 
                 CLGeocoder *clGeoCoder = [[CLGeocoder alloc] init];
                 
                 CLLocation *newLocation = [[CLLocation alloc] initWithLatitude:loc.coordinate.latitude longitude:loc.coordinate.longitude];
                 
                 //反向地理编码的请求 -> 根据经纬度 获取 位置
                 [clGeoCoder reverseGeocodeLocation:newLocation completionHandler: ^(NSArray *placemarks,NSError *error) {
                     for (CLPlacemark *placeMark in placemarks)
                     {
                         NSDictionary *addressDic=placeMark.addressDictionary;
                         
                         NSArray *location_Arr = [addressDic objectForKey:@"FormattedAddressLines"];//系统格式化后的位置
                         
                         weakSelf.location.text = [location_Arr firstObject];
                         
                     }
                 }];

             }else{
                     weakSelf.weidu.text = @"此照片没有GPS信息";
                     weakSelf.jingdu.text = @"此照片没有GPS信息";
                     weakSelf.location.text = @"此照片没有拍摄位置";
                 }
                 
             }
     
            failureBlock:^(NSError *error) {
        }];
    }
```

###demo地址
[https://github.com/pengshengsongcode/ThroughPicGetShootPlaceWithTime  ](https://github.com/pengshengsongcode/ThroughPicGetShootPlaceWithTime)
