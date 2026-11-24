//
//  MXProductCardMessage.h
//  MXEcoboostSDK-test
//
//  Created by shunxingzhang on 2021/9/1.
//  Copyright © 2021 2020 Mixdesk. All rights reserved.
//

#import "MXBaseMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface MXProductCardMessage : MXBaseMessage

@property (nonatomic, copy) NSString *pictureUrl;

@property (nonatomic, copy) NSString *title;

@property (nonatomic, copy) NSString *desc;

@property (nonatomic, copy) NSString *productUrl;

@property (nonatomic, assign) long salesCount;

/** 价格文本（如 ¥199），可空，原样展示 */
@property (nonatomic, copy, nullable) NSString *price;

/** 商品库 id，客服从商品库发送时才有，访客侧不传 */
@property (nonatomic, strong, nullable) NSNumber *productId;

/**
 * 新建商品卡片（#216）。名称、链接必填，链接/图片只允许 http/https，不合法时发送失败。
 */
- (instancetype)initWithTitle:(NSString *)title
                   productUrl:(NSString *)productUrl
                   pictureUrl:(nullable NSString *)pictureUrl
                        price:(nullable NSString *)price
                  description:(nullable NSString *)desc;

-(instancetype)initWithPictureUrl:(NSString *)pictureUrl
                            title:(NSString *)title
                      description:(NSString *)desc
                       productUrl:(NSString *)productUrl
                    andSalesCount:(long)count
    __attribute__((deprecated("请改用 initWithTitle:productUrl:pictureUrl:price:description:")));

@end

NS_ASSUME_NONNULL_END
