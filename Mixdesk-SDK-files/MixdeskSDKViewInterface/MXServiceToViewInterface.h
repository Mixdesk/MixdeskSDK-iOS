//
//  MXServiceToViewInterface.h
//  MXChatViewControllerDemo
//
//  Created by ijinmao on 15/11/5.
//  Copyright © 2015年 ijinmao. All rights reserved.
//
/**
 *  该文件的作用是：开源聊天界面调用Mixdesk SDK
 * 接口的中间层，目的是剥离开源界面中的Mixdesk业务逻辑。这样就能让该聊天界面用于非Mixdesk项目中，开发者只需要实现
 * `MXServiceToViewInterface`
 * 中的方法，即可将自己项目的业务逻辑和该聊天界面对接。
 */

#import "MXChatViewConfig.h"
#import "MXEventMessage.h"
#import "MXFileDownloadMessage.h"
#import "MXImageMessage.h"
#import "MXPhotoCardMessage.h"
#import "MXRichTextMessage.h"
#import "MXTextMessage.h"
#import "MXVoiceMessage.h"
#import <Foundation/Foundation.h>
#import <MixdeskSDK/MixdeskSDK.h>
#import <UIKit/UIKit.h>

/**
 *  该协议是UI层获取数据的委托方法
 */
@protocol MXServiceToViewInterfaceDelegate <NSObject>

/**
 * 获取到多个消息
 * @param messages 消息数组，元素为MXBaseMessage类型
 * @warning 该数组是按时间从旧到新排序
 */
- (void)didReceiveHistoryMessages:(NSArray *)messages;

/**
 * 获取到了新消息
 * @param messages 消息数组，元素为MXBaseMessage类型
 * @warning 该数组是按时间从旧到新排序
 */
- (void)didReceiveNewMessages:(NSArray *)messages;

/**
 *  收到了一条辅助信息（目前只有“客服不在线”、“被转接的消息”）
 *
 *  @param tipsContent 辅助信息
 */
- (void)didReceiveTipsContent:(NSString *)tipsContent;

- (void)didReceiveTipsContent:(NSString *)tipsContent showLines:(BOOL)show;

/**
 * 发送文字消息结果
 * @param newMessageId 发送成功以后返回的messageid
 * @param oldMessageId 发送之前messageid
 * @param newMessageDate 更新的发送时间
 * @param replacedContent
 * 需要替换的messag.content的内容(处理敏感词汇，替换原来词汇)
 * @param mediaPath 用于更新发送媒体消息成功以后缓存地址
 * @param sendStatus 发送状态
 * @param error 报错信息
 */
- (void)didSendMessageWithNewMessageId:(NSString *)newMessageId
                          oldMessageId:(NSString *)oldMessageId
                        newMessageDate:(NSDate *)newMessageDate
                       replacedContent:(NSString *)replacedContent
                       updateMediaPath:(NSString *)mediaPath
                            sendStatus:(MXChatMessageSendStatus)sendStatus
                                 error:(NSError *)error;

/**
 *  联系人已被转接
 *
 *  @param agentName 被转接的客服名字
 */
- (void)didRedirectWithAgentName:(NSString *)agentName;

// 客服分配完成
- (void)didScheduleResult:(MXClientOnlineResult)onLineResult
       withResultMessages:(NSArray<MXMessage *> *)message;

@end

/**
 *  界面发送的请求出错的委托方法
 */
@protocol MXServiceToViewInterfaceErrorDelegate <NSObject>

/**
 *  收到获取历史消息的错误
 */
- (void)getLoadHistoryMessageError;

@end

/**
 *  MXServiceToViewInterface是Mixdesk开源UI层和Mixdesk数据逻辑层的接口
 */
@interface MXServiceToViewInterface : NSObject

@property(nonatomic, weak) id<MXServiceToViewInterfaceDelegate>
    serviceToViewDelegate;

