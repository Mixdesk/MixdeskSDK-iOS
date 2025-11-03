//
//  MXTextCellModel.m
//  MixdeskSDK
//
//  Created by ijinmao on 15/10/29.
//  Copyright © 2015年 Mixdesk Inc. All rights reserved.
//

#import "MXTextCellModel.h"
#import "MXTextMessageCell.h"
#import "MXChatBaseCell.h"
#import "MXChatFileUtil.h"
#import "MXStringSizeUtil.h"
#import <UIKit/UIKit.h>
#import "MXChatViewConfig.h"
#import "MXImageUtil.h"
#import "TTTAttributedLabel.h"
#import "MXChatEmojize.h"
#import "MXServiceToViewInterface.h"
#ifndef INCLUDE_MIXDESK_SDK
#import "UIImageView+WebCache.h"
#endif

/**
 * 敏感词汇提示语的长度
 */
static CGFloat const kMXTextCellSensitiveWidth = 150.0;
/**
 * 敏感词汇提示语的高度
 */
static CGFloat const kMXTextCellSensitiveHeight = 25.0;

@interface MXTextCellModel()

/**
 * @brief cell中消息的id
 */
@property (nonatomic, readwrite, strong) NSString *messageId;

/**
 * @brief 消息的文字
 */
@property (nonatomic, readwrite, copy) NSAttributedString *cellText;

/**
 * @brief 消息的文字属性
 */
@property (nonatomic, readwrite, copy) NSDictionary *cellTextAttributes;

/**
 * @brief 消息的时间
 */
@property (nonatomic, readwrite, copy) NSDate *date;

/**
 * @brief 发送者的头像Path
 */
@property (nonatomic, readwrite, copy) NSString *avatarPath;

/**
 * @brief 发送者的头像的图片名字
 */
@property (nonatomic, readwrite, copy) UIImage *avatarImage;

/**
 * @brief 用户名字，暂时没用
 */
@property (nonatomic, readwrite, copy) NSString *userName;

/**
 * @brief 聊天气泡的image
 */
@property (nonatomic, readwrite, copy) UIImage *bubbleImage;

/**
 * @brief 消息气泡的frame
 */
@property (nonatomic, readwrite, assign) CGRect bubbleImageFrame;

/**
 * @brief 消息气泡中的文字的frame
 */
@property (nonatomic, readwrite, assign) CGRect textLabelFrame;

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
 * @brief 消息文字中，数字选中识别的字典 [number : range]
 */
@property (nonatomic, readwrite, strong) NSDictionary *numberRangeDic;

/**
 * @brief 消息文字中，url选中识别的字典 [url : range]
 */
@property (nonatomic, readwrite, strong) NSDictionary *linkNumberRangeDic;

/**
 * @brief 消息文字中，email选中识别的字典 [email : range]
 */
@property (nonatomic, readwrite, strong) NSDictionary *emailNumberRangeDic;

/**
 * @brief cell的宽度
 */
@property (nonatomic, readwrite, assign) CGFloat cellWidth;

/**
 * @brief cell的高度
 */
@property (nonatomic, readwrite, assign) CGFloat cellHeight;

/**
 * @brief 消息文字中，是否包含敏感词汇
 */
@property (nonatomic, readwrite, assign) BOOL isSensitive;

/**
 * @brief cell中消息的会话id
 */
@property (nonatomic, readwrite, strong) NSString *conversionId;

/**
 * @brief 敏感词汇提示语frame
 */
@property (nonatomic, readwrite, assign) CGRect sensitiveLableFrame;

/**
 * @brief 标签签的tagList
 */
@property (nonatomic, readwrite, strong) MXTagListView *cacheTagListView;

/**
 * @brief 标签的数据源
 */
@property (nonatomic, readwrite, strong) NSArray *cacheTags;

/**
 * @brief 已读状态指示器的frame
 */
@property (nonatomic, readwrite, assign) CGRect readStatusIndicatorFrame;

@property (nonatomic, strong) TTTAttributedLabel *textLabelForHeightCalculation;

@property (nonatomic, strong) NSString *messageContent;

@end

@implementation MXTextCellModel

