//
//  MXRichTextViewModel.m
//  Mixdesk-SDK-Demo
//
//  Created by ian luo on 16/6/14.
//  Copyright © 2016年 Mixdesk. All rights reserved.
//

#import "MXRichTextViewModel.h"
#import "MXAssetUtil.h"
#import "MXRichTextMessage.h"
#import "MXRichTextViewCell.h"
#import "MXServiceToViewInterface.h"
#import "MXWebViewBubbleCell.h"
#import "MXWebViewController.h"

@interface MXRichTextViewModel ()

@property(nonatomic, strong) MXRichTextMessage *message;

@end

@implementation MXRichTextViewModel

- (id)initCellModelWithMessage:(MXRichTextMessage *)message
                     cellWidth:(CGFloat)cellWidth
                      delegate:(id<MXCellModelDelegate>)delegator {
  if (self = [super init]) {
    self.message = message;
    self.summary = self.message.summary;
    self.iconPath = self.message.thumbnail;
    self.content = self.message.content;
  }
  return self;
}

// 加载 UI 需要的数据，完成后通过 UI 绑定的 block 更新 UI
- (void)load {
  if (self.modelChanges) {
    self.modelChanges(self.message.summary, self.message.thumbnail,
                      self.message.content);
  }

  __weak typeof(self) wself = self;
  [MXServiceToViewInterface
      downloadMediaWithUrlString:self.message.userAvatarPath
                        progress:nil
                      completion:^(NSData *mediaData, NSError *error) {
                        if (mediaData) {
                          __strong typeof(wself) sself = wself;
                          sself.avartarImage =
                              [UIImage imageWithData:mediaData];
                          if (sself.avatarLoaded) {
                            sself.avatarLoaded(sself.avartarImage);
                          }
                        }
                      }];

  [MXServiceToViewInterface
      downloadMediaWithUrlString:self.message.thumbnail
                        progress:nil
                      completion:^(NSData *mediaData, NSError *error) {
                        if (mediaData) {
                          __strong typeof(wself) sself = wself;
                          sself.iconImage = [UIImage imageWithData:mediaData];
                          if (sself.iconLoaded) {
                            sself.iconLoaded(sself.iconImage);
                          }
                        }
                      }];
}

- (void)openFrom:(UINavigationController *)cv {

  MXWebViewController *webViewController;

  webViewController = [MXWebViewController new];
  webViewController.contentHTML = self.content;
  webViewController.title = @"图文消息";
  [cv pushViewController:webViewController animated:YES];
}

- (CGFloat)getCellHeight {
  if (self.cellHeight) {
    return self.cellHeight();
  }
  return 80;
}

- (MXRichTextViewCell *)getCellWithReuseIdentifier:
    (NSString *)cellReuseIdentifer {
  return [[MXRichTextViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                   reuseIdentifier:cellReuseIdentifer];
}

//- ( MXNewRichMessageCell*)getCellWithReuseIdentifier:(NSString
//*)cellReuseIdentifer {
//    return [[MXNewRichMessageCell alloc]
//    initWithStyle:UITableViewCellStyleDefault
//    reuseIdentifier:cellReuseIdentifer];
//}

//- (MXWebViewBubbleCell*)getCellWithReuseIdentifier:(NSString
//*)cellReuseIdentifer {
//    return [[MXWebViewBubbleCell alloc]
//    initWithStyle:UITableViewCellStyleDefault
//    reuseIdentifier:cellReuseIdentifer];
//}

- (NSDate *)getCellDate {
  return self.message.date;
}

- (BOOL)isServiceRelatedCell {
  return true;
}

- (NSString *)getCellMessageId {
  return self.message.messageId;
}

- (NSString *)getMessageConversionId {
  return self.message.conversionId;
}

- (void)updateCellSendStatus:(MXChatMessageSendStatus)sendStatus {
  self.message.sendStatus = sendStatus;
}

- (void)updateCellMessageId:(NSString *)messageId {
  self.message.messageId = messageId;
}

- (void)updateCellConversionId:(NSString *)conversionId {
  self.message.conversionId = conversionId;
}

- (void)updateCellMessageDate:(NSDate *)messageDate {
  self.message.date = messageDate;
}

- (void)updateCellFrameWithCellWidth:(CGFloat)cellWidth {
}
@end
