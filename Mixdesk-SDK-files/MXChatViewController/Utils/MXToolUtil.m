//
//  MXToolUtil.m
//  Mixdesk-SDK-Demo
//
//  Created by xulianpeng on 2017/10/26.
//  Copyright © 2017年 Mixdesk. All rights reserved.
//

#import "MXToolUtil.h"
#import <sys/utsname.h>
#import <UIKit/UIKit.h>
@implementation MXToolUtil
+ (NSString*)kMXObtainDeviceVersion
{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    //iPhone
    if ([deviceString isEqualToString:@"iPhone1,1"])    return @"iPhone1G";
    if ([deviceString isEqualToString:@"iPhone1,2"])    return @"iPhone3G";
    if ([deviceString isEqualToString:@"iPhone2,1"])    return @"iPhone3GS";
    if ([deviceString isEqualToString:@"iPhone3,1"])    return @"iPhone4";
    if ([deviceString isEqualToString:@"iPhone3,2"])    return @"VerizoniPhone4";
    if ([deviceString isEqualToString:@"iPhone4,1"])    return @"iPhone4S";
    if ([deviceString isEqualToString:@"iPhone5,1"])    return @"iPhone5";
    if ([deviceString isEqualToString:@"iPhone5,2"])    return @"iPhone5";
    if ([deviceString isEqualToString:@"iPhone5,3"])    return @"iPhone5C";
    if ([deviceString isEqualToString:@"iPhone5,4"])    return @"iPhone5C";
    if ([deviceString isEqualToString:@"iPhone6,1"])    return @"iPhone5S";
    if ([deviceString isEqualToString:@"iPhone6,2"])    return @"iPhone5S";
    if ([deviceString isEqualToString:@"iPhone7,1"])    return @"iPhone6Plus";
    if ([deviceString isEqualToString:@"iPhone7,2"])    return @"iPhone6";
    if ([deviceString isEqualToString:@"iPhone8,1"])    return @"iPhone6s";
    if ([deviceString isEqualToString:@"iPhone8,2"])    return @"iPhone6sPlus";
    if ([deviceString isEqualToString:@"iPhone9,1"] || [deviceString isEqualToString:@"iPhone9,3"])    return @"iPhone7";
    if ([deviceString isEqualToString:@"iPhone9,2"] || [deviceString isEqualToString:@"iPhone9,4"])    return @"iPhone7Plus";
    if ([deviceString isEqualToString:@"iPhone10,1"] || [deviceString isEqualToString:@"iPhone10,4"])    return @"iPhone8";
    if ([deviceString isEqualToString:@"iPhone10,2"] || [deviceString isEqualToString:@"iPhone10,5"])    return @"iPhone8Plus";
    if ([deviceString isEqualToString:@"iPhone10,3"] || [deviceString isEqualToString:@"iPhone10,6"])    return @"iPhoneX";
    
    if ([deviceString isEqualToString:@"iPhone11,8"])    return @"iPhoneXR";
    if ([deviceString isEqualToString:@"iPhone11,2"])    return @"iPhoneXS";
    if ([deviceString isEqualToString:@"iPhone11,4"] || [deviceString isEqualToString:@"iPhone11,6"])    return @"iPhoneXSMAX";
    
    if ([deviceString isEqualToString:@"iPhone12,1"]) return @"iPhone11";
    if ([deviceString isEqualToString:@"iPhone12,3"]) return @"iPhone11Pro";
    if ([deviceString isEqualToString:@"iPhone12,5"]) return @"iPhone11ProMax";
    if ([deviceString isEqualToString:@"iPhone12,8"]) return @"iPhoneSE2";
    
    if ([deviceString isEqualToString:@"iPhone13,1"]) return @"iPhone12mini";
    if ([deviceString isEqualToString:@"iPhone13,2"]) return @"iPhone12";
    if ([deviceString isEqualToString:@"iPhone13,3"]) return @"iPhone12Pro";
    if ([deviceString isEqualToString:@"iPhone13,4"]) return @"iPhone12ProMax";
    
    if ([deviceString isEqualToString:@"iPhone14,2"]) return @"iPhone13Pro";
    if ([deviceString isEqualToString:@"iPhone14,3"]) return @"iPhone13ProMax";
    if ([deviceString isEqualToString:@"iPhone14,4"]) return @"iPhone13mini";
    if ([deviceString isEqualToString:@"iPhone14,5"]) return @"iPhone13";
    
    
    if ([deviceString isEqualToString:@"iPhone14,6"]) return @"iPhoneSE3";
    if ([deviceString isEqualToString:@"iPhone14,7"]) return @"iPhone 14";
    if ([deviceString isEqualToString:@"iPhone14,8"]) return @"iPhone 14 Plus";
    if ([deviceString isEqualToString:@"iPhone15,2"]) return @"iPhone 14 Pro";
    if ([deviceString isEqualToString:@"iPhone15,3"]) return @"iPhone 14 Pro Max";

    //模拟机
    if ([deviceString isEqualToString:@"x86_64"])        return @"Simulator";

    //iPod 系列
    if ([deviceString isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([deviceString isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([deviceString isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([deviceString isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([deviceString isEqualToString:@"iPod5,1"])      return @"iPod Touch 5G";
    
    //iPad 系列
    if ([deviceString isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([deviceString isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    if ([deviceString isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
    if ([deviceString isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    if ([deviceString isEqualToString:@"iPad2,4"])      return @"iPad 2 (32nm)";
    if ([deviceString isEqualToString:@"iPad2,5"])      return @"iPad mini (WiFi)";
    if ([deviceString isEqualToString:@"iPad2,6"])      return @"iPad mini (GSM)";
    if ([deviceString isEqualToString:@"iPad2,7"])      return @"iPad mini (CDMA)";
    
    if ([deviceString isEqualToString:@"iPad3,1"])      return @"iPad 3(WiFi)";
    if ([deviceString isEqualToString:@"iPad3,2"])      return @"iPad 3(CDMA)";
    if ([deviceString isEqualToString:@"iPad3,3"])      return @"iPad 3(4G)";
    if ([deviceString isEqualToString:@"iPad3,4"])      return @"iPad 4 (WiFi)";
    if ([deviceString isEqualToString:@"iPad3,5"])      return @"iPad 4 (4G)";
    if ([deviceString isEqualToString:@"iPad3,6"])      return @"iPad 4 (CDMA)";
    
    if ([deviceString isEqualToString:@"iPad4,1"])      return @"iPad Air";
    if ([deviceString isEqualToString:@"iPad4,2"])      return @"iPad Air";
    if ([deviceString isEqualToString:@"iPad4,3"])      return @"iPad Air";
    if ([deviceString isEqualToString:@"iPad5,3"])      return @"iPad Air 2";
    if ([deviceString isEqualToString:@"iPad5,4"])      return @"iPad Air 2";
    if ([deviceString isEqualToString:@"i386"])         return @"Simulator";
    if ([deviceString isEqualToString:@"x86_64"])       return @"Simulator";
    
    if ([deviceString isEqualToString:@"iPad4,4"]
        ||[deviceString isEqualToString:@"iPad4,5"]
        ||[deviceString isEqualToString:@"iPad4,6"])      return @"iPad mini 2";
    
    if ([deviceString isEqualToString:@"iPad4,7"]
        ||[deviceString isEqualToString:@"iPad4,8"]
        ||[deviceString isEqualToString:@"iPad4,9"])      return @"iPad mini 3";
    
    

    
    return deviceString;
}
+ (BOOL)kMXObtainDeviceVersionIsIphoneX{
    NSString * str = [self kMXObtainDeviceVersion];
    if ([str containsString:@"X"] || [str isEqualToString:@"Simulator"] || [str containsString:@"11"] || [str containsString:@"12"]  || [str containsString:@"13"]  || [str containsString:@"14"]) {
        return YES;
    } else {
        return NO;
    }
    
}

+ (CGFloat)kMXObtainNaviBarHeight{
    return 44;
}
+ (CGFloat)kMXObtainStatusBarHeight{
    
    if (@available(iOS 13.0, *)) {
        NSSet *set = [UIApplication sharedApplication].connectedScenes;
        UIWindowScene *windowScene = [set anyObject];
        UIStatusBarManager *statusBarManager = windowScene.statusBarManager;
        return statusBarManager.statusBarFrame.size.height;
    } else {
        return [UIApplication sharedApplication].statusBarFrame.size.height;
    }
}
+ (CGFloat)kMXObtainNaviHeight{
    
    return [self kMXObtainNaviBarHeight] + [self kMXObtainStatusBarHeight];
}
+ (CGFloat)kMXScreenWidth{
    
    return [UIScreen mainScreen].bounds.size.width;
}
+ (CGFloat)kMXScreenHeight{
    
    return [UIScreen mainScreen].bounds.size.height;
}
@end