- (MXTextCellModel *)initCellModelWithMessage:(MXTextMessage *)message
                                    cellWidth:(CGFloat)cellWidth
                                     delegate:(id<MXCellModelDelegate>)delegator
{
    if (self = [super init]) {
        self.textLabelForHeightCalculation = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        self.textLabelForHeightCalculation.numberOfLines = 0;
        self.messageId = message.messageId;
        self.conversionId = message.conversionId;
        self.sendStatus = message.sendStatus;
        self.isSensitive = message.isSensitive;
        self.cellFromType = message.fromType == MXChatMessageIncoming ? MXChatCellIncoming : MXChatCellOutgoing;
        self.messageContent = message.content;
        self.cellWidth = cellWidth;
        self.readStatus = message.readStatus;
        if (message.tags) {
            CGFloat maxWidth = cellWidth - kMXCellAvatarToHorizontalEdgeSpacing - kMXCellAvatarDiameter - kMXCellAvatarToBubbleSpacing - kMXCellBubbleToTextHorizontalLargerSpacing - kMXCellBubbleToTextHorizontalSmallerSpacing - kMXCellBubbleMaxWidthToEdgeSpacing;
            NSMutableArray *titleArr = [NSMutableArray array];
            for (MXMessageBottomTagModel * model in message.tags) {
                [titleArr addObject:model.name];
            }
            self.cacheTagListView = [[MXTagListView alloc] initWithTitleArray:titleArr andMaxWidth:maxWidth tagBackgroundColor:[UIColor colorWithWhite:1 alpha:0] tagTitleColor:[UIColor grayColor] tagFontSize:12.0 needBorder:YES];
            self.cacheTags = message.tags;
        }
        NSMutableParagraphStyle *contentParagraphStyle = [[NSMutableParagraphStyle alloc] init];
        contentParagraphStyle.lineSpacing = kMXTextCellLineSpacing;
        contentParagraphStyle.lineHeightMultiple = 1.0;
        contentParagraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        contentParagraphStyle.alignment = NSTextAlignmentLeft;
        NSMutableDictionary *contentAttributes
          = [[NSMutableDictionary alloc]
           initWithDictionary:@{
                                NSParagraphStyleAttributeName : contentParagraphStyle,
                                NSFontAttributeName : [UIFont systemFontOfSize:kMXCellTextFontSize]
                                }];
        if (message.fromType == MXChatMessageOutgoing) {
            [contentAttributes setObject:(__bridge id)[MXChatViewConfig sharedConfig].outgoingMsgTextColor.CGColor forKey:(__bridge id)kCTForegroundColorAttributeName];
        } else {
            [contentAttributes setObject:(__bridge id)[MXChatViewConfig sharedConfig].incomingMsgTextColor.CGColor forKey:(__bridge id)kCTForegroundColorAttributeName];
        }
        self.cellTextAttributes = [[NSDictionary alloc] initWithDictionary:contentAttributes];
        
        // 先转换文本（emoji等），然后基于转换后的文本来匹配链接
        NSString *convertedContent = [MXServiceToViewInterface convertToUnicodeWithEmojiAlias:message.content];
        self.cellText = [[NSAttributedString alloc] initWithString:convertedContent attributes:self.cellTextAttributes];
        self.date = message.date;
        self.cellHeight = 44.0;
        self.delegate = delegator;
        if (message.userAvatarImage) {
            self.avatarImage = message.userAvatarImage;
        } else if (message.userAvatarPath.length > 0) {
            self.avatarPath = message.userAvatarPath;
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
        } else {
            self.avatarImage = [MXChatViewConfig sharedConfig].incomingDefaultAvatarImage;
            if (message.fromType == MXChatMessageOutgoing) {
                self.avatarImage = [MXChatViewConfig sharedConfig].outgoingDefaultAvatarImage;
            }
        }
        [self configCellWidth:cellWidth];
        
        // 【修复】基于转换后的文本匹配正则，确保 Range 和显示文本一致
        self.numberRangeDic = [self createRegexMap:[MXChatViewConfig sharedConfig].numberRegexs for:convertedContent];
        self.linkNumberRangeDic = [self createRegexMap:[MXChatViewConfig sharedConfig].linkRegexs for:convertedContent];
        self.emailNumberRangeDic = [self createRegexMap:[MXChatViewConfig sharedConfig].emailRegexs for:convertedContent];
        
        //防止邮件地址被解析为连接地址
        NSMutableDictionary *tempLinkNumberRangDic = [self.linkNumberRangeDic mutableCopy];
        for ( NSString *email in self.emailNumberRangeDic.allKeys) {
            for (NSString *link in self.linkNumberRangeDic.allKeys) {
                if ([email rangeOfString:link].length != 0) {
                    [tempLinkNumberRangDic removeObjectForKey:link];
                }
            }
        }
        self.linkNumberRangeDic = tempLinkNumberRangDic;
    }
    return self;
}

