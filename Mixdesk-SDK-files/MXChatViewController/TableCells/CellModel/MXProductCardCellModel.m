//
//  MXProductCardCellModel.m
//  MXEcoboostSDK-test
//
//  Created by shunxingzhang on 2021/9/2.
//  Copyright © 2021 2020 Mixdesk. All rights reserved.
//

#import "MXProductCardCellModel.h"
#import "MXServiceToViewInterface.h"
#import "MXImageUtil.h"
#import "MXProductCardMessageCell.h"
#ifndef INCLUDE_MIXDESK_SDK
#import "UIImageView+WebCache.h"
#endif

/**
 * 聊天气泡和内容的留白间距
 */
static CGFloat const kMXCellBubbleToContentSpacing = 12.0;

/**
 * 文字内容的行间隔
 */
static CGFloat const kMXCellTextContentSpacing = 5.0;

/**
 * 商品销售量内容的高度
 */
static CGFloat const kMXCellSaleCountHeigh = 18.0;

/**
 * 图片的高宽比,宽4高3
 */
static CGFloat const kMXCellImageRatio = 0.75;

@interface MXProductCardCellModel()

/**
 * @brief cell中消息的id
 */
@property (nonatomic, readwrite, strong) NSString *messageId;

/**
 * @brief 图片image(当imagePath不存在时使用)
 */
@property (nonatomic, readwrite, strong) UIImage *image;

/**
 * @brief 消息的时间
 */
@property (nonatomic, readwrite, copy) NSDate *date;

/**
 * @brief 商品的title
 */
@property (nonatomic, readwrite, copy) NSString *title;

/**
 * @brief 商品的描述内容
 */
@property (nonatomic, readwrite, copy) NSString *desc;

/**
 * @brief 商品的销售量
 */
@property (nonatomic, readwrite, assign) long saleCount;

/**
 * @brief 商品的价格文本
 */
@property (nonatomic, readwrite, copy) NSString *price;

/**
 * @brief bubble中的价格的frame
 */
@property (nonatomic, readwrite, assign) CGRect priceFrame;

/**
 * @brief 商品的url
 */
@property (nonatomic, readwrite, copy) NSString *productUrl;

/**
 * @brief 商品图片的url
 */
@property (nonatomic, readwrite, copy) NSString *productPictureUrl;

/**
 * @brief 发送者的头像的图片
 */
@property (nonatomic, readwrite, copy) UIImage *avatarImage;

/**
 * @brief cell的高度
 */
@property (nonatomic, readwrite, assign) CGFloat cellHeight;

/**
 * @brief bubble中的imageView的frame
 */
@property (nonatomic, readwrite, assign) CGRect contentImageViewFrame;

/**
 * @brief bubble中的商品title的frame
 */
@property (nonatomic, readwrite, assign) CGRect titleFrame;

/**
 * @brief bubble中的商品描述内容的frame
 */
@property (nonatomic, readwrite, assign) CGRect descriptionFrame;

/**
 * @brief bubble中的商品销售量的frame
 */
@property (nonatomic, readwrite, assign) CGRect saleCountFrame;

/**
 * @brief bubble中查看详情的frame
 */
@property (nonatomic, readwrite, assign) CGRect linkFrame;

/**
 * @brief 消息背景框的frame
 */
@property (nonatomic, readwrite, assign) CGRect bubbleFrame;

/**
 * @brief 发送者的头像frame
 */
@property (nonatomic, readwrite, assign) CGRect avatarFrame;

/**
 * @brief 发送状态指示器的frame
 */
@property (nonatomic, readwrite, assign) CGRect sendingIndicatorFrame;

/**
 * @brief 发送出错图片的frame
 */
@property (nonatomic, readwrite, assign) CGRect sendFailureFrame;

/**
 * @brief 消息的来源类型
 */
@property (nonatomic, readwrite, assign) MXChatCellFromType cellFromType;

/**
 * @brief 发送者的头像Path
 */
@property (nonatomic, readwrite, copy) NSString *avatarPath;

/**
 * @brief cell的宽度
 */
@property (nonatomic, readwrite, assign) CGFloat cellWidth;

/**
 * @brief cell中消息的会话id
 */
@property (nonatomic, readwrite, strong) NSString *conversionId;

/**
 * @brief 已读状态指示器的frame
 */
@property (nonatomic, readwrite, assign) CGRect readStatusIndicatorFrame;

@end

@implementation MXProductCardCellModel

#pragma initialize
/**
 *  根据MXMessage内容来生成cell model
 */
