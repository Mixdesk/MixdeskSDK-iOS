//
//  MXServiceToViewInterface.m
//  MXChatViewControllerDemo
//
//  Created by ijinmao on 15/11/5.
//  Copyright © 2015年 ijinmao. All rights reserved.
//

#import "MXServiceToViewInterface.h"
#import "MXBundleUtil.h"
#import "MXChatFileUtil.h"
#import "MXEventMessageFactory.h"
#import "MXMessageFactoryHelper.h"
#import "MXVisialMessageFactory.h"
#import "NSArray+MXFunctional.h"
#import "MXToast.h"
#import <MixdeskSDK/MixdeskSDK.h>

#pragma 该文件的作用是 : 开源聊天界面调用Mixdesk SDK 接口的中间层,             \
    目的是剥离开源界面中的Mixdesk业务逻辑                                      \
        .这样就能让该聊天界面用于非Mixdesk项目中,                              \
    开发者只需要实现 'MXServiceToViewInterface'中的方法,                       \
    即可将自己项目的业务逻辑和该聊天界面对接.

@interface MXServiceToViewInterface () <MXManagerDelegate>

@end

@implementation MXServiceToViewInterface

+ (void)getServerHistoryMessagesWithMsgDate:(NSDate *)msgDate
                             messagesNumber:(NSInteger)messagesNumber
                            successDelegate:
                                (id<MXServiceToViewInterfaceDelegate>)
                                    successDelegate
                              errorDelegate:
                                  (id<MXServiceToViewInterfaceErrorDelegate>)
                                      errorDelegate {
  // 将msgDate修改成GMT时区
  [MXManager getServerHistoryMessagesWithUTCMsgDate:msgDate
      messagesNumber:messagesNumber
      success:^(NSArray<MXMessage *> *messagesArray) {
        NSArray *toMessages = [MXServiceToViewInterface
            convertToChatViewMessageWithMXMessages:messagesArray];
        if (successDelegate) {
          if ([successDelegate
                  respondsToSelector:@selector(didReceiveHistoryMessages:)]) {
            [successDelegate didReceiveHistoryMessages:toMessages];
          }
        }
      }
      failure:^(NSError *error) {
        if (errorDelegate) {
          if ([errorDelegate
                  respondsToSelector:@selector(getLoadHistoryMessageError)]) {
            [errorDelegate getLoadHistoryMessageError];
          }
        }
      }];
}

+ (void)getDatabaseHistoryMessagesWithMsgDate:(NSDate *)msgDate
                               messagesNumber:(NSInteger)messagesNumber
                                     delegate:
                                         (id<MXServiceToViewInterfaceDelegate>)
                                             delegate {
  [MXManager
      getDatabaseHistoryMessagesWithMsgDate:msgDate
                             messagesNumber:messagesNumber
                                     result:^(
                                         NSArray<MXMessage *> *messagesArray) {
                                       NSArray *toMessages = [MXServiceToViewInterface
                                           convertToChatViewMessageWithMXMessages:
                                               messagesArray];
                                       if (delegate) {
                                         if ([delegate
                                                 respondsToSelector:@selector
                                                 (didReceiveHistoryMessages:
                                                         )]) {
                                           dispatch_after(
                                               dispatch_time(
                                                   DISPATCH_TIME_NOW,
                                                   (int64_t)(0.1 *
                                                             NSEC_PER_SEC)),
                                               dispatch_get_main_queue(), ^{
                                                 [delegate
                                                     didReceiveHistoryMessages:
                                                         toMessages];
                                               });
                                         }
                                       }
                                     }];
}

