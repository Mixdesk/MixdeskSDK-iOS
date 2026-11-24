//
//  MXChatViewController.m
//  MixdeskSDK
//
//  Created by ijinmao on 15/10/28.
//  Copyright © 2015年 Mixdesk Inc. All rights reserved.
//

#import "MXChatViewController.h"
#import "MIXDESK_InputView.h"
#import "MXAssetUtil.h"
#import "MXBottomBar.h"
#import "MXBundleUtil.h"
#import "MXCellModelProtocol.h"
#import "MXChatDeviceUtil.h"
#import "MXChatViewManager.h"
#import "MXChatViewService.h"
#import "MXChatViewTableDataSource.h"
#import "MXCustomizedUIText.h"
#import "MXEvaluationView.h"
#import "MXImageUtil.h"
#import "MXKeyboardController.h"
#import "MXNotificationManager.h"
#import "MXPreChatFormListViewController.h"
#import "MXRecordView.h"
#import "MXRecorderView.h"
#import "MXRefresh.h"
#import "MXRichTextViewModel.h"
#import "MXStringSizeUtil.h"
#import "MXTabInputContentView.h"
#import "MXTextCellModel.h"
#import "MXTipsCellModel.h"
#import "MXToast.h"
#import "MXToolUtil.h"
#import "MXTransitioningAnimation.h"
#import "MXVideoPlayerViewController.h"
#import "MXWebViewBubbleCellModel.h"
#import "UIView+MXLayout.h"
#import <AVFoundation/AVFoundation.h>
#include <Foundation/Foundation.h>
#import <MixdeskSDK/MXDefinition.h>
#import <MixdeskSDK/MXManager.h>

static CGFloat const kMXChatViewInputBarHeight = 80.0;

@interface MXChatViewController () <
    UITableViewDelegate, MXChatViewServiceDelegate, MXBottomBarDelegate,
    UIImagePickerControllerDelegate, MXChatTableViewDelegate,
    MXChatCellDelegate, MXServiceToViewInterfaceErrorDelegate,
    UINavigationControllerDelegate, MXEvaluationViewDelegate,
    MXInputContentViewDelegate, MXKeyboardControllerDelegate,
    MXRecordViewDelegate, MXRecorderViewDelegate, MIXDESK_InputViewDelegate>

@property(nonatomic, strong) MXChatViewService *chatViewService;

@end

@interface MXChatViewController ()

@property(nonatomic, strong) MXTabInputContentView *contentView;
@property(nonatomic, strong) MXBottomBar *bottomBar;
@property(nonatomic, strong) NSLayoutConstraint *constaintInputBarHeight;
@property(nonatomic, strong) NSLayoutConstraint *constraintInputBarBottom;
@property(nonatomic, strong) MXEvaluationView *evaluationView;
@property(nonatomic, strong) MXKeyboardController *keyboardView;
@property(nonatomic, strong) MXRecordView *recordView;
@property(nonatomic, strong) MXRecorderView *displayRecordView; // 只用来显示
@property(nonatomic, assign) bool sendVideoMsgStatus;
@property(nonatomic, assign) bool sendPhotoMsgStatus;

@property(nonatomic, assign) BOOL isFirstScheduleClient;

@property(nonatomic, assign)
    BOOL showEvaluatBarButton; // 是否显示评价按钮，需要在访客发送了消息才能显示

@property(nonatomic, assign) MXEvaluationConfig *levels; // 评价的配置列表

@property(nonatomic, strong) UILabel *ipRestrictedMessageLabel; // 添加IP限制提示信息的Label

@end
@implementation MXChatViewController {
  MXChatViewConfig *chatViewConfig;
  MXChatViewTableDataSource *tableDataSource;
  BOOL isMXSocketFailed;                   // socket通信没有连接上
  UIStatusBarStyle previousStatusBarStyle; // 当前statusBar样式
  BOOL previousStatusBarHidden; // 调出聊天视图界面前是否隐藏 statusBar
  NSTimeInterval sendTime;      // 发送时间，用于限制发送频率
  UIView *translucentView;      // loading 的半透明层
  UIActivityIndicatorView *activityIndicatorView; // loading
  UILabel *networkStatusLable; // 网络链接不可用的提示Label

  BOOL shouldSendInputtingMessageToServer;
  BOOL needToBotttom;
  BOOL willDisapper; // 页面即将消失
}

- (void)dealloc {
  [self removeDelegateAndObserver];
  [chatViewConfig setConfigToDefault];
  [self.chatViewService
      setCurrentInputtingText:[(MXTabInputContentView *)
                                      self.bottomBar.contentView textField]
                                  .text];
  [self closeMixdeskChatView];
  [MXCustomizedUIText reset];
  [MXServiceToViewInterface completeChat];
  [MXServiceToViewInterface insertMXGroupNotificationToConversion:nil];
}

- (instancetype)initWithChatViewManager:(MXChatViewConfig *)config {
  if (self = [super init]) {
    chatViewConfig = config;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  if (@available(iOS 13.0, *)) {
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
  }

  [MXServiceToViewInterface prepareForChat];

  // Do any additional setup after loading the view.
  needToBotttom = YES;
  previousStatusBarStyle = [UIApplication sharedApplication].statusBarStyle;
  previousStatusBarHidden = [UIApplication sharedApplication].statusBarHidden;
  [[UIApplication sharedApplication] setStatusBarHidden:NO];
  [[UIApplication sharedApplication]
      setStatusBarStyle:[MXChatViewConfig sharedConfig]
                            .chatViewStyle.statusBarStyle];
  [self setNeedsStatusBarAppearanceUpdate];

  sendTime = [NSDate timeIntervalSinceReferenceDate];
  self.view.backgroundColor =
      [MXChatViewConfig sharedConfig].chatViewStyle.backgroundColor
          ?: [UIColor colorWithWhite:0.95 alpha:1];
  [self initChatTableView];
  [self initInputBar];
  [self layoutViews];
  [self initchatViewService];
  [self initTableViewDataSource];

  self.chatViewService.chatViewWidth = self.chatTableView.frame.size.width;

#ifdef INCLUDE_MIXDESK_SDK
  //[self updateNavBarTitle:[MXBundleUtil localizedStringForKey:@"wait_agent"]];
  isMXSocketFailed = NO;
  [self addObserver];
#endif

  if ([MXChatViewConfig sharedConfig].presentingAnimation ==
      MXTransiteAnimationTypePush) {
    UIScreenEdgePanGestureRecognizer *popRecognizer =
        [[UIScreenEdgePanGestureRecognizer alloc]
            initWithTarget:self
                    action:@selector(handlePopRecognizer:)];
    popRecognizer.edges = UIRectEdgeLeft;
    [self.view addGestureRecognizer:popRecognizer];
  }

  [self presentUI];

  shouldSendInputtingMessageToServer = YES;

  if (![MXManager obtainNetIsReachable]) {
    [self showNetworkStatusViewWithText:
              [MXBundleUtil localizedStringForKey:@"network_connect_error"]];
  }
}

- (void)presentUI {
  __weak typeof(self) weakSelf = self;
  [MXPreChatFormListViewController usePreChatFormIfNeededOnViewController:self
      compeletion:^(NSDictionary *userInfo) {
        NSString *targetType = userInfo[@"targetType"];
        NSString *target = userInfo[@"target"];
        NSString *menu = userInfo[@"menu"];
        if ([targetType isEqualToString:@"agent"]) {
          [MXChatViewConfig sharedConfig].scheduledAgentId = target;
        } else if ([targetType isEqualToString:@"group"]) {
          [MXChatViewConfig sharedConfig].scheduledGroupId = target;
        }

        if ([menu length] > 0) {
          [weakSelf.chatViewService selectedFormProblem:menu];
        }
        // TODO: [MXServiceToViewInterface
        // prepareForChat]也会初始化企业配置，这里会导致获取企业配置的接口调用两次,APP第一次初始化时会调3次
        [MXServiceToViewInterface
            getEnterpriseConfigInfoWithCache:NO
                                    complete:^(MXEnterprise *enterprise,
                                               NSError *e) {
                                      weakSelf.sendVideoMsgStatus =
                                          enterprise.configInfo.videoMsgStatus;
                                      // 配置 和 本地设置 都开的时候才能发送图片
                                      weakSelf.sendPhotoMsgStatus =
                                          enterprise.configInfo
                                              .photoMsgStatus &&
                                          [MXChatViewConfig sharedConfig]
                                              .enableSendImageMessage;
                                      // 添加操作按钮
                                      [weakSelf.contentView setupButtons];

                                      if(enterprise != nil) {
                                        if (enterprise.configInfo.ip_allowed) {
                                        } else {
                                        // 不允许中国大陆地区的网络发送消息
                                          [weakSelf showIpRestrictedMessageInsteadOfInputBar];
                                        }
                                      } 
                                      weakSelf.isFirstScheduleClient = YES;
                                      [weakSelf
                                              .chatViewService setClientOnline];
                                    }];
        // 获取评价的配置
        [MXServiceToViewInterface
            getEnterpriseEvaluationConfig:YES
                                 complete:^(MXEvaluationConfig *levelss,
                                            NSError *error) {
                                   // 配置评价选项
                                   weakSelf.levels = levelss;
                                   self.chatViewService.evaluationLevels =
                                       levelss;
                                 }];
      }
      cancle:^{
        // 讯前表单 左返回按钮
        [weakSelf dismissViewControllerAnimated:NO
                                     completion:^{
                                       [weakSelf dismissChatViewController];
                                     }];
      }];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:MXAudioPlayerDidInterruptNotification
                    object:nil];

  // 恢复原来的导航栏时间条
  [UIApplication sharedApplication].statusBarStyle = previousStatusBarStyle;

  [[UIApplication sharedApplication]
      setStatusBarHidden:previousStatusBarHidden];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];

  [self.keyboardView beginListeningForKeyboard];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [self.view endEditing:YES];

  willDisapper = YES;
  [self.keyboardView endListeningForKeyboard];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  willDisapper = NO;
  [UIView setAnimationsEnabled:YES];
  [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
  [self.chatViewService
      fillTextDraftToFiledIfExists:(UITextField *)
                                       [(MXTabInputContentView *)self.bottomBar
                                               .contentView textField]];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)dismissChatViewController {
  if ([MXChatViewConfig sharedConfig].presentingAnimation ==
      MXTransiteAnimationTypePush) {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
      [self dismissViewControllerAnimated:YES completion:nil];
    } else {
      [self.view.window.layer
          addAnimation:[MXTransitioningAnimation
                           createDismissingTransiteAnimation:
                               [MXChatViewConfig sharedConfig]
                                   .presentingAnimation]
                forKey:nil];
      [self dismissViewControllerAnimated:NO completion:nil];
    }
  } else {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}

