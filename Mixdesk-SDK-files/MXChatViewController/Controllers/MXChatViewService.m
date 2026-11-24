//
//  MXChatViewService.m
//  MixdeskSDK
//
//  Created by ijinmao on 15/10/28.
//  Copyright © 2015年 Mixdesk Inc. All rights reserved.
//

#import "MXChatViewService.h"
#import "MIXDESK_VoiceConverter.h"
#import "MXAssetUtil.h"
#import "MXBundleUtil.h"
#import "MXCardCellModel.h"
#import "MXCardMessage.h"
#import "MXCustomizedUIText.h"
#import "MXEvaluationResultCellModel.h"
#import "MXEventCellModel.h"
#import "MXFileDownloadCellModel.h"
#import "MXHybridMessage.h"
#import "MXHybridViewCellModel.h"
#import "MXImageCellModel.h"
#import "MXImageMessage.h"
#import "MXMessageDateCellModel.h"
#import "MXMessageFactoryHelper.h"
#import "MXPhotoCardCellModel.h"
#import "MXPhotoCardMessage.h"
#import "MXProductCardCellModel.h"
#import "MXProductCardMessage.h"
#import "MXRichTextViewModel.h"
#import "MXServiceToViewInterface.h"
#import "MXSplitLineCellModel.h"
#import "MXTextCellModel.h"
#import "MXTextMessage.h"
#import "MXTipsCellModel.h"
#import "MXToast.h"
#import "MXVideoCellModel.h"
#import "MXVideoMessage.h"
#import "MXVoiceCellModel.h"
#import "MXVoiceMessage.h"
#import "MXWebViewBubbleCellModel.h"
#import "MXWithDrawMessage.h"
#import "NSArray+MXFunctional.h"
#import "NSError+MXConvenient.h"
#include <Foundation/Foundation.h>
#import <MixdeskSDK/MixdeskSDK.h>
#import <UIKit/UIKit.h>
static NSInteger const kMXChatMessageMaxTimeInterval = 60;

/** 一次获取历史消息数的个数 */
static NSInteger const kMXChatGetHistoryMessageNumber = 20;

#ifdef INCLUDE_MIXDESK_SDK
@interface MXChatViewService () <MXServiceToViewInterfaceDelegate,
                                 MXCellModelDelegate>

@property(nonatomic, strong) MXServiceToViewInterface *serviceToViewInterface;

@property(nonatomic, assign) BOOL noAgentTipShowed;

@property(nonatomic, strong) NSMutableArray *cacheTextArr;

@property(nonatomic, strong) NSMutableArray *cacheImageArr;

@property(nonatomic, strong) NSMutableArray *cacheFilePathArr;

@property(nonatomic, strong) NSMutableArray *cacheVideoPathArr;

@end
#else
@interface MXChatViewService () <MXCellModelDelegate>

@end
#endif

@implementation MXChatViewService {
#ifdef INCLUDE_MIXDESK_SDK
  BOOL addedNoAgentTip; // 是否已经说明了没有客服标记
#endif
  // 当前界面上显示的 message
  //    NSMutableSet *currentViewMessageIdSet;
}

- (instancetype)initWithDelegate:(id<MXChatViewServiceDelegate>)delegate
                   errorDelegate:(id<MXServiceToViewInterfaceErrorDelegate>)
                                     errorDelegate {
  if (self = [super init]) {
    self.cellModels = [[NSMutableArray alloc] init];
    addedNoAgentTip = false;

    self.delegate = delegate;
    self.errorDelegate = errorDelegate;

    [self addObserve];
    [self updateChatTitleWithAgent:nil state:MXStateAllocatingAgent];
  }
  return self;
}

- (void)addObserve {
  __weak typeof(self) wself = self;
  [MXManager
      addStateObserverWithBlock:^(MXState oldState, MXState newState,
                                  NSDictionary *value, NSError *error) {
        __strong typeof(wself) sself = wself;
        MXAgent *agent = value[@"agent"];

        NSString *agentType = [agent convertPrivilegeToString];

        [sself updateChatTitleWithAgent:agent state:newState];

        if (![agentType isEqualToString:@"bot"] && agentType.length > 0) {
          [sself removeBotTipCellModels];
          [sself.delegate reloadChatTableView];
        }

        if (newState == MXStateOffline) {
          if ([value[@"reason"] isEqualToString:@"autoconnect fail"]) {
            [sself.delegate showToastViewWithContent:@"网络故障"];
          }
        }
      }
                        withKey:@"MXChatViewService"];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [MXManager removeStateChangeObserverWithKey:@"MXChatViewService"];
}

- (MXState)clientStatus {
  return [MXManager getCurrentState];
}

#pragma 增加cellModel并刷新tableView
- (void)addCellModelAndReloadTableViewWithModel:
    (id<MXCellModelProtocol>)cellModel {
  
  if (![self.cellModels containsObject:cellModel]) {
    [self.cellModels addObject:cellModel];
    //        [self.delegate reloadChatTableView];
    //        [self.delegate scrollTableViewToBottomAnimated:YES];
    [self.delegate insertCellAtBottomForModelCount:1];
  } else {
  }
}

/**
 * 获取更多历史聊天消息
 */
- (void)startGettingHistoryMessages {
  NSDate *firstMessageDate = [self getFirstServiceCellModelDate];
  if ([MXChatViewConfig sharedConfig]
          .enableSyncServerMessage) { // 默认开启消息同步
    [MXServiceToViewInterface
        getServerHistoryMessagesWithMsgDate:firstMessageDate
                             messagesNumber:kMXChatGetHistoryMessageNumber
                            successDelegate:self
                              errorDelegate:self.errorDelegate];
  } else {
    [MXServiceToViewInterface
        getDatabaseHistoryMessagesWithMsgDate:firstMessageDate
                               messagesNumber:kMXChatGetHistoryMessageNumber
                                     delegate:self];
  }
}

/**
 * 在开启无消息访客过滤的条件下获取历史聊天信息
 */
- (void)getMessagesWithScheduleAfterClientSendMessage {
  NSDate *firstMessageDate = [self getFirstServiceCellModelDate];
  if ([MXChatViewConfig sharedConfig]
          .enableSyncServerMessage) { // 默认开启消息同步
    [MXServiceToViewInterface
        getServerHistoryMessagesAndTicketsWithMsgDate:firstMessageDate
                                       messagesNumber:
                                           kMXChatGetHistoryMessageNumber
                                      successDelegate:self
                                        errorDelegate:self.errorDelegate];
  } else {
    [MXServiceToViewInterface
        getDatabaseHistoryMessagesWithMsgDate:firstMessageDate
                               messagesNumber:kMXChatGetHistoryMessageNumber
                                     delegate:self];
  }
}

/// 获取本地历史所有消息
- (void)startGettingDateBaseHistoryMessages {
  NSDate *firstMessageDate = [self getFirstServiceCellModelDate];
  [MXServiceToViewInterface
      getDatabaseHistoryMessagesWithMsgDate:firstMessageDate
                             messagesNumber:kMXChatGetHistoryMessageNumber
                                   delegate:self];
}

// xlp  获取历史消息 从最后一条数据
- (void)startGettingHistoryMessagesFromLastMessage {
  NSDate *lastMessageDate = [self getLastServiceCellModelDate];

  if ([MXChatViewConfig sharedConfig].enableSyncServerMessage) {
    [MXServiceToViewInterface
        getServerHistoryMessagesWithMsgDate:lastMessageDate
                             messagesNumber:kMXChatGetHistoryMessageNumber
                            successDelegate:self
                              errorDelegate:self.errorDelegate];
  } else {
    [MXServiceToViewInterface
        getDatabaseHistoryMessagesWithMsgDate:lastMessageDate
                               messagesNumber:kMXChatGetHistoryMessageNumber
                                     delegate:self];
  }
}
/**
 *  获取最旧的cell的日期，例如text/image/voice等
 */
- (NSDate *)getFirstServiceCellModelDate {
  for (NSInteger index = 0; index < self.cellModels.count; index++) {
    id<MXCellModelProtocol> cellModel = [self.cellModels objectAtIndex:index];
#pragma 开发者可在下面添加自己更多的业务cellModel 以便能正确获取历史消息
    if ([cellModel isKindOfClass:[MXTextCellModel class]] ||
        [cellModel isKindOfClass:[MXImageCellModel class]] ||
        [cellModel isKindOfClass:[MXVoiceCellModel class]] ||
        [cellModel isKindOfClass:[MXVideoCellModel class]] ||
        [cellModel isKindOfClass:[MXEventCellModel class]] ||
        [cellModel isKindOfClass:[MXFileDownloadCellModel class]] ||
        [cellModel isKindOfClass:[MXPhotoCardCellModel class]] ||
        [cellModel isKindOfClass:[MXProductCardCellModel class]] ||
        [cellModel isKindOfClass:[MXWebViewBubbleCellModel class]] ||
        [cellModel isKindOfClass:[MXEvaluationResultCellModel class]]) {
      return [cellModel getCellDate];
    }
  }
  return [NSDate date];
}

- (NSDate *)getLastServiceCellModelDate {
  for (NSInteger index = 0; index < self.cellModels.count; index++) {
    id<MXCellModelProtocol> cellModel = [self.cellModels objectAtIndex:index];

    if (index == self.cellModels.count - 1) {

#pragma 开发者可在下面添加自己更多的业务cellModel 以便能正确获取历史消息
      if ([cellModel isKindOfClass:[MXTextCellModel class]] ||
          [cellModel isKindOfClass:[MXImageCellModel class]] ||
          [cellModel isKindOfClass:[MXVoiceCellModel class]] ||
          [cellModel isKindOfClass:[MXVideoCellModel class]] ||
          [cellModel isKindOfClass:[MXEventCellModel class]] ||
          [cellModel isKindOfClass:[MXFileDownloadCellModel class]] ||
          [cellModel isKindOfClass:[MXPhotoCardCellModel class]] ||
          [cellModel isKindOfClass:[MXProductCardCellModel class]] ||
          [cellModel isKindOfClass:[MXWebViewBubbleCellModel class]] ||
          [cellModel isKindOfClass:[MXEvaluationResultCellModel class]]) {
        return [cellModel getCellDate];
      }
    }
  }
  return [NSDate date];
}

#pragma mark - 消息发送

- (void)cacheSendText:(NSString *)text {
  [self.cacheTextArr addObject:text];
}

- (void)cacheSendImage:(UIImage *)image {
  [self.cacheImageArr addObject:image];
}