+ (void)
    getServerHistoryMessagesAndTicketsWithMsgDate:(NSDate *)msgDate
                                   messagesNumber:(NSInteger)messagesNumber
                                  successDelegate:
                                      (id<MXServiceToViewInterfaceDelegate>)
                                          successDelegate
                                    errorDelegate:
                                        (id<MXServiceToViewInterfaceErrorDelegate>)
                                            errorDelegate {
  [MXManager getServerHistoryMessagesAndTicketsWithUTCMsgDate:msgDate
      messagesNumber:messagesNumber
      success:^(NSArray<MXMessage *> *messagesArray) {
        NSArray *toMessages = [MXServiceToViewInterface
            convertToChatViewMessageWithMXMessages:messagesArray];
        if (successDelegate) {
          if ([successDelegate
                  respondsToSelector:@selector(didReceiveHistoryMessages:)]) {
            [successDelegate didReceiveHistoryMessages:toMessages];
          }
        }
      }
      failure:^(NSError *error) {
        if (errorDelegate) {
          if ([errorDelegate
                  respondsToSelector:@selector(getLoadHistoryMessageError)]) {
            [errorDelegate getLoadHistoryMessageError];
          }
        }
      }];
}

+ (NSArray *)convertToChatViewMessageWithMXMessages:(NSArray *)messagesArray {
  // 将MXMessage转换成UI能用的Message类型
  NSMutableArray *toMessages = [[NSMutableArray alloc] init];
  for (MXMessage *fromMessage in messagesArray) {
    // 这里加要单独处理欢迎语头像处理问题
    if (fromMessage.type == MXMessageTypeWelcome &&
        [fromMessage.agentId intValue] == 0 &&
        fromMessage.messageAvatar.length < 1) {
      fromMessage.messageAvatar =
          [MXServiceToViewInterface getEnterpriseConfigAvatar];
      fromMessage.messageUserName =
          [MXServiceToViewInterface getEnterpriseConfigName];
    }

    // 非联系人消息 又没有头像 补充企业头像
    else if (fromMessage.fromType != MXMessageFromTypeClient &&
             fromMessage.messageAvatar.length < 1) {
      fromMessage.messageAvatar =
          [MXServiceToViewInterface getEnterpriseConfigAvatar];
      fromMessage.messageUserName =
          [MXServiceToViewInterface getEnterpriseConfigName];
    }

    MXBaseMessage *toMessage = [[MXMessageFactoryHelper
        factoryWithMessageAction:fromMessage.action
                     contentType:fromMessage.contentType
                        fromType:fromMessage.fromType]
        createMessage:fromMessage];
    if (toMessage) {
      [toMessages addObject:toMessage];
    }
  }

  return toMessages;
}

+ (void)sendTextMessageWithContent:(NSString *)content
                         messageId:(NSString *)localMessageId
                          delegate:
                              (id<MXServiceToViewInterfaceDelegate>)delegate;
{
  [MXManager
      sendTextMessageWithContent:content
                      completion:^(MXMessage *sendedMessage, NSError *error) {
                        if (error) {
                          [self didSendFailedWithMessage:sendedMessage
                                          localMessageId:localMessageId
                                                   error:error
                                                delegate:delegate];
                        } else {
                          [self didSendMessage:sendedMessage
                                localMessageId:localMessageId
                                      delegate:delegate];
                        }
                      }];
}

+ (void)sendImageMessageWithImage:(UIImage *)image
                        messageId:(NSString *)localMessageId
                         delegate:
                             (id<MXServiceToViewInterfaceDelegate>)delegate;
{
  [MXManager
      sendImageMessageWithImage:image
                     completion:^(MXMessage *sendedMessage, NSError *error) {
                       if (error) {
                         [self didSendFailedWithMessage:sendedMessage
                                         localMessageId:localMessageId
                                                  error:error
                                               delegate:delegate];
                       } else {
                         [self didSendMessage:sendedMessage
                               localMessageId:localMessageId
                                     delegate:delegate];
                       }
                     }];
}

