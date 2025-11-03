//
//  MXManager.h
//  MixdeskSDK
//
//  Created by dingnan on 15/10/27.
//  Copyright © 2015年 Mixdesk Inc. All rights reserved.
//

#import "MXAgent.h"
#include <objc/NSObjCRuntime.h>
#import "MXCardInfo.h"
#import "MXDefinition.h"
#import "MXEnterprise.h"
#import "MXGroupNotification.h"
#import "MXMessage.h"
#import "MXPreChatData.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define MXSDKVersion @"1.0.9"
@protocol MXManagerDelegate <NSObject>

/**
 *  收到了消息
 *  @param message 消息
 */
- (void)didReceiveMXMessages:(NSArray<MXMessage *> *)message;

/**
 *  分配完成
 *  @param onLineResult 分配状态
 *  @param message 消息
 */
- (void)didScheduleResult:(MXClientOnlineResult)onLineResult
       withResultMessages:(NSArray<MXMessage *> *)message;

@end

@protocol MXGroupNotificationDelegate <NSObject>

/**
 *  收到了群发消息
 *  @param message 消息
 */
- (void)didReceiveMXGroupNotification:(NSArray<MXGroupNotification *> *)message;

@end

/**
 * @brief MixdeskSDK的配置管理类
 *
 * 开发者可以通过MXManager中提供的接口，对SDK进行配置；
 */

@interface MXManager : NSObject

/// 注册状态观察者在状态改变的时候调用
/// 注意不要使用 self, 该 block 会被 retain，使用 self
/// 会导致调用的类无法被释放。
+ (void)addStateObserverWithBlock:(StateChangeBlock)block
                          withKey:(NSString *)key;

/// 移除已注册的状态观察者
+ (void)removeStateChangeObserverWithKey:(NSString *)key;

/// 获取当前的状态
+ (MXState)getCurrentState;

/// 获取当前联系人是否分配了聊天
+ (BOOL)haveConversation;

/**
 *  获取当前分配对话的会话id，，没有分配则为nil
 */
+ (NSString *)getCurrentConversationID;

/**
 *  开启Mixdesk服务
 *
 *  @warning
 * App进入前台时，需要开启Mixdesk服务。开发者需要在AppDelegate.m中的applicationWillEnterForeground方法中，调用此接口，用于开启Mixdesk服务
 */
+ (void)openMixdeskService;

/**
 *  关闭Mixdesk服务
 *
 *  @warning
 * App退到后台时，需要关闭Mixdesk服务。开发者需要在AppDelegate.m中的applicationDidEnterBackground方法中，调用此接口，用于关闭Mixdesk服务
 */
+ (void)closeMixdeskService;

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
 * 设置用户的设备唯一标识，在AppDelegate.m的didRegisterForRemoteNotificationsWithDeviceToken系统回调中注册deviceToken。
 * App进入后台后，Mixdesk推送给开发者服务端的消息数据格式中，会有deviceToken的字段。
 *
 * @param deviceToken 设备唯一标识，用于推送服务;
 * @warning 初始化前后均可调用，如果使用 swift，建议使用
 * registerDeviceTokenString:(NSString *)token 代替
 */
+ (void)registerDeviceToken:(NSData *)deviceToken;

/**
 @param deviceToken 去掉特殊符号和空格之后的字符串，若使用 swift 集成 MixdeskSDK
 的时候，NSData 会被自动转为 Data，这个时候无法用上面的方法正确获取
 deviceToken，需要使用这个方法。
 */
+ (void)registerDeviceTokenString:(NSString *)token;
/**
 @param deviceToken  强制上传devicetoken给后端 以上2种办法失效时的补充方法
 */
+ (void)LastRegisterDeviceToken:(NSData *)deviceToken;   // oc
+ (void)LastRegisterDeviceTokenString:(NSString *)token; // swift