- (void)cacheSendAMRFilePath:(NSString *)filePath {
  [self.cacheFilePathArr addObject:filePath];
}

- (void)cacheSendVideoFilePath:(NSString *)filePath {
  [self.cacheVideoPathArr addObject:filePath];
}

/**
 * 发送文字消息
 */
- (void)sendTextMessageWithContent:(NSString *)content {
  MXTextMessage *message = [[MXTextMessage alloc] initWithContent:content];
  message.conversionId =
      [MXServiceToViewInterface getCurrentConversationID] ?: @"";
  MXTextCellModel *cellModel =
      [[MXTextCellModel alloc] initCellModelWithMessage:message
                                              cellWidth:self.chatViewWidth
                                               delegate:self];
  [self addConversionSplitLineWithCurrentCellModel:cellModel];
  [self addMessageDateCellAtLastWithCurrentCellModel:cellModel];
  [self addCellModelAndReloadTableViewWithModel:cellModel];
  [MXServiceToViewInterface sendTextMessageWithContent:content
                                             messageId:message.messageId
                                              delegate:self];
}

/**
 * 发送图片消息
 */
- (void)sendImageMessageWithImage:(UIImage *)image {
  MXImageMessage *message = [[MXImageMessage alloc] initWithImage:image];
  message.conversionId =
      [MXServiceToViewInterface getCurrentConversationID] ?: @"";
  MXImageCellModel *cellModel =
      [[MXImageCellModel alloc] initCellModelWithMessage:message
                                               cellWidth:self.chatViewWidth
                                                delegate:self];
  [self addConversionSplitLineWithCurrentCellModel:cellModel];
  [self addMessageDateCellAtLastWithCurrentCellModel:cellModel];
  [self addCellModelAndReloadTableViewWithModel:cellModel];
#ifdef INCLUDE_MIXDESK_SDK
  [MXServiceToViewInterface sendImageMessageWithImage:image
                                            messageId:message.messageId
                                             delegate:self];
#else
  // 模仿发送成功
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
        cellModel.sendStatus = MXChatMessageSendStatusSuccess;
        [self playSendedMessageSound];
      });
#endif
}

/**
 * 以AMR格式语音文件的形式，发送语音消息
 * @param filePath AMR格式的语音文件
 */
- (void)sendVoiceMessageWithAMRFilePath:(NSString *)filePath {
  // 将AMR格式转换成WAV格式，以便使iPhone能播放
  NSData *wavData = [self convertToWAVDataWithAMRFilePath:filePath];
  MXVoiceMessage *message = [[MXVoiceMessage alloc] initWithVoiceData:wavData];
  [self sendVoiceMessageWithWAVData:wavData voiceMessage:message];
  NSData *amrData = [NSData dataWithContentsOfFile:filePath];
  [MXServiceToViewInterface sendAudioMessage:amrData
                                   messageId:message.messageId
                                    delegate:self];
}

/**
 * 以WAV格式语音数据的形式，发送语音消息
 * @param wavData WAV格式的语音数据
 */
- (void)sendVoiceMessageWithWAVData:(NSData *)wavData
                       voiceMessage:(MXVoiceMessage *)message {
  message.conversionId =
      [MXServiceToViewInterface getCurrentConversationID] ?: @"";
  MXVoiceCellModel *cellModel =
      [[MXVoiceCellModel alloc] initCellModelWithMessage:message
                                               cellWidth:self.chatViewWidth
                                                delegate:self];
  [self addConversionSplitLineWithCurrentCellModel:cellModel];
  [self addMessageDateCellAtLastWithCurrentCellModel:cellModel];
  [self addCellModelAndReloadTableViewWithModel:cellModel];
#ifndef INCLUDE_MIXDESK_SDK
  // 模仿发送成功
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
        cellModel.sendStatus = MXChatMessageSendStatusSuccess;
        [self playSendedMessageSound];
      });
#endif
}

- (void)sendVideoMessageWithFilePath:(NSString *)filePath {
  MXVideoMessage *message = [[MXVideoMessage alloc] init];
  message.videoPath = filePath;
  message.conversionId =
      [MXServiceToViewInterface getCurrentConversationID] ?: @"";
  MXVideoCellModel *cellModel =
      [[MXVideoCellModel alloc] initCellModelWithMessage:message
                                               cellWidth:self.chatViewWidth
                                                delegate:self];
  [self addConversionSplitLineWithCurrentCellModel:cellModel];
  [self addMessageDateCellAtLastWithCurrentCellModel:cellModel];
  [self addCellModelAndReloadTableViewWithModel:cellModel];
#ifdef INCLUDE_MIXDESK_SDK
  [MXServiceToViewInterface sendVideoMessageWithFilePath:filePath
                                               messageId:message.messageId
                                                delegate:self];
#else
  // 模仿发送成功
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
        cellModel.sendStatus = MXChatMessageSendStatusSuccess;
        [self playSendedMessageSound];
      });
#endif
}

/**
 * 发送商品卡片消息
 * @param productCard 商品卡片的model
 */

- (void)sendProductCardWithModel:(MXProductCardMessage *)productCard {
  MXProductCardMessage *message =
      [[MXProductCardMessage alloc] initWithTitle:productCard.title
                                       productUrl:productCard.productUrl
                                       pictureUrl:productCard.pictureUrl
                                            price:productCard.price
                                      description:productCard.desc];
  message.conversionId =
      [MXServiceToViewInterface getCurrentConversationID] ?: @"";
  MXProductCardCellModel *cellModel = [[MXProductCardCellModel alloc]
      initCellModelWithMessage:message
                     cellWidth:self.chatViewWidth
                      delegate:self];
  [self addConversionSplitLineWithCurrentCellModel:cellModel];
  [self addMessageDateCellAtLastWithCurrentCellModel:cellModel];
  [self addCellModelAndReloadTableViewWithModel:cellModel];
#ifdef INCLUDE_MIXDESK_SDK
  [MXServiceToViewInterface
      sendProductCardMessageWithTitle:message.title
                           productUrl:message.productUrl
                           pictureUrl:message.pictureUrl
                                price:message.price
                          description:message.desc
                            messageId:message.messageId
                             delegate:self];
#else
  // 模仿发送成功
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
        cellModel.sendStatus = MXChatMessageSendStatusSuccess;
        [self playSendedMessageSound];
      });
#endif
}

/**
  删除消息
 */

- (void)deleteMessageAtIndex:(NSInteger)index
                  withTipMsg:(NSString *)tipMsg
          enableLinesDisplay:(BOOL)enable {
  NSString *messageId =
      [[self.cellModels objectAtIndex:index] getCellMessageId];
  [MXServiceToViewInterface removeMessageInDatabaseWithId:messageId
                                               completion:nil];
  [self.cellModels removeObjectAtIndex:index];
  [self.delegate removeCellAtIndex:index];
  if (tipMsg && tipMsg.length > 0) {
    [self addTipCellModelWithTips:tipMsg enableLinesDisplay:enable];
  }
}

/**
 * 重新发送消息
 * @param index 需要重新发送的index
 * @param resendData 重新发送的字典 [text/image/voice : data]
 */
- (void)resendMessageAtIndex:(NSInteger)index
                  resendData:(NSDictionary *)resendData {
  // 通知逻辑层删除该message数据
#ifdef INCLUDE_MIXDESK_SDK
  NSString *messageId =
      [[self.cellModels objectAtIndex:index] getCellMessageId];
  [MXServiceToViewInterface removeMessageInDatabaseWithId:messageId
                                               completion:nil];

#endif
  [self.cellModels removeObjectAtIndex:index];
  [self.delegate removeCellAtIndex:index];
  // 判断删除这个model的之前的model是否为date，如果是，则删除时间cellModel
  if (index < 0 || self.cellModels.count <= index - 1) {
    return;
  }

  id<MXCellModelProtocol> cellModel = [self.cellModels objectAtIndex:index - 1];
  if (cellModel && [cellModel isKindOfClass:[MXMessageDateCellModel class]]) {
    [self.cellModels removeObjectAtIndex:index - 1];
    [self.delegate removeCellAtIndex:index - 1];
    index--;
  }

  if (self.cellModels.count > index) {
    id<MXCellModelProtocol> cellModel = [self.cellModels objectAtIndex:index];
    if (cellModel && [cellModel isKindOfClass:[MXTipsCellModel class]]) {
      [self.cellModels removeObjectAtIndex:index];
      [self.delegate removeCellAtIndex:index];
    }
  }

  // 重新发送
  if (resendData[@"text"]) {
    [self sendTextMessageWithContent:resendData[@"text"]];
  }
  if (resendData[@"image"]) {
    [self sendImageMessageWithImage:resendData[@"image"]];
  }
  if (resendData[@"voice"]) {
    [self sendVoiceMessageWithAMRFilePath:resendData[@"voice"]];
  }
  if (resendData[@"video"]) {
    [self sendVideoMessageWithFilePath:resendData[@"video"]];
  }
  if (resendData[@"productCard"]) {
    [self sendProductCardWithModel:resendData[@"productCard"]];
  }
}

/**
 * 发送“用户正在输入”的消息
 */
- (void)sendUserInputtingWithContent:(NSString *)content {
  [MXServiceToViewInterface sendClientInputtingWithContent:content];
}

/**
 *  在尾部增加cellModel之前，先判断两个时间间隔是否过大，如果过大，插入一个MessageDateCellModel
 *
 *  @param beAddedCellModel 准备被add的cellModel
 *  @return 是否插入了时间cell
 */
- (BOOL)addMessageDateCellAtLastWithCurrentCellModel:
    (id<MXCellModelProtocol>)beAddedCellModel {
  id<MXCellModelProtocol> lastCellModel =
      [self searchOneBussinessCellModelWithIndex:self.cellModels.count - 1
                         isSearchFromBottomToTop:true];
  NSDate *lastDate =
      lastCellModel ? [lastCellModel getCellDate] : [NSDate date];
  NSDate *beAddedDate = [beAddedCellModel getCellDate];
  // 判断被add的cell的时间比最后一个cell的时间是否要大（说明currentCell是第一个业务cell，此时显示时间cell）
  BOOL isLastDateLargerThanNextDate =
      lastDate.timeIntervalSince1970 > beAddedDate.timeIntervalSince1970;
  // 判断被add的cell比最后一个cell的时间间隔是否超过阈值
  BOOL isDateTimeIntervalLargerThanThreshold =
      beAddedDate.timeIntervalSince1970 - lastDate.timeIntervalSince1970 >=
      kMXChatMessageMaxTimeInterval;
  if (!isLastDateLargerThanNextDate && !isDateTimeIntervalLargerThanThreshold) {
    return false;
  }
  MXMessageDateCellModel *cellModel =
      [[MXMessageDateCellModel alloc] initCellModelWithDate:beAddedDate
                                                  cellWidth:self.chatViewWidth];
  if ([cellModel getCellMessageId].length > 0) {
    [self.cellModels addObject:cellModel];
    [self.delegate insertCellAtBottomForModelCount:1];
  }
  return true;
}