- (void)addObserver {
#ifdef INCLUDE_MIXDESK_SDK
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(didReceiveRefreshOutgoingAvatarNotification:)
             name:MXChatTableViewShouldRefresh
           object:nil];
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(didReceiveSocketStatusChangeNotification:)
             name:MX_NOTIFICATION_SOCKET_STATUS_CHANGE
           object:nil];
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(didReceiveSocketConnectFailedNotification:)
             name:MX_COMMUNICATION_FAILED_NOTIFICATION
           object:nil];
  if (![MXNotificationManager sharedManager].handleNotification) {
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(didReceiveClickGroupNotification:)
               name:MX_CLICK_GROUP_NOTIFICATION
             object:nil];
  }
#endif
}

- (void)removeDelegateAndObserver {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma 初始化viewModel
- (void)initchatViewService {
  self.chatViewService = [[MXChatViewService alloc] initWithDelegate:self
                                                       errorDelegate:self];
}

#pragma 初始化tableView dataSource
- (void)initTableViewDataSource {
  tableDataSource = [[MXChatViewTableDataSource alloc]
      initWithChatViewService:self.chatViewService];
  tableDataSource.chatCellDelegate = self;
  self.chatTableView.dataSource = tableDataSource;
}

#pragma mark - 初始化所有Views
/**
 * 初始化聊天的tableView
 */
- (void)initChatTableView {
  self.chatTableView =
      [[MXChatTableView alloc] initWithFrame:chatViewConfig.chatViewFrame
                                       style:UITableViewStylePlain];
  self.chatTableView.chatTableViewDelegate = self;

  // xlp 修复 发送消息 或者受到消息 会弹一下
  self.chatTableView.estimatedRowHeight = 0;
  self.chatTableView.estimatedSectionFooterHeight = 0;
  self.chatTableView.estimatedSectionHeaderHeight = 0;
  if (@available(iOS 15.0, *)) {
    self.chatTableView.sectionHeaderTopPadding = 0;
  }

  if (@available(iOS 11.0, *)) {
    self.chatTableView.contentInsetAdjustmentBehavior =
        UIScrollViewContentInsetAdjustmentAutomatic;
  }
  self.chatTableView.delegate = self;
  [self.view addSubview:self.chatTableView];

  __weak typeof(self) wself = self;
  [self.chatTableView setupPullRefreshWithAction:^{
    __strong typeof(wself) sself = wself;
    [sself.chatViewService startGettingHistoryMessages];
  }];

  [self.chatTableView.refreshView
        setText:[MXBundleUtil localizedStringForKey:@"pull_refresh_normal"]
      forStatus:MXRefreshStatusDraging];
  [self.chatTableView.refreshView
        setText:[MXBundleUtil localizedStringForKey:@"pull_refresh_triggered"]
      forStatus:MXRefreshStatusTriggered];
  [self.chatTableView.refreshView
        setText:[MXBundleUtil localizedStringForKey:@"no_more_messages"]
      forStatus:MXRefreshStatusEnd];
}

/**
 * 初始化聊天的inpur bar
 */
- (void)initInputBar {
  [self.view addSubview:self.bottomBar];
}

- (void)layoutViews {
  self.chatTableView.translatesAutoresizingMaskIntoConstraints = NO;
  self.bottomBar.translatesAutoresizingMaskIntoConstraints = NO;

  NSMutableArray *constrains = [NSMutableArray new];

  [constrains
      addObjectsFromArray:[self addFitWidthConstraintsToView:self.chatTableView
                                                        onTo:self.view]];
  [constrains
      addObjectsFromArray:[self addFitWidthConstraintsToView:self.bottomBar
                                                        onTo:self.view]];

  [constrains
      addObject:[NSLayoutConstraint
                    constraintWithItem:self.chatTableView
                             attribute:(NSLayoutAttributeTop)relatedBy
                                      :(NSLayoutRelationEqual)toItem:self.view
                             attribute:(NSLayoutAttributeTop)multiplier:1
                              constant:0]];
  [constrains
      addObject:[NSLayoutConstraint
                    constraintWithItem:self.chatTableView
                             attribute:(NSLayoutAttributeLeft)relatedBy
                                      :(NSLayoutRelationEqual)toItem:self.view
                             attribute:(NSLayoutAttributeLeft)multiplier:1
                              constant:0]];
  [constrains
      addObject:[NSLayoutConstraint
                    constraintWithItem:self.chatTableView
                             attribute:(NSLayoutAttributeRight)relatedBy
                                      :(NSLayoutRelationEqual)toItem:self.view
                             attribute:(NSLayoutAttributeRight)multiplier:1
                              constant:0]];
  [constrains
      addObject:[NSLayoutConstraint
                    constraintWithItem:self.chatTableView
                             attribute:(NSLayoutAttributeBottom)relatedBy
                                      :(NSLayoutRelationEqual)toItem
                                      :self.bottomBar
                             attribute:(NSLayoutAttributeTop)multiplier:1
                              constant:0]];

  self.constraintInputBarBottom = [NSLayoutConstraint
      constraintWithItem:self.view
               attribute:(NSLayoutAttributeBottom)relatedBy
                        :(NSLayoutRelationEqual)toItem:self.bottomBar
               attribute:(NSLayoutAttributeBottom)multiplier:1
                constant:(MXToolUtil.kMXObtainDeviceVersionIsIphoneX > 0 ? 34
                                                                         : 0)];

  [constrains addObject:self.constraintInputBarBottom];
  [self.view addConstraints:constrains];

  self.constaintInputBarHeight = [NSLayoutConstraint
      constraintWithItem:self.bottomBar
               attribute:(NSLayoutAttributeHeight)relatedBy
                        :(NSLayoutRelationEqual)toItem:nil
               attribute:(NSLayoutAttributeNotAnAttribute)multiplier:1
                constant:kMXChatViewInputBarHeight];

  [self.bottomBar addConstraint:self.constaintInputBarHeight];
}

- (NSArray *)addFitWidthConstraintsToView:(UIView *)innerView
                                     onTo:(UIView *)outterView {
  return @[
    [NSLayoutConstraint
        constraintWithItem:innerView
                 attribute:NSLayoutAttributeWidth
                 relatedBy:(NSLayoutRelationEqual)toItem:outterView
                 attribute:(NSLayoutAttributeWidth)multiplier:1
                  constant:0],
    [NSLayoutConstraint
        constraintWithItem:innerView
                 attribute:NSLayoutAttributeCenterX
                 relatedBy:(NSLayoutRelationEqual)toItem:outterView
                 attribute:(NSLayoutAttributeCenterX)multiplier:1
                  constant:0]
  ];
}

#pragma 添加消息通知的observer
- (void)setNotificationObserver {
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(resignKeyboardFirstResponder:)
             name:MXChatViewKeyboardResignFirstResponderNotification
           object:nil];
}

#pragma 消息通知observer的处理函数
- (void)resignKeyboardFirstResponder:(NSNotification *)notification {
  [self.view endEditing:true];
}

#pragma mark - MXChatTableViewDelegate

- (void)didTapChatTableView:(UITableView *)tableView {
  [self.view endEditing:true];
}

- (void)tapNavigationRedirectBtn:(id)sender {
  // [self.chatViewService forceRedirectToHumanAgent];
  // [self showActivityIndicatorView];
  [MXServiceToViewInterface transferConversationFromAiAgentToHumanWithConvId];
}

