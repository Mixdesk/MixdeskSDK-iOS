//
//  MXChatViewController.h
//  MixdeskSDK
//
//  Created by ijinmao on 15/10/28.
//  Copyright © 2015年 Mixdesk Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MXChatViewConfig.h"
#import "MXChatTableView.h"
#ifdef INCLUDE_MIXDESK_SDK
#import "MXServiceToViewInterface.h"
#endif

/**
 * @brief 聊天界面的ViewController
 *
 * 虽然开发者可以根据MXChatViewController暴露的接口来自定义界面，但推荐做法是通过MXChatViewManager中提供的接口，来对客服聊天界面进行自定义配置；
 */
#import "MXProductCardMessage.h"

@interface MXChatViewController : UIViewController

/**
 * @brief 聊天界面的tableView
 */
@property (nonatomic, strong) MXChatTableView *chatTableView;

/**
 * @brief 聊天界面底部的输入框view
 */
@property (nonatomic, strong) UIView *inputBarView;

/**
 * @brief 聊天界面底部的输入框view
 */
@property (nonatomic, strong) UITextView *inputBarTextView;


@property (nonatomic, assign) NSInteger evaluationButtonIndex;
@property (nonatomic, assign) BOOL hasEvaluationButton;
/**
 * 根据配置初始化客服聊天界面
 * @param manager 初始化配置
 */
- (instancetype)initWithChatViewManager:(MXChatViewConfig *)chatViewConfig;

/**
 *  关闭聊天界面
 */
- (void)dismissChatViewController;

- (void)didSelectNavigationRightButton;

/**
 * 聊天界面已打开时，以访客身份发送一张商品卡片（界面上立即出现，带发送中 / 失败重试）
 * @param productCard 用 -[MXProductCardMessage initWithTitle:productUrl:pictureUrl:price:description:] 创建
 */
- (void)sendProductCardMessage:(MXProductCardMessage *)productCard;

#ifdef INCLUDE_MIXDESK_SDK
/**
 *  聊天界面的委托方法
 */
@property (nonatomic, weak) id<MXServiceToViewInterfaceDelegate> serviceToViewDelegate;
#endif

@end
