//
//  MCTabInputContentView.m
//  Mixdesk
//
//  Created by Injoy on 16/4/14.
//  Copyright © 2016年 Injoy. All rights reserved.
//

#import "MXTabInputContentView.h"
#import "MXBundleUtil.h"

@implementation MXTabInputContentView
{
    CALayer *topBoder;
    UIView *tabBackgroud;
}

-(instancetype)initWithFrame:(CGRect)frame;
{
    self = [super initWithFrame:frame];
    if (self) {
        self.textField = [[MIXDESK_HPGrowingTextView alloc] initWithFrame:CGRectMake(0, 1, self.frame.size.width, self.frame.size.height)];
        self.textField.placeholder = [MXBundleUtil localizedStringForKey:@"input_content"];

        self.textField.font = [UIFont systemFontOfSize:15];
        self.textField.maxNumberOfLines = 8;
        self.textField.returnKeyType = UIReturnKeySend;
        self.textField.delegate = (id)self;
        self.textField.backgroundColor = [UIColor whiteColor];
        self.textField.textColor = [UIColor blackColor];
        [self addSubview:self.textField];

        topBoder = [CALayer layer];
        topBoder.backgroundColor = [UIColor colorWithRed:198/255.0 green:203/255.0 blue:208/255.0 alpha:1].CGColor;
        [self.layer addSublayer:topBoder];
        
        tabBackgroud = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        tabBackgroud.backgroundColor = [UIColor colorWithRed:248/255.0 green:248/255.0 blue:253/255.0 alpha:1];
        [self addSubview:tabBackgroud];
            
    }
    return self;
}



- (void)setupButtons {
    if (self.delegate && [self.delegate respondsToSelector:@selector(inputContentView:userObjectChange:)]) {
        [self.delegate inputContentView:self userObjectChange:nil];
    }
}

-(void)setNeedsLayout
{
    [super setNeedsLayout];

    topBoder.frame = CGRectMake(0, 0, self.frame.size.width, 1);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(inputContentViewShouldReturn:content:userObject:)])
    {
        return [self.delegate inputContentViewShouldReturn:self content:self.textField.text userObject:nil];
    }
    
    return YES;
}

- (BOOL)isFirstResponder
{
    return self.textField.isFirstResponder;
}

- (BOOL)becomeFirstResponder
{
    return [self.textField becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
    [super resignFirstResponder];
    return [self.textField resignFirstResponder];
}

- (UIView *)inputAccessoryView
{
    return [UIView new];
}

-(void)setInputAccessoryView:(UIView *)inputAccessoryView
{
    self.textField.inputAccessoryView = inputAccessoryView;
}

- (UIView *)inputView
{
    return self.textField.inputView;
}

- (void)setInputView:(UIView *)inputview
{
    self.textField.inputView = inputview;
}

#pragma make - HPGrowingTextViewDelegate
- (void)growingTextView:(MIXDESK_HPGrowingTextView *)growingTextView didChangeHeight:(float)height
{
    if (self.layoutDelegate && [self.layoutDelegate respondsToSelector:@selector(inputContentView:didChangeHeight:)]) {
        [self.layoutDelegate inputContentView:self didChangeHeight:self.textField.frame.size.height];
    }
}

- (void)growingTextView:(MIXDESK_HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    if (self.layoutDelegate && [self.layoutDelegate respondsToSelector:@selector(inputContentView:willChangeHeight:)]) {
        [self.layoutDelegate inputContentView:self willChangeHeight:height];
    }
}

- (BOOL)growingTextViewShouldReturn:(MIXDESK_HPGrowingTextView *)growingTextView
{
    if ([growingTextView.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length > 0) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(inputContentViewShouldReturn:content:userObject:)]) {
            BOOL should = [self.delegate inputContentViewShouldReturn:self content:growingTextView.text userObject:nil];
            if (should) {
                growingTextView.text = @"";
            }
            return should;
        }
    }
    return YES;
}

- (BOOL)growingTextViewShouldBeginEditing:(MIXDESK_HPGrowingTextView *)growingTextView
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(inputContentViewShouldBeginEditing:)]) {
        return [self.delegate inputContentViewShouldBeginEditing:self];
    }else{
        return true;
    }
}

- (void)growingTextViewDidChangeSelection:(MIXDESK_HPGrowingTextView *)growingTextView {
    if ([self.delegate respondsToSelector:@selector(inputContentTextDidChange:)]) {
        [self.delegate inputContentTextDidChange:growingTextView.text];
    }
}


@end
