//
//  MXAdviseFormSubmitViewController.m
//  Mixdesk-SDK-Demo
//
//  Created by ian luo on 16/6/29.
//  Copyright © 2016年 Mixdesk. All rights reserved.
//

#import "MXPreChatSubmitViewController.h"
#import "MXPreChatFormViewModel.h"
#import "UIView+MXLayout.h"
#import "NSArray+MXFunctional.h"
#import "MXPreChatCells.h"
#import "MXToast.h"
#import "MXAssetUtil.h"
#import "MXPreChatTopView.h"
#import "MXBundleUtil.h"

#pragma mark -
#pragma mark -

#define HEIGHT_SECTION_HEADER 40

@interface MXPreChatSubmitViewController ()

@property (nonatomic, strong) MXPreChatFormViewModel *viewModel;
@property (nonatomic, strong) MXPreChatTopView *topView;

@end

@implementation MXPreChatSubmitViewController

- (instancetype)init {
    if (self = [super initWithStyle:(UITableViewStyleGrouped)]) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (@available(iOS 13.0, *)) {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
    
    if ([self.navigationController.viewControllers firstObject] == self) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[MXAssetUtil backArrow] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    }
    
    self.title = @"请填写以下问题";
    
    self.viewModel = [MXPreChatFormViewModel new];
    self.viewModel.formData = self.formData;

    self.tableView.allowsMultipleSelection = YES;
    
    if (self.viewModel.formData.title.length > 0) {
        self.title = self.viewModel.formData.title;
    }
    
    [self.tableView registerClass:[MXPreChatMultiLineTextCell class] forCellReuseIdentifier:NSStringFromClass([MXPreChatMultiLineTextCell class])];
    [self.tableView registerClass:[MXPrechatSingleLineTextCell class] forCellReuseIdentifier:NSStringFromClass([MXPrechatSingleLineTextCell class])];
    [self.tableView registerClass:[MXPreChatSelectionCell class] forCellReuseIdentifier:NSStringFromClass([MXPreChatSelectionCell class])];
    [self.tableView registerClass:[MXPreChatCaptchaCell class] forCellReuseIdentifier:NSStringFromClass([MXPreChatCaptchaCell class])];
    [self.tableView registerClass:[MXPreChatSectionHeaderView class] forHeaderFooterViewReuseIdentifier:NSStringFromClass([MXPreChatSectionHeaderView class])];
    
    UIBarButtonItem *submit = [[UIBarButtonItem alloc] initWithTitle:[MXBundleUtil localizedStringForKey:@"submit"] style:(UIBarButtonItemStylePlain) target:self action:@selector(submitAction)];
    self.navigationItem.rightBarButtonItem = submit;
    
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)dismiss {
    if (self.cancelBlock) {
        self.cancelBlock();
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    MXPreChatSectionHeaderView *header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass([MXPreChatSectionHeaderView class])];
    
    header.viewSize = CGSizeMake(tableView.viewWidth, HEIGHT_SECTION_HEADER);
    header.viewOrigin = CGPointZero;
    header.formItem = self.viewModel.formData.form.formItems[section];
    
    if (self.viewModel.formData.content.length > 0 && section == 0) {
        UIView *view = [[UIView alloc] init];
        [view addSubview:self.topView];
        
        header.frame = CGRectMake(0, [self.topView getTopViewHeight] + 20 + [self getMarkTitleHeight], header.viewWidth, header.viewHeight);
        [view addSubview:header];
        
        return view;
    }
    
    return header;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    if (self.viewModel.formData.content.length > 0 && section == 0) {
        return HEIGHT_SECTION_HEADER + [self.topView getTopViewHeight] + 20 + [self getMarkTitleHeight];
    }
    return HEIGHT_SECTION_HEADER;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1; //means hide it
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MXPreChatFormItem *formItem = (MXPreChatFormItem *)self.viewModel.formData.form.formItems[indexPath.section];
    
    UITableViewCell *cell;
    __weak typeof(self) wself = self;
    switch (formItem.type) {
        case MXPreChatFormItemInputTypeSingleLineText:
        case MXPreChatFormItemInputTypeSingleLineDateText:
        case MXPreChatFormItemInputTypeSingleLineNumberText:
        {
            MXPrechatSingleLineTextCell *scell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(MXPrechatSingleLineTextCell.class) forIndexPath:indexPath];
            if (formItem.type == MXPreChatFormItemInputTypeSingleLineDateText) {
                scell.textField.keyboardType = UIKeyboardTypeDecimalPad;
            } else if (formItem.type == MXPreChatFormItemInputTypeSingleLineNumberText) {
                scell.textField.keyboardType = UIKeyboardTypeNumberPad;
            } else {
                scell.textField.keyboardType = [self.viewModel keyboardtypeForType:formItem.filedName];
            }
            
            //记录用户输入
            [scell setValueChangedAction:^(NSString *newString) {
                __strong typeof (wself) sself = wself;
                [sself.viewModel setValue:newString forFieldIndex:indexPath.section];
            }];
            scell.textField.text = [self.viewModel valueForFieldIndex:indexPath.section];
            cell = scell;
            break;
        }
        case MXPreCHatFormItemInputTypeMultipleLineText:
            cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(MXPreChatMultiLineTextCell.class) forIndexPath:indexPath];
            break;
        case MXPreChatFormItemInputTypeSingleSelection:
            cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(MXPreChatSelectionCell.class) forIndexPath:indexPath];
            if (![formItem.choices isEqual:[NSNull null]] && formItem.choices.count > 0) {
                cell.textLabel.text = formItem.choices[indexPath.row];
                [cell setSelected:([cell.textLabel.text isEqualToString:[self.viewModel valueForFieldIndex:indexPath.section]]) animated:NO];
            }
            break;
        case MXPreChatFormItemInputTypeMultipleSelection:
            cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(MXPreChatSelectionCell.class) forIndexPath:indexPath];
            cell.textLabel.text = formItem.choices[indexPath.row];
            
            if ([[self.viewModel valueForFieldIndex:indexPath.section] respondsToSelector:@selector(containsObject:)]) {
                [cell setSelected:[[self.viewModel valueForFieldIndex:indexPath.section] containsObject:cell.textLabel.text] animated:NO];
            }
            break;
        case MXPreChatFormItemInputTypeCaptcha:{
            MXPreChatCaptchaCell *ccell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(MXPreChatCaptchaCell.class) forIndexPath:indexPath];
            ccell.textField.text = [self.viewModel valueForFieldIndex:indexPath.section];
            //刷新验证码
            ccell.loadCaptchaAction = ^(UIButton *button){
                __strong typeof (wself) sself = wself;
                [sself.viewModel requestCaptchaComplete:^(UIImage *image) {
                    [button setImage:image forState:(UIControlStateNormal)];
                }];
            };
            
            //记录用户输入
            [ccell setValueChangedAction:^(NSString *newString) {
                __strong typeof (wself) sself = wself;
                [sself.viewModel setValue:newString forFieldIndex:indexPath.section];
            }];
            
            //cell 第一次出现后自动加载图片
            if ([self.viewModel.captchaToken length] == 0) {
                [self.viewModel requestCaptchaComplete:^(UIImage *image) {
                    [ccell.refreshCapchaButton setImage:image forState:UIControlStateNormal];
                }];
            }
            
            cell = ccell;
        }
            break;
    }
    
    
    
    return cell;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.tableView endEditing:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.viewModel.formData.form.formItems[section] choices] count] ?: 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView endEditing:YES];
    
    MXPreChatFormItem *formItem = (MXPreChatFormItem *)self.viewModel.formData.form.formItems[indexPath.section];
    
    if (formItem.type == MXPreChatFormItemInputTypeSingleSelection) {
        [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:(UITableViewScrollPositionNone)];
        [self.viewModel setValue:formItem.choices[indexPath.row] forFieldIndex:indexPath.section];
    }else if (formItem.type == MXPreChatFormItemInputTypeMultipleSelection) {
        [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:(UITableViewScrollPositionNone)];
        
        NSArray *selectedRowsInCurrentSection = [[[tableView indexPathsForSelectedRows] filter:^BOOL(NSIndexPath *i) {
            return i.section == indexPath.section;
        }] map:^id(NSIndexPath *i) {
            return formItem.choices[i.row];
        }];
        [self.viewModel setValue:selectedRowsInCurrentSection forFieldIndex:indexPath.section];
    }
    
    if (formItem.type != MXPreChatFormItemInputTypeMultipleSelection) {
        for (int i = 0; i < [[formItem choices] count]; i++) {
            if (i != indexPath.row) {
                [tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:indexPath.section] animated:NO];
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView endEditing:YES];
    
    NSArray *selectedRowsInCurrentSection = [[[tableView indexPathsForSelectedRows] filter:^BOOL(NSIndexPath *i) {
        return i.section == indexPath.section;
    }] map:^id(NSIndexPath *i) {
        return @(i.row);
    }];
    [self.viewModel setValue:selectedRowsInCurrentSection.count > 0 ? selectedRowsInCurrentSection : nil forFieldIndex:indexPath.section];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.viewModel.formData.form.formItems.count;
}