/**
 * 从服务端获取更多消息
 *
 * @param msgDate 获取该日期之前的历史消息;
 * @param messagesNum 获取消息的数量
 */
+ (void)getServerHistoryMessagesWithMsgDate:(NSDate *)msgDate
                             messagesNumber:(NSInteger)messagesNumber
                            successDelegate:
                                (id<MXServiceToViewInterfaceDelegate>)
                                    successDelegate
                              errorDelegate:
                                  (id<MXServiceToViewInterfaceErrorDelegate>)
                                      errorDelegate;

/**
 * 从本地获取更多消息
 *
 * @param msgDate 获取该日期之前的历史消息;
 * @param messagesNum 获取消息的数量
 */
+ (void)getDatabaseHistoryMessagesWithMsgDate:(NSDate *)msgDate
                               messagesNumber:(NSInteger)messagesNumber
                                     delegate:
                                         (id<MXServiceToViewInterfaceDelegate>)
                                             delegate;

/**
 * 从服务端获取留言消息和一般的消息
 *
 * @param msgDate 获取该日期之前的历史消息;
 * @param messagesNum 获取消息的数量
 */
+ (void)
    getServerHistoryMessagesAndTicketsWithMsgDate:(NSDate *)msgDate
                                   messagesNumber:(NSInteger)messagesNumber
                                  successDelegate:
                                      (id<MXServiceToViewInterfaceDelegate>)
                                          successDelegate
                                    errorDelegate:
                                        (id<MXServiceToViewInterfaceErrorDelegate>)
                                            errorDelegate;

/**
 * 发送文字消息
 * @param content
 * 消息内容。会做前后去空格处理，处理后的消息长度不能为0，否则不执行发送操作
 * @param localMessageId 本地消息id
 * @param delegate
 * 发送消息的代理，如果发送成功，会返回完整的消息对象，代理函数：-(void)didSendMessage:expcetion:
 */
+ (void)sendTextMessageWithContent:(NSString *)content
                         messageId:(NSString *)localMessageId
                          delegate:
                              (id<MXServiceToViewInterfaceDelegate>)delegate;

/**
 * 发送图片消息。该函数会做图片压缩操作，尺寸将会限制在最大1280px
 *
 * @param image 图片
 * @param localMessageId 本地消息id
 * @param delegate
 * 发送消息的代理，会返回完整的消息对象，代理函数：-(void)didSendMessage:expcetion:
 */
+ (void)sendImageMessageWithImage:(UIImage *)image
                        messageId:(NSString *)localMessageId
                         delegate:
                             (id<MXServiceToViewInterfaceDelegate>)delegate;

/**
 * 发送语音消息。使用该接口，需要开发者提供一条amr格式的语音.
 *
 * @param audio 需要发送的语音消息，格式为amr。
 * @param localMessageId 本地消息id
 * @param delegate
 * 发送消息的代理，会返回完整的消息对象，代理函数：-(void)didSendMessage:expcetion:
 */
+ (void)sendAudioMessage:(NSData *)audio
               messageId:(NSString *)localMessageId
                delegate:(id<MXServiceToViewInterfaceDelegate>)delegate;

/**
 * 发送视频消息。使用该接口，需要开发者提供MOV格式.
 *
 * @param filePath 需要发送视频的缓存路径。
 * @param localMessageId 本地消息id
 * @param delegate
 * 发送消息的代理，会返回完整的消息对象，代理函数：-(void)didSendMessage:expcetion:
 */
+ (void)sendVideoMessageWithFilePath:(NSString *)filePath
                           messageId:(NSString *)localMessageId
                            delegate:
                                (id<MXServiceToViewInterfaceDelegate>)delegate;

