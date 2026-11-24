//
//  MXProductCardMessage.m
//  MXEcoboostSDK-test
//
//  Created by shunxingzhang on 2021/9/1.
//  Copyright © 2021 2020 Mixdesk. All rights reserved.
//

#import "MXProductCardMessage.h"

@implementation MXProductCardMessage

- (instancetype)initWithPictureUrl:(NSString *)pictureUrl title:(NSString *)title description:(NSString *)desc productUrl:(NSString *)productUrl andSalesCount:(long)count
{
    if (self = [super init]) {
        self.pictureUrl = pictureUrl ?: @"";
        self.title  = title ?: @"";
        self.desc = desc ?: @"";
        self.productUrl  = productUrl ?: @"";
        self.price = @"";
        self.salesCount = count;
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title
                   productUrl:(NSString *)productUrl
                   pictureUrl:(NSString *)pictureUrl
                        price:(NSString *)price
                  description:(NSString *)desc
{
    if (self = [super init]) {
        self.title = title ?: @"";
        self.productUrl = productUrl ?: @"";
        self.pictureUrl = pictureUrl ?: @"";
        self.price = price ?: @"";
        self.desc = desc ?: @"";
        self.salesCount = 0;
    }
    return self;
}

@end