/**
 *  在首部增加cellModel之前，先判断两个时间间隔是否过大，如果过大，插入一个MessageDateCellModel
 *
 *  @param beInsertedCellModel 准备被insert的cellModel
 *  @return 是否插入了时间cell
 */
- (BOOL)insertMessageDateCellAtFirstWithCellModel:
    (id<MXCellModelProtocol>)beInsertedCellModel {
  NSDate *firstDate = [NSDate date];
  if (self.cellModels.count == 0) {
    return false;
  }
  id<MXCellModelProtocol> firstCellModel = [self.cellModels objectAtIndex:0];
  if (![firstCellModel isServiceRelatedCell]) {
    return false;
  }
  NSDate *beInsertedDate = [beInsertedCellModel getCellDate];
  firstDate = [firstCellModel getCellDate];
  // 判断被insert的Cell的date和第一个cell的date的时间间隔是否超过阈值
  BOOL isDateTimeIntervalLargerThanThreshold =
      firstDate.timeIntervalSince1970 - beInsertedDate.timeIntervalSince1970 >=
      kMXChatMessageMaxTimeInterval;
  if (!isDateTimeIntervalLargerThanThreshold) {
    return false;
  }
  MXMessageDateCellModel *cellModel =
      [[MXMessageDateCellModel alloc] initCellModelWithDate:firstDate
                                                  cellWidth:self.chatViewWidth];
  [self.cellModels insertObject:cellModel atIndex:0];
  [self.delegate insertCellAtTopForModelCount:1];
  return true;
}

/**
 *  在尾部增加cellModel之前，先判断两个message
 * 是否是不同会话的，插入一个MXSplitLineCellModel
 *
 *  @param beAddedCellModel 准备被add的cellModel
 *  @return 是否插入
 */
- (BOOL)addConversionSplitLineWithCurrentCellModel:
    (id<MXCellModelProtocol>)beAddedCellModel {
  if (![MXServiceToViewInterface haveConversation] &&
      beAddedCellModel.getMessageConversionId.length == 0) {
    if (_cellModels.count == 0) {
      return false;
    }
    id<MXCellModelProtocol> lastCellModel;
    bool haveSplit = false;
    for (id<MXCellModelProtocol> cellModel in
         [_cellModels reverseObjectEnumerator]) {
      if ([cellModel isKindOfClass:[MXSplitLineCellModel class]]) {
        haveSplit = true;
      }
      if ([cellModel getMessageConversionId].length > 0) {
        lastCellModel = cellModel;
        break;
      }
    }

    if (lastCellModel && !haveSplit) {
      MXSplitLineCellModel *cellModel = [[MXSplitLineCellModel alloc]
          initCellModelWithCellWidth:self.chatViewWidth
                  withConversionDate:[beAddedCellModel getCellDate]];
      [self.cellModels addObject:cellModel];
      [self.delegate insertCellAtBottomForModelCount:1];
      return true;
    }
    return false;
  }

  MXSplitLineCellModel *cellModel =
      [self insertConversionSplitLineWithCellModel:beAddedCellModel
                                    withCellModels:_cellModels];
  if (cellModel) {
    [self.cellModels addObject:cellModel];
    [self.delegate insertCellAtBottomForModelCount:1];
    return true;
  }
  return false;
}

/**
 *  判断是否需要加入不同回话的分割线
 *
 *  @param beInsertedCellModel 准备被insert的cellModel
 */
- (MXSplitLineCellModel *)insertConversionSplitLineWithCellModel:
                              (id<MXCellModelProtocol>)beInsertedCellModel
                                                  withCellModels:
                                                      (NSArray *)cellModelArr {
  if (cellModelArr.count == 0) {
    return nil;
  }
  id<MXCellModelProtocol> lastCellModel;
  for (id<MXCellModelProtocol> cellModel in
       [cellModelArr reverseObjectEnumerator]) {
    if ([cellModel getMessageConversionId].length > 0) {
      lastCellModel = cellModel;
      break;
    }
  }
  if (!lastCellModel) {
    return nil;
  }

  if ([beInsertedCellModel getMessageConversionId].length > 0 &&
      ![lastCellModel.getMessageConversionId
          isEqualToString:beInsertedCellModel.getMessageConversionId]) {
    MXSplitLineCellModel *cellModel1 = [[MXSplitLineCellModel alloc]
        initCellModelWithCellWidth:self.chatViewWidth
                withConversionDate:[beInsertedCellModel getCellDate]];
    return cellModel1;
  }
  return nil;
}

/**
 * 从后往前从cellModels中获取到业务相关的cellModel，即text, image, voice等；
 */
/**
 *  从cellModels中搜索第一个业务相关的cellModel，即text, image, voice等；
 *  @warning 业务相关的cellModel，必须满足协议方法isServiceRelatedCell
 *
 *  @param searchIndex             search的起始位置
 *  @param isSearchFromBottomToTop search的方向 YES：从后往前搜索
 * NO：从前往后搜索
 *
 *  @return 搜索到的第一个业务相关的cellModel
 */
- (id<MXCellModelProtocol>)
    searchOneBussinessCellModelWithIndex:(NSInteger)searchIndex
                 isSearchFromBottomToTop:(BOOL)isSearchFromBottomToTop {
  if (self.cellModels.count <= searchIndex) {
    return nil;
  }
  id<MXCellModelProtocol> cellModel =
      [self.cellModels objectAtIndex:searchIndex];
  // 判断获取到的cellModel是否是业务相关的cell，如果不是则继续往前取
  if ([cellModel isServiceRelatedCell]) {
    return cellModel;
  }
  NSInteger nextSearchIndex =
      isSearchFromBottomToTop ? searchIndex - 1 : searchIndex + 1;
  [self searchOneBussinessCellModelWithIndex:nextSearchIndex
                     isSearchFromBottomToTop:isSearchFromBottomToTop];
  return nil;
}

/**
 * 通知viewController更新tableView；
 */
- (void)reloadChatTableView {
  if (self.delegate) {
    if ([self.delegate respondsToSelector:@selector(reloadChatTableView)]) {
      [self.delegate reloadChatTableView];
    }
  }
}

- (void)scrollToBottom {
  if (self.delegate) {
    if ([self.delegate
            respondsToSelector:@selector(scrollTableViewToBottomAnimated:)]) {
      [self.delegate scrollTableViewToBottomAnimated:NO];
    }
  }
}

#ifndef INCLUDE_MIXDESK_SDK
/**
 * 使用MXChatViewControllerDemo的时候，调试用的方法，用于收取和上一个message一样的消息
 */
- (void)loadLastMessage {
  id<MXCellModelProtocol> lastCellModel =
      [self searchOneBussinessCellModelWithIndex:self.cellModels.count - 1
                         isSearchFromBottomToTop:true];
  if (lastCellModel) {
    if ([lastCellModel isKindOfClass:[MXTextCellModel class]]) {
      MXTextCellModel *textCellModel = (MXTextCellModel *)lastCellModel;
      MXTextMessage *message = [[MXTextMessage alloc]
          initWithContent:[textCellModel.cellText string]];
      message.fromType = MXChatMessageIncoming;
      MXTextCellModel *newCellModel =
          [[MXTextCellModel alloc] initCellModelWithMessage:message
                                                  cellWidth:self.chatViewWidth
                                                   delegate:self];
      [self.cellModels addObject:newCellModel];
      [self.delegate insertCellAtBottomForModelCount:1];

    } else if ([lastCellModel isKindOfClass:[MXImageCellModel class]]) {
      MXImageCellModel *imageCellModel = (MXImageCellModel *)lastCellModel;
      MXImageMessage *message =
          [[MXImageMessage alloc] initWithImage:imageCellModel.image];
      message.fromType = MXChatMessageIncoming;
      MXImageCellModel *newCellModel =
          [[MXImageCellModel alloc] initCellModelWithMessage:message
                                                   cellWidth:self.chatViewWidth
                                                    delegate:self];
      [self.cellModels addObject:newCellModel];
      [self.delegate insertCellAtBottomForModelCount:1];
    } else if ([lastCellModel isKindOfClass:[MXVoiceCellModel class]]) {
      MXVoiceCellModel *voiceCellModel = (MXVoiceCellModel *)lastCellModel;
      MXVoiceMessage *message =
          [[MXVoiceMessage alloc] initWithVoiceData:voiceCellModel.voiceData];
      message.fromType = MXChatMessageIncoming;
      MXVoiceCellModel *newCellModel =
          [[MXVoiceCellModel alloc] initCellModelWithMessage:message
                                                   cellWidth:self.chatViewWidth
                                                    delegate:self];
      [self.cellModels addObject:newCellModel];
      [self.delegate insertCellAtBottomForModelCount:1];
    }
  }
  // text message
  MXTextMessage *textMessage =
      [[MXTextMessage alloc] initWithContent:@"Let's Rooooooooooock~"];
  textMessage.fromType = MXChatMessageIncoming;
  MXTextCellModel *textCellModel =
      [[MXTextCellModel alloc] initCellModelWithMessage:textMessage
                                              cellWidth:self.chatViewWidth
                                               delegate:self];
  [self.cellModels addObject:textCellModel];
  [self.delegate insertCellAtBottomForModelCount:1];
  // image message
  MXImageMessage *imageMessage = [[MXImageMessage alloc]
      initWithImagePath:@"https://s3.cn-north-1.amazonaws.com.cn/"
                        @"pics.mixdesk.bucket/65135e4c4fde7b5f"];
  imageMessage.fromType = MXChatMessageIncoming;
  MXImageCellModel *imageCellModel =
      [[MXImageCellModel alloc] initCellModelWithMessage:imageMessage
                                               cellWidth:self.chatViewWidth
                                                delegate:self];
  [self.cellModels addObject:imageCellModel];
  [self.delegate insertCellAtBottomForModelCount:1];
  // tip message
  //        MXTipsCellModel *tipCellModel = [[MXTipsCellModel alloc]
  //        initCellModelWithTips:@"主人，您的客服离线啦~"
  //        cellWidth:self.cellWidth enableLinesDisplay:true]; [self.cellModels
  //        addObject:tipCellModel];
  // voice message
  MXVoiceMessage *voiceMessage = [[MXVoiceMessage alloc]
      initWithVoicePath:@"http://7xiy8i.com1.z0.glb.clouddn.com/test.amr"];
  voiceMessage.fromType = MXChatMessageIncoming;
  MXVoiceCellModel *voiceCellModel =
      [[MXVoiceCellModel alloc] initCellModelWithMessage:voiceMessage
                                               cellWidth:self.chatViewWidth
                                                delegate:self];
  [self.cellModels addObject:voiceCellModel];
  [self.delegate insertCellAtBottomForModelCount:1];
  [self playReceivedMessageSound];
}

