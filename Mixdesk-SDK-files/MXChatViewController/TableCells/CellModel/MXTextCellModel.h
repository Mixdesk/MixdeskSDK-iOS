//
//  MXTextCellModel.h
//  MixdeskSDK
//
//  Created by ijinmao on 15/10/29.
//  Copyright © 2015年 Mixdesk Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MXCellModelProtocol.h"
#import "MXTextMessage.h"
#import "MXTagListView.h"

/**
 * MXTextCellModel定义了文字消息的基本类型数据，包括产生cell的内部所有view的显示数据，cell内部元素的frame等
 * @warning MXTextCellModel必须满足MXCellModelProtocol协议
 */
@interface MXTextCellModel : NSObject <MXCellModelProtocol>

/**
 * @brief cell中消息的id
 */
@property (nonatomic, readonly, strong) NSString *messageId;

/**
 * @brief 用户名字，暂时没用
 */
@property (nonatomic, readonly, copy) NSString *userName;

/**
 * @brief 该cellModel的委托对象
 */
@property (nonatomic, weak) id<MXCellModelDelegate> delegate;

/**
 * @brief cell的高度
 */
@property (nonatomic, readonly, assign) CGFloat cellHeight;

/**
 * @brief cell的宽度
 */
@property (nonatomic, readonly, assign) CGFloat cellWidth;

/**
 * @brief 消息的文字
 */
@property (nonatomic, readonly, copy) NSAttributedString *cellText;

/**
 * @brief 消息的文字属性
 */
@property (nonatomic, readonly, copy) NSDictionary *cellTextAttributes;

/**
 * @brief 消息的时间
 */
@property (nonatomic, readonly, copy) NSDate *date;

/**
 * @brief 发送者的头像Path
 */
@property (nonatomic, readonly, copy) NSString *avatarPath;

/**
 * @brief 发送者的头像的图片
 */
@property (nonatomic, readonly, copy) UIImage *avatarImage;

/**
 * @brief 聊天气泡的image
 */
@property (nonatomic, readonly, copy) UIImage *bubbleImage;

/**
 * @brief 消息气泡的frame
 */
@property (nonatomic, readonly, assign) CGRect bubbleImageFrame;

/**
 * @brief 消息气泡中的文字的frame
 */
@property (nonatomic, readonly, assign) CGRect textLabelFrame;

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
 * @brief 消息文字中，数字选中识别的字典 [number : range]
 */
@property (nonatomic, readonly, strong) NSDictionary *numberRangeDic;

/**
 * @brief 消息文字中，url选中识别的字典 [url : range]
 */
@property (nonatomic, readonly, strong) NSDictionary *linkNumberRangeDic;

/**
 * @brief 消息文字中，email选中识别的字典 [email : range]
 */
@property (nonatomic, readonly, strong) NSDictionary *emailNumberRangeDic;

/**
 * @brief 消息文字中，是否包含敏感词汇
 */
@property (nonatomic, readonly, assign) BOOL isSensitive;

/**
 * @brief 敏感词汇提示语frame
 */
@property (nonatomic, readonly, assign) CGRect sensitiveLableFrame;

/**
 * @brief 消息的发送状态
 */
@property (nonatomic, assign) MXChatMessageSendStatus sendStatus;

/**
 * @brief 标签的tagList
 */
@property (nonatomic, readonly, strong) MXTagListView *cacheTagListView;

/**
 * @brief 标签的数据源
 */
@property (nonatomic, readonly, strong) NSArray *cacheTags;

/**
 *  根据MXMessage内容来生成cell model
 */
- (MXTextCellModel *)initCellModelWithMessage:(MXTextMessage *)message
                                    cellWidth:(CGFloat)cellWidth
                                     delegate:(id<MXCellModelDelegate>)delegator;


@end