+ (void)sendAudioMessage:(NSData *)audio
               messageId:(NSString *)localMessageId
                delegate:(id<MXServiceToViewInterfaceDelegate>)delegate {
  [MXManager sendAudioMessage:audio
                   completion:^(MXMessage *sendedMessage, NSError *error) {
                     if (error) {
                       [self didSendFailedWithMessage:sendedMessage
                                       localMessageId:localMessageId
                                                error:error
                                             delegate:delegate];
                     } else {
                       [self didSendMessage:sendedMessage
                             localMessageId:localMessageId
                                   delegate:delegate];
                     }
                   }];
}

+ (void)sendVideoMessageWithFilePath:(NSString *)filePath
                           messageId:(NSString *)localMessageId
                            delegate:
                                (id<MXServiceToViewInterfaceDelegate>)delegate {
  [MXManager sendVideoMessage:filePath
                   completion:^(MXMessage *sendedMessage, NSError *error) {
                     if (error) {
                       [self didSendFailedWithMessage:sendedMessage
                                       localMessageId:localMessageId
                                                error:error
                                             delegate:delegate];
                     } else {
                       [self didSendMessage:sendedMessage
                             localMessageId:localMessageId
                                   delegate:delegate];
                     }
                   }];
}

+ (void)sendProductCardMessageWithPictureUrl:(NSString *)pictureUrl
                                       title:(NSString *)title
                                descripation:(NSString *)descripation
                                  productUrl:(NSString *)productUrl
                                  salesCount:(long)salesCount
                                   messageId:(NSString *)localMessageId
                                    delegate:
                                        (id<MXServiceToViewInterfaceDelegate>)
                                            delegate {
  [MXManager
      sendProductCardMessageWithPictureUrl:pictureUrl
                                     title:title
                              descripation:descripation
                                productUrl:productUrl
                                salesCount:salesCount
                                completion:^(MXMessage *sendedMessage,
                                             NSError *error) {
                                  if (error) {
                                    [self
                                        didSendFailedWithMessage:sendedMessage
                                                  localMessageId:localMessageId
                                                           error:error
                                                        delegate:delegate];
                                  } else {
                                    [self didSendMessage:sendedMessage
                                          localMessageId:localMessageId
                                                delegate:delegate];
                                  }
                                }];
}

+ (void)sendProductCardMessageWithTitle:(NSString *)title
                             productUrl:(NSString *)productUrl
                             pictureUrl:(NSString *)pictureUrl
                                  price:(NSString *)price
                            description:(NSString *)desc
                              messageId:(NSString *)localMessageId
                               delegate:(id<MXServiceToViewInterfaceDelegate>)
                                            delegate {
  void (^completion)(MXMessage *, NSError *) =
      ^(MXMessage *sendedMessage, NSError *error) {
        if (error) {
          [self didSendFailedWithMessage:sendedMessage
                          localMessageId:localMessageId
                                   error:error
                                delegate:delegate];
        } else {
          [self didSendMessage:sendedMessage
                localMessageId:localMessageId
                      delegate:delegate];
        }
      };
  SEL sel = NSSelectorFromString(
      @"sendProductCardMessageWithTitle:productUrl:pictureUrl:price:"
      @"description:completion:");
  if ([MXManager respondsToSelector:sel]) {
    // 逻辑层 MixdeskSDK.framework >= 1.0.6
    typedef MXMessage *(*MXSendProductCardIMP)(
        id, SEL, NSString *, NSString *, NSString *, NSString *, NSString *,
        void (^)(MXMessage *, NSError *));
    MXSendProductCardIMP imp =
        (MXSendProductCardIMP)[MXManager methodForSelector:sel];
    imp([MXManager class], sel, title, productUrl, pictureUrl, price, desc,
        completion);
  } else {
    // 兼容旧版 framework：旧方法参数为 nil 会崩溃，这里兜底为空串；旧版不支持 price
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [MXManager sendProductCardMessageWithPictureUrl:pictureUrl ?: @""
                                              title:title ?: @""
                                       descripation:desc ?: @""
                                         productUrl:productUrl ?: @""
                                         salesCount:0
                                         completion:completion];
#pragma clang diagnostic pop
  }
}

