//
//  ViewController.m
//  根据图片获取拍照时间和拍照地点
//
//  Created by 彭盛凇 on 2017/7/6.
//  Copyright © 2017年 huangbaoche. All rights reserved.
//

#import "ViewController.h"

#import <MobileCoreServices/MobileCoreServices.h>

#import <ImageIO/CGImageProperties.h>

#import <AssetsLibrary/AssetsLibrary.h>

#import <CoreLocation/CoreLocation.h>

#import "NSDictionary+CLLocation.h"

@interface ViewController ()
<UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) UIImagePickerController *imagePickerVC;

@property (nonatomic, strong) CLLocationManager *locationmanager;//拍照定位

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *time;
@property (weak, nonatomic) IBOutlet UILabel *jingdu;
@property (weak, nonatomic) IBOutlet UILabel *weidu;
@property (weak, nonatomic) IBOutlet UILabel *location;

@property (nonatomic, copy) NSString *locationFormat;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.locationManager = [[CLLocationManager alloc] init];
    
    self.locationManager.delegate = self;
    
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    self.locationManager.distanceFilter = 1000.0f;
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)doAction_1:(id)sender {//拍照
    
    self.imagePickerVC.sourceType = UIImagePickerControllerSourceTypeCamera;
    // model出控制器
    [self presentViewController:self.imagePickerVC animated:YES completion:nil];
    
}
- (IBAction)doAction:(id)sender {//相册
    
    self.imagePickerVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    // model出控制器
    [self presentViewController:self.imagePickerVC animated:YES completion:nil];
    
}

#pragma mark 拍照定位

-(void)getLocation
{
    //判断定位功能是否打开
    if ([CLLocationManager locationServicesEnabled]) {
        self.locationmanager = [[CLLocationManager alloc]init];
        self.locationmanager.delegate = self;
        [self.locationmanager requestAlwaysAuthorization];
        
        [self.locationmanager requestWhenInUseAuthorization];
        
        //设置寻址精度
        self.locationmanager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locationmanager.distanceFilter = 5.0;
        [self.locationmanager startUpdatingLocation];
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
    
    [self.locationmanager stopUpdatingLocation];

}

#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    //[Generic] Creating an image format with an unknown type is an error
    
    UIImage * image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    self.imageView.image = image;
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    NSLog(@"info:----->\n%@", info);
    
    if(picker.sourceType == UIImagePickerControllerSourceTypeCamera) {//拍照
        
        //照片mediaInfo
        NSDictionary * imageMetadata = info[@"UIImagePickerControllerMediaMetadata"];
        
        NSDictionary *tIFFDictionary =  [imageMetadata objectForKey:(NSString *)kCGImagePropertyTIFFDictionary];
        
        NSString * pictureTime = tIFFDictionary[@"DateTime"];//2016:01:05 11:45:36
        
        self.time.text = pictureTime;
        
        if ([CLLocationManager locationServicesEnabled]) {
            
            //获取经纬度
            [self getLocation];
            
        }else {
            NSLog(@"请开启定位功能！");
        }
        
    } else if(picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary){//相册
        
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
    
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    NSLog(@"点击了取消按钮");
    [picker dismissViewControllerAnimated:YES completion:nil];
}

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
@end