- (void)didSelectNavigationRightButton {
  NSLog(@"点击了自定义导航栏右键，开发者可在这里增加功能。");
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  id<MXCellModelProtocol> cellModel =
      [self.chatViewService.cellModels objectAtIndex:indexPath.row];
  return [cellModel getCellHeight];
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [self.view endEditing:YES];
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForFooterInSection:(NSInteger)section {
  return 0.0000001;
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForHeaderInSection:(NSInteger)section {
  return 0.000001;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate {
  if (self.chatTableView.refreshView.status == MXRefreshStatusTriggered) {
    [self.chatTableView startAnimation];
  }
  needToBotttom = false;
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  CGFloat contentH = scrollView.contentSize.height;
  CGFloat offsetY = scrollView.contentOffset.y;
  CGFloat sizeH = scrollView.bounds.size.height;
  if (offsetY > contentH - 1.5 * sizeH) {
    needToBotttom = true;
  }
}

- (void)didGetHistoryMessagesWithCommitTableAdjustment:
    (void (^)(void))commitTableAdjustment {
  __weak typeof(self) wself = self;
  [self.chatTableView stopAnimationCompletion:^{
    __strong typeof(wself) sself = wself;
    CGFloat oldHeight = sself.chatTableView.contentSize.height;
    commitTableAdjustment();
    CGFloat heightIncreatment =
        sself.chatTableView.contentSize.height - oldHeight;
    if (heightIncreatment > 0) {
      heightIncreatment -= sself.chatTableView.refreshView.bounds.size.height;
      sself.chatTableView.contentOffset = CGPointMake(0, heightIncreatment);
      [sself.chatTableView flashScrollIndicators];
    } else {
      [sself.chatTableView setLoadEnded];
    }
  }];
}

- (void)didUpdateCellModelWithIndexPath:(NSIndexPath *)indexPath
                           needToBottom:(BOOL)toBottom {
  [self.chatTableView updateTableViewAtIndexPath:indexPath];
  toBottom ? [self chatTableViewScrollToBottomWithAnimated:false] : nil;
}

- (void)insertCellAtBottomForModelCount:(NSInteger)count {
  [self checkEvaluationBarButton];
  NSMutableArray *indexToAdd = [NSMutableArray new];
  NSInteger currentCellCount = [self.chatTableView numberOfRowsInSection:0];
  for (int i = 0; i < count; i++) {
    [indexToAdd addObject:[NSIndexPath indexPathForRow:currentCellCount + i
                                             inSection:0]];
  }
  [self.chatTableView insertRowsAtIndexPaths:indexToAdd
                            withRowAnimation:(UITableViewRowAnimationBottom)];
}

- (void)insertCellAtTopForModelCount:(NSInteger)count {
  NSMutableArray *indexToAdd = [NSMutableArray new];
  for (int i = 0; i < count; i++) {
    [indexToAdd insertObject:[NSIndexPath indexPathForRow:i inSection:0]
                     atIndex:0];
  }
  [self.chatTableView insertRowsAtIndexPaths:indexToAdd
                            withRowAnimation:(UITableViewRowAnimationTop)];
}

- (void)insertCellAtCurrentIndex:(NSInteger)currentRow
                      modelCount:(NSInteger)count {
  NSMutableArray *indexToAdd = [NSMutableArray new];
  for (int i = 0; i < count; i++) {
    [indexToAdd addObject:[NSIndexPath indexPathForRow:currentRow + i
                                             inSection:0]];
  }

  [self.chatTableView insertRowsAtIndexPaths:indexToAdd
                            withRowAnimation:UITableViewRowAnimationBottom];
}

- (void)removeCellAtIndex:(NSInteger)index {
  NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
  [self.chatTableView deleteRowsAtIndexPaths:@[ indexPath ]
                            withRowAnimation:UITableViewRowAnimationFade];
}

- (void)reloadChatTableView {
  [self.chatTableView reloadData];
}

// 精确刷新特定的行，避免整个表格重新加载
- (void)reloadCellsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
  NSLog(@"[MXChatViewController] 收到精确刷新请求，indexPaths: %@", indexPaths);
  if (indexPaths.count == 0) {
    return;
  }
  
  // 过滤掉超出范围的indexPath
  NSMutableArray *validIndexPaths = [NSMutableArray array];
  NSInteger totalRows = [self.chatTableView numberOfRowsInSection:0];
  
  for (NSIndexPath *indexPath in indexPaths) {
    if (indexPath.row < totalRows) {
      [validIndexPaths addObject:indexPath];
    } else {
      NSLog(@"[MXChatViewController] 跳过超出范围的indexPath: %@, 总行数: %ld", indexPath, (long)totalRows);
    }
  }
  
  if (validIndexPaths.count > 0) {
    NSLog(@"[MXChatViewController] 正在刷新 %lu 行", (unsigned long)validIndexPaths.count);
    [self.chatTableView reloadRowsAtIndexPaths:validIndexPaths 
                              withRowAnimation:UITableViewRowAnimationNone];
  }
}

- (void)scrollTableViewToBottomAnimated:(BOOL)animated {
  [self checkEvaluationBarButton];
  [self chatTableViewScrollToBottomWithAnimated:animated];
}

- (void)showEvaluationAlertView {
  if (!willDisapper) {
    [self.view.window endEditing:YES];
    [self.evaluationView showEvaluationAlertView];
  }
}

- (BOOL)isChatRecording {
  return [self.recordView isRecording];
}

- (void)didScheduleClientWithViewTitle:(NSString *)viewTitle
                           agentStatus:(MXChatAgentStatus)agentStatus {

  [self updateNavTitleWithAgentName:viewTitle agentStatus:agentStatus];
}

- (void)changeNavReightBtnWithAgentType:(NSString *)agentType
                                 hidden:(BOOL)hidden {
  // 隐藏 loading
  [self dismissActivityIndicatorView];
  UIBarButtonItem *item = nil;

  if (!hidden && [MXChatViewConfig sharedConfig].enableEvaluationButton &&
      [MXServiceToViewInterface allowActiveEvaluation]) {
    self.showEvaluatBarButton = YES;
  } else {
    self.showEvaluatBarButton = NO;
  }

  [self checkEvaluationBarButton];

  if ([agentType isEqualToString:@"aiAgent"]) {
    __weak typeof(self) weakSelf = self;
    [MXServiceToViewInterface
        getIsShowRedirectHumanButtonComplete:^(BOOL isShow, NSError *error) {
          __strong typeof(weakSelf) strongSelf = weakSelf;
          if (isShow && strongSelf) {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
            btn.frame = CGRectMake(0, 0, 30, 30);
            [btn setTitle:[MXBundleUtil
                              localizedStringForKey:@"mixdesk_redirect_sheet"]
                 forState:UIControlStateNormal];
            btn.titleLabel.font =
                [MXChatViewConfig sharedConfig].chatViewStyle.navTitleFont
                    ?: [UIFont systemFontOfSize:16.0];
            [btn addTarget:strongSelf
                          action:@selector(tapNavigationRedirectBtn:)
                forControlEvents:UIControlEventTouchUpInside];
            strongSelf.navigationItem.rightBarButtonItem =
                [[UIBarButtonItem alloc] initWithCustomView:btn];
          } else {
            // 直接隐藏
            strongSelf.navigationItem.rightBarButtonItem = nil;
          }
        }];
    return;
  } else if ([MXChatViewConfig sharedConfig].navBarRightButton) {
    item = [[UIBarButtonItem alloc]
        initWithCustomView:[MXChatViewConfig sharedConfig].navBarRightButton];
  }

  self.navigationItem.rightBarButtonItem = item;
}

- (void)checkEvaluationBarButton {
  // 先检查当前是否有评价按钮
  BOOL shouldShowEvaluationButton =
      self.showEvaluatBarButton && [self.chatViewService haveSendMessage];

  // 当前显示但不应该显示，移除按钮
  if (self.hasEvaluationButton && !shouldShowEvaluationButton) {

    self.hasEvaluationButton = NO;
  }
  // 当前不显示但应该显示，重新设置所有按钮
  else if (!self.hasEvaluationButton && shouldShowEvaluationButton) {
    // 重新调用设置按钮的方法
    [self inputContentView:nil userObjectChange:nil];
  }
}

- (void)didReceiveMessage {
  // 判断是否显示新消息提示  旧版本 是根据此时 是否已经滚动到底部,不在底部
  // 则toast 提示新消息 否则直接显示最新消息
  if ([self.chatTableView isTableViewScrolledToBottom]) {
    [self chatTableViewScrollToBottomWithAnimated:YES];
  } else {
    if ([MXChatViewConfig sharedConfig].enableShowNewMessageAlert) {
      [MXToast
          showToast:[MXBundleUtil localizedStringForKey:@"display_new_message"]
           duration:1.5
             window:self.view];
    }
  }
}

- (void)showToastViewWithContent:(NSString *)content {
  [MXToast showToast:content duration:1.0 window:self.view];
}

#pragma mark - MXInputBarDelegate

- (BOOL)sendMessagePrepareWithText:(NSString *)text
                             image:(UIImage *)image
                    andAMRFilePath:(NSString *)filePath
                  andVideoFilePath:(NSString *)videoPath {
  // 判断当前联系人是否正在登陆，如果正在登陆，显示禁止发送的提示
  if (self.chatViewService.clientStatus == MXStateAllocatingAgent ||
      [NSDate timeIntervalSinceReferenceDate] - sendTime < 1) {
    NSString *alertText =
        self.chatViewService.clientStatus == MXStateAllocatingAgent
            ? @"cannot_text_client_is_onlining"
            : @"send_to_fast";
    [MXToast showToast:[MXBundleUtil localizedStringForKey:alertText]
              duration:2
                window:self.view.window];
    [[(MXTabInputContentView *)self.bottomBar.contentView textField]
        setText:text];
    return NO;
  }

  if (self.chatViewService.clientStatus == MXStateUnallocatedAgent) {
    [self.view endEditing:YES];
  }
  if (text) {
    [self.chatViewService sendTextMessageWithContent:text];
  } else if (image) {
    [self.chatViewService sendImageMessageWithImage:image];
  } else if (filePath) {
    [self.chatViewService sendVoiceMessageWithAMRFilePath:filePath];
  } else if (videoPath) {
    [self.chatViewService sendVideoMessageWithFilePath:videoPath];
  }
  sendTime = [NSDate timeIntervalSinceReferenceDate];
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
        [self chatTableViewScrollToBottomWithAnimated:YES];
      });
  return YES;
}

