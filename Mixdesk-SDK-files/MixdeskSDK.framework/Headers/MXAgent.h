//
//  MXAgent.h
//  MixdeskSDK
//
//  Created by dingnan on 15/10/23.
//  Copyright © 2015年 Mixdesk Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MXModel.h"

typedef enum : NSUInteger {
    MXAgentStatusOnline   = 0,  //客服在线
    MXAgentStatusHide     = 1   //客服隐身
} MXAgentStatus;

typedef enum : NSUInteger {
    MXAgentPrivilegeAdmin = 0,  //管理员
    MXAgentPrivilegeAgent = 1,  //客服
    MXAgentPrivilegeAiAgent = 2, // ai_agent => privilege: "bot:ai_agent"
    MXAgentPrivilegeNone  = 999   //None
} MXAgentPrivilege;

@interface MXAgent : MXModel <NSCopying>

/** 客服id */
@property (nonatomic, strong) NSString         *agentId;

/** 客服昵称 */
@property (nonatomic, copy  ) NSString         *nickname;

/** 权限 */
@property (nonatomic, assign) MXAgentPrivilege privilege;

/** 头像的URL */
@property (nonatomic, strong) NSString         *avatarPath;

/** 公开的手机号 */
@property (nonatomic, strong) NSString         *publicCellphone;

/** 个人手机号 */
@property (nonatomic, copy  ) NSString         *cellphone;

/** 座机号 */
@property (nonatomic, strong) NSString         *telephone;

/** 邮箱 */
@property (nonatomic, copy  ) NSString         *publicEmail;

/** QQ */
@property (nonatomic, copy  ) NSString         *qq;

/** 微信 */
@property (nonatomic, copy  ) NSString         *weixin;

/** 状态 */
@property (nonatomic, assign) MXAgentStatus    status;

/** 个人签名 */
@property (nonatomic, copy  ) NSString         *signature;

/** 是否在线 */
@property (nonatomic, assign) bool             isOnline;
/** agent 的 id,第一个agentId是 其token */ //18.4.2添加
@property (nonatomic, strong) NSNumber       *agentId_real;


/*
 该消息对应的 enterprise id, 不一定有值，也不存数据库，仅用来判断该消息属于哪个企业，用来切换数据库, 如果这个地方没有值，查看所属的 message 对象里面的 enterpriseId 字段
 */
@property (nonatomic, copy) NSString *enterpriseId;

// 转换 agent type
- (NSString *)convertPrivilegeToString;

@end