#endif

#pragma MXCellModelDelegate

- (void)didTapHighMenuWithText:(NSString *)menuText {
  if (menuText && menuText.length > 0) {
    [self sendTextMessageWithContent:menuText];
  }
}

- (void)didUpdateCellDataWithMessageId:(NSString *)messageId {
  // 获取又更新的cell的index
  NSInteger index = [self getIndexOfCellWithMessageId:messageId];
  if (index < 0 || index > self.cellModels.count - 1) {
    return;
  }
  [self updateCellWithIndex:index needToBottom:NO];
}

- (NSInteger)getIndexOfCellWithMessageId:(NSString *)messageId {
  for (NSInteger index = 0; index < self.cellModels.count; index++) {
    id<MXCellModelProtocol> cellModel = [self.cellModels objectAtIndex:index];
    if ([[cellModel getCellMessageId] isEqualToString:messageId]) {
      // 更新该cell
      return index;
    }
  }
  return -1;
}

// 通知tableView更新该indexPath的cell
- (void)updateCellWithIndex:(NSInteger)index needToBottom:(BOOL)toBottom {
  NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
  if (self.delegate) {
    if ([self.delegate respondsToSelector:@selector
                       (didUpdateCellModelWithIndexPath:needToBottom:)]) {
      [self.delegate didUpdateCellModelWithIndexPath:indexPath
                                        needToBottom:toBottom];
    }
  }
}