/**
 * 初始化SDK。Mixdesk建议开发者在AppDelegate.m中的系统回调didFinishLaunchingWithOptions中进行SDK初始化。
 * 如果成功返回一个联系人的信息，开发者可保存该clientId，绑定开发者自己的用户系统，下次使用setClientOnlineWithClientId进行上线
 *
 * @param appKey Mixdesk提供的AppKey
 * @param completion
 * 如果初始化成功，将会返回clientId，并且error为nil；如果初始化失败，clientId为空，会返回error
 */
+ (void)initWithAppkey:(NSString *)appKey
            completion:(void (^)(NSString *clientId, NSError *error))completion;

/**
    获取本地初始化过的 app key
 */
+ (NSArray *)getLocalAppKeys;

/**
 获取当前使用的 app key
 */
+ (NSString *)getCurrentAppKey;

/**
 获取消息所对应的企业 appkey
 */
+ (NSString *)appKeyForMessage:(MXMessage *)message;

/**
 * 设置询前表单客服分配的问题
 * @param problem           询前表单选择的问题内容
 */
+ (void)setScheduledProblem:(NSString *)problem;

/**
 * 开发者自定义当前联系人的信息，用于展示给客服。
 *
 * @param clientInfo 联系人的信息
 * @warning
 * 需要联系人先上线，再上传联系人信息。如果开发者使用Mixdesk的开源界面，不需要调用此接口，使用
 * MXChatViewManager 中的 setClientInfo 配置用户自定义信息即可。
 * @warning 如果开发者使用「开源聊天界面」的接口来上线，则需要监听
 * MX_CLIENT_ONLINE_SUCCESS_NOTIFICATION「联系人成功上线」的广播（见
 * MXDefinition.h），再调用此接口
 */
+ (void)setClientInfo:(NSDictionary<NSString *, NSString *> *)clientInfo
           completion:(void (^)(BOOL success, NSError *error))completion;

/**
 * 开发者自定义当前联系人的信息，用于展示给客服，强制更新
 *
 * @param clientInfo 联系人的信息
 * @warning
 * 需要联系人先上线，再上传联系人信息。如果开发者使用Mixdesk的开源界面，不需要调用此接口，使用
 * MXChatViewManager 中的 setClientInfo 配置用户自定义信息即可。
 * @warning 如果开发者使用「开源聊天界面」的接口来上线，则需要监听
 * MX_CLIENT_ONLINE_SUCCESS_NOTIFICATION「联系人成功上线」的广播（见
 * MXDefinition.h），再调用此接口
 */
+ (void)updateClientInfo:(NSDictionary<NSString *, NSString *> *)clientInfo
              completion:(void (^)(BOOL success, NSError *error))completion;

/**
 *  设置联系人的头像
 *
 *  @param avatarImage 头像Image
 *  @param completion  设置头像图片的回调
 *  @warning 需要联系人上线之后，再调用此接口，具体请监听
 * MX_CLIENT_ONLINE_SUCCESS_NOTIFICATION「联系人成功上线」的广播，具体见
 * MXDefinition.h
 */
+ (void)setClientAvatar:(UIImage *)avatarImage
             completion:
                 (void (^)(NSString *avatarUrl, NSError *error))completion;

/**
 * 让当前的client上线。请求成功后，该联系人将会出现在客服的对话列表中。
 *
 * @param result 上线结果，可以用作判断是否上线成功
 * @param agent 上线成功后，被分配的客服实体
 * @param messages 当前对话的消息
 * @param receiveMessageDelegate 接收消息的委托代理
 * @warning 需要初始化后才能调用；
 * @warning 建议在联系人点击「在线客服」按钮时，再调用该接口；不建议在 App
 * 启动时调用该接口，这样会产生大量无效对话；
 */
+ (void)setCurrentClientOnlineWithSuccess:
            (void (^)(MXClientOnlineResult result, MXAgent *agent,
                      NSArray<MXMessage *> *messages))success
                                  failure:(void (^)(NSError *error))failure
                   receiveMessageDelegate:
                       (id<MXManagerDelegate>)receiveMessageDelegate;