- (void)submitAction {
    __weak typeof(self) wself = self;
    
    [self showLoadingIndicator];
    NSArray *unsatisfiedSectionIndexs = [self.viewModel submitFormCompletion:^(id response, NSError *e) {
        __strong typeof (wself) sself = wself;
        [sself hideLoadingIndicator];
        if (e == nil) {
            [sself dismissViewControllerAnimated:YES completion:^{
                
                if (sself.completeBlock) {
                    sself.completeBlock([sself createUserInfo]);
                    //成功提交表单后的回调 ,此时保存 _hasSubmittedFormLocalBool
                    [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"hasSubmittedFormLocalBool"];
                    [[NSUserDefaults standardUserDefaults]synchronize];
                    
                }
            }];
        } else {
            if (e.code != 1) {
                [self resetCaptchaCellIfExists];
            }
            
            [MXToast showToast:e.domain duration:2 window:[UIApplication sharedApplication].keyWindow];
        }
    }];
    
    for (int i = 0; i < self.viewModel.formData.form.formItems.count; i ++) {
        MXPreChatSectionHeaderView *header = (MXPreChatSectionHeaderView *)[self.tableView headerViewForSection:i];
        [header setStatus:![unsatisfiedSectionIndexs containsObject:@(i)]];
    }
}

