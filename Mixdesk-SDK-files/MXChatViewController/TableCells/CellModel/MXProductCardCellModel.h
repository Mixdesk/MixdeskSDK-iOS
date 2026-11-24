//
//  MXProductCardCellModel.h
//  MXEcoboostSDK-test
//
//  Created by shunxingzhang on 2021/9/2.
//  Copyright © 2021 2020 Mixdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MXCellModelProtocol.h"
#import "MXProductCardMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface MXProductCardCellModel : NSObject <MXCellModelProtocol>

/**
 * @brief cell中消息的id
 */
@property (nonatomic, readonly, strong) NSString *messageId;

/**
 * @brief 该cellModel的委托对象
 */
@property (nonatomic, weak) id<MXCellModelDelegate> delegate;

/**
 * @brief 图片image
 */
@property (nonatomic, readonly, strong) UIImage *image;

/**
 * @brief 消息的时间
 */
@property (nonatomic, readonly, copy) NSDate *date;

/**
 * @brief 商品的title
 */
@property (nonatomic, readonly, copy) NSString *title;

/**
 * @brief 商品的描述内容
 */
@property (nonatomic, readonly, copy) NSString *desc;

/**
 * @brief 商品的销售量
 */
@property (nonatomic, readonly, assign) long saleCount;

/**
 * @brief 商品的价格文本（可空）
 */
@property (nonatomic, readonly, copy) NSString *price;

/**
 * @brief bubble中的价格的frame
 */
@property (nonatomic, readonly, assign) CGRect priceFrame;

/**
 * @brief 商品的url
 */
@property (nonatomic, readonly, copy) NSString *productUrl;

/**
 * @brief 商品图片的url
 */
@property (nonatomic, readonly, copy) NSString *productPictureUrl;

/**
 * @brief 发送者的头像的图片
 */
@property (nonatomic, readonly, copy) UIImage *avatarImage;

/**
 * @brief cell的高度
 */
@property (nonatomic, readonly, assign) CGFloat cellHeight;

/**
 * @brief bubble中的imageView的frame
 */
@property (nonatomic, readonly, assign) CGRect contentImageViewFrame;

/**
 * @brief bubble中的商品title的frame
 */
@property (nonatomic, readonly, assign) CGRect titleFrame;

/**
 * @brief bubble中的商品描述内容的frame
 */
@property (nonatomic, readonly, assign) CGRect descriptionFrame;

/**
 * @brief bubble中的商品销售量的frame
 */
@property (nonatomic, readonly, assign) CGRect saleCountFrame;

/**
 * @brief bubble中查看详情的frame
 */
@property (nonatomic, readonly, assign) CGRect linkFrame;

/**
 * @brief 消息背景框的frame
 */
@property (nonatomic, readonly, assign) CGRect bubbleFrame;

/**
 * @brief 发送者的头像frame
 */
@property (nonatomic, readonly, assign) CGRect avatarFrame;

/**
 * @brief 发送状态指示器的frame
 */
@property (nonatomic, readonly, assign) CGRect sendingIndicatorFrame;

/**
 * @brief 发送出错图片的frame
 */
@property (nonatomic, readonly, assign) CGRect sendFailureFrame;

/**
 * @brief 消息的来源类型
 */
@property (nonatomic, readonly, assign) MXChatCellFromType cellFromType;

/**
 * @brief 消息的发送状态
 */
@property (nonatomic, assign) MXChatMessageSendStatus sendStatus;

/**
 * @brief 消息的已读状态 (2: 已送达, 3: 已读)
 */
@property (nonatomic, assign) NSNumber *readStatus;

/**
 * @brief 已读状态指示器的frame
 */
@property (nonatomic, readonly, assign) CGRect readStatusIndicatorFrame;

/**
 *  根据MXMessage内容来生成cell model
 */
- (MXProductCardCellModel *)initCellModelWithMessage:(MXProductCardMessage *)message
                                     cellWidth:(CGFloat)cellWidth
                                      delegate:(id<MXCellModelDelegate>)delegate;

/** 名称字体 16pt */
+ (UIFont *)titleFont;
/** 价格字体 16pt 粗体 */
+ (UIFont *)priceFont;
/** 描述字体 13pt */
+ (UIFont *)descFont;
/** 按最大行数计算文字高度 */
+ (CGFloat)heightForText:(NSString *)text font:(UIFont *)font width:(CGFloat)width maxLines:(NSInteger)maxLines;

@end

NS_ASSUME_NONNULL_END