/**
 * 发送商品卡片消息
 *
 * @param pictureUrl 商品图片的url。不能为空，否则不执行发送操作。
 * @param title 商品标题。不能为空，否则不执行发送操作。
 * @param descripation 商品描述内容。不能为空，否则不执行发送操作。
 * @param productUrl 商品链接。不能为空，否则不执行发送操作。
 * @param salesCount 销售量。不设置就默认为0。
 * @param localMessageId 本地消息id
 * @param delegate
 * 发送消息的代理，会返回完整的消息对象，代理函数：-(void)didSendMessage:expcetion:
 */
+ (void)sendProductCardMessageWithPictureUrl:(NSString *)pictureUrl
                                       title:(NSString *)title
                                descripation:(NSString *)descripation
                                  productUrl:(NSString *)productUrl
                                  salesCount:(long)salesCount
                                   messageId:(NSString *)localMessageId
                                    delegate:
                                        (id<MXServiceToViewInterfaceDelegate>)
                                            delegate;

/**
 * 将用户正在输入的内容，提供给客服查看。该接口没有调用限制，但每1秒内只会向服务器发送一次数据
 * @param content 提供给客服看到的内容
 */
+ (void)sendClientInputtingWithContent:(NSString *)content;

/**
 * 根据开发者自定义的id，登陆Mixdesk客服系统
 * @param ;
 */
- (void)setClientOnlineWithCustomizedId:(NSString *)customizedId
                                success:(void (^)(BOOL completion,
                                                  NSString *agentName,
                                                  NSString *agentType,
                                                  NSArray *receivedMessages,
                                                  NSError *error))success
                 receiveMessageDelegate:(id<MXServiceToViewInterfaceDelegate>)
                                            receiveMessageDelegate;

/**
 * 根据Mixdesk的联系人id，登陆Mixdesk客服系统
 * @param ;
 */
- (void)setClientOnlineWithClientId:(NSString *)clientId
                            success:(void (^)(BOOL completion,
                                              NSString *agentName,
                                              NSString *agentType,
                                              NSArray *receivedMessages,
                                              NSError *error))success
             receiveMessageDelegate:
                 (id<MXServiceToViewInterfaceDelegate>)receiveMessageDelegate;

/**
 * 设置询前表单客服分配的问题
 */
+ (void)setScheduledProblem:(NSString *)problem;

/**
 * 设置联系人离线
 * @param ;
 */
+ (void)setClientOffline;

/**
 *  点击了某消息
 *
 *  @param messageId 消息id
 #pragma mark xlp - .m文件已经注释 17/7/25

 */
//+ (void)didTapMessageWithMessageId:(NSString *)messageId;

/**
 *  获取当前客服名字
 */
+ (NSString *)getCurrentAgentName;

/**
 *  获取当前客服对象
 */
+ (MXAgent *)getCurrentAgent;

/**
 *  获取当前客服状态
 *
 *  @return onDuty - 在线  offDuty - 隐身  offLine - 离线
 */
+ (MXChatAgentStatus)getCurrentAgentStatus;

/**
 *  当前是否有客服
 *
 */
+ (BOOL)isThereAgent;

/**
 *  当前是否有分配对话
 *
 */
+ (BOOL)haveConversation;

/**
 *  获取当前分配对话的会话id，，没有分配则为nil
 */
+ (NSString *)getCurrentConversationID;

/**
 *  下载多媒体消息的多媒体内容
 *
 *  @param messageId     消息id
 *  @param progressBlock 下载进度
 *  @param completion    完成回调
 */
+ (void)downloadMediaWithUrlString:(NSString *)urlString
                          progress:(void (^)(float progress))progressBlock
                        completion:(void (^)(NSData *mediaData,
                                             NSError *error))completion;

/**
 *  将数据库中某个message删除
 *
 *  @param messageId 消息id
 */
+ (void)removeMessageInDatabaseWithId:(NSString *)messageId
                           completion:(void (^)(BOOL success,
                                                NSError *error))completion;

/**
 *  获取当前联系人的联系人信息
 *
 *  @return 当前的联系人的信息
 *
 */