static UIBarButtonItem *rightBarButtonItemCache = nil;

- (void)showLoadingIndicator {
    [self.view endEditing:true];
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyleGray)];
    rightBarButtonItemCache = self.navigationItem.rightBarButtonItem;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:indicator];
    [indicator startAnimating];
}

- (void)hideLoadingIndicator {
    self.navigationItem.rightBarButtonItem = rightBarButtonItemCache;
}

- (void)resetCaptchaCellIfExists {
    if (self.viewModel.formData.isUseCapcha) {
        [self.viewModel requestCaptchaComplete:^(UIImage *image) {
            MXPreChatCaptchaCell *captchaCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:self.viewModel.formData.form.formItems.count - 1]];
            if ([captchaCell isKindOfClass:[MXPreChatCaptchaCell class]]) {
                captchaCell.textField.text = @"";
                [self.viewModel setValue:nil forFieldIndex:self.viewModel.formData.form.formItems.count - 1];
                [captchaCell.refreshCapchaButton setImage:image forState:UIControlStateNormal];
            }
        }];
    }
}

//
- (NSDictionary *)createUserInfo {
    if (self.selectedMenuItem) {
        NSString *target = self.selectedMenuItem.target;
        NSString *targetType = self.selectedMenuItem.targetKind;
        return @{@"target":target, @"targetType":targetType, @"menu":[self.selectedMenuItem desc]};
    } else {
        return nil;
    }
}

- (MXPreChatTopView *)topView {
    if (!_topView) {
        CGFloat horizontalSpacing = 10.0;
        
//        CGFloat headerMaxWidth = self.tableView.viewWidth - horizontalSpacing * 2;
//        CGSize textSize = CGSizeMake(headerMaxWidth, MAXFLOAT);
//        CGRect textRect = [self.viewModel.formData.menu.title boundingRectWithSize:textSize
//                                                     options:NSStringDrawingUsesLineFragmentOrigin
//                                                  attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium]}
//                                                     context:nil];
        
        _topView = [[MXPreChatTopView alloc] initWithHTMLText:self.viewModel.formData.content maxWidth:[self headerMaxWidth]];
        _topView.frame = CGRectMake(horizontalSpacing, 0, [self headerMaxWidth], [_topView getTopViewHeight] + 20 + [self getMarkTitleHeight]);
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, [_topView getTopViewHeight] + 10, [self headerMaxWidth], [self getMarkTitleHeight])];
        titleLabel.text = self.viewModel.formData.form.title;
        titleLabel.textColor = [UIColor mx_colorWithHexString:ebonyClay];
        titleLabel.font = [UIFont systemFontOfSize:16 weight: UIFontWeightMedium];
        [_topView addSubview:titleLabel];
    }
    return _topView;
}

- (CGFloat)getMarkTitleHeight {
    CGFloat headerMaxWidth = [self headerMaxWidth]; //self.tableView.viewWidth - 10 * 2;
    CGSize textSize = CGSizeMake(headerMaxWidth, MAXFLOAT);
    CGRect textRect = [self.viewModel.formData.menu.title boundingRectWithSize:textSize
                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                              attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium]}
                                                 context:nil];
    return textRect.size.height;
}

- (CGFloat)headerMaxWidth {
    CGFloat horizontalSpacing = 10.0;
    return self.tableView.viewWidth - horizontalSpacing * 2;
}

@end