- (MXProductCardCellModel *)initCellModelWithMessage:(MXProductCardMessage *)message
                                           cellWidth:(CGFloat)cellWidth
                                            delegate:(id<MXCellModelDelegate>)delegate
{
    if (self = [super init]) {
        self.cellWidth = cellWidth;
        self.delegate = delegate;
        self.sendStatus = message.sendStatus;
        self.productPictureUrl = message.pictureUrl;
        self.messageId = message.messageId;
        self.conversionId = message.conversionId;
        self.readStatus = message.readStatus;
        self.date = message.date;
        self.title = message.title;
        self.productUrl = message.productUrl;
        self.desc = message.desc;
        self.saleCount = message.salesCount;
        self.price = message.price ?: @"";
        self.avatarPath = @"";
        self.cellHeight = 44.0;
        if (message.userAvatarImage) {
            self.avatarImage = message.userAvatarImage;
        } else if (message.userAvatarPath.length > 0) {
            self.avatarPath = message.userAvatarPath;
            //这里使用Mixdesk接口下载多媒体消息的图片，开发者也可以替换成自己的图片缓存策略
#ifdef INCLUDE_MIXDESK_SDK
            [MXServiceToViewInterface downloadMediaWithUrlString:message.userAvatarPath progress:^(float progress) {
            } completion:^(NSData *mediaData, NSError *error) {
                if (mediaData && !error) {
                    self.avatarImage = [UIImage imageWithData:mediaData];
                } else {
                    self.avatarImage = message.fromType == MXChatMessageIncoming ? [MXChatViewConfig sharedConfig].incomingDefaultAvatarImage : [MXChatViewConfig sharedConfig].outgoingDefaultAvatarImage;
                }
                if (self.delegate) {
                    if ([self.delegate respondsToSelector:@selector(didUpdateCellDataWithMessageId:)]) {
                        //通知ViewController去刷新tableView
                        [self.delegate didUpdateCellDataWithMessageId:self.messageId];
                    }
                }
            }];
#else
            __block UIImageView *tempImageView = [UIImageView new];
            [tempImageView sd_setImageWithURL:[NSURL URLWithString:message.userAvatarPath] placeholderImage:nil options:SDWebImageProgressiveDownload completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                
                self.avatarImage = tempImageView.image.copy;
                if (self.delegate) {
                    if ([self.delegate respondsToSelector:@selector(didUpdateCellDataWithMessageId:)]) {
                        //通知ViewController去刷新tableView
                        [self.delegate didUpdateCellDataWithMessageId:self.messageId];
                    }
                }
            }];
#endif
        } else {
            self.avatarImage = [MXChatViewConfig sharedConfig].incomingDefaultAvatarImage;
            if (message.fromType == MXChatMessageOutgoing) {
                self.avatarImage = [MXChatViewConfig sharedConfig].outgoingDefaultAvatarImage;
            }
        }
        
        //内容图片
        if (message.pictureUrl.length > 0) {
            
            //默认cell高度为图片显示的最大高度
            //先按内容算好高度，图片下载完成后再刷新
            [self setModelsWithContentImage:nil cellFromType:message.fromType cellWidth:cellWidth];
            
            //                [self setModelsWithContentImage:[MXChatViewConfig sharedConfig].incomingBubbleImage cellFromType:message.fromType cellWidth:cellWidth];
            
            //这里使用Mixdesk接口下载多媒体消息的图片，开发者也可以替换成自己的图片缓存策略
#ifdef INCLUDE_MIXDESK_SDK
            [MXServiceToViewInterface downloadMediaWithUrlString:message.pictureUrl progress:^(float progress) {
            } completion:^(NSData *mediaData, NSError *error) {
                if (mediaData && !error) {
                    self.image = [UIImage imageWithData:mediaData];
                    [self setModelsWithContentImage:self.image cellFromType:message.fromType cellWidth:cellWidth];
                } else {
                    self.image = [MXChatViewConfig sharedConfig].imageLoadErrorImage;
                    [self setModelsWithContentImage:self.image cellFromType:message.fromType cellWidth:cellWidth];
                }
                if (self.delegate) {
                    if ([self.delegate respondsToSelector:@selector(didUpdateCellDataWithMessageId:)]) {
                        [self.delegate didUpdateCellDataWithMessageId:self.messageId];
                    }
                }
            }];
#else
            //非MixdeskSDK用户，使用了SDWebImage来做图片缓存
            __block UIImageView *tempImageView = [[UIImageView alloc] init];
            [tempImageView sd_setImageWithURL:[NSURL URLWithString:message.pictureUrl] placeholderImage:nil options:SDWebImageProgressiveDownload completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                
                if (image) {
                    self.image = tempImageView.image.copy;
                    [self setModelsWithContentImage:self.image cellFromType:message.fromType cellWidth:cellWidth];
                } else {
                    self.image = [MXChatViewConfig sharedConfig].imageLoadErrorImage;
                    [self setModelsWithContentImage:self.image cellFromType:message.fromType cellWidth:cellWidth];
                }
                if (self.delegate) {
                    if ([self.delegate respondsToSelector:@selector(didUpdateCellDataWithMessageId:)]) {
                        [self.delegate didUpdateCellDataWithMessageId:self.messageId];
                    }
                }
            }];
#endif
        } else {
            //无图：隐藏图片区，只显示文字区
            self.image = nil;
            [self setModelsWithContentImage:nil cellFromType:message.fromType cellWidth:cellWidth];
        }
    } else {
        [self setModelsWithContentImage:self.image cellFromType:message.fromType cellWidth:cellWidth];
    }
    return self;
}