#pragma AMR to WAV转换
- (NSData *)convertToWAVDataWithAMRFilePath:(NSString *)amrFilePath {
  NSString *tempPath = [NSSearchPathForDirectoriesInDomains(
      NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  tempPath = [tempPath stringByAppendingPathComponent:@"record.wav"];
  [MIXDESK_VoiceConverter amrToWav:amrFilePath wavSavePath:tempPath];
  NSData *wavData = [NSData dataWithContentsOfFile:tempPath];
  [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
  return wavData;
}

#pragma 更新cellModel中的frame
- (void)updateCellModelsFrame {
  for (id<MXCellModelProtocol> cellModel in self.cellModels) {
    [cellModel updateCellFrameWithCellWidth:self.chatViewWidth];
  }
}

#pragma 欢迎语
- (void)sendLocalWelcomeChatMessage {
  if (![MXChatViewConfig sharedConfig].enableChatWelcome) {
    return;
  }
  // 消息时间
  MXMessageDateCellModel *dateCellModel =
      [[MXMessageDateCellModel alloc] initCellModelWithDate:[NSDate date]
                                                  cellWidth:self.chatViewWidth];
  [self.cellModels addObject:dateCellModel];
  [self.delegate insertCellAtBottomForModelCount:1];
  // 欢迎消息
  MXTextMessage *welcomeMessage = [[MXTextMessage alloc]
      initWithContent:[MXChatViewConfig sharedConfig].chatWelcomeText];
  welcomeMessage.fromType = MXChatMessageIncoming;
  welcomeMessage.userName = [MXChatViewConfig sharedConfig].agentName;
  welcomeMessage.userAvatarImage =
      [MXChatViewConfig sharedConfig].incomingDefaultAvatarImage;
  welcomeMessage.sendStatus = MXChatMessageSendStatusSuccess;
  MXTextCellModel *cellModel =
      [[MXTextCellModel alloc] initCellModelWithMessage:welcomeMessage
                                              cellWidth:self.chatViewWidth
                                               delegate:self];
  [self.cellModels addObject:cellModel];
  [self.delegate insertCellAtBottomForModelCount:1];
}

#pragma 点击了某个cell
- (void)didTapMessageCellAtIndex:(NSInteger)index {
  id<MXCellModelProtocol> cellModel = [self.cellModels objectAtIndex:index];
  if ([cellModel isKindOfClass:[MXVoiceCellModel class]]) {
    MXVoiceCellModel *voiceCellModel = (MXVoiceCellModel *)cellModel;
    [voiceCellModel setVoiceHasPlayed];
    //        #ifdef INCLUDE_MIXDESK_SDK
    //        [MXServiceToViewInterface didTapMessageWithMessageId:[cellModel
    //        getCellMessageId]];
    // #endif
  }
}

#pragma 讯前表单选择的问题
- (void)selectedFormProblem:(NSString *)content {
  if (content && content.length > 0) {
    [MXServiceToViewInterface setScheduledProblem:content];
  }
}

#pragma 播放声音
- (void)playReceivedMessageSound {
  if (![MXChatViewConfig sharedConfig].enableMessageSound ||
      [MXChatViewConfig sharedConfig].incomingMsgSoundFileName.length == 0) {
    return;
  }
  [MXChatFileUtil
      playSoundWithSoundFile:
          [MXAssetUtil resourceWithName:[MXChatViewConfig sharedConfig]
                                            .incomingMsgSoundFileName]];
}

- (void)playSendedMessageSound {
  if (![MXChatViewConfig sharedConfig].enableMessageSound ||
      [MXChatViewConfig sharedConfig].outgoingMsgSoundFileName.length == 0) {
    return;
  }
  [MXChatFileUtil
      playSoundWithSoundFile:
          [MXAssetUtil resourceWithName:[MXChatViewConfig sharedConfig]
                                            .outgoingMsgSoundFileName]];
}

#pragma mark - create model
- (id<MXCellModelProtocol>)createCellModelWith:(MXBaseMessage *)message {
  id<MXCellModelProtocol> cellModel = nil;
  if (![message isKindOfClass:[MXEventMessage class]]) {
    if ([message isKindOfClass:[MXTextMessage class]]) {
      cellModel = [[MXTextCellModel alloc]
          initCellModelWithMessage:(MXTextMessage *)message
                         cellWidth:self.chatViewWidth
                          delegate:self];
    } else if ([message isKindOfClass:[MXImageMessage class]]) {
      cellModel = [[MXImageCellModel alloc]
          initCellModelWithMessage:(MXImageMessage *)message
                         cellWidth:self.chatViewWidth
                          delegate:self];
    } else if ([message isKindOfClass:[MXVoiceMessage class]]) {
      cellModel = [[MXVoiceCellModel alloc]
          initCellModelWithMessage:(MXVoiceMessage *)message
                         cellWidth:self.chatViewWidth
                          delegate:self];
    } else if ([message isKindOfClass:[MXVideoMessage class]]) {
      cellModel = [[MXVideoCellModel alloc]
          initCellModelWithMessage:(MXVideoMessage *)message
                         cellWidth:self.chatViewWidth
                          delegate:self];
    } else if ([message isKindOfClass:[MXFileDownloadMessage class]]) {
      cellModel = [[MXFileDownloadCellModel alloc]
          initCellModelWithMessage:(MXFileDownloadMessage *)message
                         cellWidth:self.chatViewWidth
                          delegate:self];
    } else if ([message isKindOfClass:[MXRichTextMessage class]]) {
      cellModel = [[MXWebViewBubbleCellModel alloc]
          initCellModelWithMessage:(MXRichTextMessage *)message
                         cellWidth:self.chatViewWidth
                          delegate:self];

    } else if ([message isKindOfClass:[MXCardMessage class]]) {
      cellModel = [[MXCardCellModel alloc]
          initCellModelWithMessage:(MXCardMessage *)message
                         cellWidth:self.chatViewWidth
                          delegate:self];
    } else if ([message isKindOfClass:[MXWithDrawMessage class]]) {
      // 消息撤回
      MXWithDrawMessage *withDrawMessage = (MXWithDrawMessage *)message;
      cellModel =
          [[MXTipsCellModel alloc] initCellModelWithTips:withDrawMessage.content
                                               cellWidth:self.chatViewWidth
                                      enableLinesDisplay:NO];
    } else if ([message isKindOfClass:[MXPhotoCardMessage class]]) {
      cellModel = [[MXPhotoCardCellModel alloc]
          initCellModelWithMessage:(MXPhotoCardMessage *)message
                         cellWidth:self.chatViewWidth
                          delegate:self];
    } else if ([message isKindOfClass:[MXProductCardMessage class]]) {
      cellModel = [[MXProductCardCellModel alloc]
          initCellModelWithMessage:(MXProductCardMessage *)message
                         cellWidth:self.chatViewWidth
                          delegate:self];
    } else if ([message isKindOfClass:[MXHybridMessage class]]) {
      cellModel = [[MXWebViewBubbleCellModel alloc]
          initCellModelWithMessage:(MXHybridMessage *)message
                         cellWidth:self.chatViewWidth
                          delegate:self];
    }
  }
  return cellModel;
}

#pragma mark - 消息保存到cellmodel中
/**
 *  将消息数组中的消息转换成cellModel，并添加到cellModels中去;
 *
 *  @param newMessages             消息实体array
 *  @param isInsertAtFirstIndex 是否将messages插入到顶部
 *
 *  @return 返回转换为cell的个数
 */
- (NSInteger)saveToCellModelsWithMessages:(NSArray *)newMessages
                     isInsertAtFirstIndex:(BOOL)isInsertAtFirstIndex {

  NSMutableArray *newCellModels = [NSMutableArray new];

  dispatch_async(
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [MXServiceToViewInterface
            updateMessageIds:[newMessages valueForKey:@"messageId"]
                toReadStatus:YES];
      });

  // 1. 如果相同 messaeg Id 的 cell model 存在，则替换，否则追加
  for (MXBaseMessage *message in newMessages) {

    // 如果开启了隐藏历史对话 且 消息所属会话与当前会话不相同，则不添加
    if ([MXServiceToViewInterface currentHideHistoryConversation] &&
        ![message.conversionId isEqualToString:[MXServiceToViewInterface
                                                   getCurrentConversationID]]) {
      continue;
    }

    id<MXCellModelProtocol> newCellModel = [self createCellModelWith:message];

    if (!newCellModel) { // EventMessage 不会生成 cell model
      continue;
    }

    //        // 如果富文本为空，不显示
    //        if ([newCellModel isKindOfClass:[MXWebViewBubbleCellModel class]])
    //        {
    //            MXRichTextMessage *richMessage = (MXRichTextMessage *)message;
    //            if ([richMessage.content isEqual:[NSNull null]] ||
    //            richMessage.content.length == 0) {
    //                NSLog(@"--- 空的富文本");
    //                continue;
    //            }
    //        }

    NSArray *redundentCellModels =
        [self.cellModels filter:^BOOL(id<MXCellModelProtocol> cellModel) {
          return [[cellModel getCellMessageId]
              isEqualToString:[newCellModel getCellMessageId]];
        }];

    if ([redundentCellModels count] > 0) {
      [self.cellModels
          replaceObjectAtIndex:[self.cellModels
                                   indexOfObject:[redundentCellModels
                                                     firstObject]]
                    withObject:newCellModel];
    } else {
      MXSplitLineCellModel *splitLineCellModel =
          [self insertConversionSplitLineWithCellModel:newCellModel
                                        withCellModels:newCellModels];
      if (splitLineCellModel) {
        [newCellModels addObject:splitLineCellModel];
      }
      [newCellModels addObject:newCellModel];
    }
  }

  // 2. 计算新的 cell model 在列表中的位置
  NSMutableSet *positionVector = [NSMutableSet
      new]; // 计算位置的辅助容器，如果所有消息都为 0，放在底部，都为
            // 1，放在顶部，两者都有，则需要重新排序。
  NSDate *firstMessageDate = [self.cellModels.firstObject getCellDate];
  NSDate *lastMessageDate = [self.cellModels.lastObject getCellDate];
  [newCellModels
      enumerateObjectsUsingBlock:^(id<MXCellModelProtocol> newCellModel,
                                   NSUInteger idx, BOOL *stop) {
        if (![newCellModel isKindOfClass:[MXSplitLineCellModel class]]) {
          if ([firstMessageDate compare:[newCellModel getCellDate]] ==
              NSOrderedDescending) {
            [positionVector addObject:@"1"];
          } else if ([lastMessageDate compare:[newCellModel getCellDate]] ==
                     NSOrderedAscending) {
            [positionVector addObject:@"0"];
          }
        }
      }];

  if (positionVector.count > 1) {
    positionVector = [[NSMutableSet alloc] initWithObjects:@"2", nil];
  }

  __block NSUInteger position = 0; // 0: bottom, 1: top, 2: random

  [positionVector
      enumerateObjectsUsingBlock:^(id _Nonnull obj, BOOL *_Nonnull stop) {
        position = [obj intValue];
      }];

  if (newCellModels.count == 0) {
    return 0;
  }
  // 判断是否需要添加分割线
  if (position == 1) {
    id<MXCellModelProtocol> currentFirstCellModel;
    for (id<MXCellModelProtocol> cellModel in self.cellModels) {
      if ([cellModel getMessageConversionId].length > 0) {
        currentFirstCellModel = cellModel;
        break;
      }
    }
    if (!currentFirstCellModel) {
      MXSplitLineCellModel *splitLineCellModel =
          [self insertConversionSplitLineWithCellModel:currentFirstCellModel
                                        withCellModels:newCellModels];
      if (splitLineCellModel) {
        [newCellModels addObject:splitLineCellModel];
      }
    }
  } else if (position == 0) {
    MXSplitLineCellModel *splitLineCellModel =
        [self insertConversionSplitLineWithCellModel:[newCellModels firstObject]
                                      withCellModels:self.cellModels];
    if (splitLineCellModel) {
      [newCellModels insertObject:splitLineCellModel atIndex:0];
    }
  }
  NSUInteger newMessageCount = newCellModels.count;
  switch (position) {
  case 1: // top
    [self insertMessageDateCellAtFirstWithCellModel:
              [newCellModels firstObject]]; // 如果需要，顶部插入时间
    self.cellModels = [[newCellModels
        arrayByAddingObjectsFromArray:self.cellModels] mutableCopy];
    break;
  case 0: // bottom
    [self addMessageDateCellAtLastWithCurrentCellModel:
              [newCellModels firstObject]]; // 如果需要，底部插入时间
    [self.cellModels addObjectsFromArray:newCellModels];
    break;
  default:
    [self.cellModels
        addObjectsFromArray:
            newCellModels]; // 退出后会被重新排序，这种情况只可能出现在聊天过程中
                            // socket
                            // 断开后，轮询后台消息，会比自己发的消息早，但是应该放到前面。
    break;
  }

  return newMessageCount;
}

/**
 *  发送用户评价
 */
- (void)sendEvaluationLevel:(NSInteger)level
            evaluation_type:(NSInteger)evaluation_type
                    tag_ids:(NSArray *)tag_ids
                    comment:(NSString *)comment
                   resolved:(NSInteger)resolved {
  // 生成评价结果的 cell
  [self showEvaluationCellWithLevel:level
                    evaluation_type:evaluation_type
                            tag_ids:tag_ids
                            comment:comment
                           resolved:resolved];
#ifdef INCLUDE_MIXDESK_SDK
  [MXServiceToViewInterface setEvaluationLevel:level
                               evaluation_type:evaluation_type
                                       tag_ids:tag_ids
                                       comment:comment
                                      resolved:resolved];
#endif
}

// 显示用户评价的 cell
- (void)showEvaluationCellWithLevel:(NSInteger)level
                    evaluation_type:(NSInteger)evaluation_type
                            tag_ids:(NSArray *)tag_ids
                            comment:(NSString *)comment
                           resolved:(NSInteger)resolved {
  MXEvaluationResultCellModel *cellModel = [[MXEvaluationResultCellModel alloc]
      initCellModelWithEvaluation:level
                  evaluation_type:evaluation_type
                          tag_ids:tag_ids
                          comment:comment
                         resolved:resolved
                        cellWidth:self.chatViewWidth
                 evaluationLevels:self.evaluationLevels];
  [self.cellModels addObject:cellModel];
  [self.delegate insertCellAtBottomForModelCount:1];
  if (self.delegate) {
    if ([self.delegate
            respondsToSelector:@selector(scrollTableViewToBottomAnimated:)]) {
      [self.delegate scrollTableViewToBottomAnimated:YES];
    }
  }
}

- (void)addTipCellModelWithTips:(NSString *)tips
             enableLinesDisplay:(BOOL)enableLinesDisplay {
  MXTipsCellModel *cellModel =
      [[MXTipsCellModel alloc] initCellModelWithTips:tips
                                           cellWidth:self.chatViewWidth
                                  enableLinesDisplay:enableLinesDisplay];
  [self.cellModels addObject:cellModel];
  [self.delegate insertCellAtBottomForModelCount:1];

  if (self.delegate) {
    if ([self.delegate
            respondsToSelector:@selector(scrollTableViewToBottomAnimated:)]) {
      [self.delegate scrollTableViewToBottomAnimated:YES];
    }
  }
}

// 增加转人工提示的 cell model
- (void)addTipCellModelWithType:(MXTipType)tipType tipText:(NSString *)tipText {
  // 判断 table 中是否出现「转人工」，如果出现过，并不在最后一个
  // cell，则将之移到底部
  MXTipsCellModel *tipModel = nil;
  if (tipType == MXTipTypeBotRedirect ||
      tipType == MXTipTypeBotManualRedirect) {
    for (id<MXCellModelProtocol> model in self.cellModels) {
      if ([model isKindOfClass:[MXTipsCellModel class]]) {
        MXTipsCellModel *cellModel = (MXTipsCellModel *)model;
        if (cellModel.tipType == tipType) {
          tipModel = cellModel;
          break;
        }
      }
    }
  }
  if (tipModel) {
    // 将目标 model 移到最底部
    [self.cellModels removeObject:tipModel];
    [self.cellModels addObject:tipModel];
    [self.delegate reloadChatTableView];
  } else {
    MXTipsCellModel *cellModel =
        [[MXTipsCellModel alloc] initBotTipCellModelWithTips:tipText
                                                   cellWidth:self.chatViewWidth
                                                     tipType:tipType];
    [self.cellModels addObject:cellModel];
    [self.delegate insertCellAtBottomForModelCount:1];
  }
  [self scrollToBottom];
}

// 清除当前界面的「转人工」的 tipCell
- (void)removeBotTipCellModels {
  NSMutableArray *newCellModels = [NSMutableArray new];
  for (id<MXCellModelProtocol> model in self.cellModels) {
    if ([model isKindOfClass:[MXTipsCellModel class]]) {
      MXTipsCellModel *cellModel = (MXTipsCellModel *)model;
      if (cellModel.tipType == MXTipTypeBotRedirect ||
          cellModel.tipType == MXTipTypeBotManualRedirect) {
        continue;
      }
    }
    [newCellModels addObject:model];
  }
  self.cellModels = newCellModels;
}
#ifdef INCLUDE_MIXDESK_SDK

#pragma mark - 联系人上线的逻辑
// 上线
- (void)setClientOnline {
  if (self.clientStatus == MXStateAllocatingAgent) {
    return;
  }
  if ([MXChatViewConfig sharedConfig].MXClientId.length == 0 &&
      [MXChatViewConfig sharedConfig].customizedId.length > 0) {
    [self onlineWithCustomizedId];
  } else {
    [self onlineWithClientId];
  }
}

// 连接客服上线
- (void)onlineWithClientId {
  __weak typeof(self) weakSelf = self;
  NSDate *msgDate = [NSDate date];

  [self.serviceToViewInterface
      setClientOnlineWithClientId:[MXChatViewConfig sharedConfig].MXClientId
                          success:^(BOOL completion, NSString *agentName,
                                    NSString *agentType,
                                    NSArray *receivedMessages, NSError *error) {
                            __strong typeof(weakSelf) strongSelf = weakSelf;
                            if ([error reason].length == 0) {
                              if (receivedMessages.count <= 0) {
                                [MXManager
                                    getDatabaseHistoryMessagesWithMsgDate:
                                        msgDate
                                                           messagesNumber:0
                                                                   result:^(
                                                                       NSArray<
                                                                           MXMessage
                                                                               *>
                                                                           *messagesArray) {
                                                                     NSArray *toMessages =
                                                                         [strongSelf
                                                                             convertToChatViewMessageWithMXMessages:
                                                                                 messagesArray];
                                                                     [strongSelf
                                                                         handleClientOnlineWithRreceivedMessages:
                                                                             toMessages
                                                                                                  completeStatus:
                                                                                                      completion];
                                                                   }];
                              } else {
                                [strongSelf
                                    handleClientOnlineWithRreceivedMessages:
                                        receivedMessages
                                                             completeStatus:
                                                                 completion];
                              }
                            } else {
                              [MXToast
                                  showToast:[error shortDescription]
                                   duration:2.0
                                     window:[[UIApplication sharedApplication]
                                                    .windows lastObject]];
                            }
                          }
           receiveMessageDelegate:self];
}

#pragma mark - message转为UI类型
- (NSArray *)convertToChatViewMessageWithMXMessages:(NSArray *)messagesArray {
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
    MXBaseMessage *toMessage = [[MXMessageFactoryHelper
        factoryWithMessageAction:fromMessage.action
                     contentType:fromMessage.contentType
                        fromType:fromMessage.fromType]
        createMessage:fromMessage];
    if (toMessage) {
      // 开启了隐藏历史会话 且 该消息不是是当前会话的消息 则不添加
      if ([MXServiceToViewInterface currentHideHistoryConversation] &&
          ![toMessage.conversionId
              isEqualToString:[MXServiceToViewInterface
                                  getCurrentConversationID]]) {
        continue;
      }
      [toMessages addObject:toMessage];
    }
  }

  return toMessages;
}

- (void)onlineWithCustomizedId {
  __weak typeof(self) weakSelf = self;
  NSDate *msgDate = [NSDate date];

  [self.serviceToViewInterface
      setClientOnlineWithCustomizedId:[MXChatViewConfig sharedConfig]
                                          .customizedId
                              success:^(BOOL completion, NSString *agentName,
                                        NSString *agentType,
                                        NSArray *receivedMessages,
                                        NSError *error) {
                                __strong typeof(weakSelf) strongSelf = weakSelf;
                                if ([error reason].length == 0) {
                                  if (receivedMessages.count <= 0) {
                                    [MXManager
                                        getDatabaseHistoryMessagesWithMsgDate:
                                            msgDate
                                                               messagesNumber:0
                                                                       result:^(
                                                                           NSArray<
                                                                               MXMessage
                                                                                   *>
                                                                               *messagesArray) {
                                                                         NSArray *toMessages =
                                                                             [strongSelf
                                                                                 convertToChatViewMessageWithMXMessages:
                                                                                     messagesArray];
                                                                         [strongSelf
                                                                             handleClientOnlineWithRreceivedMessages:
                                                                                 toMessages
                                                                                                      completeStatus:
                                                                                                          completion];
                                                                       }];
                                  } else {
                                    [strongSelf
                                        handleClientOnlineWithRreceivedMessages:
                                            receivedMessages
                                                                 completeStatus:
                                                                     completion];
                                  }
                                } else {
                                  [MXToast
                                      showToast:[error shortDescription]
                                       duration:2.5
                                         window:[[UIApplication
                                                     sharedApplication]
                                                        .windows lastObject]];
                                }
                              }
               receiveMessageDelegate:self];
}

- (void)handleClientOnlineWithRreceivedMessages:(NSArray *)receivedMessages
                                 completeStatus:(BOOL)completion {
  if (receivedMessages) {
    NSInteger newCellCount = [self saveToCellModelsWithMessages:receivedMessages
                                           isInsertAtFirstIndex:NO];
    [UIView setAnimationsEnabled:NO];
    [self.delegate insertCellAtTopForModelCount:newCellCount];
    [self scrollToBottom];
    [UIView setAnimationsEnabled:YES];
    // 判断是否有需要移除的营销机器人引导按钮
    [self checkNeedRemoveBotGuideMessageWithForceReload:YES];

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{
          [self scrollToBottom]; // some image may lead the table didn't reach
                                 // bottom
        });
  }

  [self afterClientOnline];
}

