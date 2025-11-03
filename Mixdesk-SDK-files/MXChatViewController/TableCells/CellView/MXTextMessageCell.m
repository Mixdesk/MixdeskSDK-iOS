//
//  MXTextMessageCell.m
//  MixdeskSDK
//
//  Created by ijinmao on 15/10/29.
//  Copyright © 2015年 Mixdesk Inc. All rights reserved.
//

#import "MXTextMessageCell.h"
#import "MXChatFileUtil.h"
#import "MXChatViewConfig.h"
#import "MXBundleUtil.h"
#import "MXTextCellModel.h"
#import "TTTAttributedLabel.h"
#import "MXTagListView.h"
#import "MXServiceToViewInterface.h"

static const NSInteger kMXTextCellSelectedUrlActionSheetTag = 2000;
static const NSInteger kMXTextCellSelectedNumberActionSheetTag = 2001;
static const NSInteger kMXTextCellSelectedEmailActionSheetTag = 2002;
static const NSString *kMXTextCellsensitiveWords = @"！消息包含不规范用语";

@interface MXTextMessageCell() <TTTAttributedLabelDelegate, UIActionSheetDelegate, UIAlertViewDelegate>

@end

@implementation MXTextMessageCell  {
    UIImageView *avatarImageView;
    TTTAttributedLabel *textLabel;
    UILabel *sensitiveTextLabel;
    UIImageView *bubbleImageView;
    UIActivityIndicatorView *sendingIndicator;
    UIImageView *failureImageView;
    UIImageView *readStatusIndicatorView;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        //初始化头像
        avatarImageView = [[UIImageView alloc] init];
        avatarImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:avatarImageView];
        //初始化气泡
        bubbleImageView = [[UIImageView alloc] init];
        bubbleImageView.userInteractionEnabled = true;
        UILongPressGestureRecognizer *longPressBubbleGesture=[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressBubbleView:)];
        [bubbleImageView addGestureRecognizer:longPressBubbleGesture];
        [self.contentView addSubview:bubbleImageView];
        //初始化文字
        if([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0){
            textLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
            textLabel.delegate = self;
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"
            textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
#pragma clang diagnostic pop
        }
        textLabel.numberOfLines = 0;
        textLabel.textAlignment = NSTextAlignmentLeft;
        textLabel.userInteractionEnabled = true;
        textLabel.backgroundColor = [UIColor clearColor];
        [bubbleImageView addSubview:textLabel];
        //初始化indicator
        sendingIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        sendingIndicator.hidden = YES;
        [self.contentView addSubview:sendingIndicator];
        //初始化出错image
        failureImageView = [[UIImageView alloc] initWithImage:[MXChatViewConfig sharedConfig].messageSendFailureImage];
        UITapGestureRecognizer *tapFailureImageGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapFailImage:)];
        failureImageView.userInteractionEnabled = true;
        [failureImageView addGestureRecognizer:tapFailureImageGesture];
        [self.contentView addSubview:failureImageView];
        sensitiveTextLabel = [[UILabel alloc] init];
        sensitiveTextLabel.text = [NSString stringWithFormat:@"%@",kMXTextCellsensitiveWords];
        sensitiveTextLabel.textColor = [UIColor grayColor];
        sensitiveTextLabel.font = [UIFont systemFontOfSize:14];
        [sensitiveTextLabel setHidden:YES];
        [self.contentView addSubview:sensitiveTextLabel];
        
        //初始化已读状态指示器
        readStatusIndicatorView = [[UIImageView alloc] init];
        readStatusIndicatorView.contentMode = UIViewContentModeScaleAspectFit;
        readStatusIndicatorView.hidden = YES;
        [self.contentView addSubview:readStatusIndicatorView];
    }
    return self;
}