//根据内容生成其他model（#216：高度按内容计算，名称最多 2 行，价格 1 行，描述 1 行，无图隐藏图片区）
- (void)setModelsWithContentImage:(UIImage *)contentImage
                          cellFromType:(MXChatMessageFromType)cellFromType
                        cellWidth:(CGFloat)cellWidth
{
    //内容宽度固定为 cellWidth / 2
    CGFloat contentWidth = ceil(cellWidth / 2);
    CGFloat y = kMXCellBubbleToContentSpacing;

    //商品图片：只有有图片链接时才显示
    if (self.productPictureUrl.length > 0) {
        self.contentImageViewFrame = CGRectMake(kMXCellBubbleToContentSpacing, y, contentWidth, ceil(contentWidth * kMXCellImageRatio));
        y = CGRectGetMaxY(self.contentImageViewFrame) + kMXCellBubbleToContentSpacing;
    } else {
        self.contentImageViewFrame = CGRectZero;
    }

    //商品名称，最多 2 行
    CGFloat titleHeight = [MXProductCardCellModel heightForText:self.title font:[MXProductCardCellModel titleFont] width:contentWidth maxLines:2];
    self.titleFrame = CGRectMake(kMXCellBubbleToContentSpacing, y, contentWidth, titleHeight);
    y = CGRectGetMaxY(self.titleFrame);

    //价格（无价格不占行）；旧数据无价格但有销量时显示销量
    if (self.price.length > 0) {
        self.priceFrame = CGRectMake(kMXCellBubbleToContentSpacing, y + kMXCellTextContentSpacing, contentWidth, ceil([MXProductCardCellModel priceFont].lineHeight));
        y = CGRectGetMaxY(self.priceFrame);
        self.saleCountFrame = CGRectZero;
    } else if (self.saleCount > 0) {
        self.priceFrame = CGRectZero;
        self.saleCountFrame = CGRectMake(kMXCellBubbleToContentSpacing, y + kMXCellTextContentSpacing, contentWidth, kMXCellSaleCountHeigh);
        y = CGRectGetMaxY(self.saleCountFrame);
    } else {
        self.priceFrame = CGRectZero;
        self.saleCountFrame = CGRectZero;
    }

    //描述，1 行
    if (self.desc.length > 0) {
        self.descriptionFrame = CGRectMake(kMXCellBubbleToContentSpacing, y + kMXCellTextContentSpacing, contentWidth, ceil([MXProductCardCellModel descFont].lineHeight));
        y = CGRectGetMaxY(self.descriptionFrame);
    } else {
        self.descriptionFrame = CGRectZero;
    }
    //不再显示“查看详情”，整卡可点
    self.linkFrame = CGRectZero;

    CGFloat bubbleWidth = contentWidth + 2 * kMXCellBubbleToContentSpacing;
    CGFloat bubbleHeight = y + kMXCellBubbleToContentSpacing;

    if (cellFromType == MXChatMessageOutgoing) {
        //发送出去的消息
        self.cellFromType = MXChatCellOutgoing;
        //头像的frame
        if ([MXChatViewConfig sharedConfig].enableOutgoingAvatar) {
            self.avatarFrame = CGRectMake(cellWidth-kMXCellAvatarToHorizontalEdgeSpacing-kMXCellAvatarDiameter, kMXCellAvatarToVerticalEdgeSpacing, kMXCellAvatarDiameter, kMXCellAvatarDiameter);
        } else {
            self.avatarFrame = CGRectMake(0, 0, 0, 0);
        }
        //气泡的frame
        self.bubbleFrame = CGRectMake(cellWidth - self.avatarFrame.size.width - kMXCellAvatarToHorizontalEdgeSpacing - kMXCellAvatarToBubbleSpacing - bubbleWidth,
                                      kMXCellAvatarToVerticalEdgeSpacing,
                                      bubbleWidth,
                                      bubbleHeight);
    } else {
        //收到的消息
        self.cellFromType = MXChatCellIncoming;
        //头像的frame
        if ([MXChatViewConfig sharedConfig].enableIncomingAvatar) {
            self.avatarFrame = CGRectMake(kMXCellAvatarToHorizontalEdgeSpacing, kMXCellAvatarToVerticalEdgeSpacing, kMXCellAvatarDiameter, kMXCellAvatarDiameter);
        } else {
            self.avatarFrame = CGRectMake(0, 0, 0, 0);
        }
        //气泡的frame
        self.bubbleFrame = CGRectMake(self.avatarFrame.origin.x+self.avatarFrame.size.width+kMXCellAvatarToBubbleSpacing,
                                      self.avatarFrame.origin.y,
                                      bubbleWidth,
                                      bubbleHeight);
    }

    //发送消息的indicator的frame
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, kMXCellIndicatorDiameter, kMXCellIndicatorDiameter)];
    self.sendingIndicatorFrame = CGRectMake(self.bubbleFrame.origin.x-kMXCellBubbleToIndicatorSpacing-indicatorView.frame.size.width, self.bubbleFrame.origin.y+self.bubbleFrame.size.height/2-indicatorView.frame.size.height/2, indicatorView.frame.size.width, indicatorView.frame.size.height);
    
    //发送失败的图片frame
    UIImage *failureImage = [MXChatViewConfig sharedConfig].messageSendFailureImage;
    CGSize failureSize = CGSizeMake(ceil(failureImage.size.width * 2 / 3), ceil(failureImage.size.height * 2 / 3));
    self.sendFailureFrame = CGRectMake(self.bubbleFrame.origin.x-kMXCellBubbleToIndicatorSpacing-failureSize.width, self.bubbleFrame.origin.y+self.bubbleFrame.size.height/2-failureSize.height/2, failureSize.width, failureSize.height);
    
    //已读状态指示器的frame (仅对发送的消息显示)
    CGFloat statusIndicatorSize = 12.0; // 状态指示器大小
    if (self.cellFromType == MXChatCellOutgoing) {
        // 状态指示器放在气泡左边5像素，垂直居中对齐气泡底部
        self.readStatusIndicatorFrame = CGRectMake(CGRectGetMinX(self.bubbleFrame) - statusIndicatorSize - 5,
                                                  CGRectGetMaxY(self.bubbleFrame) - statusIndicatorSize,
                                                  statusIndicatorSize,
                                                  statusIndicatorSize);
    } else {
        // 接收的消息不显示状态指示器
        self.readStatusIndicatorFrame = CGRectZero;
    }
    
    //计算cell的高度
    self.cellHeight = self.bubbleFrame.origin.y + self.bubbleFrame.size.height + kMXCellAvatarToVerticalEdgeSpacing;

}