+ (void)sendClientInputtingWithContent:(NSString *)content {
  [MXManager sendClientInputtingWithContent:content];
}

+ (void)didSendMessage:(MXMessage *)sendedMessage
        localMessageId:(NSString *)localMessageId
              delegate:(id<MXServiceToViewInterfaceDelegate>)delegate {
  if (delegate) {
    if ([delegate respondsToSelector:@selector
                  (didSendMessageWithNewMessageId:
                                     oldMessageId:newMessageDate:replacedContent
                                                 :updateMediaPath:sendStatus
                                                 :error:)]) {
      MXChatMessageSendStatus sendStatus = MXChatMessageSendStatusSuccess;
      if (sendedMessage.sendStatus == MXMessageSendStatusFailed) {
        sendStatus = MXChatMessageSendStatusFailure;
      } else if (sendedMessage.sendStatus == MXMessageSendStatusSending) {
        sendStatus = MXChatMessageSendStatusSending;
      }
      [delegate didSendMessageWithNewMessageId:sendedMessage.messageId
                                  oldMessageId:localMessageId
                                newMessageDate:sendedMessage.createdOn
                               replacedContent:sendedMessage.isSensitive
                                                   ? sendedMessage.content
                                                   : nil
                               updateMediaPath:sendedMessage.content
                                    sendStatus:sendStatus
                                         error:nil];
    }
  }
}

+ (void)didSendFailedWithMessage:(MXMessage *)failedMessage
                  localMessageId:(NSString *)localMessageId
                           error:(NSError *)error
                        delegate:
                            (id<MXServiceToViewInterfaceDelegate>)delegate {
  NSLog(@"MixdeskSDK: 发送text消息失败\nerror = %@", error.userInfo[@"serverError"]);
  if (delegate) {
    if ([delegate respondsToSelector:@selector
                  (didSendMessageWithNewMessageId:
                                     oldMessageId:newMessageDate:replacedContent
                                                 :updateMediaPath:sendStatus
                                                 :error:)]) {

      // 这里需要针对于发送消息的错误做出提示
      if(error.code == -1011 
        && error.userInfo[@"serverError"] 
        && error.userInfo[@"serverError"] != [NSNull null]
        && [error.userInfo[@"serverError"] isKindOfClass:[NSDictionary class]]
        && [error.userInfo[@"serverError"] objectForKey:@"error"] != nil
        && [[error.userInfo[@"serverError"] objectForKey:@"error"] isKindOfClass:[NSDictionary class]]
        && [[error.userInfo[@"serverError"] objectForKey:@"error"] objectForKey:@"code"] != nil
        && [[error.userInfo[@"serverError"] objectForKey:@"error"] objectForKey:@"code"] != [NSNull null]
        && [[[error.userInfo[@"serverError"] objectForKey:@"error"] objectForKey:@"code"] intValue] == 206500105
        && [[error.userInfo[@"serverError"] objectForKey:@"error"] objectForKey:@"message"] != nil
        && [[error.userInfo[@"serverError"] objectForKey:@"error"] objectForKey:@"message"] != [NSNull null]
      ) {
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* windowScene in [UIApplication sharedApplication].connectedScenes) {
                if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                    window = windowScene.windows.firstObject;
                    break;
                }
            }
        } else {
            window = [UIApplication sharedApplication].keyWindow;
        }
          NSString *message = [[error.userInfo[@"serverError"] objectForKey:@"error"] objectForKey:@"message"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [MXToast showToast:message duration:1.0 window:window];
        });
      }

      [delegate didSendMessageWithNewMessageId:localMessageId
                                  oldMessageId:localMessageId
                                newMessageDate:nil
                               replacedContent:nil
                               updateMediaPath:nil
                                    sendStatus:MXChatMessageSendStatusFailure
                                         error:error];
    }
  }
}

+ (void)setClientOffline {
  [MXManager setClientOffline];
}

