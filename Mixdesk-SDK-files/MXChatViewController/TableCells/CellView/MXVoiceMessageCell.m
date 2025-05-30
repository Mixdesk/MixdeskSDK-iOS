//
//  MXVoiceMessageCell.m
//  MixdeskSDK
//
//  Created by ijinmao on 15/10/29.
//  Copyright © 2015年 Mixdesk Inc. All rights reserved.
//

#import "MXVoiceMessageCell.h"
#import "MXChatFileUtil.h"
#import "MXChatViewConfig.h"
#import "MXChatAudioPlayer.h"
#import "MIXDESK_VoiceConverter.h"
#import "MXAssetUtil.h"
#import "MXVoiceCellModel.h"
#import "MXImageUtil.h"

@interface MXVoiceMessageCell()<MXChatAudioPlayerDelegate>

@end

@implementation MXVoiceMessageCell {
    UIImageView *avatarImageView;
    UIImageView *bubbleImageView;
    UIActivityIndicatorView *sendingIndicator;
    UILabel *durationLabel;
    UIImageView *voiceImageView;
    UIImageView *failureImageView;
    UIActivityIndicatorView *loadingIndicator;
    MXChatAudioPlayer *audioPlayer;
    NSData *voiceData;
    UIView *notPlayPointView;
    BOOL isPlaying;
    BOOL isLoadVoiceSuccess;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MXAudioPlayerDidInterruptNotification object:nil];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        isPlaying = false;
        isLoadVoiceSuccess = false;
        //初始化头像
        avatarImageView = [[UIImageView alloc] init];
        avatarImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:avatarImageView];
        //初始化气泡
        bubbleImageView = [[UIImageView alloc] init];
        bubbleImageView.userInteractionEnabled = true;
        UITapGestureRecognizer *tapBubbleGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapVoiceBubbleGesture:)];
        [bubbleImageView addGestureRecognizer:tapBubbleGesture];
        [self.contentView addSubview:bubbleImageView];
        //初始化indicator
        sendingIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        sendingIndicator.hidden = YES;
        [self.contentView addSubview:sendingIndicator];
        //初始化语音时长的label
        durationLabel = [[UILabel alloc] init];
        durationLabel.textColor = [UIColor lightGrayColor];
        durationLabel.font = [UIFont systemFontOfSize:kMXCellVoiceDurationLabelFontSize];
        durationLabel.textAlignment = NSTextAlignmentCenter;
        durationLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:durationLabel];
        //初始化语音图片
        voiceImageView = [[UIImageView alloc] init];
        [bubbleImageView addSubview:voiceImageView];
        //初始化出错image
        failureImageView = [[UIImageView alloc] initWithImage:[MXChatViewConfig sharedConfig].messageSendFailureImage];
        UITapGestureRecognizer *tapFailureImageGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapFailImage:)];
        failureImageView.userInteractionEnabled = true;
        [failureImageView addGestureRecognizer:tapFailureImageGesture];
        [self.contentView addSubview:failureImageView];
        //初始化加载数据的indicator
        loadingIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        loadingIndicator.hidden = YES;
        [bubbleImageView addSubview:loadingIndicator];
        //初始化未播放的小红点view
        notPlayPointView = [[UIView alloc] init];
        notPlayPointView.backgroundColor = [UIColor redColor];
        notPlayPointView.hidden = true;
        [self.contentView addSubview:notPlayPointView];
        //注册声音中断的通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopVoiceDisplay) name:MXAudioPlayerDidInterruptNotification object:nil];
    }
    return self;
}

#pragma 点击语音的事件
- (void)didTapVoiceBubbleGesture:(id)sender {
    if (!voiceData || !isLoadVoiceSuccess) {
        return ;
    }
    notPlayPointView.hidden = true;
    if (isPlaying) {
        [self stopVoiceDisplay];
        [[MXChatAudioPlayer sharedInstance] stopSound];
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:MXAudioPlayerDidInterruptNotification object:nil];
    isPlaying = true;
    [voiceImageView startAnimating];
    //由于MXChatAudioPlayer是单例，所以每次点击某个cell进行播放，都必须重新设置audioPlayer的delegate
    [MXChatAudioPlayer sharedInstance].delegate = self;
    [MXChatAudioPlayer sharedInstance].keepSessionActive = [MXChatViewConfig sharedConfig].keepAudioSessionActive;
    [MXChatAudioPlayer sharedInstance].playMode = [MXChatViewConfig sharedConfig].playMode;
    [[MXChatAudioPlayer sharedInstance] playSongWithData:voiceData];
    //通知代理点击了语音
    if (self.chatCellDelegate) {
        if ([self.chatCellDelegate respondsToSelector:@selector(didTapMessageInCell:)]) {
            [self.chatCellDelegate didTapMessageInCell:self];
        }
    }
}