/**
 * 根据Mixdesk的联系人id，登陆Mixdesk客服系统，并上线该联系人。请求成功后，该联系人将会出现在客服的对话列表中。
 *
 * @param clientId Mixdesk的联系人id
 * @param result 上线结果，可以用作判断是否上线成功。
 * @param agent 上线成功后，被分配的客服实体
 * @param messages 当前对话的消息
 * @param receiveMessageDelegate 接收消息的委托代理
 * @warning 需要初始化后才能调用；
 * @warning 建议在联系人点击「在线客服」按钮时，再调用该接口；不建议在 App
 * 启动时调用该接口，这样会产生大量无效对话；
 */
+ (void)setClientOnlineWithClientId:(NSString *)clientId
                            success:(void (^)(MXClientOnlineResult result,
                                              MXAgent *agent,
                                              NSArray<MXMessage *> *messages))
                                        success
                            failure:(void (^)(NSError *error))failure
             receiveMessageDelegate:
                 (id<MXManagerDelegate>)receiveMessageDelegate;

/**
 * 根据开发者自定义的id，登陆Mixdesk客服系统，并上线该联系人。请求成功后，该联系人将会出现在客服的对话列表中。
 *
 * @param customizedId
 * 开发者自定义的id，服务端查询该企业是否有该自定义id对应的client，如果存在，则用该client上线并分配对话；如果不存在，服务端生成一个新的client上线并分配对话，并将该customizedId与该新生成的client进行绑定；
 * @param result 上线结果，可以用作判断是否上线成功。
 * @param agent 上线成功后，被分配的客服实体
 * @param messages 当前对话的消息
 * @param receiveMessageDelegate 接收消息的委托代理
 * @warning 需要初始化后才能调
 * @warning
 * customizedId不能为自增长，否则有安全隐患，建议开发者使用setClientOnlineWithClientId接口进行登录
 * @warning 建议在联系人点击「在线客服」按钮时，再调用该接口；不建议在 App
 * 启动时调用该接口，这样会产生大量无效对话；
 */
+ (void)setClientOnlineWithCustomizedId:(NSString *)customizedId
                                success:
                                    (void (^)(MXClientOnlineResult result,
                                              MXAgent *agent,
                                              NSArray<MXMessage *> *messages))
                                        success
                                failure:(void (^)(NSError *error))failure
                 receiveMessageDelegate:
                     (id<MXManagerDelegate>)receiveMessageDelegate;

/**
 *  获取当前联系人的联系人id，开发者可保存该联系人id，下次使用setClientOnlineWithClientId接口来让该联系人登陆Mixdesk客服系统
 *
 *  @return 当前的联系人id
 *
 */
+ (NSString *)getCurrentClientId;

/**
 当前的联系人自定义 id
 */
+ (NSString *)getCurrentCustomizedId;

/**
 *  获取当前联系人的联系人信息
 *
 *  @return 当前的联系人的信息
 *
 */
+ (NSDictionary *)getCurrentClientInfo;

/**
 * Mixdesk将重新初始化一个新的联系人，该联系人没有任何历史记录及用户信息。开发者可选择将该id保存并与app的用户绑定。
 *
 * @param completion 初始化新联系人的回调；success:是否创建成功成功;
 * clientId:新联系人的id，开发者可选择将该id保存并与app的用户绑定。
 * @warning
 * 需要在初始化后，且联系人为离线状态调用。否则success为NO，且返回当前在线联系人的clientId
 */
+ (void)createClient:(void (^)(NSString *clientId, NSError *error))completion;

/**
 * 设置联系人离线
 * @warning 需要初始化成功后才能调用
 * @warning
 * Mixdesk建议：退出聊天界面时，不要调用此接口；因为：如果设置了联系人离线，则客服发送的消息将会发送给开发者的推送服务器；如果没有设置联系人离线，开发者接受即时消息的代理收到消息，并收到新消息产生的notification；开发者可以监听此notification，用于显示小红点未读标记；
 */