//+ (void)didTapMessageWithMessageId:(NSString *)messageId {
////    [MXManager updateMessage:messageId toReadStatus:YES];
//}

+ (NSString *)getCurrentAgentName {
  NSString *agentName = [MXManager getCurrentAgent].nickname;
  return agentName.length == 0 ? @"" : agentName;
}

+ (MXAgent *)getCurrentAgent {
  return [MXManager getCurrentAgent];
}

+ (MXChatAgentStatus)getCurrentAgentStatus {
  MXAgent *agent = [MXManager getCurrentAgent];
  if (!agent.isOnline) {
    return MXChatAgentStatusOffLine;
  }
  switch (agent.status) {
  case MXAgentStatusHide:
    return MXChatAgentStatusOffDuty;
    break;
  case MXAgentStatusOnline:
    return MXChatAgentStatusOnDuty;
    break;
  default:
    return MXChatAgentStatusOnDuty;
    break;
  }
}

+ (BOOL)isThereAgent {
  return [MXManager getCurrentAgent].agentId.length > 0;
}

+ (BOOL)haveConversation {
  return [MXManager haveConversation];
}

+ (NSString *)getCurrentConversationID {
  return [MXManager getCurrentConversationID];
}

+ (void)downloadMediaWithUrlString:(NSString *)urlString
                          progress:(void (^)(float progress))progressBlock
                        completion:(void (^)(NSData *mediaData,
                                             NSError *error))completion {
  [MXManager downloadMediaWithUrlString:urlString
      progress:^(float progress) {
        if (progressBlock) {
          progressBlock(progress);
        }
      }
      completion:^(NSData *mediaData, NSError *error) {
        if (completion) {
          completion(mediaData, error);
        }
      }];
}

+ (void)removeMessageInDatabaseWithId:(NSString *)messageId
                           completion:(void (^)(BOOL, NSError *))completion {
  [MXManager removeMessageInDatabaseWithId:messageId completion:completion];
}

+ (NSDictionary *)getCurrentClientInfo {
  return [MXManager getCurrentClientInfo];
}

+ (void)uploadClientAvatar:(UIImage *)avatarImage
                completion:
                    (void (^)(NSString *avatarUrl, NSError *error))completion {
  [MXManager setClientAvatar:avatarImage
                  completion:^(NSString *avatarUrl, NSError *error) {
                    [MXChatViewConfig sharedConfig].outgoingDefaultAvatarImage =
                        avatarImage;
                    [[NSNotificationCenter defaultCenter]
                        postNotificationName:MXChatTableViewShouldRefresh
                                      object:avatarImage];
                    if (completion) {
                      completion(avatarUrl, error);
                    }
                  }];
}

+ (void)getEnterpriseConfigInfoWithCache:(BOOL)isLoadCache
                                complete:(void (^)(MXEnterprise *,
                                                   NSError *))action {
  [MXManager getEnterpriseConfigDataWithCache:isLoadCache complete:action];
}

+ (void)getEnterpriseEvaluationConfig:(BOOL)isLoadCache
                             complete:(void (^)(MXEvaluationConfig *,
                                                NSError *))action {
  [MXManager getEnterpriseEvaluationConfig:isLoadCache complete:action];
}

/**
点击快捷按钮的回调
*/

+ (void)clickQuickBtn:(NSString *)func_id
         quick_btn_id:(NSInteger)quick_btn_id
                 func:(NSInteger)func {
   [MXManager clickQuickBtn:func_id quick_btn_id:quick_btn_id func:func];
}

+ (NSString *)getEnterpriseConfigAvatar {
  return [MXManager getEnterpriseConfigAvatar];
}

+ (NSString *)getEnterpriseConfigName {
  return [MXManager getEnterpriseConfigName];
}

+ (BOOL)allowActiveEvaluation {
  return [MXManager allowActiveEvaluation];
}

#pragma 实例方法
- (instancetype)init {
  if (self = [super init]) {
  }
  return self;
}