#pragma MXChatCellProtocol
- (void)updateCellWithCellModel:(id<MXCellModelProtocol>)model {
    if (![model isKindOfClass:[MXVoiceCellModel class]]) {
        NSAssert(NO, @"传给MXVoiceMessageCell的Model类型不正确");
        return ;
    }
    MXVoiceCellModel *cellModel = (MXVoiceCellModel *)model;
    
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
    
    //是否成功获取到语音数据
    isLoadVoiceSuccess = cellModel.isLoadVoiceSuccess;
    
    //消息图片
    if (!voiceImageView.isAnimating) {
        if (cellModel.isLoadVoiceSuccess) {
            voiceImageView.image = [MXImageUtil convertImageColorWithImage:[MXAssetUtil voiceAnimationGreen3] toColor:[MXChatViewConfig sharedConfig].outgoingMsgTextColor];
            UIImage *animationImage1 = [MXAssetUtil voiceAnimationGreen1];
            UIImage *animationImage2 = [MXAssetUtil voiceAnimationGreen2];
            UIImage *animationImage3 = [MXAssetUtil voiceAnimationGreen3];
            if (cellModel.cellFromType == MXChatCellIncoming) {
                animationImage1 = [MXAssetUtil voiceAnimationGray1];
                animationImage2 = [MXAssetUtil voiceAnimationGray2];
                animationImage3 = [MXAssetUtil voiceAnimationGray3];
                voiceImageView.image = [MXAssetUtil voiceAnimationGray3];
            }
            

            voiceImageView.animationImages = [NSArray arrayWithObjects:
                                              [MXImageUtil convertImageColorWithImage:animationImage1 toColor:[MXChatViewConfig sharedConfig].outgoingMsgTextColor],
                                              [MXImageUtil convertImageColorWithImage:animationImage2 toColor:[MXChatViewConfig sharedConfig].outgoingMsgTextColor],
                                              [MXImageUtil convertImageColorWithImage:animationImage3 toColor:[MXChatViewConfig sharedConfig].outgoingMsgTextColor],nil];
            voiceImageView.animationDuration = 1;
            voiceImageView.animationRepeatCount = 0;
        } else {
            voiceImageView.image = [MXAssetUtil voiceAnimationGreenError];
            if (cellModel.cellFromType == MXChatCellIncoming) {
                voiceImageView.image = [MXAssetUtil voiceAnimationGrayError];
            }
        }
    }
    
    //刷新语音时长label
    NSString *durationText = [NSString stringWithFormat:@"%d\"", (int)cellModel.voiceDuration];
    durationLabel.text = durationText;
    durationLabel.frame = cellModel.durationLabelFrame;
    durationLabel.hidden = true;
    
    //判断是否正在加载声音，是否显示加载数据的indicator
    loadingIndicator.frame = cellModel.loadingIndicatorFrame;
    voiceImageView.frame = cellModel.voiceImageFrame;
    if (cellModel.voiceData) {
        voiceData = cellModel.voiceData;
        voiceImageView.hidden = false;
        loadingIndicator.hidden = true;
        [loadingIndicator stopAnimating];
    } else {
        voiceImageView.hidden = true;
        loadingIndicator.hidden = false;
        [loadingIndicator startAnimating];
    }
    
    //刷新indicator
    sendingIndicator.hidden = true;
    [sendingIndicator stopAnimating];
    if (cellModel.sendStatus == MXChatMessageSendStatusSending && cellModel.cellFromType == MXChatCellOutgoing) {
        sendingIndicator.hidden = false;
        sendingIndicator.frame = cellModel.sendingIndicatorFrame;
        [sendingIndicator startAnimating];
    } else {
        durationLabel.hidden = false;
    }
    
    //刷新出错图片
    failureImageView.hidden = true;
    if (cellModel.sendStatus == MXChatMessageSendStatusFailure) {
        failureImageView.hidden = false;
        failureImageView.frame = cellModel.sendFailureFrame;
    }
    
    //未播放按钮
    if (cellModel.cellFromType == MXChatCellIncoming && !cellModel.isPlayed) {
        notPlayPointView.frame = cellModel.notPlayViewFrame;
        notPlayPointView.layer.masksToBounds = true;
        notPlayPointView.layer.cornerRadius = cellModel.notPlayViewFrame.size.width / 2;
        notPlayPointView.hidden = false;
    } else {
        notPlayPointView.hidden = true;
    }
}

/**
 *  开始播放声音
 */
//- (void)playVoice {
//    [voiceImageView startAnimating];
//    //关闭键盘通知
//    [[NSNotificationCenter defaultCenter] postNotificationName:MXChatViewKeyboardResignFirstResponderNotification object:nil];
//}

/**
 *  停止播放声音
 */
- (void)stopVoiceDisplay {
    [voiceImageView stopAnimating];
    isPlaying = false;
}

#pragma MXChatAudioPlayerDelegate
- (void)MXAudioPlayerBeiginLoadVoice {
    
}

- (void)MXAudioPlayerBeiginPlay {
    
}

- (void)MXAudioPlayerDidFinishPlay {
    [self stopVoiceDisplay];
}

#pragma 点击发送失败消息 重新发送事件
- (void)tapFailImage:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"重新发送吗？" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    [alertView show];
}

#pragma UIAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            //将voiceData写进文件
            NSString *wavPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            wavPath = [wavPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.wav", (int)[NSDate date].timeIntervalSince1970]];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager createFileAtPath:wavPath contents:voiceData attributes:nil];
            if (![fileManager fileExistsAtPath:wavPath]) {
                NSAssert(NO, @"将voiceData写进文件失败");
            }
            //将wav文件转换成amr文件
            NSString *amrPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            amrPath = [amrPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.amr", (int)[NSDate date].timeIntervalSince1970]];
            [MIXDESK_VoiceConverter wavToAmr:wavPath amrSavePath:amrPath];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.chatCellDelegate resendMessageInCell:self resendData:@{@"voice" : amrPath}];
            });
        });
    }
}




@end