+ (NSDictionary *)getCurrentClientInfo;

/**
 *  上传联系人的头像
 *
 *  @param avatarImage 头像image
 *  @param completion  上传的回调
 */
+ (void)uploadClientAvatar:(UIImage *)avatarImage
                completion:
                    (void (^)(NSString *avatarUrl, NSError *error))completion;

/**
 *  对当前的对话做出评价
 *
 *  @param level 服务评级
 *  @param comment    评价留言
 */
+ (void)setEvaluationLevel:(NSInteger *)level
           evaluation_type:(NSInteger *)evaluation_type
                   tag_ids:(NSArray *)tag_ids
                   comment:(NSString *)comment
                  resolved:(NSInteger)resolved;

/**
 *  上传联系人信息
 *
 *  @param clientInfo 联系人信息
 */
+ (void)setClientInfoWithDictionary:(NSDictionary *)clientInfo
                         completion:
                             (void (^)(BOOL success, NSError *error))completion;

/**
 *  更新联系人信息
 *
 *  @param clientInfo 联系人信息
 */
+ (void)updateClientInfoWithDictionary:(NSDictionary *)clientInfo
                            completion:(void (^)(BOOL success,
                                                 NSError *error))completion;

/**
 *  缓存当前的输入文字
 *
 *  @param inputtingText 输入文字
 */
+ (void)setCurrentInputtingText:(NSString *)inputtingText;

/**
 *  获取缓存的输入文字
 *
 *  @return 输入文字
 */
+ (NSString *)getPreviousInputtingText;

/**
 * 获得服务端未读消息

 * @return 输入文字
 */
+ (void)getUnreadMessagesWithCompletion:(void (^)(NSArray *messages,
                                                  NSError *error))completion;

/**
 * 获得指定customizedId服务端未读消息
 */
+ (void)getUnreadMessagesWithCustomizedId:(NSString *)customizedId
                           withCompletion:(void (^)(NSArray *messages,
                                                    NSError *error))completion;

/**
 * 获得本地未读消息

 * @return 输入文字
 */
+ (NSArray *)getLocalUnreadMessages;

/**
 * 判断是否被加入了黑名单
 */
+ (BOOL)isBlacklisted;

/**
 * 清除已下载的文件
 */
+ (void)clearReceivedFiles;

/**
 修改或增加已保存的消息中的 accessory data 中的数据

 @param accessoryData 字典中的数据必须是基本数据和字符串
 */
+ (void)updateMessageWithId:(NSString *)messageId
           forAccessoryData:(NSDictionary *)accessoryData;

+ (void)updateMessageIds:(NSArray *)messageIds toReadStatus:(BOOL)isRead;

/**
 * 将所有消息标记为已读
 */
+ (void)markAllMessagesAsRead;

/**
 是否显示撤回消息提示语

 * @return NO: 不显示提示语， YES：显示提示语
 */
+ (BOOL)getEnterpriseConfigWithdrawToastStatus;

/**
 * 汇报文件被下载
 */
+ (void)clientDownloadFileWithMessageId:(NSString *)messageId
                          conversatioId:(NSString *)conversationId
                          andCompletion:
                              (void (^)(NSString *url, NSError *error))action;

/**
 *  取消下载
 *
 *  @param urlString     url
 */
+ (void)cancelDownloadForUrl:(NSString *)urlString;

// 强制转人工
- (void)forceRedirectHumanAgentWithSuccess:
            (void (^)(BOOL completion, NSString *agentName,
                      NSArray *receivedMessages))success
                                   failure:(void (^)(NSError *error))failure
                    receiveMessageDelegate:
                        (id<MXServiceToViewInterfaceDelegate>)
                            receiveMessageDelegate;

// 强制转人工
+ (NSString *)getCurrentAgentId;

/**
 获取当前的客服 type: agent | admin | robot
 */
+ (NSString *)getCurrentAgentType;