- (void)setClientOnlineWithCustomizedId:(NSString *)customizedId
                                success:(void (^)(BOOL completion,
                                                  NSString *agentName,
                                                  NSString *agentType,
                                                  NSArray *receivedMessages,
                                                  NSError *error))success
                 receiveMessageDelegate:(id<MXServiceToViewInterfaceDelegate>)
                                            receiveMessageDelegate {
  self.serviceToViewDelegate = receiveMessageDelegate;
  [MXManager setClientOnlineWithCustomizedId:customizedId
      success:^(MXClientOnlineResult result, MXAgent *agent,
                NSArray<MXMessage *> *messages) {
        NSArray *toMessages = [MXServiceToViewInterface
            convertToChatViewMessageWithMXMessages:messages];
        if (result == MXClientOnlineResultSuccess) {
          NSString *agentType = [agent convertPrivilegeToString];
          success(true, agent.nickname, agentType, toMessages, nil);
        } else if (result == MXClientOnlineResultNotScheduledAgent) {
          success(false, @"", @"", toMessages, nil);
        }
      }
      failure:^(NSError *error) {
        success(false, @"", @"", nil, error);
      }
      receiveMessageDelegate:self];
}

- (void)setClientOnlineWithClientId:(NSString *)clientId
                            success:(void (^)(BOOL completion,
                                              NSString *agentName,
                                              NSString *agentType,
                                              NSArray *receivedMessages,
                                              NSError *error))success
             receiveMessageDelegate:
                 (id<MXServiceToViewInterfaceDelegate>)receiveMessageDelegate {
  self.serviceToViewDelegate = receiveMessageDelegate;

  [MXManager setClientOnlineWithClientId:clientId
      success:^(MXClientOnlineResult result, MXAgent *agent,
                NSArray<MXMessage *> *messages) {
        if (result == MXClientOnlineResultSuccess) {
          NSArray *toMessages = [MXServiceToViewInterface
              convertToChatViewMessageWithMXMessages:messages];
          NSString *agentType = [agent convertPrivilegeToString];
          success(true, agent.nickname, agentType, toMessages, nil);
        } else if ((result == MXClientOnlineResultNotScheduledAgent) ||
                   (result == MXClientOnlineResultBlacklisted)) {
          success(false, @"", @"", nil, nil);
        }
      }
      failure:^(NSError *error) {
        success(false, @"初始化失败，请重新打开", @"", nil, error);
      }
      receiveMessageDelegate:self];
}

+ (void)setScheduledProblem:(NSString *)problem {
  [MXManager setScheduledProblem:problem];
}

+ (void)setEvaluationLevel:(NSInteger)level
           evaluation_type:(NSInteger)evaluation_type
                   tag_ids:(NSArray *)tag_ids
                   comment:(NSString *)comment
                  resolved:(NSInteger)resolved {
  [MXManager
      evaluateCurrentConversationWithEvaluation:level
                                evaluation_type:evaluation_type
                                        tag_ids:tag_ids
                                        comment:comment
                                       resolved:resolved
                                     completion:^(BOOL success, NSError *error){
                                     }];
}

+ (void)setClientInfoWithDictionary:(NSDictionary *)clientInfo
                         completion:(void (^)(BOOL success,
                                              NSError *error))completion {
  if (!clientInfo) {
    NSLog(@"Mixdesk SDK：上传自定义信息不能为空。");
    completion(false, nil);
  }

  if ([MXChatViewConfig sharedConfig].updateClientInfoUseOverride) {
    [MXManager updateClientInfo:clientInfo completion:completion];
  } else {
    [MXManager setClientInfo:clientInfo completion:completion];
  }
}

+ (void)updateClientInfoWithDictionary:(NSDictionary *)clientInfo
                            completion:(void (^)(BOOL success,
                                                 NSError *error))completion {
  if (!clientInfo) {
    NSLog(@"Mixdesk SDK：上传自定义信息不能为空。");
    completion(false, nil);
  }
  [MXManager updateClientInfo:clientInfo
                   completion:^(BOOL success, NSError *error) {
                     completion(success, error);
                   }];
}