#pragma 文字度量
+ (UIFont *)titleFont {
    return [UIFont systemFontOfSize:16.0];
}

+ (UIFont *)priceFont {
    return [UIFont boldSystemFontOfSize:16.0];
}

+ (UIFont *)descFont {
    return [UIFont systemFontOfSize:13.0];
}

+ (CGFloat)heightForText:(NSString *)text font:(UIFont *)font width:(CGFloat)width maxLines:(NSInteger)maxLines {
    CGFloat lineHeight = ceil(font.lineHeight);
    if (text.length == 0 || width <= 0) {
        return lineHeight;
    }
    CGRect rect = [text boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                  attributes:@{NSFontAttributeName : font}
                                     context:nil];
    CGFloat h = ceil(rect.size.height);
    if (maxLines > 0) {
        h = MIN(h, lineHeight * maxLines);
    }
    return MAX(h, lineHeight);
}

#pragma MXCellModelProtocol
- (CGFloat)getCellHeight {
    return self.cellHeight > 0 ? self.cellHeight : 0;
}

/**
 *  通过重用的名字初始化cell
 *  @return 初始化了一个cell
 */
- (MXChatBaseCell *)getCellWithReuseIdentifier:(NSString *)cellReuseIdentifer {
    return [[MXProductCardMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellReuseIdentifer];
}

- (NSDate *)getCellDate {
    return self.date;
}

- (BOOL)isServiceRelatedCell {
    return true;
}

- (NSString *)getCellMessageId {
    return self.messageId;
}

- (NSString *)getMessageReadStatus {
    return self.readStatus;
}

- (NSString *)getMessageConversionId {
    return self.conversionId;
}

- (void)updateCellMessageId:(NSString *)messageId {
    self.messageId = messageId;
}

- (void)updateCellSendStatus:(MXChatMessageSendStatus)sendStatus {
    self.sendStatus = sendStatus;
}

- (void)updateCellReadStatus:(NSNumber *)readStatus {
    self.readStatus = readStatus;
}

- (void)updateCellConversionId:(NSString *)conversionId {
    self.conversionId = conversionId;
}

- (void)updateCellMessageDate:(NSDate *)messageDate {
    self.date = messageDate;
}

- (void)updateCellFrameWithCellWidth:(CGFloat)cellWidth {
    self.cellWidth = cellWidth;
    [self setModelsWithContentImage:self.image cellFromType:(MXChatMessageFromType)self.cellFromType cellWidth:cellWidth];
}

@end
