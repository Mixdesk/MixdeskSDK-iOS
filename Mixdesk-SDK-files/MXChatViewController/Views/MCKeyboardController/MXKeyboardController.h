//
//  MXKeyboardController.h
//  Mixdesk
//
//  Created by Injoy on 16/4/15.
//  Copyright © 2016年 Injoy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class MXKeyboardController;

typedef NS_ENUM(NSInteger, MXKeyboardStatus) {
    MXKeyboardStatusShowing,    //显示状态
    MXKeyboardStatusWillShow,   //即将显示
    MXKeyboardStatusWillHide,   //即将隐藏
    MXKeyboardStatusHide,       //隐藏
};

@protocol MXKeyboardControllerDelegate <NSObject>

/**
 *  统一处理frame正在改变或已经改变的事件。键盘状态请通过keyboardStatus判断
 *
 *  @param keyboardFrame         当前键盘的frame
 *  @param isImpressionOfGesture 是否是因为手势影响的frame
 */
- (void)keyboardController:(MXKeyboardController *)keyboardController keyboardChangeFrame:(CGRect)keyboardFrame isImpressionOfGesture:(BOOL)isImpressionOfGesture;

@end

@interface MXKeyboardController : NSObject

@property (weak, nonatomic) id<MXKeyboardControllerDelegate> delegate;

/** 当前响应键盘交互的对象 */
@property (strong, nonatomic, readonly) UIView *currentResponder;

/** 能够响应键盘事件的对象 */
@property (strong, nonatomic, readonly) NSArray *responders;

@property (weak, nonatomic, readonly) UIView *contextView;

@property (weak, nonatomic, readonly) UIPanGestureRecognizer *panGestureRecognizer;

/** 指「panGestureRecognizer」与键盘的距离「keyboardTriggerPoint」时触发键盘与用户的交互和平移 */
@property (assign, nonatomic) CGPoint keyboardTriggerPoint;

@property (assign, nonatomic) MXKeyboardStatus keyboardStatus;

/**
 *  创建键盘控制器
 *
 *  @param responders           能够响应键盘事件的对象。需要能获取到inputAccessoryView
 *  @param contextView          与键盘交互的参考物。
 *  @param panGestureRecognizer 处理用户手指平移与键盘的交互
 *
 */
- (instancetype)initWithResponders:(NSArray *)responders
                     contextView:(UIView *)contextView
            panGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer
                        delegate:(id<MXKeyboardControllerDelegate>)delegate;

/**
 *  开始监控键盘。
 */
- (void)beginListeningForKeyboard;

/**
 *  结束
 */
- (void)endListeningForKeyboard;


@end