+ (void)setCurrentInputtingText:(NSString *)inputtingText {
  [MXManager setCurrentInputtingText:inputtingText];
}

+ (NSString *)getPreviousInputtingText {
  return [MXManager getPreviousInputtingText];
}

+ (void)getUnreadMessagesWithCompletion:(void (^)(NSArray *messages,
                                                  NSError *error))completion {
  return [MXManager getUnreadMessagesWithCompletion:completion];
}

+ (void)getUnreadMessagesWithCustomizedId:(NSString *)customizedId
                           withCompletion:
                               (void (^)(NSArray *, NSError *))completion {
  return [MXManager getUnreadMessagesWithCustomizedId:customizedId
                                           completion:completion];
}

+ (NSArray *)getLocalUnreadMessages {
  return [MXManager getLocalUnreadeMessages];
}

+ (BOOL)isBlacklisted {
  return [MXManager isBlacklisted];
}

+ (BOOL)isAreaRestricted {
  return [MXManager isAreaRestricted];
}

+ (BOOL)isAgentToClientMsgStatus {
  return [MXManager isAgentToClientMsgStatus];
}

+ (void)clearReceivedFiles {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  BOOL isDir = YES;
  if ([fileManager fileExistsAtPath:DIR_RECEIVED_FILE isDirectory:&isDir]) {
    NSError *error;
    [fileManager removeItemAtPath:DIR_RECEIVED_FILE error:&error];
    if (error) {
      NSLog(@"Fail to clear received files: %@", error.localizedDescription);
    }
  }
}

+ (void)updateMessageWithId:(NSString *)messageId
           forAccessoryData:(NSDictionary *)accessoryData {
  [MXManager updateMessageWithId:messageId forAccessoryData:accessoryData];
}

+ (void)updateMessageIds:(NSArray *)messageIds toReadStatus:(BOOL)isRead {
  [MXManager updateMessageIds:messageIds toReadStatus:isRead];
}

+ (void)markAllMessagesAsRead {
  [MXManager markAllMessagesAsRead];
}

+ (BOOL)getEnterpriseConfigWithdrawToastStatus {
  return [MXManager getEnterpriseConfigWithdrawToastStatus];
}

+ (void)prepareForChat {
  [MXManager didStartChat];
}

+ (void)completeChat {
  [MXManager didEndChat];
}

+ (void)refreshLocalClientWithCustomizedId:(NSString *)customizedId
                                  complete:
                                      (void (^)(NSString *clientId))action {
  [MXManager refreshLocalClientWithCustomizedId:customizedId complete:action];
}

+ (void)clientDownloadFileWithMessageId:(NSString *)messageId
                          conversatioId:(NSString *)conversationId
                          andCompletion:
                              (void (^)(NSString *url, NSError *error))action {
  [MXManager clientDownloadFileWithMessageId:messageId
                               conversatioId:conversationId
                               andCompletion:action];
}

+ (void)cancelDownloadForUrl:(NSString *)urlString {
  [MXManager cancelDownloadForUrl:urlString];
}

#pragma mark - MXManagerDelegate

- (void)didReceiveMXMessages:(NSArray<MXMessage *> *)messages {
  if (!self.serviceToViewDelegate) {
    return;
  }

  if ([self.serviceToViewDelegate
          respondsToSelector:@selector(didReceiveNewMessages:)]) {
    [self.serviceToViewDelegate
        didReceiveNewMessages:
            [MXServiceToViewInterface
                convertToChatViewMessageWithMXMessages:messages]];
  }
}

- (void)didScheduleResult:(MXClientOnlineResult)onLineResult
       withResultMessages:(NSArray<MXMessage *> *)message {
  if ([self.serviceToViewDelegate respondsToSelector:@selector
                                  (didScheduleResult:withResultMessages:)]) {
    [self.serviceToViewDelegate didScheduleResult:onLineResult
                               withResultMessages:message];
  }
}