- (void)afterClientOnline {
  __weak typeof(self) wself = self;
  // 上传联系人信息
  [self setCurrentClientInfoWithCompletion:^(BOOL success) {
    // 获取联系人信息
    __strong typeof(wself) sself = wself;
    [sself getClientInfo];
  }];

  [self sendPreSendMessages];
}
/**
 * @param forceReload 是否需要强制刷新UI
 */
- (void)checkNeedRemoveBotGuideMessageWithForceReload:(BOOL)forceReload {
  if (forceReload) {
    [self reloadChatTableView];
  }
}

#define kSaveTextDraftIfNeeded @"kSaveTextDraftIfNeeded"
- (void)saveTextDraftIfNeeded:(UITextField *)tf {
  if (tf.text.length) {
    [[NSUserDefaults standardUserDefaults] setObject:tf.text
                                              forKey:kSaveTextDraftIfNeeded];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }
}

- (void)fillTextDraftToFiledIfExists:(UITextField *)tf {
  NSString *string = [[NSUserDefaults standardUserDefaults]
      objectForKey:kSaveTextDraftIfNeeded];
  if (string.length) {
    tf.text = string;
    [[NSUserDefaults standardUserDefaults]
        removeObjectForKey:kSaveTextDraftIfNeeded];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }
}

- (void)sendPreSendMessages {
  //    if ([MXServiceToViewInterface getCurrentAgentStatus] ==
  //    MXChatAgentStatusOnDuty) {
  for (id messageContent in [MXChatViewConfig sharedConfig].preSendMessages) {
    if ([messageContent isKindOfClass:NSString.class]) {
      [self sendTextMessageWithContent:messageContent];
    } else if ([messageContent isKindOfClass:UIImage.class]) {
      [self sendImageMessageWithImage:messageContent];
    } else if ([messageContent isKindOfClass:MXProductCardMessage.class]) {
      [self sendProductCardWithModel:messageContent];
    }
  }

  [MXChatViewConfig sharedConfig].preSendMessages = nil;
  //    }
}

// 获取联系人信息
- (void)getClientInfo {
  NSDictionary *localClientInfo = [MXChatViewConfig sharedConfig].clientInfo;
  NSDictionary *remoteClientInfo =
      [MXServiceToViewInterface getCurrentClientInfo];
  NSString *avatarPath = [localClientInfo objectForKey:@"avatar"];
  if ([avatarPath length] == 0) {
    avatarPath = remoteClientInfo[@"avatar"];
    if (avatarPath.length == 0) {
      return;
    }
  }

  [MXServiceToViewInterface
      downloadMediaWithUrlString:avatarPath
                        progress:nil
                      completion:^(NSData *mediaData, NSError *error) {
                        if (mediaData) {
                          [MXChatViewConfig sharedConfig]
                              .outgoingDefaultAvatarImage =
                              [UIImage imageWithData:mediaData];
                          [self refreshOutgoingAvatarWithImage:
                                    [MXChatViewConfig sharedConfig]
                                        .outgoingDefaultAvatarImage];
                        }
                      }];
}

// 上传联系人信息
- (void)setCurrentClientInfoWithCompletion:(void (^)(BOOL success))completion {
  // 1. 如果用户自定义了头像，上传
  // 2. 上传用户的其他自定义信息
  [self setClientAvartarIfNeededComplete:^{
    if ([MXChatViewConfig sharedConfig].clientInfo) {
      [MXServiceToViewInterface
          setClientInfoWithDictionary:[MXChatViewConfig sharedConfig].clientInfo
                           completion:^(BOOL success, NSError *error) {
                             completion(success);
                           }];
    } else {
      completion(true);
    }
  }];
}

- (void)setClientAvartarIfNeededComplete:(void (^)(void))completion {
  if ([MXChatViewConfig sharedConfig].shouldUploadOutgoingAvartar) {
    [MXServiceToViewInterface
        uploadClientAvatar:[MXChatViewConfig sharedConfig]
                               .outgoingDefaultAvatarImage
                completion:^(NSString *avatarUrl, NSError *error) {
                  NSMutableDictionary *userInfo =
                      [[MXChatViewConfig sharedConfig].clientInfo mutableCopy];
                  if (!userInfo) {
                    userInfo = [NSMutableDictionary new];
                  }
                  [userInfo setObject:avatarUrl forKey:@"avatar"];
                  [MXChatViewConfig sharedConfig].shouldUploadOutgoingAvartar =
                      NO;
                  completion();
                }];
  } else {
    completion();
  }
}

- (void)updateChatTitleWithAgent:(MXAgent *)agent state:(MXState)state {
  MXChatAgentStatus agentStatus = [self getAgentStatus:agent];
  NSString *viewTitle = @"";
  if (self.delegate) {
    if ([self.delegate respondsToSelector:@selector
                       (didScheduleClientWithViewTitle:agentStatus:)]) {
      switch (state) {
      case MXStateAllocatingAgent:
        viewTitle = [MXBundleUtil localizedStringForKey:@"wait_agent"];
        agentStatus = MXChatAgentStatusNone;
        break;
      case MXStateUnallocatedAgent:
      case MXStateBlacklisted:
      case MXStateOffline:
        viewTitle =
            @""; // [MXBundleUtil localizedStringForKey:@"no_agent_title"];
        agentStatus = MXChatAgentStatusNone;
        break;
      case MXStateAllocatedAgent:
        viewTitle = agent.nickname;
        break;
      case MXStateInitialized:
      case MXStateUninitialized:
        viewTitle = [MXBundleUtil localizedStringForKey:@"wait_agent"];
        agentStatus = MXChatAgentStatusNone;
        break;
      }

      if(agent.privilege == MXAgentPrivilegeAiAgent){
        agentStatus = MXChatAgentStatusOnDuty;
      }

      [self.delegate didScheduleClientWithViewTitle:viewTitle
                                        agentStatus:agentStatus];
    }

    if ([self.delegate respondsToSelector:@selector
                       (changeNavReightBtnWithAgentType:hidden:)]) {
      NSString *agentType = @"";
      switch (agent.privilege) {
      case MXAgentPrivilegeAdmin:
        agentType = @"admin";
        break;
      case MXAgentPrivilegeAgent:
        agentType = @"agent";
        break;
      case MXAgentPrivilegeAiAgent:
        agentType = @"aiAgent";
        break;
      case MXAgentPrivilegeNone:
        agentType = @"";
        break;
      default:
        break;
      }

      [self.delegate
          changeNavReightBtnWithAgentType:agentType
                                   hidden:(state != MXStateAllocatedAgent)];
    }
  }
}