// 发送文本消息
- (BOOL)sendTextMessage:(NSString *)text {
  // 判断当前联系人是否正在登陆，如果正在登陆，显示禁止发送的提示
  return [self sendMessagePrepareWithText:text
                                    image:nil
                           andAMRFilePath:nil
                         andVideoFilePath:nil];
}

- (void)sendImageWithSourceType:(UIImagePickerControllerSourceType)sourceType {
  NSString *mediaPermission =
      [MXChatDeviceUtil isDeviceSupportImageSourceType:(int)sourceType];
  if (!mediaPermission) {
    return;
  }
  if (![mediaPermission isEqualToString:@"ok"]) {
    [MXToast showToast:[MXBundleUtil localizedStringForKey:mediaPermission]
              duration:2
                window:self.view];
    return;
  }

  // 判断当前联系人是否正在登陆，如果正在登陆，显示禁止发送的提示
  if (self.chatViewService.clientStatus == MXStateAllocatingAgent ||
      [NSDate timeIntervalSinceReferenceDate] - sendTime < 1) {
    NSString *alertText =
        self.chatViewService.clientStatus == MXStateAllocatingAgent
            ? @"cannot_text_client_is_onlining"
            : @"send_to_fast";
    [MXToast showToast:[MXBundleUtil localizedStringForKey:alertText]
              duration:2
                window:self.view];
    return;
  }
  sendTime = [NSDate timeIntervalSinceReferenceDate];
  self.navigationController.delegate = self;
  // 兼容ipad打不开相册问题，使用队列延迟
  //    videoExportPreset
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = (int)sourceType;
    if (self.sendVideoMsgStatus && self.sendPhotoMsgStatus) {
      picker.mediaTypes = @[ @"public.movie", @"public.image" ];
    } else if (self.sendVideoMsgStatus) {
      picker.mediaTypes = @[ @"public.movie" ];
    } else {
      picker.mediaTypes = @[ @"public.image" ];
    }
    //        picker.mediaTypes               = self.sendVideoMsgStatus ?
    //        @[@"public.movie",@"public.image"] : @[@"public.image"];
    picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
    picker.delegate = (id)self;
    picker.allowsEditing =
        [MXChatViewConfig sharedConfig].enablePhotoLibraryEdit;
    if (@available(iOS 11.0, *)) {
      picker.videoExportPreset = AVAssetExportPresetPassthrough;
    }
    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:picker animated:YES completion:nil];
  }];
}

- (void)inputContentTextDidChange:(NSString *)newString {
  if ([MXManager getCurrentState] == MXStateAllocatedAgent) {

    if (shouldSendInputtingMessageToServer && newString.length > 0) {
      shouldSendInputtingMessageToServer = NO;
      [self.chatViewService sendUserInputtingWithContent:newString];
      dispatch_after(
          dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)),
          dispatch_get_main_queue(), ^{
            self->shouldSendInputtingMessageToServer = YES;
          });
    }
  }
}

- (void)chatTableViewScrollToBottomWithAnimated:(BOOL)animated {
  NSInteger cellCount = [self.chatTableView numberOfRowsInSection:0];
  if (cellCount > 0) {
    [self.chatTableView
        scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:cellCount - 1
                                                  inSection:0]
              atScrollPosition:UITableViewScrollPositionBottom
                      animated:animated];
  }
}

- (void)beginRecord:(CGPoint)point {
  if (TARGET_IPHONE_SIMULATOR) {
    [MXToast
        showToast:[MXBundleUtil
                      localizedStringForKey:@"simulator_not_support_microphone"]
         duration:2
           window:self.view];
    return;
  }

  // 判断当前联系人是否正在登陆，如果正在登陆，显示禁止发送的提示
  if (self.chatViewService.clientStatus == MXStateAllocatingAgent ||
      [NSDate timeIntervalSinceReferenceDate] - sendTime < 1) {
    NSString *alertText =
        self.chatViewService.clientStatus == MXStateAllocatingAgent
            ? @"cannot_text_client_is_onlining"
            : @"send_to_fast";
    [MXToast showToast:[MXBundleUtil localizedStringForKey:alertText]
              duration:2
                window:self.view];
    return;
  }
  sendTime = [NSDate timeIntervalSinceReferenceDate];
  // 停止播放的通知
  [[NSNotificationCenter defaultCenter]
      postNotificationName:MXAudioPlayerDidInterruptNotification
                    object:nil];

  // 判断是否开启了语音权限
  if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
    // 首先记录点击语音的时间，如果第一次授权，则确定授权的时间会较长，这时不应该初始化record
    // view
    CGFloat tapVoiceTimeInMilliSeconds =
        [NSDate timeIntervalSinceReferenceDate] * 1000;
    [MXChatDeviceUtil isDeviceSupportMicrophoneWithPermission:^(
                          BOOL permission) {
      CGFloat getPermissionTimeInMilliSeconds =
          [NSDate timeIntervalSinceReferenceDate] * 1000;
      if (getPermissionTimeInMilliSeconds - tapVoiceTimeInMilliSeconds > 100) {
        return;
      }
      if (permission) {
        [self startRecord];
      } else {
        [MXToast
            showToast:[MXBundleUtil localizedStringForKey:@"microphone_denied"]
             duration:2
               window:self.view];
      }
    }];
  } else {
    [self startRecord];
  }
}

- (void)startRecord {
  [self.recordView reDisplayRecordView];
  [self.recordView startRecording];
}

- (void)finishRecord:(CGPoint)point {
  [self.recordView stopRecord];
  [self didEndRecord];
}

- (void)cancelRecord:(CGPoint)point {
  [self.recordView cancelRecording];
  [self didEndRecord];
}

- (void)changedRecordViewToCancel:(CGPoint)point {
  self.recordView.revoke = true;
}

- (void)changedRecordViewToNormal:(CGPoint)point {
  self.recordView.revoke = false;
}

- (void)didEndRecord {
}

#pragma MXRecordViewDelegate
- (void)didFinishRecordingWithAMRFilePath:(NSString *)filePath {
  //    [self.chatViewService sendVoiceMessageWithAMRFilePath:filePath];
  //    [self chatTableViewScrollToBottomWithAnimated:true];
  [self sendMessagePrepareWithText:nil
                             image:nil
                    andAMRFilePath:filePath
                  andVideoFilePath:nil];
}

- (void)didUpdateVolumeInRecordView:(UIView *)recordView
                             volume:(CGFloat)volume {
  [self.displayRecordView changeVolumeLayerDiameter:volume];
}

#pragma UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker
    didFinishPickingMediaWithInfo:(NSDictionary *)info {
  NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
  // 当选择的类型是图片
  if ([type isEqualToString:@"public.image"]) {
    // 图片
    UIImage *image = [MXImageUtil
        resizeImage:
            [MXImageUtil
                fixrotation:[info
                                objectForKey:
                                    [MXChatViewConfig sharedConfig]
                                            .enablePhotoLibraryEdit
                                        ? UIImagePickerControllerEditedImage
                                        : UIImagePickerControllerOriginalImage]]
            maxSize:CGSizeMake(1000, 1000)];
    [picker dismissViewControllerAnimated:YES
                               completion:^{
                                 //        [self.chatViewService
                                 //        sendImageMessageWithImage:image];
                                 //        [self
                                 //        chatTableViewScrollToBottomWithAnimated:true];
                                 [self sendMessagePrepareWithText:nil
                                                            image:image
                                                   andAMRFilePath:nil
                                                 andVideoFilePath:nil];
                               }];
    return;
  } else if ([type isEqualToString:@"public.movie"]) {
    // 视频
    NSURL *videoUrl = [info objectForKey:UIImagePickerControllerMediaURL];
    if (videoUrl) {
      float videoSize = [MXChatFileUtil getfileSizeAtPath:[videoUrl path]];
      if (videoSize > 400 * 1024 * 1024) {
        [MXToast showToast:[MXBundleUtil localizedStringForKey:
                                             @"display_video_more_than_limit"]
                  duration:2
                    window:[UIApplication sharedApplication].keyWindow];
        [MXChatFileUtil deleteFileAtPath:[videoUrl path]];
        return;
      }
      NSString *resultPath = [MXChatFileUtil saveVideoSourceWith:videoUrl];
      if (resultPath) {
        [self sendMessagePrepareWithText:nil
                                   image:nil
                          andAMRFilePath:nil
                        andVideoFilePath:resultPath];
      }
    }
  }
  [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma UINavigationControllerDelegate 设置当前 statusBarStyle
- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
  // 修改status样式
  if ([navigationController isKindOfClass:[UIImagePickerController class]]) {
    [UIApplication sharedApplication].statusBarStyle = previousStatusBarStyle;
  }
  self.navigationController.delegate = nil;
}

#pragma MXChatCellDelegate
- (void)showToastViewInCell:(UITableViewCell *)cell
                  toastText:(NSString *)toastText {
  [MXToast showToast:toastText duration:1.0 window:self.view];
}

- (void)resendMessageInCell:(UITableViewCell *)cell
                 resendData:(NSDictionary *)resendData {
  // 先删除之前的消息
  NSIndexPath *indexPath = [self.chatTableView indexPathForCell:cell];
  [self.chatViewService resendMessageAtIndex:indexPath.row
                                  resendData:resendData];
  [self chatTableViewScrollToBottomWithAnimated:true];
}

- (void)replaceTipCell:(UITableViewCell *)cell {
}

- (void)reloadCellAsContentUpdated:(UITableViewCell *)cell
                         messageId:(NSString *)messageId {
  [self.chatTableView reloadData];
  [self.chatTableView layoutIfNeeded];
  if (needToBotttom) {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      NSIndexPath *indexPath = [NSIndexPath
          indexPathForRow:([weakSelf.chatTableView
                               numberOfRowsInSection:
                                   ([weakSelf.chatTableView numberOfSections] -
                                    1)] -
                           1)
                inSection:([weakSelf.chatTableView numberOfSections] - 1)];
      [weakSelf.chatTableView
          scrollToRowAtIndexPath:indexPath
                atScrollPosition:UITableViewScrollPositionBottom
                        animated:false];
    });
  }
}