+ (void)setClientOffline;

/**
 * 获取当前正在接待的客服信息
 *
 * @return 客服实体
 * @warning
 * 需要在初始化成功后且联系人在上线状态调用。如果上线后没有客服在线，将会返回nil；如果分配到客服，则返回该Agent对象。
 */
+ (MXAgent *)getCurrentAgent;

/**
 * 从服务端获取某日期之前的历史消息
 *
 * @param msgDate        获取该日期之前的历史消息，注：该日期是UTC格式的;
 * @param messagesNumber 获取消息的数量
 * @param success        回调中，messagesArray:消息数组
 * @param failure        获取失败，返回错误信息
 * @warning 需要在初始化成功后调用才有效
 */
+ (void)
    getServerHistoryMessagesWithUTCMsgDate:(NSDate *)msgDate
                            messagesNumber:(NSInteger)messagesNumber
                                   success:(void (^)(NSArray<MXMessage *>
                                                         *messagesArray))success
                                   failure:(void (^)(NSError *error))failure;

/**
 * 从服务端获取某日期之前的历史消息(包含所有信息)
 *
 * @param msgDate        获取该日期之前的历史消息，注：该日期是UTC格式的;
 * @param messagesNumber 获取消息的数量
 * @param success        回调中，messagesArray:消息数组
 * @param failure        获取失败，返回错误信息
 * @warning 需要在初始化成功后调用才有效
 */
+ (void)
    getServerHistoryMessagesAndTicketsWithUTCMsgDate:(NSDate *)msgDate
                                      messagesNumber:(NSInteger)messagesNumber
                                             success:
                                                 (void (^)(NSArray<MXMessage *>
                                                               *messagesArray))
                                                     success
                                             failure:(void (^)(NSError *error))
                                                         failure;

/**
 * 从本地数据库获取历史消息
 *
 * @param msgDate        获取该日期之前的历史消息;
 * @param messagesNumber 获取消息的数量
 * @param success        回调中，messagesArray:消息数组
 * @warning 需要在初始化成功后调用才有效
 */
+ (void)getDatabaseHistoryMessagesWithMsgDate:(NSDate *)msgDate
                               messagesNumber:(NSInteger)messagesNumber
                                       result:
                                           (void (^)(NSArray<MXMessage *>
                                                         *messagesArray))result;

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
 *  取消下载
 *
 *  @param urlString     url
 */
+ (void)cancelDownloadForUrl:(NSString *)urlString;

/**
 *  清除所有Mixdesk的多媒体缓存
 *
 *  @param mediaSize Mixdesk缓存多媒体的大小，以 M 为单位
 */
+ (void)removeAllMediaDataWithCompletion:(void (^)(float mediaSize))completion;

/**
 * 发送文字消息
 *
 * @param content
 * 消息内容。会做前后去空格处理，处理后的消息长度不能为0，否则不执行发送操作
 * @param sendedMessage
 * 返回发送后的消息。消息是否发送成功，需根据message的sendStatus判断。
 *
 * @return 该条文字消息。此时该消息状态为发送中.
 * @warning 需要在初始化成功后，且联系人是在线状态时调用才有效
 */
+ (MXMessage *)sendTextMessageWithContent:(NSString *)content
                               completion:(void (^)(MXMessage *sendedMessage,
                                                    NSError *error))completion;

/**
 * 发送图片消息。
 *
 * @param image 图片
 * @param sendedMessage
 * 返回发送后的消息。如果发送成功，message的content为图片的网络地址。消息是否发送成功，需根据message的sendStatus判断。
 * @return
 * 该条图片消息。此时该消息状态为发送中，message的content属性是本地图片路径
 * @warning
 * SDK不会去限制图片大小，如果开发者需要限制图片大小，需要调整图片大小后，再使用此接口
 * @warning 需要在初始化成功后，且联系人是在线状态时调用才有效
 */