- (MXChatAgentStatus)getAgentStatus:(MXAgent *)agent {
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

- (BOOL)haveSendMessage {
  // 获取当前会话ID
  NSString *currentConversationID =
      [MXServiceToViewInterface getCurrentConversationID];

  // 如果当前没有会话ID，直接返回NO
  if (!currentConversationID || currentConversationID.length == 0) {
    return NO;
  }

  // 从后向前遍历消息列表
  for (id<MXCellModelProtocol> cellModel in
       [self.cellModels reverseObjectEnumerator]) {
    // 获取消息的会话ID
    NSString *messageCoversionId = [cellModel getMessageConversionId];

    // 验证会话ID一致性
    if (!(messageCoversionId && messageCoversionId.length > 0 &&
          [messageCoversionId isEqualToString:currentConversationID])) {
      continue; // ID不匹配，跳过此消息
    }

    // 检查消息类型
    BOOL isValidCellType =
        [cellModel isKindOfClass:[MXTextCellModel class]] ||
        [cellModel isKindOfClass:[MXVoiceCellModel class]] ||
        [cellModel isKindOfClass:[MXVideoCellModel class]] ||
        [cellModel isKindOfClass:[MXImageCellModel class]] ||
        [cellModel isKindOfClass:[MXProductCardCellModel class]];

    if (isValidCellType) {
      // 检查消息方向是否为发送（而非接收）
      BOOL isOutgoingMessage =
          (MXChatCellFromType)
              [cellModel performSelector:@selector(cellFromType)] ==
          MXChatCellOutgoing;

      if (isOutgoingMessage) {
        return YES; // 找到了符合条件的消息
      }
    }
  }

  // 没有找到符合条件的消息
  return NO;
}

#pragma mark - MXServiceToViewInterfaceDelegate

// 进入页面从服务器或者数据库获取历史消息
- (void)didReceiveHistoryMessages:(NSArray *)messages {
  if (self.delegate) {
    if ([self.delegate respondsToSelector:@selector
                       (didGetHistoryMessagesWithCommitTableAdjustment:)]) {
      __weak typeof(self) wself = self;
      [self.delegate didGetHistoryMessagesWithCommitTableAdjustment:^{
        __strong typeof(wself) sself = wself;
        if (messages.count > 0) {
          [sself saveToCellModelsWithMessages:messages
                         isInsertAtFirstIndex:true];
          // 判断是否有需要移除的营销机器人引导按钮
          [sself checkNeedRemoveBotGuideMessageWithForceReload:YES];
        }
      }];
    }
  }
}

// 分配客服成功
- (void)didScheduleResult:(MXClientOnlineResult)onLineResult
       withResultMessages:(NSArray<MXMessage *> *)message {

  // 让UI显示历史消息成功了再发送
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
        if (self.cacheTextArr.count > 0) {
          for (NSString *text in self.cacheTextArr) {
            [self sendTextMessageWithContent:text];
          }
          [self.cacheTextArr removeAllObjects];
        }

        if (self.cacheImageArr.count > 0) {
          for (UIImage *image in self.cacheImageArr) {
            [self sendImageMessageWithImage:image];
          }
          [self.cacheImageArr removeAllObjects];
        }

        if (self.cacheFilePathArr.count > 0) {
          for (NSString *path in self.cacheFilePathArr) {
            [self sendVoiceMessageWithAMRFilePath:path];
          }
          [self.cacheFilePathArr removeAllObjects];
        }

        if (self.cacheVideoPathArr.count > 0) {
          for (NSString *path in self.cacheVideoPathArr) {
            [self sendVideoMessageWithFilePath:path];
          }
          [self.cacheVideoPathArr removeAllObjects];
        }
      });
}

#pragma mark - handle message
- (void)handleEventMessage:(MXEventMessage *)eventMessage {
  // 撤回消息
  if (eventMessage.eventType == MXChatEventTypeWithdrawMsg) {
    [self.cellModels enumerateObjectsUsingBlock:^(
                         id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
      id<MXCellModelProtocol> cellModel = obj;
      NSString *cellMessageId = [cellModel getCellMessageId];
      if (cellMessageId &&
          cellMessageId.integerValue == eventMessage.messageId.integerValue) {
        [MXManager updateMessageWithDrawWithId:cellMessageId
                                withIsWithDraw:YES];
        [self.cellModels removeObjectAtIndex:idx];
        [self.delegate removeCellAtIndex:idx];

        if ([MXServiceToViewInterface getEnterpriseConfigWithdrawToastStatus]) {
          MXTipsCellModel *cellModel = [[MXTipsCellModel alloc]
              initCellModelWithTips:@"客服撤回了一条消息"
                          cellWidth:self.chatViewWidth
                 enableLinesDisplay:NO];
          [self.cellModels insertObject:cellModel atIndex:idx];
          [self.delegate insertCellAtCurrentIndex:idx modelCount:1];
        }
      }
    }];

    [self.delegate reloadChatTableView];
  }
  NSString *tipString = eventMessage.tipString;
  if (tipString.length > 0) {
    if ([self respondsToSelector:@selector(didReceiveTipsContent:)]) {
      [self didReceiveTipsContent:tipString showLines:NO];
    }
  }

  // 客服邀请评价、客服主动结束会话
  if (eventMessage.eventType == MXChatEventTypeInviteEvaluation) {
    if (self.delegate) {
      if ([self.delegate
              respondsToSelector:@selector(showEvaluationAlertView)] &&
          [self.delegate respondsToSelector:@selector(isChatRecording)]) {
        if (![self.delegate isChatRecording]) {
          [self.delegate showEvaluationAlertView];
        }
      }
    }
  }

  // 客服已读消息
  if (eventMessage.eventType == MXChatEventTypeAgentToClientMsgRead) {
    // 使用更安全的消息状态更新机制，避免重新加载整个数据源
    [self updateMessageStatusForEventMessage:eventMessage readStatus:@(3)];
  }

  // 客服收到消息
  if (eventMessage.eventType == MXChatEventTypeAgentToClientMsgDelivered) {
    [self updateMessageStatusForEventMessage:eventMessage readStatus:@(2)];
  }
}

- (void)handleVisualMessages:(NSArray *)messages {
  NSInteger newCellCount = [self saveToCellModelsWithMessages:messages
                                         isInsertAtFirstIndex:false];
  [self playReceivedMessageSound];
  BOOL needsResort = NO;

  // find earliest message
  MXBaseMessage *earliest = [messages
      reduce:[messages firstObject]
        step:^id(MXBaseMessage *current, MXBaseMessage *element) {
          return [[earliest date] compare:[element date]] == NSOrderedDescending
                     ? element
                     : current;
        }];

  if ([[earliest date] compare:[[self.cellModels lastObject] getCellDate]] ==
      NSOrderedAscending) {
    needsResort = YES;
  }

  if (needsResort) {
    [self.cellModels sortUsingComparator:^NSComparisonResult(
                         id<MXCellModelProtocol> _Nonnull obj1,
                         id<MXCellModelProtocol> _Nonnull obj2) {
      return [[obj1 getCellDate] compare:[obj2 getCellDate]];
    }];
  }
  [self.delegate insertCellAtBottomForModelCount:newCellCount];
}

- (void)onceLoadHistoryAndRefreshWithSendMsg:(NSString *)message {
  //    [self afterClientOnline];
  [self sendTextMessageWithContent:message];
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
        NSDate *msgDate = [NSDate date];
        [MXManager
            getDatabaseHistoryMessagesWithMsgDate:msgDate
                                   messagesNumber:0
                                           result:^(NSArray<MXMessage *>
                                                        *messagesArray) {
                                             
                                             if (self.cellModels) {
                                               [self.cellModels
                                                       removeAllObjects];
                                             }
                                             NSArray *receivedMessages = [self
                                                 convertToChatViewMessageWithMXMessages:
                                                     messagesArray];
                                             if (receivedMessages) {
                                               [self
                                                   saveToCellModelsWithMessages:
                                                       receivedMessages
                                                           isInsertAtFirstIndex:
                                                               NO];
                                               // 判断是否有需要移除的营销机器人引导按钮
                                               [self
                                                   checkNeedRemoveBotGuideMessageWithForceReload:
                                                       YES];

                                               //                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                               //                (int64_t)(0.5 *
                                               //                NSEC_PER_SEC)),
                                               //                dispatch_get_main_queue(),
                                               //                ^{
                                               //                    [self
                                               //                    scrollToBottom];
                                               //                });
                                             }
                                           }];
      });
}

-(void)onceLoadHistoryMessages {
  NSDate *msgDate = [NSDate date];
  [MXManager
      getDatabaseHistoryMessagesWithMsgDate:msgDate
                             messagesNumber:0
                                   result:^(NSArray<MXMessage *> *messagesArray) {
                                    if (self.cellModels) {
                                               [self.cellModels
                                                       removeAllObjects];
                                             }
                                     NSArray *receivedMessages = [self
                                                 convertToChatViewMessageWithMXMessages:
                                                     messagesArray];
                                             if (receivedMessages) {
                                               [self
                                                   saveToCellModelsWithMessages:
                                                       receivedMessages
                                                           isInsertAtFirstIndex:
                                                               NO];
                                             }
                                   }];
}

// 按照id 更新消息的已读和已送达状态
// 目前只能通过更新单个消息的readStatus 来更新, 直接使用 reloadData 有问题
- (void)updateMessageStatusForEventMessage:(MXEventMessage *)eventMessage readStatus:(NSNumber *)readStatus {
  dispatch_async(dispatch_get_main_queue(), ^{    
    for (NSInteger i = 0; i < self.cellModels.count; i++) {
      id<MXCellModelProtocol> cellModel = [self.cellModels objectAtIndex:i];
      NSString *messageId = [cellModel getCellMessageId];
      NSNumber *messagerReadStatus = [cellModel getMessageReadStatus] ?: @2;
      
      // 根据消息ID或其他条件匹配需要更新的消息
      if (messageId && [self shouldUpdateMessageStatus:messageId forEvent:eventMessage] && messagerReadStatus.integerValue < readStatus) {
        // 更新单个cell的状态
          if ([cellModel respondsToSelector:@selector(updateCellSendStatus:)]) {
            [cellModel updateCellReadStatus:readStatus];

            dispatch_after(
              dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
              dispatch_get_main_queue(), ^{
                [self updateCellWithIndex:i needToBottom:NO];
              }
            );
          }
      }
    }
  });
}

