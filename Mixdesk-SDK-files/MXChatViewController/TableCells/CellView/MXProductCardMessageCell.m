//
//  MXProductCardMessageCell.m
//  MXEcoboostSDK-test
//
//  Created by shunxingzhang on 2021/9/2.
//  Copyright © 2021 2020 Mixdesk. All rights reserved.
//

#import "MXProductCardMessageCell.h"
#import "MXProductCardCellModel.h"
#import "MXChatViewConfig.h"
#import "MXImageUtil.h"
#import "MXBundleUtil.h"

@implementation MXProductCardMessageCell
{
    UIImageView *avatarImageView;
    UIView *bubbleView;
    UIImageView *bubbleContentImageView;
    UILabel *titleLabel;
    UILabel *descLable;
    UILabel *saleCountLable;
    UILabel *priceLabel;
    UILabel *linkLable;
    UIActivityIndicatorView *sendingIndicator;
    UIImageView *failureImageView;
    MXProductCardCellModel *cellModel;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        //初始化头像
        avatarImageView = [[UIImageView alloc] init];
        avatarImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:avatarImageView];
        //初始化气泡
        bubbleView = [[UIView alloc] init];
        bubbleView.backgroundColor = [UIColor colorWithRed:242/255.0 green:242/255.0 blue:247/255.0 alpha:1];
        bubbleView.layer.masksToBounds = true;
        bubbleView.layer.cornerRadius = 6.0;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bubbleTapped)];
        [bubbleView addGestureRecognizer:tapGesture];
        
        [self.contentView addSubview:bubbleView];
        
        //初始化contentImageView
        bubbleContentImageView = [[UIImageView alloc] init];
        bubbleContentImageView.contentMode = UIViewContentModeScaleAspectFill;
        bubbleContentImageView.clipsToBounds = YES;
        [bubbleView addSubview:bubbleContentImageView];
        //初始化title
        titleLabel = [[UILabel alloc] init];
        titleLabel.font = [MXProductCardCellModel titleFont];
        titleLabel.textColor = [UIColor colorWithRed:4/255.0 green:15/255.0 blue:66/255.0 alpha:1];
        titleLabel.numberOfLines = 2;
        titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [bubbleView addSubview:titleLabel];
        //初始化description
        descLable = [[UILabel alloc] init];
        descLable.font = [MXProductCardCellModel descFont];
        descLable.textColor = [UIColor colorWithRed:111/255.0 green:117/255.0 blue:146/255.0 alpha:1];
        descLable.numberOfLines = 1;
        descLable.lineBreakMode = NSLineBreakByTruncatingTail;
        [bubbleView addSubview:descLable];
        //初始化价格
        priceLabel = [[UILabel alloc] init];
        priceLabel.font = [MXProductCardCellModel priceFont];
        priceLabel.textColor = [UIColor colorWithRed:245/255.0 green:63/255.0 blue:63/255.0 alpha:1];
        priceLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [bubbleView addSubview:priceLabel];
        //初始化salecount
        saleCountLable = [[UILabel alloc] init];
        saleCountLable.font = [UIFont systemFontOfSize:13.0];
        saleCountLable.textColor = [UIColor colorWithRed:111/255.0 green:117/255.0 blue:146/255.0 alpha:1];
        [bubbleView addSubview:saleCountLable];
        //初始化link
        linkLable = [[UILabel alloc] init];
        linkLable.font = [UIFont systemFontOfSize:13.0];
        linkLable.textColor = [UIColor colorWithRed:24/255.0 green:128/255.0 blue:155/255.0 alpha:1];
        linkLable.textAlignment = NSTextAlignmentRight;
        linkLable.text = [MXBundleUtil localizedStringForKey:@"product_message_check_details"];
        linkLable.hidden = YES; //#216 整卡可点，不再显示“查看详情”
        [bubbleView addSubview:linkLable];
        
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
    }
    return self;
}

#pragma MXChatCellProtocol
- (void)updateCellWithCellModel:(id<MXCellModelProtocol>)model {
    if (![model isKindOfClass:[MXProductCardCellModel class]]) {
        NSAssert(NO, @"传给MXProductCardCellModel的Model类型不正确");
        return ;
    }
    cellModel = (MXProductCardCellModel *)model;

    //刷新头像
    if (cellModel.avatarImage) {
        avatarImageView.image = cellModel.avatarImage;
    }
    avatarImageView.frame = cellModel.avatarFrame;
    if ([MXChatViewConfig sharedConfig].enableRoundAvatar) {
        avatarImageView.layer.masksToBounds = YES;
        avatarImageView.layer.cornerRadius = cellModel.avatarFrame.size.width / 2;
    }
    
    //刷新气泡
    bubbleView.frame = cellModel.bubbleFrame;
    bubbleContentImageView.frame = cellModel.contentImageViewFrame;
    
    //消息图片
    bubbleContentImageView.hidden = cellModel.productPictureUrl.length == 0;
    bubbleContentImageView.image = cellModel.image;
    titleLabel.text = cellModel.title;
    descLable.text = cellModel.desc;
    descLable.hidden = cellModel.desc.length == 0;
    priceLabel.text = cellModel.price;
    priceLabel.hidden = cellModel.price.length == 0;
    priceLabel.frame = cellModel.priceFrame;
    //旧数据：无价格且有销量时显示销量
    saleCountLable.hidden = CGRectIsEmpty(cellModel.saleCountFrame);
    saleCountLable.text = [NSString stringWithFormat:@"%@: %ld",[MXBundleUtil localizedStringForKey:@"product_message_sales"],cellModel.saleCount];
    
    titleLabel.frame = cellModel.titleFrame;
    descLable.frame = cellModel.descriptionFrame;
    saleCountLable.frame = cellModel.saleCountFrame;
    linkLable.frame = cellModel.linkFrame;
    
    sendingIndicator.hidden = true;
    [sendingIndicator stopAnimating];
    if (cellModel.sendStatus == MXChatMessageSendStatusSending && cellModel.cellFromType == MXChatCellOutgoing) {
        sendingIndicator.hidden = false;
        sendingIndicator.frame = cellModel.sendingIndicatorFrame;
        [sendingIndicator startAnimating];
    }
    
    failureImageView.hidden = true;
    if (cellModel.sendStatus == MXChatMessageSendStatusFailure) {
        failureImageView.hidden = false;
        failureImageView.frame = cellModel.sendFailureFrame;
    }
}

#pragma 单击气泡
- (void)bubbleTapped {
    
    if ([self.chatCellDelegate respondsToSelector:@selector(didTapProductCard:)]) {
        NSString *productUrl = [NSString stringWithFormat:@"%@",cellModel.productUrl];
        [self.chatCellDelegate didTapProductCard:productUrl];
    }
}

#pragma 点击发送失败消息 重新发送事件
- (void)tapFailImage:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[MXBundleUtil localizedStringForKey:@"retry_send_message"] message:nil delegate:self cancelButtonTitle:[MXBundleUtil localizedStringForKey:@"alert_view_cancel"] otherButtonTitles:[MXBundleUtil localizedStringForKey:@"alert_view_confirm"], nil];
    [alertView show];
}

#pragma UIAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        MXProductCardMessage *message = [[MXProductCardMessage alloc] initWithTitle:cellModel.title productUrl:cellModel.productUrl pictureUrl:cellModel.productPictureUrl price:cellModel.price description:cellModel.desc];
        [self.chatCellDelegate resendMessageInCell:self resendData:@{@"productCard" : message}];
    }
}

@end
