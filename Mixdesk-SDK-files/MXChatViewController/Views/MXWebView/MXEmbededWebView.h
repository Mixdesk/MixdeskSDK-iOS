//
//  MXEmbededWebView.h
//  Mixdesk-SDK-Demo
//
//  Created by ian luo on 16/9/5.
//  Copyright © 2016年 Mixdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface MXEmbededWebView : WKWebView

@property (nonatomic, copy)void(^loadComplete)(CGFloat);
@property (nonatomic, copy)void(^tappedLink)(NSURL *);

- (void)loadHTML:(NSString *)html WithCompletion:(void(^)(CGFloat))block;

@end