+ (MXMessage *)sendImageMessageWithImage:(UIImage *)image
                              completion:(void (^)(MXMessage *sendedMessage,
                                                   NSError *error))completion;

/**
 * 发送语音消息。
 *
 * @param audio 需要发送的语音消息，格式为amr。
 * @param sendedMessage
 * 返回发送后的消息。如果发送成功，message的content为语音的网络地址。消息是否发送成功，需根据message的sendStatus判断。
 * @return
 * 该条语音消息。此时该消息状态为发送中，message的content属性是本地语音路径.
 * @warning 使用该接口，需要开发者提供一条amr格式的语音.
 * @warning 需要在初始化成功后，且联系人是在线状态时调用才有效
 */
+ (MXMessage *)sendAudioMessage:(NSData *)audio
                     completion:(void (^)(MXMessage *sendedMessage,
                                          NSError *error))completion;

/**
 * 发送视频消息。
 *
 * @param videoPath 需要发送的视频本地路径
 * @param sendedMessage
 * 返回发送后的消息。如果发送成功，message的content为视频的网络地址。消息是否发送成功，需根据message的sendStatus判断。
 * @return
 * 该条视频消息。此时该消息状态为发送中，message的content属性是本地视频路径.
 * @warning 使用该接口，会对提供的视频进行压缩，并且转换为MP4格式发送.
 * @warning 需要在初始化成功后，且联系人是在线状态时调用才有效
 */
+ (MXMessage *)sendVideoMessage:(NSString *)videoPath
                     completion:(void (^)(MXMessage *sendedMessage,
                                          NSError *error))completion;

/**
 * 发送商品卡片消息
 *
 * @param pictureUrl 商品图片的url。不能为空，否则不执行发送操作。
 * @param title 商品标题。不能为空，否则不执行发送操作。
 * @param descripation 商品描述内容。不能为空，否则不执行发送操作。
 * @param productUrl 商品链接。不能为空，否则不执行发送操作。
 * @param salesCount 销售量。不设置就默认为0。
 *
 * @return 该条商品卡片消息。此时该消息状态为发送中.
 * @warning 需要在初始化成功后，且联系人是在线状态时调用才有效
 */
+ (MXMessage *)
    sendProductCardMessageWithPictureUrl:(NSString *)pictureUrl
                                   title:(NSString *)title
                            descripation:(NSString *)descripation
                              productUrl:(NSString *)productUrl
                              salesCount:(long)salesCount
                              completion:(void (^)(MXMessage *sendedMessage,
                                                   NSError *error))completion;

/**
 * 将用户正在输入的内容，提供给客服查看。该接口没有调用限制，但每1秒内只会向服务器发送一次数据
 * @param content 提供给客服看到的内容
 * @warning 需要在初始化成功后，且联系人是在线状态时调用才有效
 */
+ (void)sendClientInputtingWithContent:(NSString *)content;

/**
 * 是否修改某条消息为未读
 * @param messageIds 被修改的消息id数组
 * @param isRead   该消息是否已读
 */
+ (void)updateMessageIds:(NSArray *)messageIds toReadStatus:(BOOL)isRead;

/**
 * 修改某条消息的已读状态
 * @param messageIds 被修改的消息id数组
 * @param readStatus   该消息 已送达 | 已读
 */
+ (void)updateMessageReadStatusByIds:(NSArray *)messageIds readStatus:(NSNumber *)readStatus;


/**
 * 将所有消息标记为已读
 */
+ (void)markAllMessagesAsRead;

/**
 *  将数据库中某个message删除
 *
 *  @param messageId 消息id
 */
+ (void)removeMessageInDatabaseWithId:(NSString *)messageId
                           completion:(void (^)(BOOL success,
                                                NSError *error))completion;