- (void)deleteCell:(UITableViewCell *)cell
            withTipMsg:(NSString *)tipMsg
    enableLinesDisplay:(BOOL)enable {
  NSIndexPath *indexPath = [self.chatTableView indexPathForCell:cell];
  [self.chatViewService deleteMessageAtIndex:indexPath.row
                                  withTipMsg:tipMsg
                          enableLinesDisplay:enable];
  [self chatTableViewScrollToBottomWithAnimated:true];
}

- (void)didSelectMessageInCell:(UITableViewCell *)cell
                messageContent:(NSString *)content
               selectedContent:(NSString *)selectedContent {
}

- (void)didTapMenuWithText:(NSString *)menuText {
  // 去掉 menu 的序号后，主动发送该 menu 消息
  NSRange orderRange = [menuText rangeOfString:@". "];
  if (orderRange.location == NSNotFound) {
    return;
  }
  if ([self handleSendMessageAbility]) {
    NSString *sendText = [menuText substringFromIndex:orderRange.location + 2];
    [self.chatViewService sendTextMessageWithContent:sendText];
    [self chatTableViewScrollToBottomWithAnimated:YES];
  }
}

- (void)didTapGuideWithText:(NSString *)guideText {
  if ([self handleSendMessageAbility]) {
    [self.chatViewService sendTextMessageWithContent:guideText];
    [self chatTableViewScrollToBottomWithAnimated:YES];
  }
}

- (void)didTapBotRedirectBtn {
  [self tapNavigationRedirectBtn:nil];
}

- (void)didTapMessageInCell:(UITableViewCell *)cell {
  NSIndexPath *indexPath = [self.chatTableView indexPathForCell:cell];
  [self.chatViewService didTapMessageCellAtIndex:indexPath.row];
}

- (void)showPlayVideoControllerWith:(NSString *)videoLocalPath
                         serverPath:(NSString *)videoServer {
  MXVideoPlayerViewController *playerVC = [[MXVideoPlayerViewController alloc]
      initPlayerWithLocalPath:videoLocalPath
                   serverPath:videoServer];
  [self presentViewController:playerVC animated:YES completion:nil];
}

- (void)didTapProductCard:(NSString *)productUrl {

  if (chatViewConfig.productCardCallBack) {
    // 接入方设置了回调，由接入方自行处理
    chatViewConfig.productCardCallBack(productUrl);
    return;
  }
  // 默认只放行 http / https，防止 javascript:、自定义 scheme 等外链
  NSURL *url = [MXChatViewController safeProductURLFromString:productUrl];
  if (url) {
    [[UIApplication sharedApplication] openURL:url
                                       options:@{}
                             completionHandler:nil];
  }
}