- (NSDictionary *)createRegexMap:(NSArray *)regexs for:(NSString *)s {
    NSMutableDictionary *regexDic = [[NSMutableDictionary alloc] init];
    for (NSString *linkRegex in regexs) {
        
        for (NSTextCheckingResult *matchedResult in [self matchWithRegex:linkRegex in:s]) {
            if (matchedResult.range.location != NSNotFound) {
                [regexDic setValue:[NSValue valueWithRange:matchedResult.range] forKey:[s substringWithRange:matchedResult.range]];
            }
        }
    }
    return regexDic;
}

- (NSArray *)matchWithRegex:(NSString *)r in:(NSString *)string {
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:r options:(NSRegularExpressionCaseInsensitive) error:nil];
    NSArray *matchResults = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    return matchResults;
}

- (void)configCellWidth:(CGFloat)cellWidth {
    //文字最大宽度
    CGFloat maxLabelWidth = cellWidth - kMXCellAvatarToHorizontalEdgeSpacing - kMXCellAvatarDiameter - kMXCellAvatarToBubbleSpacing - kMXCellBubbleToTextHorizontalLargerSpacing - kMXCellBubbleToTextHorizontalSmallerSpacing - kMXCellBubbleMaxWidthToEdgeSpacing;
    //文字高度
    //        CGFloat messageTextHeight = [MXStringSizeUtil getHeightForAttributedText:self.cellText textWidth:maxLabelWidth];
    self.textLabelForHeightCalculation.attributedText = self.cellText;
    CGSize messageTextSize = [self.textLabelForHeightCalculation sizeThatFits:CGSizeMake(maxLabelWidth, MAXFLOAT)];
    CGFloat messageTextHeight = messageTextSize.height;
    
    //判断文字中是否有emoji
//    if ([MXChatEmojize stringContainsEmoji:[self.cellText string]]) {
//        NSAttributedString *oneLineText = [[NSAttributedString alloc] initWithString:@"haha" attributes:self.cellTextAttributes];
//        CGFloat oneLineTextHeight = [MXStringSizeUtil getHeightForAttributedText:oneLineText textWidth:maxLabelWidth];
//        NSInteger textLines = ceil(messageTextHeight / oneLineTextHeight);
//        messageTextHeight += 8 * textLines;
//    }
    //文字宽度
    CGFloat messageTextWidth = [MXStringSizeUtil getWidthForAttributedText:self.cellText textHeight:messageTextHeight];
    if (messageTextSize.width > messageTextWidth) {
        messageTextWidth = messageTextSize.width;
    }
    //#warning 注：这里textLabel的宽度之所以要增加，是因为TTTAttributedLabel的bug，在文字有"."的情况下，有可能显示不出来，开发者可以帮忙定位TTTAttributedLabel的这个bug^.^
    NSRange periodRange = [self.messageContent rangeOfString:@"."];
    if (periodRange.location != NSNotFound) {
        messageTextWidth += 8;
    }
    if (messageTextWidth > maxLabelWidth) {
        messageTextWidth = maxLabelWidth;
    }
    //气泡高度
    CGFloat bubbleHeight = messageTextHeight + kMXCellBubbleToTextVerticalSpacing * 2;
    //气泡宽度
    CGFloat bubbleWidth = messageTextWidth + kMXCellBubbleToTextHorizontalLargerSpacing + kMXCellBubbleToTextHorizontalSmallerSpacing;
    
    //根据消息的来源，进行处理
    UIImage *bubbleImage = [MXChatViewConfig sharedConfig].incomingBubbleImage;
    if ([MXChatViewConfig sharedConfig].incomingBubbleColor) {
        bubbleImage = [MXImageUtil convertImageColorWithImage:bubbleImage toColor:[MXChatViewConfig sharedConfig].incomingBubbleColor];
    }
    if (self.cellFromType == MXChatMessageOutgoing) {
        //发送出去的消息
        bubbleImage = [MXChatViewConfig sharedConfig].outgoingBubbleImage;
        if ([MXChatViewConfig sharedConfig].outgoingBubbleColor) {
            bubbleImage = [MXImageUtil convertImageColorWithImage:bubbleImage toColor:[MXChatViewConfig sharedConfig].outgoingBubbleColor];
        }
        
        //头像的frame
        if ([MXChatViewConfig sharedConfig].enableOutgoingAvatar) {
            self.avatarFrame = CGRectMake(cellWidth-kMXCellAvatarToHorizontalEdgeSpacing-kMXCellAvatarDiameter, kMXCellAvatarToVerticalEdgeSpacing, kMXCellAvatarDiameter, kMXCellAvatarDiameter);
        } else {
            self.avatarFrame = CGRectMake(cellWidth-kMXCellAvatarToHorizontalEdgeSpacing-kMXCellAvatarDiameter, kMXCellAvatarToVerticalEdgeSpacing, 0, 0);
        }
        //气泡的frame
        self.bubbleImageFrame = CGRectMake(cellWidth-self.avatarFrame.size.width-kMXCellAvatarToHorizontalEdgeSpacing-kMXCellAvatarToBubbleSpacing-bubbleWidth, kMXCellAvatarToVerticalEdgeSpacing, bubbleWidth, bubbleHeight);
        //文字的frame
        self.textLabelFrame = CGRectMake(kMXCellBubbleToTextHorizontalSmallerSpacing, kMXCellBubbleToTextVerticalSpacing, messageTextWidth, messageTextHeight);
        //敏感词汇提示语的frame
        self.sensitiveLableFrame = CGRectMake(CGRectGetMaxX(self.bubbleImageFrame) - kMXTextCellSensitiveWidth, CGRectGetMaxY(self.bubbleImageFrame), kMXTextCellSensitiveWidth, self.isSensitive ? kMXTextCellSensitiveHeight : 0);
    } else {
        //收到的消息
        //头像的frame
        if ([MXChatViewConfig sharedConfig].enableIncomingAvatar) {
            self.avatarFrame = CGRectMake(kMXCellAvatarToHorizontalEdgeSpacing, kMXCellAvatarToVerticalEdgeSpacing, kMXCellAvatarDiameter, kMXCellAvatarDiameter);
        } else {
            self.avatarFrame = CGRectMake(kMXCellAvatarToHorizontalEdgeSpacing, kMXCellAvatarToVerticalEdgeSpacing, 0, 0);
        }
        //气泡的frame
        self.bubbleImageFrame = CGRectMake(self.avatarFrame.origin.x+self.avatarFrame.size.width+kMXCellAvatarToBubbleSpacing, self.avatarFrame.origin.y, bubbleWidth, bubbleHeight);
        //文字的frame
        self.textLabelFrame = CGRectMake(kMXCellBubbleToTextHorizontalLargerSpacing, kMXCellBubbleToTextVerticalSpacing, messageTextWidth, messageTextHeight);
        //敏感词汇提示语的frame
        self.sensitiveLableFrame = CGRectMake(CGRectGetMinX(self.bubbleImageFrame), CGRectGetMaxY(self.bubbleImageFrame), kMXTextCellSensitiveWidth, self.isSensitive ? kMXTextCellSensitiveHeight : 0);
    }
    
    //气泡图片
    self.bubbleImage = [bubbleImage resizableImageWithCapInsets:[MXChatViewConfig sharedConfig].bubbleImageStretchInsets];
    
    //发送消息的indicator的frame
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, kMXCellIndicatorDiameter, kMXCellIndicatorDiameter)];
    self.sendingIndicatorFrame = CGRectMake(self.bubbleImageFrame.origin.x-kMXCellBubbleToIndicatorSpacing-indicatorView.frame.size.width, self.bubbleImageFrame.origin.y+self.bubbleImageFrame.size.height/2-indicatorView.frame.size.height/2, indicatorView.frame.size.width, indicatorView.frame.size.height);
    
    //发送失败的图片frame
    UIImage *failureImage = [MXChatViewConfig sharedConfig].messageSendFailureImage;
    CGSize failureSize = CGSizeMake(ceil(failureImage.size.width * 2 / 3), ceil(failureImage.size.height * 2 / 3));
    self.sendFailureFrame = CGRectMake(self.bubbleImageFrame.origin.x-kMXCellBubbleToIndicatorSpacing-failureSize.width, self.bubbleImageFrame.origin.y+self.bubbleImageFrame.size.height/2-failureSize.height/2, failureSize.width, failureSize.height);
    
    //已读状态指示器的frame (仅对发送的消息显示)
    CGFloat statusIndicatorSize = 12.0; // 状态指示器大小
    if (self.cellFromType == MXChatCellOutgoing) {
        // 状态指示器放在气泡左边5像素，垂直居中对齐气泡底部
        self.readStatusIndicatorFrame = CGRectMake(CGRectGetMinX(self.bubbleImageFrame) - statusIndicatorSize - 5, 
                                                  CGRectGetMaxY(self.bubbleImageFrame) - statusIndicatorSize, 
                                                  statusIndicatorSize, 
                                                  statusIndicatorSize);
    } else {
        // 接收的消息不显示状态指示器
        self.readStatusIndicatorFrame = CGRectZero;
    }
    
    if (self.cacheTagListView) {
        [self.cacheTagListView updateLayoutWithMaxWidth:maxLabelWidth];
        self.cacheTagListView.frame = CGRectMake(self.bubbleImageFrame.origin.x,  CGRectGetMaxY(self.bubbleImageFrame) + kMXCellBubbleToIndicatorSpacing, self.cacheTagListView.bounds.size.width, self.cacheTagListView.bounds.size.height);
    }
    
    //计算cell的高度
    self.cellHeight = self.bubbleImageFrame.origin.y + self.bubbleImageFrame.size.height + kMXCellAvatarToVerticalEdgeSpacing + (self.isSensitive ? kMXTextCellSensitiveHeight : 0) + (self.cacheTagListView != nil ? self.cacheTagListView.frame.size.height + kMXCellBubbleToIndicatorSpacing : 0);
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
    return [[MXTextMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellReuseIdentifer];
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

- (NSString *)getMessageConversionId {
    return self.conversionId;
}

- (NSString *)getMessageReadStatus {
    return self.readStatus;
}

- (void)updateCellSendStatus:(MXChatMessageSendStatus)sendStatus {
    self.sendStatus = sendStatus;
}

- (void)updateCellMessageId:(NSString *)messageId {
    self.messageId = messageId;
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

-(void)updateSensitiveState:(BOOL)state cellText:(NSString *)cellText{
    self.isSensitive = state;
    
    // 【修复】先转换文本，然后基于转换后的文本重新匹配链接
    NSString *convertedContent = [MXServiceToViewInterface convertToUnicodeWithEmojiAlias:cellText];
    self.cellText = [[NSAttributedString alloc] initWithString:convertedContent attributes:self.cellTextAttributes];
    self.messageContent = cellText;
    
    // 【修复】基于转换后的文本重新匹配正则，确保 Range 和显示文本一致
    self.numberRangeDic = [self createRegexMap:[MXChatViewConfig sharedConfig].numberRegexs for:convertedContent];
    self.linkNumberRangeDic = [self createRegexMap:[MXChatViewConfig sharedConfig].linkRegexs for:convertedContent];
    self.emailNumberRangeDic = [self createRegexMap:[MXChatViewConfig sharedConfig].emailRegexs for:convertedContent];
    
    //防止邮件地址被解析为连接地址
    NSMutableDictionary *tempLinkNumberRangDic = [self.linkNumberRangeDic mutableCopy];
    for ( NSString *email in self.emailNumberRangeDic.allKeys) {
        for (NSString *link in self.linkNumberRangeDic.allKeys) {
            if ([email rangeOfString:link].length != 0) {
                [tempLinkNumberRangDic removeObjectForKey:link];
            }
        }
    }
    self.linkNumberRangeDic = tempLinkNumberRangDic;
    
    [self configCellWidth:self.cellWidth];
}

- (void)updateCellFrameWithCellWidth:(CGFloat)cellWidth {
    self.cellWidth = cellWidth;
    [self configCellWidth:cellWidth];
}

- (void)updateOutgoingAvatarImage:(UIImage *)avatarImage {
    if (self.cellFromType == MXChatCellOutgoing) {
        self.avatarImage = avatarImage;
    }
}

@end