/**
 *  将 SDK 本地数据库中的消息都删除
 */
+ (void)removeAllMessageFromDatabaseWithCompletion:
    (void (^)(BOOL success, NSError *error))completion;

/**
 *  结束当前的对话
 *
 *  @param completion 结束对话后的回调
 *  @warning
 * Mixdesk建议：退出聊天界面时，不要调用此接口，联系人产生的对话如果长时间没有响应，Mixdesk后端将会结束这些超时的对话。
 *  @warning
 * 因为结束对话后，客服在工作台将不能对已经结束的对话发送消息，联系人也就不能收到客服的回复了。一般联系人咨询的场景是：联系人在聊天界面咨询了一个问题后，通常不会在聊天界面中等待客服的回复，而是退出聊天界面去玩儿
 * App
 * 的其他功能；如果退出聊天界面，就结束了该对话，那么该条对话将变成历史对话，客服在
 * web 工作台看不到该对话，有可能就把这条对话无视掉了。
 *  @warning 如果开发者担心系统超时结束对话的时间很慢，开发者可以建立一个
 * Timer，在联系人退出聊天界面后开始计时，并在联系人重新进入客服聊天界面或监听到
 * SDK 收到客服消息时，重置 Timer；如果 Timer
 * 超过开发者设置的时间阈值，则可以调用结束当前对话。
 */
+ (void)endCurrentConversationWithCompletion:
    (void (^)(BOOL success, NSError *error))completion;