+ (NSURL *)safeProductURLFromString:(NSString *)urlString {
  if (![urlString isKindOfClass:[NSString class]] || urlString.length == 0) {
    return nil;
  }
  NSURL *url = [NSURL
      URLWithString:[urlString stringByTrimmingCharactersInSet:
                                   [NSCharacterSet
                                       whitespaceAndNewlineCharacterSet]]];
  NSString *scheme = url.scheme.lowercaseString;
  if (url.host.length == 0 ||
      !([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"])) {
    return nil;
  }
  return url;
}

- (void)sendProductCardMessage:(MXProductCardMessage *)productCard {
  if (![productCard isKindOfClass:[MXProductCardMessage class]]) {
    return;
  }
  [self.chatViewService sendProductCardWithModel:productCard];
}

#pragma MXEvaluationViewDelegate
- (void)didSelectLevel:(NSInteger)level
       evaluation_type:(NSInteger)evaluation_type
               tag_ids:(NSArray *)tag_ids
               comment:(NSString *)comment
              resolved:(NSInteger)resolved {
  [self.chatViewService sendEvaluationLevel:level
                            evaluation_type:evaluation_type
                                    tag_ids:tag_ids
                                    comment:comment
                                   resolved:resolved];
}

#ifdef INCLUDE_MIXDESK_SDK
#pragma MXServiceToViewInterfaceErrorDelegate 后端返回的数据的错误委托方法
- (void)getLoadHistoryMessageError {
  //    [self.chatTableView finishLoadingTopRefreshViewWithCellNumber:0
  //    isLoadOver:YES];
  [self.chatTableView stopAnimationCompletion:^{
    //        [MXToast showToast:[MXBundleUtil
    //        localizedStringForKey:@"load_history_message_error"] duration:1.0
    //        window:self.view];

    // 后端获取信息失败，取消错误信息提示，从数据库获取历史消息
    [self.chatViewService startGettingDateBaseHistoryMessages];
  }];
}

/**
 *  根据是否正在分配客服，更新导航栏title
 */
- (void)updateNavTitleWithAgentName:(NSString *)agentName
                        agentStatus:(MXChatAgentStatus)agentStatus {
  // 如果开发者设定了 title ，则不更新 title
  if ([MXChatViewConfig sharedConfig].navTitleText) {
    return;
  }
  UIView *titleView = [UIView new];
  UILabel *titleLabel = [UILabel new];
  titleLabel.text = agentName;

  UIFont *font = [MXChatViewConfig sharedConfig].chatViewStyle.navTitleFont ?: [[UINavigationBar appearance].titleTextAttributes objectForKey:NSFontAttributeName] ?: [UIFont systemFontOfSize:16.0];
  UIColor *color = [MXChatViewConfig sharedConfig].navTitleColor
                       ?: [[UINavigationBar appearance].titleTextAttributes
                              objectForKey:NSForegroundColorAttributeName];
  titleLabel.font = font;
  titleLabel.textColor = color;
  CGFloat titleHeight =
      [MXStringSizeUtil getHeightForText:@"客服"
                                withFont:titleLabel.font
                                andWidth:self.view.frame.size.width];
  CGFloat titleWidth = [MXStringSizeUtil getWidthForText:agentName
                                                withFont:titleLabel.font
                                               andHeight:titleHeight];
  // UIImageView *statusImageView = [UIImageView new];
  // switch (agentStatus) {
  // case MXChatAgentStatusOnDuty:
  //   statusImageView.image = [MXAssetUtil agentOnDutyImage];
  //   break;
  // case MXChatAgentStatusOffDuty:
  //   statusImageView.image = [MXAssetUtil agentOffDutyImage];
  //   break;
  // case MXChatAgentStatusOffLine:
  //   statusImageView.image = [MXAssetUtil agentOfflineImage];
  //   break;
  // default:
  //   break;
  // }

  // if ([titleLabel.text
  //         isEqualToString:[MXBundleUtil
  //                             localizedStringForKey:@"no_agent_title"]]) {
  //   statusImageView.image = nil;
  // }
  CGFloat maxTitleViewWidth =
      [[UIScreen mainScreen] bounds].size.width - 2 * 50;
//  CGFloat statusImageWidth = statusImageView.image.size.width;
//  CGFloat titleLabelOriginX = statusImageWidth + 8;
  CGFloat titleLabelWidth =
      titleWidth > maxTitleViewWidth
          ? maxTitleViewWidth
          : titleWidth;

  // statusImageView.frame =
  //     CGRectMake(0, titleHeight / 2 - statusImageView.image.size.height / 2,
  //                statusImageWidth, statusImageView.image.size.height);
  titleLabel.frame =
      CGRectMake(0, 0, titleLabelWidth, titleHeight);
  titleView.frame =
      CGRectMake(0, 0, titleLabelWidth, titleHeight);
//  [titleView addSubview:statusImageView];
  [titleView addSubview:titleLabel];
  self.navigationItem.titleView = titleView;
}

- (void)didReceiveSocketConnectFailedNotification:
    (NSNotification *)notification {
  isMXSocketFailed = YES;
  if (![MXManager obtainNetIsReachable]) {
    [self showNetworkStatusViewWithText:
              [MXBundleUtil localizedStringForKey:@"network_connect_error"]];
  } else {
    [self showNetworkStatusViewWithText:
              [MXBundleUtil localizedStringForKey:@"network_connect_warning"]];
  }
}

- (void)didReceiveClickGroupNotification:(NSNotification *)notification {
  [self.chatViewService setClientOnline];
}

- (void)didReceiveSocketStatusChangeNotification:
    (NSNotification *)notification {
  if (notification.userInfo) {
    NSString *status = [notification.userInfo
        objectForKey:MX_NOTIFICATION_SOCKET_STATUS_CHANGE];
    id reason = [notification.userInfo objectForKey:@"reason"];
    if ([status isEqualToString:SOCKET_STATUS_CONNECTED]) {
      isMXSocketFailed = NO;
      [self dismissNetworkStatusView];
    } else if ([status isEqualToString:SOCKET_STATUS_DISCONNECTED]) {
      isMXSocketFailed = YES;
      if (![MXManager obtainNetIsReachable]) {
        [self
            showNetworkStatusViewWithText:
                [MXBundleUtil localizedStringForKey:@"network_connect_error"]];
      } else if (reason && ![reason isEqual:[NSNull null]] &&
                 [@"autoconnect fail" isEqualToString:reason]) {
        [self showNetworkStatusViewWithText:
                  [MXBundleUtil
                      localizedStringForKey:@"network_connect_warning"]];
      }
    }
  }
}

- (void)didReceiveRefreshOutgoingAvatarNotification:
    (NSNotification *)notification {
  if ([notification.object isKindOfClass:[UIImage class]]) {
    [self.chatViewService refreshOutgoingAvatarWithImage:notification.object];
  }
}

- (void)closeMixdeskChatView {
  if ([self.navigationItem.title
          isEqualToString:[MXBundleUtil
                              localizedStringForKey:@"no_agent_title"]]) {
    [self.chatViewService dismissingChatViewController];
  }
}

#pragma mark - rotation

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
- (void)didRotateFromInterfaceOrientation:
    (UIInterfaceOrientation)fromInterfaceOrientation {
  [self updateTableCells];
  [self.view endEditing:YES];
}
#else
#endif

// ios8以上系统的横屏的事件
- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:
           (id<UIViewControllerTransitionCoordinator>)coordinator {
  [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
  [coordinator
      animateAlongsideTransition:^(
          id<UIViewControllerTransitionCoordinatorContext> context) {
      }
      completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self updateTableCells];
      }];
  [self.view endEditing:YES];
}

- (void)updateTableCells {
  self.chatViewService.chatViewWidth = self.chatTableView.frame.size.width;
  [self.chatViewService updateCellModelsFrame];
  [self.chatTableView reloadData];
}

#pragma mark - input content view deletate

- (void)inputContentView:(MXInputContentView *)inputContentView
        userObjectChange:(NSObject *)object {
  self.bottomBar.buttonGroupBar.buttons = [NSMutableArray new];
  CGRect rect = CGRectMake(0, 0, 40, 40);
  UIButton *recorderBtn = [[UIButton alloc] initWithFrame:rect];
  [recorderBtn
      setImage:[MXChatViewConfig sharedConfig].chatViewStyle.voiceSenderImage
      forState:(UIControlStateNormal)];
  if ([MXChatViewConfig sharedConfig]
          .chatViewStyle.voiceSenderHighlightedImage) {
    [recorderBtn setImage:[MXChatViewConfig sharedConfig]
                              .chatViewStyle.voiceSenderHighlightedImage
                 forState:UIControlStateHighlighted];
  }
  [recorderBtn addTarget:self
                  action:@selector(showRecorder)
        forControlEvents:(UIControlEventTouchUpInside)];

  UIButton *cameraBtn = [[UIButton alloc] initWithFrame:rect];
  [cameraBtn
      setImage:[MXChatViewConfig sharedConfig].chatViewStyle.cameraSenderImage
      forState:(UIControlStateNormal)];
  if ([MXChatViewConfig sharedConfig]
          .chatViewStyle.cameraSenderHighlightedImage) {
    [cameraBtn setImage:[MXChatViewConfig sharedConfig]
                            .chatViewStyle.cameraSenderHighlightedImage
               forState:UIControlStateHighlighted];
  }
  [cameraBtn addTarget:self
                action:@selector(camera)
      forControlEvents:(UIControlEventTouchUpInside)];

  UIButton *imageRoll = [[UIButton alloc] initWithFrame:rect];
  [imageRoll
      setImage:[MXChatViewConfig sharedConfig].chatViewStyle.photoSenderImage
      forState:(UIControlStateNormal)];
  if ([MXChatViewConfig sharedConfig]
          .chatViewStyle.photoSenderHighlightedImage) {
    [imageRoll setImage:[MXChatViewConfig sharedConfig]
                            .chatViewStyle.photoSenderHighlightedImage
               forState:UIControlStateHighlighted];
  }
  [imageRoll addTarget:self
                action:@selector(imageRoll)
      forControlEvents:(UIControlEventTouchUpInside)];

  UIButton *emoji = [[UIButton alloc] initWithFrame:rect];
  [emoji setImage:[MXChatViewConfig sharedConfig].chatViewStyle.emojiSenderImage
         forState:(UIControlStateNormal)];
  if ([MXChatViewConfig sharedConfig]
          .chatViewStyle.emojiSenderHighlightedImage) {
    [emoji setImage:[MXChatViewConfig sharedConfig]
                        .chatViewStyle.emojiSenderHighlightedImage
           forState:UIControlStateHighlighted];
  }
  [emoji addTarget:self
                action:@selector(emoji)
      forControlEvents:(UIControlEventTouchUpInside)];

  UIButton *enableEvaluation = [[UIButton alloc] initWithFrame:rect];
  [enableEvaluation setImage:[MXChatViewConfig sharedConfig]
                                 .chatViewStyle.evaluationSenderImage
                    forState:(UIControlStateNormal)];
  [enableEvaluation addTarget:self
                       action:@selector(evaluation)
             forControlEvents:(UIControlEventTouchUpInside)];

  if ([MXChatViewConfig sharedConfig].enableSendVoiceMessage) {
    [self.bottomBar.buttonGroupBar addButton:recorderBtn];
  }

  // 可以发视频或者可以发图片才添加拍照按钮
  if (self.sendVideoMsgStatus || self.sendPhotoMsgStatus) {
    [self.bottomBar.buttonGroupBar addButton:cameraBtn];
  }
  if (self.sendPhotoMsgStatus) {
    [self.bottomBar.buttonGroupBar addButton:imageRoll];
  }

  if ([MXChatViewConfig sharedConfig].enableSendEmoji) {
    [self.bottomBar.buttonGroupBar addButton:emoji];
  }
  // 始终添加评价按钮，然后通过hidden属性控制显示和隐藏
  [self.bottomBar.buttonGroupBar addButton:enableEvaluation];

  // 根据条件设置评价按钮的显示状态
  if (self.showEvaluatBarButton &&
      [MXChatViewConfig sharedConfig].enableEvaluationButton &&
      [MXServiceToViewInterface allowActiveEvaluation] &&
      [self.chatViewService haveSendMessage]) {
    enableEvaluation.hidden = NO;
    self.hasEvaluationButton = YES;
  } else {
    enableEvaluation.hidden = YES;
    self.hasEvaluationButton = NO;
  }
}

- (BOOL)handleSendMessageAbility {

  // xlp 检测网络 排除断网状态还能发送信息
  if (![MXManager obtainNetIsReachable] || isMXSocketFailed) {
    [[(MXTabInputContentView *)self.bottomBar.contentView textField]
        resignFirstResponder];
    [MXToast
        showToast:[MXBundleUtil
                      localizedStringForKey:@"mixdesk_communication_failed"]
         duration:2.0
           window:self.view];
    return NO;
  }

  // 判断当前联系人是否正在登陆，如果正在登陆，显示禁止发送的提示
  if (self.chatViewService.clientStatus == MXStateAllocatingAgent) {
    NSString *alertText = @"cannot_text_client_is_onlining";
    [MXToast showToast:[MXBundleUtil localizedStringForKey:alertText]
              duration:2
                window:[[UIApplication sharedApplication].windows lastObject]];

    return NO;
  }
  return YES;
}

- (void)showRecorder {
  if ([self handleSendMessageAbility]) {
    if (self.bottomBar.isFirstResponder) {
      [self.bottomBar resignFirstResponder];
    } else {
      self.bottomBar.inputView = self.displayRecordView;
      [self.bottomBar becomeFirstResponder];
    }
  }
}

- (void)camera {
  if ([self handleSendMessageAbility]) {
    [self sendImageWithSourceType:(UIImagePickerControllerSourceTypeCamera)];
  }
}

- (void)imageRoll {
  if ([self handleSendMessageAbility]) {
    [self sendImageWithSourceType:
              (UIImagePickerControllerSourceTypePhotoLibrary)];
  }
}

- (void)emoji {
  if ([self handleSendMessageAbility]) {
    if (self.bottomBar.isFirstResponder) {
      [self.bottomBar resignFirstResponder];
    } else {

      CGFloat emojiViewHeight = MXToolUtil.kMXObtainDeviceVersionIsIphoneX
                                    ? (emojikeyboardHeight + 34)
                                    : emojikeyboardHeight;

      MIXDESK_InputView *mmView = [[MIXDESK_InputView alloc]
          initWithFrame:CGRectMake(0, 0, self.view.frame.size.width,
                                   emojiViewHeight)];
      mmView.inputViewDelegate = self;
      self.bottomBar.inputView = mmView;

      [self.bottomBar becomeFirstResponder];
    }
  }
}

- (void)evaluation {
  // if ([self handleSendMessageAbility]) {
  //   if (self.bottomBar.isFirstResponder) {
  //     [self.bottomBar resignFirstResponder];
  //   } else {
  //     [self showEvaluationAlertView];
  //   }
  // }
  [self showEvaluationAlertView];
}

- (BOOL)inputContentViewShouldReturn:(MXInputContentView *)inputContentView
                             content:(NSString *)content
                          userObject:(NSObject *)object {

  if ([content length] > 0) {
    if ([self handleSendMessageAbility]) {
      [self sendTextMessage:content];
      return YES;
    } else {
      return NO;
    }
  }
  return YES;
}

- (BOOL)inputContentViewShouldBeginEditing:
    (MXInputContentView *)inputContentView {

  // xlp 检测网络 排除断网状态还能发送信息
  if (![MXManager obtainNetIsReachable] || isMXSocketFailed) {
    [MXToast
        showToast:[MXBundleUtil
                      localizedStringForKey:@"mixdesk_communication_failed"]
         duration:2.0
           window:self.view];
    return NO;
  }
  return YES;
}

#pragma mark - inputbar delegate

- (void)inputBar:(MXBottomBar *)inputBar willChangeHeight:(CGFloat)height {
  if (height > kMXChatViewInputBarHeight) {
    CGFloat diff = height - self.constaintInputBarHeight.constant;
    if (diff < self.chatTableView.contentInset.top +
                   self.self.chatTableView.contentSize.height) {
      self.chatTableView.contentOffset =
          CGPointMake(self.chatTableView.contentOffset.x,
                      self.chatTableView.contentOffset.y + diff);
    }

    [self changeInputBarHeightConstraintConstant:height];
  } else {
    [self changeInputBarHeightConstraintConstant:kMXChatViewInputBarHeight];
  }
}

- (void)changeInputBarHeightConstraintConstant:(CGFloat)height {
  self.constaintInputBarHeight.constant = height;

  self.keyboardView.keyboardTriggerPoint = CGPointMake(0, height);
  [self.view setNeedsUpdateConstraints];
  [self.view layoutIfNeeded];
}

- (void)changeInputBarBottomLayoutGuideConstant:(CGFloat)height {
  // xlp 收回键盘 时 减去 34 todo
  if (MXToolUtil.kMXObtainDeviceVersionIsIphoneX) {
    if (height == 0) {
      height = 34;

    } else if (height == emojikeyboardHeight) {
      // 点击表情 弹出表情键盘时
      height += 34;
    }
  }

  self.constraintInputBarBottom.constant = height;

  [self.view setNeedsUpdateConstraints];
  [self.view layoutIfNeeded];
}

#pragma mark - keyboard controller delegate
- (void)keyboardController:(MXKeyboardController *)keyboardController
       keyboardChangeFrame:(CGRect)keyboardFrame
     isImpressionOfGesture:(BOOL)isImpressionOfGesture {

  CGFloat viewHeight =
      self.navigationController.navigationBar.translucent
          ? CGRectGetMaxY(self.view.frame)
          : CGRectGetMaxY(self.view.frame) - MXToolUtil.kMXObtainNaviHeight;

  CGFloat heightFromBottom =
      MAX(0.0, viewHeight - CGRectGetMinY(keyboardFrame));

  if (!isImpressionOfGesture) {

    if (MXToolUtil.kMXObtainDeviceVersionIsIphoneX) {

      CGFloat diff = heightFromBottom - self.constraintInputBarBottom.constant +
                     (heightFromBottom == 0 ? 34 : 0);
      if (diff < self.chatTableView.contentInset.top +
                     self.chatTableView.contentSize.height) {
        self.chatTableView.contentOffset =
            CGPointMake(self.chatTableView.contentOffset.x,
                        self.chatTableView.contentOffset.y + diff);
      }

    } else {

      CGFloat diff = heightFromBottom - self.constraintInputBarBottom.constant;
      if (diff < self.chatTableView.contentInset.top +
                     self.chatTableView.contentSize.height) {
        self.chatTableView.contentOffset =
            CGPointMake(self.chatTableView.contentOffset.x,
                        self.chatTableView.contentOffset.y + diff);
      }
    }
  }

  [self changeInputBarBottomLayoutGuideConstant:heightFromBottom];
}

#pragma mark - MCRecorderViewDelegate
- (void)recordEnd {
  [self finishRecord:CGPointZero];
}

- (void)recordStarted {
  [self beginRecord:CGPointZero];
}

- (void)recordCanceld {
  [self cancelRecord:CGPointZero];
}

#pragma mark - emoji delegate and datasource

- (void)MXInputViewObtainEmojiStr:(NSString *)emojiStr {
  MIXDESK_HPGrowingTextView *textField =
      [(MXTabInputContentView *)self.bottomBar.contentView textField];
  textField.text = [textField.text stringByAppendingString:emojiStr];
}
- (void)MXInputViewDeleteEmoji {
  MIXDESK_HPGrowingTextView *textField =
      [(MXTabInputContentView *)self.bottomBar.contentView textField];
  if (textField.text.length > 0) {
    NSRange lastRange = [textField.text
        rangeOfComposedCharacterSequenceAtIndex:([textField.text length] - 1)];
    textField.text =
        [textField.text stringByReplacingCharactersInRange:lastRange
                                                withString:@""];
  }
}
- (void)MXInputViewSendEmoji {
  MIXDESK_HPGrowingTextView *textField =
      [(MXTabInputContentView *)self.bottomBar.contentView textField];
  if (textField.text.length > 0) {

    [self sendTextMessage:textField.text];
    [(MXTabInputContentView *)self.bottomBar.contentView textField].text = @"";
  }
}

#pragma mark -

- (void)handlePopRecognizer:(UIScreenEdgePanGestureRecognizer *)recognizer {
  CGPoint translation = [recognizer translationInView:self.view];

  CGFloat xPercent = translation.x / CGRectGetWidth(self.view.bounds) * 0.5;

  switch (recognizer.state) {
  case UIGestureRecognizerStateBegan:
    [MXTransitioningAnimation setInteractive:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
    break;
  case UIGestureRecognizerStateChanged:
    [MXTransitioningAnimation updateInteractiveTransition:xPercent];
    break;
  default:
    if (xPercent < .25) {
      [MXTransitioningAnimation cancelInteractiveTransition];
    } else {
      [MXTransitioningAnimation finishInteractiveTransition];
    }
    [MXTransitioningAnimation setInteractive:NO];
    break;
  }
}

#endif

#pragma mark - lazy

- (MXEvaluationView *)evaluationView {
  if (!_evaluationView) {
    _evaluationView = [[MXEvaluationView alloc] init];
    _evaluationView.delegate = self;
  }
  return _evaluationView;
}

- (MXTabInputContentView *)contentView {
  if (!_contentView) {
    _contentView = [[MXTabInputContentView alloc]
        initWithFrame:CGRectMake(0, 0, self.view.frame.size.width,
                                 emojikeyboardHeight)];
  }
  return _contentView;
}

- (MXBottomBar *)bottomBar {
  if (!_bottomBar) {
    //        MXTabInputContentView *contentView = [[MXTabInputContentView
    //        alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width,
    //        emojikeyboardHeight )];

    _bottomBar = [[MXBottomBar alloc]
        initWithFrame:CGRectMake(0, 0, self.view.frame.size.width,
                                 kMXChatViewInputBarHeight)
          contentView:self.contentView];
    _bottomBar.delegate = self;
    _bottomBar.contentViewDelegate = self;
    //        [contentView setupButtons];
  }
  return _bottomBar;
}

- (MXKeyboardController *)keyboardView {
  if (!_keyboardView) {
    _keyboardView = [[MXKeyboardController alloc]
          initWithResponders:@[ self.bottomBar.contentView, self.bottomBar ]
                 contextView:self.view
        panGestureRecognizer:self.chatTableView.panGestureRecognizer
                    delegate:self];
    _keyboardView.keyboardTriggerPoint =
        CGPointMake(0, self.constaintInputBarHeight.constant);
  }
  return _keyboardView;
}

- (MXRecorderView *)displayRecordView {
  if (!_displayRecordView) {
    _displayRecordView = [[MXRecorderView alloc]
        initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 258)];
    _displayRecordView.delegate = self;
    _displayRecordView.backgroundColor =
        [[UIColor alloc] initWithRed:242 / 255.0
                               green:242 / 255.0
                                blue:247 / 255.0
                               alpha:1];
  }
  return _displayRecordView;
}

- (MXRecordView *)recordView {
  // 如果开发者不自定义录音界面，则将播放界面显示出来
  if (!_recordView) {
    _recordView = [[MXRecordView alloc]
            initWithFrame:CGRectMake(0, 0, self.chatTableView.frame.size.width,
                                     /*viewSize.height*/
                                     [UIScreen mainScreen].bounds.size.height -
                                         self.bottomBar.frame.size.height)
        maxRecordDuration:[MXChatViewConfig sharedConfig].maxVoiceDuration];
    _recordView.recordMode = [MXChatViewConfig sharedConfig].recordMode;
    _recordView.keepSessionActive =
        [MXChatViewConfig sharedConfig].keepAudioSessionActive;
    _recordView.recordViewDelegate = self;
    //        [self.view addSubview:_recordView];
  }

  return _recordView;
}

/**
 显示数据提交遮罩层
 */
- (void)showActivityIndicatorView {
  if (!translucentView) {
    translucentView = [[UIView alloc]
        initWithFrame:CGRectMake(0, 0, self.chatTableView.frame.size.width,
                                 self.chatTableView.frame.size.height)];
    translucentView.backgroundColor = [UIColor blackColor];
    translucentView.alpha = 0.5;
    translucentView.autoresizingMask =
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    activityIndicatorView = [[UIActivityIndicatorView alloc]
        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [activityIndicatorView
        setCenter:CGPointMake(self.chatTableView.frame.size.width / 2.0,
                              self.chatTableView.frame.size.height / 2.0)];
    [translucentView addSubview:activityIndicatorView];
    activityIndicatorView.autoresizingMask =
        UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleLeftMargin |
        UIViewAutoresizingFlexibleRightMargin |
        UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:translucentView];
  }

  translucentView.hidden = NO;
  translucentView.alpha = 0;
  [activityIndicatorView startAnimating];
  [UIView animateWithDuration:0.5
                   animations:^{
                     self->translucentView.alpha = 0.5;
                   }];
}

/**
 隐藏数据提交遮罩层
 */
- (void)dismissActivityIndicatorView {
  if (translucentView) {
    [activityIndicatorView stopAnimating];
    translucentView.hidden = YES;
  }
}

#pragma mark - network status view

/**
 显示网络链接错误的提示
 */
- (void)showNetworkStatusViewWithText:(NSString *)content {
  if (!networkStatusLable) {
    networkStatusLable = [[UILabel alloc] initWithFrame:CGRectZero];
    networkStatusLable.textAlignment = NSTextAlignmentCenter;
    networkStatusLable.backgroundColor = [UIColor redColor];
    [self.view addSubview:networkStatusLable];
    [self.view bringSubviewToFront:networkStatusLable];
    networkStatusLable.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:@[
      [NSLayoutConstraint
          constraintWithItem:networkStatusLable
                   attribute:NSLayoutAttributeTop
                   relatedBy:NSLayoutRelationEqual
                      toItem:self.view
                   attribute:NSLayoutAttributeTop
                  multiplier:1
                    constant:[MXChatDeviceUtil getDeviceNavRect:self]
                                 .size.height +
                             [MXChatDeviceUtil getDeviceStatusBarRect]
                                 .size.height],
      [NSLayoutConstraint constraintWithItem:networkStatusLable
                                   attribute:NSLayoutAttributeLeft
                                   relatedBy:NSLayoutRelationEqual
                                      toItem:self.view
                                   attribute:NSLayoutAttributeLeft
                                  multiplier:1
                                    constant:0],
      [NSLayoutConstraint constraintWithItem:networkStatusLable
                                   attribute:NSLayoutAttributeRight
                                   relatedBy:NSLayoutRelationEqual
                                      toItem:self.view
                                   attribute:NSLayoutAttributeRight
                                  multiplier:1
                                    constant:0],
      [NSLayoutConstraint constraintWithItem:networkStatusLable
                                   attribute:NSLayoutAttributeHeight
                                   relatedBy:NSLayoutRelationEqual
                                      toItem:nil
                                   attribute:NSLayoutAttributeNotAnAttribute
                                  multiplier:1
                                    constant:30],
    ]];
  }

  UIImage *iconImage =
      [content
          isEqualToString:[MXBundleUtil
                              localizedStringForKey:@"network_connect_error"]]
          ? [MXAssetUtil networkStatusError]
          : [MXAssetUtil networkStatusWarning];
  UIColor *statusBackgroundColor =
      [content
          isEqualToString:[MXBundleUtil
                              localizedStringForKey:@"network_connect_error"]]
          ? [UIColor mx_colorWithHexString:@"#FFECEA"]
          : [UIColor mx_colorWithHexString:@"#FFF5E6"];

  NSMutableAttributedString *mutableAttr =
      [[NSMutableAttributedString alloc] init];
  NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
  attachment.image = iconImage;
  attachment.bounds = CGRectMake(0, -2, 15, 15);
  [mutableAttr
      appendAttributedString:[NSAttributedString
                                 attributedStringWithAttachment:attachment]];

  [mutableAttr
      appendAttributedString:[[NSMutableAttributedString alloc]
                                 initWithString:[NSString
                                                    stringWithFormat:@" %@",
                                                                     content]
                                     attributes:@{
                                       NSFontAttributeName :
                                           [UIFont systemFontOfSize:14.0],
                                       NSForegroundColorAttributeName :
                                           [UIColor grayColor],
                                     }]];

  networkStatusLable.attributedText = mutableAttr;
  networkStatusLable.hidden = NO;
  networkStatusLable.backgroundColor = statusBackgroundColor;
}