#pragma MXChatCellProtocol
- (void)updateCellWithCellModel:(id<MXCellModelProtocol>)model {
    if (![model isKindOfClass:[MXTextCellModel class]]) {
        NSAssert(NO, @"传给MXTextMessageCell的Model类型不正确");
        return ;
    }
    MXTextCellModel *cellModel = (MXTextCellModel *)model;
    
    //刷新头像
    if (cellModel.avatarImage) {
        avatarImageView.image = cellModel.avatarImage;
    }
    avatarImageView.frame = cellModel.avatarFrame;
    if ([MXChatViewConfig sharedConfig].enableRoundAvatar) {
        avatarImageView.layer.masksToBounds = YES;
        avatarImageView.layer.cornerRadius = cellModel.avatarFrame.size.width/2;
    }
    
    //刷新气泡
    bubbleImageView.image = cellModel.bubbleImage;
    bubbleImageView.frame = cellModel.bubbleImageFrame;
    
    //刷新indicator
    sendingIndicator.hidden = true;
    [sendingIndicator stopAnimating];
    if (cellModel.sendStatus == MXChatMessageSendStatusSending && cellModel.cellFromType == MXChatCellOutgoing) {
        sendingIndicator.hidden = false;
        sendingIndicator.frame = cellModel.sendingIndicatorFrame;
        [sendingIndicator startAnimating];
    }
    
    //刷新聊天文字
    textLabel.frame = cellModel.textLabelFrame;
    if ([textLabel isKindOfClass:[TTTAttributedLabel class]]) {
        textLabel.text = cellModel.cellText;
    } else {
        textLabel.attributedText = cellModel.cellText;
    }
    
    // 【修复】获取当前文本的实际长度，用于 Range 验证
    NSUInteger textLength = 0;
    if ([textLabel isKindOfClass:[TTTAttributedLabel class]]) {
        textLength = [cellModel.cellText string].length;
    } else {
        textLength = cellModel.cellText.length;
    }
    
    //获取文字中的可选中的元素，添加 Range 验证防止越界
    if (cellModel.emailNumberRangeDic.count > 0) {
        for (NSString *key in cellModel.emailNumberRangeDic.allKeys) {
            NSRange range = [cellModel.emailNumberRangeDic[key] rangeValue];
            // 【修复】验证 Range 是否在有效范围内
            if (range.location != NSNotFound && 
                range.location < textLength && 
                NSMaxRange(range) <= textLength) {
                @try {
                    [textLabel addLinkToTransitInformation:@{@"email" : key} withRange:range];
                } @catch (NSException *exception) {
                    NSLog(@"⚠️ 添加邮箱链接失败: %@, range: %@, textLength: %lu", exception, NSStringFromRange(range), (unsigned long)textLength);
                }
            } else {
                NSLog(@"⚠️ 邮箱链接 Range 越界，已跳过: key=%@, range=%@, textLength=%lu", key, NSStringFromRange(range), (unsigned long)textLength);
            }
        }
    }
    if (cellModel.numberRangeDic.count > 0) {
        for (NSString *key in cellModel.numberRangeDic.allKeys) {
            NSRange range = [cellModel.numberRangeDic[key] rangeValue];
            // 【修复】验证 Range 是否在有效范围内
            if (range.location != NSNotFound && 
                range.location < textLength && 
                NSMaxRange(range) <= textLength) {
                @try {
                    [textLabel addLinkToPhoneNumber:key withRange:range];
                } @catch (NSException *exception) {
                    NSLog(@"⚠️ 添加电话链接失败: %@, range: %@, textLength: %lu", exception, NSStringFromRange(range), (unsigned long)textLength);
                }
            } else {
                NSLog(@"⚠️ 电话链接 Range 越界，已跳过: key=%@, range=%@, textLength=%lu", key, NSStringFromRange(range), (unsigned long)textLength);
            }
        }
    }
    if (cellModel.linkNumberRangeDic.count > 0) {
        for (NSString *key in cellModel.linkNumberRangeDic.allKeys) {
            NSRange range = [cellModel.linkNumberRangeDic[key] rangeValue];
            // 【修复】验证 Range 是否在有效范围内
            if (range.location != NSNotFound && 
                range.location < textLength && 
                NSMaxRange(range) <= textLength) {
                @try {
                    [textLabel addLinkToURL:[NSURL URLWithString:key] withRange:range];
                } @catch (NSException *exception) {
                    NSLog(@"⚠️ 添加 URL 链接失败: %@, range: %@, textLength: %lu", exception, NSStringFromRange(range), (unsigned long)textLength);
                }
            } else {
                NSLog(@"⚠️ URL 链接 Range 越界，已跳过: key=%@, range=%@, textLength=%lu", key, NSStringFromRange(range), (unsigned long)textLength);
            }
        }
    }
    
    //刷新出错图片
    failureImageView.hidden = true;
    if (cellModel.sendStatus == MXChatMessageSendStatusFailure) {
        failureImageView.hidden = false;
        failureImageView.frame = cellModel.sendFailureFrame;
    }
    
    [sensitiveTextLabel setHidden:!cellModel.isSensitive];
    sensitiveTextLabel.frame = cellModel.sensitiveLableFrame;
    
    for (UIView *tempView in self.contentView.subviews) {
        if ([tempView isKindOfClass:[MXTagListView class]]) {
            [tempView removeFromSuperview];
        }
    }
    if (cellModel.cacheTagListView) {
        [self.contentView addSubview:cellModel.cacheTagListView];
        NSArray *cacheTags = [[NSArray alloc] initWithArray:cellModel.cacheTags];
        __weak __typeof(self) weakSelf = self;
        cellModel.cacheTagListView.mxTagListSelectedIndex = ^(NSInteger index) {
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            MXMessageBottomTagModel * model = cacheTags[index];
            switch (model.tagType) {
                case MXMessageBottomTagTypeCopy:
                    [[UIPasteboard generalPasteboard] setString:model.value];
                    if (strongSelf.chatCellDelegate) {
                        if ([strongSelf.chatCellDelegate respondsToSelector:@selector(showToastViewInCell:toastText:)]) {
                            [strongSelf.chatCellDelegate showToastViewInCell:strongSelf toastText:[MXBundleUtil localizedStringForKey:@"save_text_success"]];
                        }
                    }
                    break;
                case MXMessageBottomTagTypeCall:
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", model.value]]];
                    break;
                case MXMessageBottomTagTypeLink:
                    if ([model.value rangeOfString:@"://"].location == NSNotFound) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@", model.value]]];
                    } else {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:model.value]];
                    }
                    break;
                default:
                    break;
            }
        };
    }
    
    //刷新已读状态指示器
    [self updateReadStatusIndicator:cellModel];
}

