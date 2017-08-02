//
//  WGS84TOGCJ02.h
//  根据图片获取拍照时间和拍照地点
//
//  Created by 彭盛凇 on 2017/8/2.
//  Copyright © 2017年 huangbaoche. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface WGS84TOGCJ02 : NSObject
//判断是否已经超出中国范围
+(BOOL)isLocationOutOfChina:(CLLocationCoordinate2D)location;
//转GCJ-02
+(CLLocationCoordinate2D)transformFromWGSToGCJ:(CLLocationCoordinate2D)wgsLoc;
@end
