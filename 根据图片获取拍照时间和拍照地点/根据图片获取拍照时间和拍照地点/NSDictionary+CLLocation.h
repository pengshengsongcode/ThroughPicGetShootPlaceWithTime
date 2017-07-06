//
//  NSDictionary+CLLocation.h
//  TravelNote
//
//  Created by liu  on 12-5-24.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <ImageIO/ImageIO.h>
@interface NSDictionary (CLLocation)

//图片的GPSDictionary转化为CLLocation对象
-(CLLocation*)locationFromGPSDictionary;


@end