#pragma TTTAttributedLabelDelegate 点击事件
- (void)attributedLabel:(TTTAttributedLabel *)label
didLongPressLinkWithPhoneNumber:(NSString *)phoneNumber
                atPoint:(CGPoint)point {
    [self showMenueController];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithPhoneNumber:(NSString *)phoneNumber {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:phoneNumber delegate:self cancelButtonTitle:[MXBundleUtil localizedStringForKey:@"alert_view_cancel"] destructiveButtonTitle:nil otherButtonTitles:[NSString stringWithFormat:@"%@%@", [MXBundleUtil localizedStringForKey:@"make_call_to"], phoneNumber], [NSString stringWithFormat:@"%@%@", [MXBundleUtil localizedStringForKey:@"send_message_to"], phoneNumber], [MXBundleUtil localizedStringForKey:@"save_text"], nil];
    sheet.tag = kMXTextCellSelectedNumberActionSheetTag;
    [sheet showInView:[UIApplication sharedApplication].keyWindow];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:[url absoluteString] delegate:self cancelButtonTitle:[MXBundleUtil localizedStringForKey:@"alert_view_cancel"] destructiveButtonTitle:nil otherButtonTitles:[MXBundleUtil localizedStringForKey:@"open_url_by_safari"], [MXBundleUtil localizedStringForKey:@"save_text"], nil];
    sheet.tag = kMXTextCellSelectedUrlActionSheetTag;
    [sheet showInView:[UIApplication sharedApplication].keyWindow];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithTransitInformation:(NSDictionary *)components {
    if (!components[@"email"]) {
        return ;
    }
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:components[@"email"] delegate:self cancelButtonTitle:[MXBundleUtil localizedStringForKey:@"alert_view_cancel"] destructiveButtonTitle:nil otherButtonTitles:[MXBundleUtil localizedStringForKey:@"make_email_to"], [MXBundleUtil localizedStringForKey:@"save_text"], nil];
    sheet.tag = kMXTextCellSelectedEmailActionSheetTag;
    [sheet showInView:[UIApplication sharedApplication].keyWindow];
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:MXChatViewKeyboardResignFirstResponderNotification object:nil];
    switch (actionSheet.tag) {
        case kMXTextCellSelectedNumberActionSheetTag: {
            switch (buttonIndex) {
                case 0:
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", actionSheet.title]]];
                    break;
                case 1:
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"sms://%@", actionSheet.title]]];
                    break;
                case 2:
                    [UIPasteboard generalPasteboard].string = actionSheet.title;
                    break;
                default:
                    break;
            }
            break;
        }
        case kMXTextCellSelectedUrlActionSheetTag: {
            switch (buttonIndex) {
                case 0: {
                    if ([actionSheet.title rangeOfString:@"://"].location == NSNotFound) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@", actionSheet.title]]];
                    } else {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:actionSheet.title]];
                    }
                    break;
                }
                case 1:
                    [UIPasteboard generalPasteboard].string = actionSheet.title;
                    break;
                default:
                    break;
            }
            break;
        }
        case kMXTextCellSelectedEmailActionSheetTag: {
            switch (buttonIndex) {
                case 0: {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"mailto://%@", actionSheet.title]]];
                    break;
                }
                case 1:
                    [UIPasteboard generalPasteboard].string = actionSheet.title;
                    break;
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
    //通知界面点击了消息
    if (self.chatCellDelegate) {
        if ([self.chatCellDelegate respondsToSelector:@selector(didSelectMessageInCell:messageContent:selectedContent:)]) {
            [self.chatCellDelegate didSelectMessageInCell:self messageContent:self.textLabel.text selectedContent:actionSheet.title];
        }
    }
}