// 强制转人工
- (void)forceRedirectHumanAgentWithSuccess:
            (void (^)(BOOL completion, NSString *agentName,
                      NSArray *receivedMessages))success
                                   failure:(void (^)(NSError *error))failure
                    receiveMessageDelegate:
                        (id<MXServiceToViewInterfaceDelegate>)
                            receiveMessageDelegate {
  self.serviceToViewDelegate = receiveMessageDelegate;

  [MXManager
      forceRedirectHumanAgentWithSuccess:^(MXClientOnlineResult result,
                                           MXAgent *agent,
                                           NSArray<MXMessage *> *messages) {
        NSArray *toMessages = [MXServiceToViewInterface
            convertToChatViewMessageWithMXMessages:messages];
        if (result == MXClientOnlineResultSuccess) {
          success(true, agent.nickname, toMessages);
        } else if (result == MXClientOnlineResultNotScheduledAgent) {
          success(false, @"", toMessages);
        }
      }
      failure:^(NSError *error) {

      }
      receiveMessageDelegate:self];
}

/**
 转换 emoji 别名为 Unicode
 */
+ (NSString *)convertToUnicodeWithEmojiAlias:(NSString *)text {
  return [MXManager convertToUnicodeWithEmojiAlias:text];
}

+ (NSString *)getCurrentAgentId {
  return [MXManager getCurrentAgentId];
}

+ (NSString *)getCurrentAgentType {
  return [MXManager getCurrentAgentType];
}

+ (void)getEvaluationPromtTextComplete:(void (^)(NSString *, NSError *))action {
  [MXManager getEvaluationPromtTextComplete:action];
}

+ (void)getEvaluationPromtFeedbackComplete:(void (^)(NSString *,
                                                     NSError *))action {
  [MXManager getEvaluationPromtFeedbackComplete:action];
}

+ (void)getIsShowRedirectHumanButtonComplete:(void (^)(BOOL, NSError *))action {
  [MXManager getIsShowRedirectHumanButtonComplete:action];
}

+ (void)requestPreChatServeyDataIfNeedCompletion:
    (void (^)(MXPreChatData *data, NSError *error))block {
  NSString *clientId = [MXChatViewConfig sharedConfig].MXClientId;
  NSString *customId = [MXChatViewConfig sharedConfig].customizedId;

  [MXManager requestPreChatServeyDataIfNeedWithClientId:clientId
                                           customizedId:customId
                                             completion:block];
}

+ (void)getCaptchaComplete:(void (^)(NSString *token, UIImage *image))block {
  [MXManager getCaptchaComplete:block];
}

+ (void)getCaptchaWithURLComplete:(void (^)(NSString *token,
                                            NSString *url))block {
  [MXManager getCaptchaURLComplete:block];
}

+ (void)submitPreChatForm:(NSDictionary *)formData
               completion:(void (^)(id, NSError *))block {
  [MXManager submitPreChatForm:formData completion:block];
}

+ (NSError *)checkGlobalError {
  return [MXManager checkGlobalError];
}

+ (void)openMXGroupNotificationServiceWithDelegate:
    (id<MXGroupNotificationDelegate>)delegate {
  [MXManager openMXGroupNotificationServiceWithDelegate:delegate];
}

+ (void)insertMXGroupNotificationToConversion:
    (MXGroupNotification *)notification {
  [MXManager insertMXGroupNotificationToConversion:notification];
}

+ (BOOL)currentOpenVisitorNoMessage {
  return [MXManager currentOpenVisitorNoMessage];
}

+ (BOOL)currentHideHistoryConversation {
  return [MXManager currentHideHistoryConversation];
}

+ (void)transferConversationFromAiAgentToHumanWithConvId {
  [MXManager transferConversationFromAiAgentToHumanWithConvId];
}

@end
