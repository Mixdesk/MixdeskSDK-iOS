//
//  MXVisialMessageFactory.h
//  Mixdesk-SDK-Demo
//
//  Created by ian luo on 2016/11/17.
//  Copyright © 2016年 Mixdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MXMessageFactoryHelper.h"

@class MXProductCardMessage;

@interface MXVisialMessageFactory : NSObject <MXMessageFactory>

- (MXBaseMessage *)createMessage:(MXMessage *)plainMessage;

/** hybrid 内容数组：优先 extra.content，取不到回退 message.content */
+ (NSArray *)hybridContentArrayFromMessage:(MXMessage *)message;

/** product_card 的 body 转成 MXProductCardMessage（兼容旧数据 sales_count） */
+ (MXProductCardMessage *)productCardFromBody:(NSDictionary *)body;

@end