// 判断是否需要更新消息状态
- (BOOL)shouldUpdateMessageStatus:(NSString *)messageId forEvent:(MXEventMessage *)eventMessage {
  if (eventMessage.extraInfo && eventMessage.extraInfo[@"msgIds"]) {
    if ([eventMessage.extraInfo[@"msgIds"] isKindOfClass:[NSArray class]]) {
      // 直接将 msgIds 转换为 字符串数组
      NSArray *msgIds = [eventMessage.extraInfo[@"msgIds"] map:^id(id obj) {
        return [NSString stringWithFormat:@"%@", obj];
      }];
      
      // 将messageId 转换为 字符串
      NSString *messageIdString = [NSString stringWithFormat:@"%@", messageId];

      if ([msgIds containsObject:messageIdString]) {
        return YES;
      }
    }
  }
  return NO; 
}

#pragma mark - viewInface delegate

- (void)didReceiveNewMessages:(NSArray *)messages {
  if (messages.count == 1 &&
      [[messages firstObject]
          isKindOfClass:[MXEventMessage class]]) { // Event message
    MXEventMessage *eventMessage = (MXEventMessage *)[messages firstObject];
    if (eventMessage.eventType == MXChatEventTypeRedirectFail) {
      // 转人工失败
    } else {
      [self handleEventMessage:eventMessage];
    }
  } else {
    [self handleVisualMessages:messages];
  }
  // 通知界面收到了消息
  BOOL isRefreshView = true;
  if (![MXChatViewConfig sharedConfig].enableEventDispaly &&
      [[messages firstObject] isKindOfClass:[MXEventMessage class]]) {
    isRefreshView = false;
  } else {
    if (messages.count == 1 &&
        [[messages firstObject] isKindOfClass:[MXEventMessage class]]) {
      MXEventMessage *eventMessage = [messages firstObject];
      if (eventMessage.eventType == MXChatEventTypeAgentInputting) {
        isRefreshView = false;
      }
    }
  }

  if ([messages count] == 1 &&
      [[messages firstObject] isKindOfClass:[MXEventMessage class]]) {
    // 渲染手动转人工
    if (((MXEventMessage *)[messages firstObject]).eventType ==
        MXChatEventTypeInitConversation) {
    }
  }

  // 等待 0.1 秒，等待 tableView 更新后再滑动到底部，优化体验
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
        if (self.delegate && isRefreshView) {
          if ([self.delegate respondsToSelector:@selector(didReceiveMessage)]) {
            [self.delegate didReceiveMessage];
          }
        }
      });
}


- (void)didReceiveTipsContent:(NSString *)tipsContent {
  [self didReceiveTipsContent:tipsContent showLines:YES];
}

- (void)didReceiveTipsContent:(NSString *)tipsContent showLines:(BOOL)show {
  MXTipsCellModel *cellModel =
      [[MXTipsCellModel alloc] initCellModelWithTips:tipsContent
                                           cellWidth:self.chatViewWidth
                                  enableLinesDisplay:show];
  [self addCellModelAfterReceivedWithCellModel:cellModel];
}

- (void)addCellModelAfterReceivedWithCellModel:
    (id<MXCellModelProtocol>)cellModel {
  [self addMessageDateCellAtLastWithCurrentCellModel:cellModel];
  [self didReceiveMessageWithCellModel:cellModel];
}

- (void)didReceiveMessageWithCellModel:(id<MXCellModelProtocol>)cellModel {
  [self addCellModelAndReloadTableViewWithModel:cellModel];
  [self playReceivedMessageSound];
  if (self.delegate) {
    if ([self.delegate respondsToSelector:@selector(didReceiveMessage)]) {
      [self.delegate didReceiveMessage];
    }
  }
}

- (void)didRedirectWithAgentName:(NSString *)agentName {
  //[self updateChatTitleWithAgent:[MXServiceToViewInterface getCurrentAgent]];
}

- (void)didSendMessageWithNewMessageId:(NSString *)newMessageId
                          oldMessageId:(NSString *)oldMessageId
                        newMessageDate:(NSDate *)newMessageDate
                       replacedContent:(NSString *)replacedContent
                       updateMediaPath:(NSString *)mediaPath
                            sendStatus:(MXChatMessageSendStatus)sendStatus
                                 error:(NSError *)error {
  [self playSendedMessageSound];

  NSInteger index = [self getIndexOfCellWithMessageId:oldMessageId];
  if (index < 0) {
    return;
  }
  id<MXCellModelProtocol> cellModel = [self.cellModels objectAtIndex:index];
  if ([cellModel respondsToSelector:@selector(updateCellMessageId:)]) {
    [cellModel updateCellMessageId:newMessageId];
  }
  if ([cellModel respondsToSelector:@selector(updateCellSendStatus:)]) {
    [cellModel updateCellSendStatus:sendStatus];
  }

  BOOL needSplitLine = NO;
  if (cellModel.getMessageConversionId.length < 1) {
    if ([cellModel respondsToSelector:@selector(updateCellConversionId:)]) {
      [cellModel updateCellConversionId:[MXServiceToViewInterface
                                            getCurrentConversationID]];
    }
  } else {
    if (![cellModel.getMessageConversionId
            isEqualToString:[MXServiceToViewInterface
                                getCurrentConversationID]]) {
      needSplitLine = YES;
      if ([cellModel respondsToSelector:@selector(updateCellConversionId:)]) {
        [cellModel updateCellConversionId:[MXServiceToViewInterface
                                              getCurrentConversationID]];
      }
    }
  }
  if (newMessageDate) {
    if ([cellModel respondsToSelector:@selector(updateCellMessageDate:)]) {
      [cellModel updateCellMessageDate:newMessageDate];
    }
  }
  if (replacedContent) {
    if ([cellModel respondsToSelector:@selector(updateSensitiveState:
                                                            cellText:)]) {
      [cellModel updateSensitiveState:YES cellText:replacedContent];
    }
  }

  if (mediaPath) {
    if ([cellModel respondsToSelector:@selector(updateMediaServerPath:)]) {
      [cellModel updateMediaServerPath:mediaPath];
    }
  }

  // 消息发送完成，刷新单行cell
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
        if (needSplitLine) {
          MXSplitLineCellModel *cellModel1 = [[MXSplitLineCellModel alloc]
              initCellModelWithCellWidth:self.chatViewWidth
                      withConversionDate:newMessageDate];
          [self.cellModels replaceObjectAtIndex:index withObject:cellModel1];
          [self.cellModels addObject:cellModel];
          [self reloadChatTableView];
          [self scrollToBottom];
        } else {
          [self updateCellWithIndex:index needToBottom:YES];
        }
      });

  // 将 messageId 保存到 set，用于去重
  //    if (![currentViewMessageIdSet containsObject:newMessageId]) {
  //        [currentViewMessageIdSet addObject:newMessageId];
  //    }
  if (error && error.userInfo.count > 0 &&
      [error.userInfo valueForKey:@"NSLocalizedDescription"] &&
      [[error.userInfo valueForKey:@"NSLocalizedDescription"]
          isEqualToString:@"file upper limit!!"]) {
    [MXToast showToast:[MXBundleUtil localizedStringForKey:@"file_upload_limit"]
              duration:2
                window:[UIApplication sharedApplication].keyWindow];
  }
}

#endif

/**
 *  刷新所有的本机用户的头像
 */
- (void)refreshOutgoingAvatarWithImage:(UIImage *)avatarImage {
  NSMutableArray *indexsToReload = [NSMutableArray new];
  for (NSInteger index = 0; index < self.cellModels.count; index++) {
    id<MXCellModelProtocol> cellModel = [self.cellModels objectAtIndex:index];
    if ([cellModel respondsToSelector:@selector(updateOutgoingAvatarImage:)]) {
      [cellModel updateOutgoingAvatarImage:avatarImage];
      [indexsToReload addObject:[NSIndexPath indexPathForRow:index
                                                   inSection:0]];
    }
  }
}

- (void)dismissingChatViewController {
  [MXServiceToViewInterface setClientOffline];
}

- (NSString *)getPreviousInputtingText {
#ifdef INCLUDE_MIXDESK_SDK
  return [MXServiceToViewInterface getPreviousInputtingText];
#else
  return @"";
#endif
}

- (void)setCurrentInputtingText:(NSString *)inputtingText {
  [MXServiceToViewInterface setCurrentInputtingText:inputtingText];
}

/**
 生成本地的消息，不发送网络请求
 */
- (void)createLocalTextMessageWithText:(NSString *)text {
  // text message
  MXAgent *agent = [MXServiceToViewInterface getCurrentAgent];
  MXTextMessage *textMessage = [[MXTextMessage alloc] initWithContent:text];
  textMessage.fromType = MXChatMessageIncoming;
  if (agent) {
    textMessage.userName = agent.nickname;
    textMessage.userAvatarPath = agent.avatarPath;
  }

  [self didReceiveNewMessages:@[ textMessage ]];
}

/**
 强制转人工
 */
- (void)forceRedirectToHumanAgent {
  NSString *currentAgentId = [MXServiceToViewInterface getCurrentAgentId];
  [self setClientOnline];
  [self removeBotTipCellModels];
  [self reloadChatTableView];
}

/*
 * automation aiAgent 转人工
 */

#pragma mark - lazyload
#ifdef INCLUDE_MIXDESK_SDK
- (MXServiceToViewInterface *)serviceToViewInterface {
  if (!_serviceToViewInterface) {
    _serviceToViewInterface = [MXServiceToViewInterface new];
  }
  return _serviceToViewInterface;
}

#endif

- (NSMutableArray *)cacheTextArr {
  if (!_cacheTextArr) {
    _cacheTextArr = [NSMutableArray new];
  }
  return _cacheTextArr;
}

- (NSMutableArray *)cacheImageArr {
  if (!_cacheImageArr) {
    _cacheImageArr = [NSMutableArray new];
  }
  return _cacheImageArr;
}

- (NSMutableArray *)cacheFilePathArr {
  if (!_cacheFilePathArr) {
    _cacheFilePathArr = [NSMutableArray new];
  }
  return _cacheFilePathArr;
}

- (NSMutableArray *)cacheVideoPathArr {
  if (!_cacheVideoPathArr) {
    _cacheVideoPathArr = [NSMutableArray new];
  }
  return _cacheVideoPathArr;
}

@end