// 评价当前对话
+ (void)evaluateCurrentConversationWithEvaluation:(NSInteger)level
                                  evaluation_type:(NSInteger)evaluation_type
                                          tag_ids:(NSArray *)tag_ids
                                          comment:(NSString *)comment
                                         resolved:(NSInteger)resolved
                                       completion:
                                           (void (^)(BOOL success,
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
 * 获得当前MixdeskSDK的版本号
 */
+ (NSString *)getMixdeskSDKVersion;

/**
 * 获得所有未读消息，包括本地和服务端的
 */
+ (void)getUnreadMessagesWithCompletion:(void (^)(NSArray *messages,
                                                  NSError *error))completion;

/**
 *  获取指定 customizedId 联系人的未读消息
 */
+ (void)getUnreadMessagesWithCustomizedId:(NSString *)customizedId
                               completion:(void (^)(NSArray *messages,
                                                    NSError *error))completion;

/**
 获得本地未读消息
 */
+ (NSArray *)getLocalUnreadeMessages;

/**
 * 当前用户是否被加入黑名单
 */
+ (BOOL)isBlacklisted;

/**
 * 请求文件的下载地址
 */
+ (void)clientDownloadFileWithMessageId:(NSString *)messageId
                          conversatioId:(NSString *)conversationId
                          andCompletion:
                              (void (^)(NSString *url, NSError *error))action;

/**
 修改或增加已保存的消息中的 accessory data 中的数据

 @param accessoryData 字典中的数据必须是基本数据和字符串
 */
+ (void)updateMessageWithId:(NSString *)messageId
           forAccessoryData:(NSDictionary *)accessoryData;

/**
 将消息标记为撤回

 @param isWithDraw YES为已撤回消息、NO为普通消息
 */
+ (void)updateMessageWithDrawWithId:(NSString *)messageId
                     withIsWithDraw:(BOOL)isWithDraw;

/**
 是否显示撤回消息提示语

 * @return NO: 不显示提示语， YES：显示提示语
 */
+ (BOOL)getEnterpriseConfigWithdrawToastStatus;

/**
 强制转人工
 */
+ (void)forceRedirectHumanAgentWithSuccess:
            (void (^)(MXClientOnlineResult result, MXAgent *agent,
                      NSArray<MXMessage *> *messages))success
                                   failure:(void (^)(NSError *error))failure
                    receiveMessageDelegate:
                        (id<MXManagerDelegate>)receiveMessageDelegate;

/**
 转换 emoji 别名为 Unicode
 */
+ (NSString *)convertToUnicodeWithEmojiAlias:(NSString *)text;

/**
 获取当前的客服 id
 */
+ (NSString *)getCurrentAgentId;

/**
 获取当前的客服 type: agent | admin
 */
+ (NSString *)getCurrentAgentType;

/**
获取当前企业的配置信息
 */

+ (void)getEnterpriseConfigDataWithCache:(BOOL)isLoadCache
                                complete:
                                    (void (^)(MXEnterprise *, NSError *))action;

/**
获取当前企业配置头像
 */
+ (NSString *)getEnterpriseConfigAvatar;

/**
获取当前企业配置名称
 */
+ (NSString *)getEnterpriseConfigName;

/**
 开始显示聊天界面，如果自定义聊天界面，在聊天界面出现的时候调用，通知 SDK
 进行初始化
 */
+ (void)didStartChat;

/**
 聊天结束，如果自定义聊天界面，在聊天界面消失的时候嗲用，通知 SDK 进行清理工作
 */
+ (void)didEndChat;

/* 获取客服邀请评价显示的文案
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
    切换本地用户为指定的自定义 id 用户, 回调的 clientId 如果为 nil
   的话表示刷新失败，或者该用户不存在。
 */
+ (void)refreshLocalClientWithCustomizedId:(NSString *)customizedId
                                  complete:(void (^)(NSString *clientId))action;

+ (NSError *)checkGlobalError;

/**
 *  配置sdk的渠道来源
 *
 * @param channel  来源渠道
 */
+ (void)configSourceChannel:(MXSDKSourceChannel)channel;

/**
 根据当前的用户 id， 或者自定义用户
 id，首先判断需不需要显示询前表单：如果当前对话未结束，则需要显示，这时发起请求，从服务器获取表单数据，返回的结果根据用户指定的
 agent token， group token（如果有），将数据过滤之后返回。
 */
+ (void)requestPreChatServeyDataIfNeedWithClientId:(NSString *)clientIdIn
                                      customizedId:(NSString *)customizedIdIn
                                        completion:
                                            (void (^)(MXPreChatData *data,
                                                      NSError *error))block;

/**
 获取验证码图片和 token
 */
+ (void)getCaptchaComplete:(void (^)(NSString *token, UIImage *image))block;

/**
 获取验证码图片和 token
 */
+ (void)getCaptchaURLComplete:(void (^)(NSString *token,
                                        NSString *imageURL))block;

/**
 提交用户填写的讯前表单数据
 */
+ (void)submitPreChatForm:(NSDictionary *)formData
               completion:(void (^)(id, NSError *))block;

/**
更新线索卡片
*/
+ (void)updateCardInfo:(NSDictionary *)param
            completion:(void (^)(BOOL success, NSError *error))completion;

/**
 获取是否第一次上线
 */
+ (BOOL)getLoginStatus;
/*获取网络是否可用*/
+ (BOOL)obtainNetIsReachable;

+ (void)refreshPushInfoWithToken:(NSString *)token
                         Success:(void (^)(BOOL completion))success
                         failure:(void (^)(NSError *error))failure;

/**
 * 是否允许联系人主动评价客服
 */
+ (BOOL)allowActiveEvaluation;

/**
 * 当前是否开启无消息访客过滤
 */
+ (BOOL)currentOpenVisitorNoMessage;

/**
 * 当前是否隐藏历史对话
 */
+ (BOOL)currentHideHistoryConversation;

/**
 * 设置设备信息
 */
+ (void)setClientVisitInfoToService;

/**
 *  automation aiAgent 转人工
 */
+ (void)transferConversationFromAiAgentToHumanWithConvId;

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
 当前企业是否地区限制
 */
+ (BOOL)isAreaRestricted;

/**
 当前企业是否能查看客服的已读状态
 */
+ (BOOL)isAgentToClientMsgStatus;

@end