/**
 获取客服邀请评价显示的文案
 */
+ (void)getEvaluationPromtTextComplete:(void (^)(NSString *, NSError *))action;

/**
 获取客服邀请评价的反馈配置
 */
+ (void)getEvaluationPromtFeedbackComplete:(void (^)(NSString *,
                                                     NSError *))action;

/**
 获取是否显示强制转接人工按钮
 */
+ (void)getIsShowRedirectHumanButtonComplete:(void (^)(BOOL, NSError *))action;

/**
 获取当前企业的配置信息
 */
+ (void)getEnterpriseConfigInfoWithCache:(BOOL)isLoadCache
                                complete:
                                    (void (^)(MXEnterprise *, NSError *))action;

// 评价当前对话
+ (void)evaluateConversationWithConvId:
                                 level:(NSInteger *)level
                       evaluation_type:(NSInteger *)evaluation_type
                               tag_ids:(NSArray *)tag_ids
                               comment:(NSString *)comment
                              resolved:(NSInteger)resolved
                               success:(void (^)(BOOL completion))success
                               faliure:(void (^)(NSError *error))failure;

/**
获取当前企业的评价配置
*/

+ (void)getEnterpriseEvaluationConfig:(BOOL)isLoadCache
                             complete:(void (^)(MXEvaluationConfig *,
                                                NSError *))action;

/**
点击快捷按钮的回调
*/

+ (void)clickQuickBtn:(NSString *)func_id
         quick_btn_id:(NSInteger)quick_btn_id
                 func:(NSInteger)func;

/**
获取当前企业配置头像
 */
+ (NSString *)getEnterpriseConfigAvatar;

/**
获取当前企业配置名称
 */
+ (NSString *)getEnterpriseConfigName;

/**
 * 是否允许联系人主动评价客服
 */
+ (BOOL)allowActiveEvaluation;

/**
 在准备显示聊天界面是调用
 */
+ (void)prepareForChat;

/**
 在聊天界面消失是调用
 */
+ (void)completeChat;

/**
 切换本地用户为指定的自定义 id 用户, 回调的 clientId 如果为 nil
 的话表示刷新失败，或者该用户不存在。
 */
+ (void)refreshLocalClientWithCustomizedId:(NSString *)customizedId
                                  complete:(void (^)(NSString *clientId))action;

/**

 */
+ (void)requestPreChatServeyDataIfNeedCompletion:
    (void (^)(MXPreChatData *data, NSError *error))block;

/**
 获取验证码
 */
+ (void)getCaptchaComplete:(void (^)(NSString *token, UIImage *image))block;

+ (void)getCaptchaWithURLComplete:(void (^)(NSString *token,
                                            NSString *url))block;

+ (void)submitPreChatForm:(NSDictionary *)formData
               completion:(void (^)(id, NSError *))block;

/**
 判断上一步操作是否失败
 */
+ (NSError *)checkGlobalError;

/**
 转换 emoji 别名为 Unicode
 */
+ (NSString *)convertToUnicodeWithEmojiAlias:(NSString *)text;

/**
 *  开启Mixdesk群发消息服务
 * @param delegate 接收群发消息的代理;
 * @warning 需要在SDK初始化成功以后调用
 */
+ (void)openMXGroupNotificationServiceWithDelegate:
    (id<MXGroupNotificationDelegate>)delegate;

/**
 *  插入Mixdesk群发消息到会话流里面
 * @param notification 群发消息;
 */
+ (void)insertMXGroupNotificationToConversion:
    (MXGroupNotification *)notification;

/**
 * 当前是否开启无消息访客过滤
 */
+ (BOOL)currentOpenVisitorNoMessage;

/**
 * 当前是否隐藏历史对话
 */
+ (BOOL)currentHideHistoryConversation;

/**
 *  automation aiAgent 转人工
 */
+ (void)transferConversationFromAiAgentToHumanWithConvId;

@end
