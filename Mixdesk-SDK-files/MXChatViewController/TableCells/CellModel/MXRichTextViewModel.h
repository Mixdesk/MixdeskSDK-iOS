//
//  MXRichTextViewModel.h
//  Mixdesk-SDK-Demo
//
//  Created by ian luo on 16/6/14.
//  Copyright © 2016年 Mixdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MXCellModelProtocol.h"

@class MXRichTextMessage;
@interface MXRichTextViewModel : NSObject <MXCellModelProtocol>

//与 UI 绑定的数据变化回调

@property (nonatomic, copy) CGFloat(^cellHeight)(void);
@property (nonatomic, copy) void(^avatarLoaded)(UIImage *);
@property (nonatomic, copy) void(^iconLoaded)(UIImage *);
@property (nonatomic, copy) void(^modelChanges)(NSString *summary, NSString *iconPath, NSString *content);
@property (nonatomic, copy) void(^botEvaluateDidTapUseful)(NSString *);
@property (nonatomic, copy) void(^botEvaluateDidTapUseless)(NSString *);

//暴露给 UI 的模型数据
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *summary;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy) NSString *iconPath;
@property (nonatomic, strong) UIImage *avartarImage;
@property (nonatomic, readonly, assign) CGRect avatarFrame;
@property (nonatomic, strong) UIImage *iconImage;

@property (nonatomic, assign) CGFloat cachedWetViewHeight;

@property (nonatomic, assign) BOOL isEvaluated;

/**
 * @brief 问题是否已解决的标记
 */
@property (nonatomic, assign) BOOL solved;

- (void)openFrom:(UIViewController *)cv;

- (void)load;

- (id)initCellModelWithMessage:(MXRichTextMessage *)message cellWidth:(CGFloat)cellWidth delegate:(id<MXCellModelDelegate>)delegator;

@end