#pragma 长按事件
- (void)longPressBubbleView:(id)sender {
    if (((UILongPressGestureRecognizer*)sender).state == UIGestureRecognizerStateBegan) {
        [self showMenueController];
    }
}

- (void)showMenueController {
    [self showMenuControllerInView:self targetRect:bubbleImageView.frame menuItemsName:@{@"textCopy" : textLabel.text}];
    
}

#pragma 点击发送失败消息 重新发送事件
- (void)tapFailImage:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"重新发送吗？" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    [alertView show];
}

#pragma UIAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self.chatCellDelegate resendMessageInCell:self resendData:@{@"text" : textLabel.text}];
    }
}

#pragma mark - 已读状态指示器
- (void)updateReadStatusIndicator:(MXTextCellModel *)cellModel {
    // 默认隐藏状态指示器
    readStatusIndicatorView.hidden = YES;
    
    // 只有发送的消息才显示状态指示器
    if (cellModel.cellFromType != MXChatCellOutgoing) {
        return;
    }
    
    // 检查是否需要显示状态指示器（需要isAgentToClientMsgStatus为YES）
    if (![MXServiceToViewInterface isAgentToClientMsgStatus]) {
        return;
    }
    
    // 根据readStatus显示对应的状态
    if (cellModel.readStatus != nil) {
        NSInteger status = [cellModel.readStatus integerValue];
        UIImage *statusImage = nil;
        
        switch (status) {
            case 2: // 已送达
                statusImage = [self createDeliveredStatusImage];
                break;
            case 3: // 已读
                statusImage = [self createReadStatusImage];
                break;
            default:
                // 其他状态不显示
                return;
        }
        
        if (statusImage) {
            readStatusIndicatorView.image = statusImage;
            readStatusIndicatorView.frame = cellModel.readStatusIndicatorFrame;
            readStatusIndicatorView.hidden = NO;
        }
    }
}

// 创建已送达状态图标（空心圆，边框#bbb）
- (UIImage *)createDeliveredStatusImage {
    CGSize size = CGSizeMake(12, 12);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // 设置边框颜色为#bbb
    UIColor *borderColor = [UIColor colorWithRed:0xbb/255.0 green:0xbb/255.0 blue:0xbb/255.0 alpha:1.0];
    CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
    CGContextSetLineWidth(context, 1.0);
    
    // 绘制空心圆
    CGRect circleRect = CGRectMake(1, 1, 10, 10);
    CGContextStrokeEllipseInRect(context, circleRect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

// 创建已读状态图标（圆形背景#bbb + 白色勾号）
- (UIImage *)createReadStatusImage {
    CGSize size = CGSizeMake(12, 12);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // 设置填充颜色为#bbb
    UIColor *fillColor = [UIColor colorWithRed:0xbb/255.0 green:0xbb/255.0 blue:0xbb/255.0 alpha:1.0];
    CGContextSetFillColorWithColor(context, fillColor.CGColor);
    
    // 绘制圆形背景（填充#bbb）
    CGRect circleRect = CGRectMake(0, 0, 12, 12);
    CGContextFillEllipseInRect(context, circleRect);
    
    // 设置勾号颜色为白色
    UIColor *checkColor = [UIColor whiteColor];
    CGContextSetStrokeColorWithColor(context, checkColor.CGColor);
    CGContextSetLineWidth(context, 1.5);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    
    // 绘制白色勾号
    CGContextMoveToPoint(context, 3, 6);
    CGContextAddLineToPoint(context, 5.5, 8.5);
    CGContextAddLineToPoint(context, 9, 4.5);
    CGContextStrokePath(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