/**
 隐藏网络链接错误的提示
 */
- (void)dismissNetworkStatusView {
  if (networkStatusLable) {
    networkStatusLable.hidden = YES;
  }
}

// 添加显示IP限制信息的方法
- (void)showIpRestrictedMessage {
    if (!self.ipRestrictedMessageLabel) {
        self.ipRestrictedMessageLabel = [[UILabel alloc] init];
        self.ipRestrictedMessageLabel.text = @"抱歉,当前系统暂不支持通过中国大陆地区的网络发送消息,感谢您的理解";
        self.ipRestrictedMessageLabel.textAlignment = NSTextAlignmentCenter;
        self.ipRestrictedMessageLabel.textColor = [UIColor mx_colorWithHexString:@"#333"];
        self.ipRestrictedMessageLabel.font = [UIFont systemFontOfSize:15];
        self.ipRestrictedMessageLabel.numberOfLines = 0;
        self.ipRestrictedMessageLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.view addSubview:self.ipRestrictedMessageLabel];
        
        // 设置约束
        [NSLayoutConstraint activateConstraints:@[
            [self.ipRestrictedMessageLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
            [self.ipRestrictedMessageLabel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
            [self.ipRestrictedMessageLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
            [self.ipRestrictedMessageLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20]
        ]];
    }
    
    self.ipRestrictedMessageLabel.hidden = NO;
}

// 添加显示IP限制信息替代输入栏的方法
- (void)showIpRestrictedMessageInsteadOfInputBar {
    // 隐藏原来的输入栏
    self.bottomBar.hidden = YES;
    
    // 创建IP限制提示Label
    if (!self.ipRestrictedMessageLabel) {
        self.ipRestrictedMessageLabel = [[UILabel alloc] init];
        self.ipRestrictedMessageLabel.text =[MXBundleUtil localizedStringForKey:@"mx_ip_restricted_message"];
        self.ipRestrictedMessageLabel.textAlignment = NSTextAlignmentCenter;
        self.ipRestrictedMessageLabel.textColor = [UIColor mx_colorWithHexString:@"#333"];
        self.ipRestrictedMessageLabel.font = [UIFont systemFontOfSize:14];
        self.ipRestrictedMessageLabel.numberOfLines = 0;
        self.ipRestrictedMessageLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.view addSubview:self.ipRestrictedMessageLabel];
        
        // 添加上边框视图
        UIView *topBorder = [UIView new];
        topBorder.backgroundColor = [UIColor lightGrayColor];
        topBorder.translatesAutoresizingMaskIntoConstraints = NO;
        [self.ipRestrictedMessageLabel addSubview:topBorder];
        
        // 设置上边框约束
        [NSLayoutConstraint activateConstraints:@[
            [topBorder.topAnchor constraintEqualToAnchor:self.ipRestrictedMessageLabel.topAnchor],
            [topBorder.leadingAnchor constraintEqualToAnchor:self.ipRestrictedMessageLabel.leadingAnchor],
            [topBorder.trailingAnchor constraintEqualToAnchor:self.ipRestrictedMessageLabel.trailingAnchor],
            [topBorder.heightAnchor constraintEqualToConstant:0.5]
        ]];
        
        // 将提示信息放在底部输入栏的位置
        [NSLayoutConstraint activateConstraints:@[
            [self.ipRestrictedMessageLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [self.ipRestrictedMessageLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
            [self.ipRestrictedMessageLabel.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:(MXToolUtil.kMXObtainDeviceVersionIsIphoneX > 0 ? -34 : 0)],
            [self.ipRestrictedMessageLabel.heightAnchor constraintEqualToConstant:kMXChatViewInputBarHeight]
        ]];
        
        // 修改聊天表格视图的底部约束，让它延伸到提示文本上方
        for (NSLayoutConstraint *constraint in self.view.constraints) {
            if (constraint.firstItem == self.chatTableView && constraint.firstAttribute == NSLayoutAttributeBottom) {
                [constraint setActive:NO];
                [NSLayoutConstraint constraintWithItem:self.chatTableView
                                           attribute:NSLayoutAttributeBottom
                                           relatedBy:NSLayoutRelationEqual
                                              toItem:self.ipRestrictedMessageLabel
                                           attribute:NSLayoutAttributeTop
                                          multiplier:1
                                            constant:0].active = YES;
                break;
            }
        }
    }
}

@end
