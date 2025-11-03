---
layout: docs_show
title: 移动应用 SDK for iOS
permalink: /docs/mixdesk-ios-sdk/
edition: m2025
---

#MixdeskSDK [![](https://travis-ci.org/Meiqia/MeiqiaSDK-iOS.svg?branch=master)]() [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![GitHub release](https://img.shields.io/github/v/release/Mixdesk/MixdeskSDK-iOS)](https://github.com/Mixdesk/MixdeskSDK-iOS/releases)

> 在您阅读此文档之前，我们假定您已经具备了基础的 iOS 应用开发经验，并能够理解相关基础概念。

> 请您首先把文档全部仔细阅读完毕,再进行您的开发

* [一 导入MixdeskSDK](#一导入MixdeskSDK)
* [二 开始你的集成之旅](#二开始你的集成之旅)
* [三 SDK工作流程](#三SDK工作流程)
* [四 SDK工作流程](#四SDK工作流程)
* [五 Mixdesk API 接口介绍](#五接口介绍)
* [六 SDK中嵌入MixdeskSDK](#六SDK中嵌入MixdeskSDK)
* [七 名词解释](#七名词解释)
* [八 常见问题](#八常见问题)
* [九 更新日志](#九更新日志)

>进行您的开发之前,请您一定下载我们的[官方Demo](https://github.com/Mixdesk/MixdeskSDK-iOS),参考我们的使用方法.

>'墙裂'建议开发者使用最新的版本。

- 请查看[Mixdesk在Github上的网页](https://github.com/Mixdesk/MixdeskSDK-iOS/releases) ，确认最新的版本号。
- Demo开发者功能 ->点击查看当前SDK版本号
- 查看SDK中MixdeskManager.h类中 **#define MixdeskSDKVersion **
- pod search Mixdesk(此方法由于本地pod缓存,导致获取不到最新的)

# 一 导入MixdeskSDK

 **推荐你使用CocoaPods导入我们的SDK,原因如下:**

- 后期 sdk更新会很方便.
- 手动更新你需要删除旧库,下载新库,再重新配置等很麻烦,且由于删除旧库时未删除干净,再迁入新库时会导致很多莫名其妙的问题. 
- Swift项目已经完美支持CocoPods

##1.1  CocoaPods 导入

在 Podfile 中加入：

```
pod 'Mixdesk', '~> 1.0.2'
```
接着安装Mixdesk pod 即可：

```
$ pod install
```

## 1.2 手动导入MixdeskSDK
###1.2.1 导入到OC 项目
打开下载到本地的文件, 找到MixdeskSDK-files文件夹下的 `MixdeskSDK.framework` 、 `MixdeskChatViewController` 、 `MixdeskSDKViewInterface` 、`MixdeskNotification`,将这四个文件夹拷贝到新创建的工程路径下面，然后在工程目录结构中，右键选择 *Add Files to “工程名”* 。或者直接拖入 Xcode 工程目录结构中。

###1.2.2  导入到Swift 项目

* 按照上面的方法引入Mixdesk SDK 的文件。
* 在 Bridging Header 头文件中，‘#import <MixdeskSDK/MixdeskManager.h>’、'#import "MixdeskChatViewManager.h"'。注：[如何添加 Bridging Header](http://bencoding.com/2015/04/15/adding-a-swift-bridge-header-manually/)。

###1.2.3 引入依赖库

Mixdesk SDK 的实现，依赖了一些系统框架，在开发应用时，要在工程里加入这些框架。开发者首先点击工程右边的工程名,然后在工程名右边依次选择 *TARGETS* -> *BuiLd Phases* -> *Link Binary With Libraries*，展开 *LinkBinary With Libraries* 后点击展开后下面的 *+* 来添加下面的依赖项:

- libsqlite3.tbd
- libicucore.tbd
- AVFoundation.framework
- CoreTelephony.framework
- SystemConfiguration.framework
- MobileCoreServices.framework
- QuickLook.framework

# 二 开始你的集成之旅
>如果导入sdk到你的工程没有问题,接下来只需5步就ok了,能满足一般的需求.

```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#pragma mark  集成第一步: 初始化,  参数:appkey  ,尽可能早的初始化appkey.
    [MXManager initWithAppkey:@"" completion:^(NSString *clientId, NSError *error) {
        if (!error) {
            // 这里可以开启SDK的群发功能, 注意需要在SDK初始化成功以后调用
            // [[MXNotificationManager sharedManager] openMXGroupNotificationServer];
            NSLog(@"Mixdesk SDK：初始化成功");
        } else {
            NSLog(@"error:%@",error);
        }
    }];
  /*你自己的代码*/
    return YES;
}
- (void)applicationWillEnterForeground:(UIApplication *)application {
    #pragma mark  集成第二步: 进入前台 打开Mixdesk服务
    [MXManager openMixdeskService];
}
- (void)applicationDidEnterBackground:(UIApplication *)application {
    #pragma mark  集成第三步: 进入后台 关闭Mixdesk服务
    [MXManager closeMixdeskService];
}
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    #pragma mark  集成第四步: 上传设备deviceToken
    [MXManager registerDeviceToken:deviceToken];
}

#pragma mark  集成第五步: 跳转到聊天界面(button的点击方法)
- (void)pushToMixdeskVC:(UIButton *)button {
#pragma mark 总之, 要自定义UI层  请参考 MXChatViewStyle.h类中的相关的方法 ,要修改逻辑相关的 请参考MXChatViewManager.h中相关的方法
    
#pragma mark  最简单的集成方法: 全部使用Mixdesk的,  不做任何自定义UI.
    MXChatViewManager *chatViewManager = [[MXChatViewManager alloc] init];
    [chatViewManager setoutgoingDefaultAvatarImage:[UIImage imageNamed:@"mixdesk-icon"]];
    [chatViewManager pushMXChatViewControllerInViewController:self];
#pragma mark  觉得返回按钮系统的太丑 想自定义 采用下面的方法
//    MXChatViewManager *chatViewManager = [[MXChatViewManager alloc] init];
//    MXChatViewStyle *aStyle = [chatViewManager chatViewStyle];
//    [aStyle setNavBarTintColor:[UIColor redColor]];
//    [aStyle setNavBackButtonImage:[UIImage imageNamed:@"mixdesk-icon"]];
//    [chatViewManager pushMXChatViewControllerInViewController:self];
#pragma mark 觉得头像 方形不好看 ,设置为圆形.
//    MXChatViewManager *chatViewManager = [[MXChatViewManager alloc] init];
//    MXChatViewStyle *aStyle = [chatViewManager chatViewStyle];
//    [aStyle setEnableRoundAvatar:YES];
//    [aStyle setEnableOutgoingAvatar:NO]; //不显示用户头像
//    [aStyle setEnableIncomingAvatar:NO]; //不显示客服头像
//    [chatViewManager pushMXChatViewControllerInViewController:self];
#pragma mark 导航栏 右按钮 想自定义 ,但是不到万不得已,不推荐使用这个,会造成mixdesk功能的缺失,因为这个按钮 1 当你在工作台打开机器人开关后 显示转人工,点击转为人工客服. 2在人工客服时 还可以评价客服
//    MXChatViewManager *chatViewManager = [[MXChatViewManager alloc] init];
//    MXChatViewStyle *aStyle = [chatViewManager chatViewStyle];
//    UIButton *bt = [UIButton buttonWithType:UIButtonTypeCustom];
//    [bt setImage:[UIImage imageNamed:@"mixdesk-icon"] forState:UIControlStateNormal];
//    [aStyle setNavBarRightButton:bt];
//    [chatViewManager pushMXChatViewControllerInViewController:self];
#pragma mark 客户自定义信息
//    MXChatViewManager *chatViewManager = [[MXChatViewManager alloc] init];
////    [chatViewManager setClientInfo:@{@"name":@"123测试",@"gender":@"man11",@"age":@"100"} override:YES];
//    [chatViewManager setClientInfo:@{@"name":@"123测试",@"gender":@"man11",@"age":@"100"}];
//    [chatViewManager pushMXChatViewControllerInViewController:self];

#pragma mark 预发送消息
//    MXChatViewManager *chatViewManager = [[MXChatViewManager alloc] init];
//    [chatViewManager setPreSendMessages: @[@"我想咨询的订单号：【1705045496811】"]];
//    [chatViewManager pushMXChatViewControllerInViewController:self];
    
#pragma mark 如果你想绑定自己的用户系统 ,当然推荐你使用 客户自定义信息来绑定用户的相关个人信息
#pragma mark 切记切记切记  一定要确保 customId 是唯一的,这样保证  customId和mixdesk生成的用户ID是一对一的
//    MXChatViewManager *chatViewManager = [[MXChatViewManager alloc] init];
//    NSString *customId = @"获取你们自己的用户ID 或 其他唯一标识的";
//    if (customId){
//        [chatViewManager setLoginCustomizedId:customId];
//    }else{
//   #pragma mark 切记切记切记 下面这一行是错误的写法 , 这样会导致 ID = "notadda" 和 mixdesk多个用户绑定,最终导致 对话内容错乱 A客户能看到 B C D的客户的对话内容
//        //[chatViewManager setLoginCustomizedId:@"notadda"];
//    }
//    [chatViewManager pushMXChatViewControllerInViewController:self];
}

```

>请保证自己的集成代码和上述代码一致,请保证自己的集成代码和上述代码一致,请保证自己的集成代码和上述代码一致,重要的事情说三遍!!!

# 三 说好的推送呢

当前仅支持一种推送方案，当APP切换到后台时,mixdesk服务端发送消息至开发者的服务端，开发者再通过极光等第三方推送推送消息到 App，可见 [SDK 工作流程](#SDK工作流程) 。

设置服务器地址，请使用mixdesk管理员帐号登录 [mixdesk](http://app.mixdesk.com)，在「设置」 -\> 「SDK」中设置。

![设置推送地址](https://github.com/Mixdesk/MixdeskSDK-iOS/blob/master/resources/img/1667446550675.png)

### 推送消息数据结构

当有消息需要推送时，mixdesk服务器会向开发者设置的服务器地址发送推送消息，方法类型为 *POST*，数据格式为 *JSON* 。

发送的请求格式介绍：

request.header.authorization 为数据签名。

request.body 为消息数据，数据结构为：

|Key|说明|
|---|---|
|id|消息 id|
|messageId|当前对话的会话 id|
|content|消息内容|
|messageTime|发送时间|
|fromName|发送人姓名|
|deviceToken|发送对象设备的 deviceToken，格式为字符串|
|clientId|发送对象的联系人 id|
|customizedId|开发者传的自定义 id|
|contentType|消息内容类型 - text/photo/audio|
|deviceOS|设备系统|
|customizedData|开发者上传的自定义的属性|
|type|消息类型 - mesage 普通消息 / ending 结束消息|

开发者可以根据请求中的签名，对推送消息进行数据验证，Mixdesk提供了 `Java、Python、Ruby、JavaScript、PHP` 5种语言的计算签名的代码，具体请移步 [Mixdesk SDK 1.0 推送的数据结构签名算法](https://github.com/Mixdesk/MixdeskSDK-Push-Signature-Example)。

#至此,集成结束.

# 四 SDK工作流程

mixdesk SDK 的工作流程如下图所示。

![SDK工作流程图](https://github.com/Mixdesk/MixdeskSDK-iOS/blob/master/resources/img/SDK-FlowChart.png)


**注意：**
* 如果开发者对 mixdesk 的开源界面进行了定制，最好 Fork 一份 github 上的代码。这以后 mixdesk 对开源界面进行了更新，开发者只需 merge mixdesk 的代码，就可以免去定制后更新的麻烦。



# 五 接口介绍

##初始化sdk
所有操作都必须在初始化 SDK ，并且 mixdesk 服务端返回可用的 clientId 后才能正常执行。

开发者在 mixdesk 工作台注册 App 后，可获取到一个可用的 AppKey。在 `AppDelegate.m` 的系统回调 `didFinishLaunchingWithOptions` 中调用初始化 SDK 接口：

```objc
[MXManager initWithAppkey:@"开发者注册的App的AppKey" completion:^(NSString *clientId, NSError *error) {
}];
```

如果您不知道 *AppKey* ，请使用 mixdesk 管理员帐号登录 [mixdesk](http://www.mixdesk.com)，在「设置」 -> 「SDK」 菜单中查看。如下图：

![mixdesk AppKey 查看界面图片](https://github.com/Mixdesk/MixdeskSDK-iOS/blob/master/resources/img/1667446646061.png)


## 添加自定义信息

功能效果展示：
![mixdesk工作台联系人自定义信息图片](https://github.com/Mixdesk/MixdeskSDK-iOS/blob/master/resources/img/1667446854328.png)

为了让客服能更准确帮助用户，开发者可上传不同用户的属性信息。示例如下：

```objc
//创建自定义信息
NSDictionary* clientCustomizedAttrs = @{
@"name"        : @"Kobe Bryant"
};

/**
 *  设置联系人的自定义信息
 *
 *  @param clientInfo 联系人的自定义信息
    @param override 是否强制更新，如果不设置此值为 YES，设置只有第一次有效。
 */
[chatViewManager setClientInfo:clientCustomizedAttrs override:YES];
或者
[MXManager setClientInfo:clientCustomizedAttrs completion:^(BOOL success) {
}];
```

以下字段是Mixdesk定义好的，开发者可通过上方提到的接口，直接对下方的字段进行设置：

|Key|说明|
|---|---|
|name|真实姓名|
|tel|电话|
|email|邮件|
|comment|备注|

**注意**
* 开启自定义响应事件以后，需要自己通过监听通知来处理响应事件，否则点击群发消息以后会没有反应。

**注意**
* 该选项需要在用户上线前设置。

![查看ID](https://github.com/Mixdesk/MixdeskSDK-iOS/blob/master/resources/img/1667446915131.png)


## 调出视图

你只需要在用户需要客服服务的时候，调出Mixdesk UI。如下所示：

```objc
MXChatViewManager *chatViewManager = [[MXChatViewManager alloc] init];
[chatViewManager pushMXChatViewControllerInViewController:self];
```

`MXServiceToViewInterface` 文件是开源聊天界面调用Mixdesk SDK 接口的中间层，目的是剥离开源界面中的Mixdesk业务逻辑。这样就能让该聊天界面用于非Mixdesk项目中，开发者只需要实现 `MXServiceToViewInterface` 中的方法，即可将自己项目的业务逻辑和该聊天界面对接。

## 开启同步服务端消息设置

如果开启消息同步，在聊天界面中下拉刷新，将会获取服务端的历史消息；

如果关闭消息同步，则是获取本机数据库中的历史消息；

由于联系人可能在多设备聊天，关闭消息同步后获取的历史消息，将可能少于服务端的历史消息。

```objc
MXChatViewManager *chatViewManager = [[MXChatViewManager alloc] init];
//开启同步消息
[chatViewManager enableSyncServerMessage:true];
[chatViewManager pushMXChatViewControllerInViewController:self];
```

### 设置登录客服的联系人 id

设置 mixdesk 联系人的 id 后，该id对应的联系人将会上线。

```objc
MXChatViewManager *chatViewManager = [[MXChatViewManager alloc] init];
[chatViewManager setLoginMXClientId:clientId];
[chatViewManager pushMXChatViewControllerInViewController:self];
```

**注意**，如果 mixdesk 服务端没有找到该联系人 id 对应的联系人，则会返回`该联系人不存在`的错误。

开发者需要获取 clientId，可使用接口`[MXManager getCurrentClientId]`。



### 真机调试时,语言没有切换为中文

为了能正常识别App的系统语言，开发者的 App 的 info.plist 中需要有添加 Localizations 配置。如果需要支持英文、简体中文、繁体中文，info.plist 的 Souce Code 中需要有如下配置：

```
<key>CFBundleLocalizations</key>
<array>
    <string>zh_CN</string>
    <string>zh_TW</string>
    <string>en</string>
</array>
```

开源聊天界面的更多配置，可参见 [MXChatViewManager.h](https://github.com/Mixdesk/MixdeskSDK-iOS/blob/master/Mixdesk-SDK-files/MXChatViewController/Config/MXChatViewManager.h) 文件。

# 六 SDK中嵌入MixdeskSDK

**本节主要介绍部分重要的接口。在`MixdeskSDK.framework`的`MXManager.h`中，所有接口都有详细注释。**

开发者可使用 mixdesk 提供的 API，自行定制聊天界面。使用以下接口前，别忘了 [初始化 SDK](#初始化-sdk)。


## 接口描述

### 初始化SDK

mixdesk建议开发者在 `AppDelegate.m` 的系统回调 `didFinishLaunchingWithOptions` 中，调用初始化 SDK 接口。这是因为第一次初始化 mixdesk SDK，SDK 会向 mixdesk 服务端发送一个初始化联系人的请求，SDK 其他接口都必须是在初始化 SDK 成功后进行，所以 App 应尽早初始化 SDK 。

```objc
//建议在AppDelegate.m系统回调didFinishLaunchingWithOptions中增加
[MXManager initWithAppkey:@"开发者注册的App的AppKey" completion:^(NSString *clientId, NSError *error) {
}];
```

### 注册设备的 deviceToken

mixdesk需要获取每个设备的 deviceToken，才能在 App 进入后台以后，推送消息给开发者的服务端。消息数据中有 deviceToken 字段，开发者获取到后，可通知 APNS 推送给该设备。

在 AppDelegate.m中的系统回调 `didRegisterForRemoteNotificationsWithDeviceToken` 中，调用上传 deviceToken 接口：

```objc
[MXManager registerDeviceToken:deviceToken];
```

### 关闭 mixdesk 推送

详细介绍请见 [消息推送](#三说好的推送呢)。

### 让当前的联系人上线。

初始化 SDK 成功后，SDK 中有一个可使用的联系人 id，调用该接口即可让其上线，如下代码：

```objc
[MXManager setCurrentClientOnlineWithCompletion:^(MXClientOnlineResult result, MXAgent *agent, NSArray<MXMessage *> *messages) {
//可根据result来判断是否上线成功
} receiveMessageDelegate:self];
```


### 根据 mixdesk 的联系人 id，登陆 mixdesk 客服系统，并上线该联系人。

开发者可通过 [获取当前联系人 id](#获取当前联系人-id) 接口，取得联系人 id ，保存到开发者的服务端，以此来绑定 mixdesk 联系人和开发者用户系统。
如果开发者保存了 mixdesk 的联系人 id，可调用如下接口让其上线。调用此接口后，当前可用的联系人即为开发者传的联系人 id。

```objc
[MXManager setClientOnlineWithClientId:clientId completion:^(MXClientOnlineResult result, MXAgent *agent, NSArray<MXMessage *> *messages) {
//可根据result来判断是否上线成功
} receiveMessageDelegate:self];
```


### 根据开发者自定义的 id，登陆 mixdesk 客服系统，并上线该联系人。

如果开发者不愿保存 mixdesk 联系人 id，来绑定自己的用户系统，也将用户 id当做参数，进行联系人的上线，mixdesk将会为开发者绑定一个联系人，下次开发者直接调用如下接口，就能让这个绑定的联系人上线。

调用此接口后，当前可用的联系人即为该自定义 id 对应的联系人 id。

**特别注意：**传给 mixdesk 的自定义 id 不能为自增长的，否则非常容易受到中间人攻击，此情况的开发者建议保存 mixdesk 联系人 id。

```objc
[MXManager setClientOnlineWithCustomizedId:customizedId completion:^(MXClientOnlineResult result, MXAgent *agent, NSArray<MXMessage *> *messages) {
//可根据result来判断是否上线成功
} receiveMessageDelegate:self];
```

### 监听联系人上线成功后的广播

开发者可监听联系人上线成功的广播，在上线成功后，可上传该联系人的自定义信息等操作。广播的名字为 `MX_CLIENT_ONLINE_SUCCESS_NOTIFICATION`，定义在 [MXDefinition.h](https://github.com/Mixdesk/MixdeskSDK-iOS/blob/master/Mixdesk-SDK-Demo/MixdeskSDK.framework/Headers/MXDefinition.h) 中。

### 获取当前联系人 id

开发者可通过此接口接口，取得联系人 id，保存到开发者的服务端，以此来绑定 mixdesk 联系人和开发者用户系统。

```objc
NSString *clientId = [MXManager getCurrentClientId];
```


### 创建一个新的联系人

如果开发者想初始化一个新的联系人，可调用此接口。

该联系人没有任何历史记录及用户信息。

开发者可选择将该 id 保存并与 App 的用户绑定。

```objc
[MXManager createClient:^(BOOL success, NSString *clientId) {
//开发者可保存该clientId
}];
```


### 设置联系人离线

```objc
NSString *clientId = [MXManager setClientOffline];
```

如果没有设置联系人离线，开发者设置的代理将收到即时消息，并收到新消息产生的广播。开发者可以监听此 notification，用于显示小红点未读标记。

如果设置了联系人离线，则客服发送的消息将会发送给开发者的服务端。

`Mixdesk建议`，联系人退出聊天界面时，不设置联系人离线，这样开发者仍能监听到收到消息的广播，以便提醒联系人有新消息。


### 监听收到消息的广播

开发者可在合适的地方，监听收到消息的广播，用于提醒联系人有新消息。广播的名字为 `MX_RECEIVED_NEW_MESSAGES_NOTIFICATION`，定义在 [MXDefinition.h](https://github.com/Mixdesk/MixdeskSDK-iOS/blob/master/Mixdesk-SDK-Demo/MixdeskSDK.framework/Headers/MXDefinition.h) 中。

开发者可获取广播中的userInfo，来获取收到的消息数组，数组中是Mixdesk消息 [MXMessage](https://github.com/Mixdesk/MixdeskSDK-iOS/blob/master/Mixdesk-SDK-Demo/MixdeskSDK.framework/Headers/MXMessage.h) 实体，例如：`[notification.userInfo objectForKey:@"messages"]`

**注意**，如果联系人退出聊天界面，开发者没有调用设置联系人离线接口的话，以后该联系人收到新消息，仍能收到`有新消息的广播`。

``` 
### 在合适的地方监听有新消息的广播
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNewMXMessages:) name:MX_RECEIVED_NEW_MESSAGES_NOTIFICATION object:nil];

### 监听收到Mixdesk聊天消息的广播
- (void)didReceiveNewMXMessages:(NSNotification *)notification {
//广播中的消息数组
NSArray *messages = [notification.userInfo objectForKey:@"messages"];
NSLog(@"监听到了收到客服消息的广播");
}

```

### 获取当前正在接待的客服信息

开发者可用此接口获取当前正在接待联系人的客服信息：

```
MXAgent *agent = [MXManager getCurrentAgent];
```


### 添加自定义信息

添加自定义信息操作和上述相同，跳至 [添加自定义信息](#添加自定义信息)。


### 从服务端获取更多消息

开发者可用此接口获取服务端的历史消息：

```objc
[MXManager getServerHistoryMessagesWithUTCMsgDate:firstMessageDate messagesNumber:messageNumber success:^(NSArray<MXMessage *> *messagesArray) {
//显示获取到的消息等逻辑
} failure:^(NSError *error) {
//进行错误处理
}];
```

**注意**，服务端的历史消息是该联系人在**所有平台上**产生的消息，包括网页端、Android SDK、iOS可在聊天界面的下拉刷新处调用。


### 从本地数据库获取历史消息

由于使用 [从服务端获取更多消息](#从服务端获取更多消息)接口，会产生数据流量，开发者也可使用此接口来获取 iOS SDK 本地的历史消息。

```objc
[MXManager getDatabaseHistoryMessagesWithMsgDate:firstMessageDate messagesNumber:messageNumber result:^(NSArray<MXMessage *> *messagesArray) {
//显示获取到的消息等逻辑
}];
```

**注意**，由于没有同步服务端的消息，所以本地数据库的历史消息有可能少于服务端的消息。

### 接收即时消息

开发者可能注意到了，使用上面提到的3个联系人上线接口，都有一个参数是`设置接收消息的代理`，开发者可在此设置接收消息的代理，由代理来接收消息。

设置代理后，实现 `MXManagerDelegate` 中的 `didReceiveMXMessage:` 方法，即可通过这个代理函数接收消息。


### 发送消息

开发者调用此接口来发送**文字消息**：

```objc
[MXManager sendTextMessageWithContent:content completion:^(MXMessage *sendedMessage) {
//消息发送成功后的处理
}];
```

开发者调用此接口来发送**图片消息**：

```objc
[MXManager sendImageMessageWithImage:image completion:^(MXMessage *sendedMessage) {
//消息发送成功后的处理
}];
```

开发者调用此接口来发送**语音消息**：

```objc
[MXManager sendAudioMessage:audioData completion:^(MXMessage *sendedMessage, NSError *error) {
//消息发送成功后的处理
}];
```

开发者调用此接口来发送**视频消息**：

```objc
[MXManager sendVideoMessage:filePath completion:^(MXMessage *sendedMessage, NSError *error) {
//消息发送成功后的处理
}];
```

**注意**，调用发送消息接口后，回调中会返回一个消息实体，开发者可根据此消息的状态，来判断该条消息是发送成功还是发送失败。

### 获取未读消息数

开发者使用此接口来统一获取所有的未读消息，用户可以在需要显示未读消息数是调用此接口，此接口会自动判断并合并本地和服务器上的未读消息，当用户进入聊天界面后，未读消息将会清零。
`[MXManager getUnreadMessagesWithCompletion:completion]`

### 获取自定义 id 未读消息

开发者使用此接口来统一获取自定义 id 所有的未读消息
`[MXManager getUnreadMessagesWithCustomizedId:customizedId completion:completion]`

###录音和播放录音

录音和播放录音分别包含 3 种可配置的模式：
- 暂停其他音频
- 和其他音频同时播放
- 降低其他音频声音

用户可以根据情况选择，在 `MXChatViewManager.h` 中直接配置以下两个属性：

`@property (nonatomic, assign) MXPlayMode playMode;`

`@property (nonatomic, assign) MXRecordMode recordMode;`

如果宿主应用本身也有声音播放，比如游戏，为了不影响背景音乐播放，可以设置 `@property (nonatomic, assign) BOOL keepAudioSessionActive;` 为 `YES` 这样就不会再完成播放和录音之后关闭 AudioSession，从而不会影响背景音乐。

**注意，游戏中，要将声音播放的 category 设置为 play and record，否则会导致录音之后无法播放声音。**


### 预发送消息

在 `MXChatViewManager.h` 中， 通过设置 `@property (nonatomic, strong) NSArray *preSendMessages;` 来让客户显示聊天窗口的时候，自动向客服发送消息，支持文字和图片。

### 监听聊天界面显示和消失

* `MX_NOTIFICATION_CHAT_BEGIN` 在聊天界面出现的时候发送
* `MX_NOTIFICATION_CHAT_END` 在聊天界面消失时发送


### 用户排队

监听消息:
当用户被客服接入时，会受到 `MX_NOTIFICATION_QUEUEING_END` 通知。


# 六  SDK 中嵌入Mixdesk SDK
如果你的开发项目也是 SDK，那么在了解常规 App 嵌入Mixdesk SDK 的基础上，还需要注意其他事项。

与 App 嵌入Mixdesk SDK 的步骤相同，需要 导入Mixdesk SDK -\> 引入依赖库 -\> 初始化 SDK -\> 使用Mixdesk SDK。

如果开发者使用了Mixdesk提供的聊天界面，还需要公开素材包：

开发者点击工程右边的工程名,然后在工程名右边依次选择 *TARGETS* -\> *BuiLd Phases* -\> *Copy Files* ，展开 *Copy Files* 后点击展开后下面的 *+* 来添加Mixdesk素材包 `MXChatViewAsset.bundle`。

在之后发布你的 SDK 时，将 `MXChatViewAsset.bundle` 一起打包即可。


# 七 名词解释

### 开发者的推送消息服务器

目前Mixdesk是把 SDK 的 `离线消息` 通过 webhook 形式发送给 - 开发者提供的 URL。

接收Mixdesk SDK 离线消息的服务器即为 `开发者的推送消息服务器`。

### Mixdesk联系人 id

Mixdesk SDK 在上线后（或称为分配对话后），均有一个唯一 id。

开发者可保存此 id，在其他设备上进行上线操作。这样此 id 的联系人信息和历史对话，都会同步到其他设备。

### 开发者自定义 id

即开发者自己定义的 id，例如开发者账号系统下的 user_id。

开发者可用此 id 进行上线，上线成功后，此 id 会绑定一个 `Mixdesk联系人 id`。开发者在其他设备用自己的 id 上线后，可以同步之前的数据。

**注意**，如果开发者自己的 id 过于简单（例如自增长的数字），安全起见，建议开发者保存 `Mixdesk联系人 id`，来进行上线操作。


# 八 常见问题
- [更新SDK](#更新SDK)
- [iOS 11下 SDK 的聊天界面底部输入框出现绿色条状,且无法输入](#ios11下sdk的聊天界面底部输入框出现绿色条状,且无法输入)
- [SDK 初始化失败](#sdk-初始化失败)
- [没有显示 导航栏栏/UINavgationBar](#没有显示-导航栏栏uinavgationbar)
- [Xcode Warning: was built for newer iOS version (7.0) than being linked (6.0)](#xcode-warning-was-built-for-newer-ios-version-70-than-being-linked-60)
- [Mixdesk静态库的文件大小太大](#Mixdesk静态库的文件大小太大)
- [使用 TabBarController 后，输入框高度出现异常](#使用-tabbarcontroller-后inputbar-高度出现异常)
- [键盘弹起后输入框和键盘之间有偏移](#键盘弹起后输入框和键盘之间有偏移)
- [如何得到客服 id 或客服分组 id](#如何得到客服id或客服分组id)
- [如何在聊天界面之外监听新消息的通知](#如何在聊天界面之外监听新消息的通知)
- [第三方库冲突](#第三方库冲突)
- [工作台联系人信息显示应用的名称不正确](#工作台联系人信息显示应用的名称不正确)
- [编译中出现 undefined symbols](#编译中出现-undefined-symbols)

## 更新SDK
### 1.pod集成的用户
  
  直接在工程中修改 podfile里面 mixdesk 的版本号为最新的版本号,然后 终端 cd到项目工程目录下,执行 **pod update mixdesk**即可完成SDK的更新.

### 2.手动集成的客户比较麻烦,我们这边探索的办法为:

1通过**show In finder** 删除自己项目工程中的mixdesk的四个文件

**`MixdeskSDK.framework` 、 `MXChatViewController`  `MXChatViewInterface` 和 `MXMessageForm`**

2 cleanXcode,

3 从github上下载新版Demo,然后找到
**`MixdeskSDK.framework` 、 `MXChatViewController`  `MXChatViewInterface` 和 `MXMessageForm`**,复制粘贴到 项目工程中 **show in finder**之前存放SDK 4个文件的地方

4 然后通过 **add files to** ,将复制的sdk下的四个文件夹 添加到工程中的原来放置这4个文件的地方

## iOS 11下 SDK 的聊天界面底部输入框出现绿色条状,且无法输入
请升级到最新版本, 已完成iOS 11的适配. 
**温馨提示: 遇到iOS 有重大更新的时候,请提前进入技术支持群,询问SDK是否要更新.**
## SDK 初始化失败

### 1. 没有配置 NSExceptionDomains
如果没有配置`NSExceptionDomains`，MixdeskSDK会返回`MXErrorCodePlistConfigurationError`，并且在控制台中打印：`!!!Mixdesk SDK Error：请开发者在 App 的 info.plist 中增加 NSExceptionDomains，具体操作方法请见「https://github.com/Mixdesk/MixdeskSDK-iOS#info.plist设置」`。如果出现上诉情况，请 [配置NSExceptionDomains](#infoplist设置)

**注意**，如果发现添加配置后，仍然打印配置错误，请开发者检查是否错误地将配置加进了项目 Tests 的 info.plist 中去。

### 2. 网络异常
如果上诉情况均不存在，请检查引入MixdeskSDK的设备的网络是否通畅

## 没有显示 导航栏/UINavgationBar
Mixdesk开源的聊天界面用的是系统的 `UINavgationController`，所以没有显示导航栏的原因有3种可能：

* 如果使用的是`Push`方式弹出视图，那么可能是传入 `viewController` 没有基于 `UINavigationController`。
* 如果使用的是`Push`方式弹出视图，那么可能是 `UINavgationBar` 被隐藏或者是透明的。
* App中使用了 `Category`，对 `UINavgationBar` 做了修改，造成无法显示。

其中1、2种情况，除了修改代码，还可以直接使用 `present` 方式弹出视图解决。

## Xcode Warning: was built for newer iOS version (7.0) than being linked (6.0)

如果开发者的 App 最低支持系统是 7.0 以下，将会出现这种 warning。

`ld: warning: object file (/Mixdesk-SDK-Demo/MXChatViewController/Vendors/MLAudioRecorder/amr_en_de/lib/libopencore-amrnb.a(wrapper.o)) was built for newer iOS version (7.0) than being linked (6.0)`

原因是Mixdesk将 SDK 中使用的开源库 [opencore-amr](http://sourceforge.net/projects/opencore-amr/) 针对支持Bitcode而重新编译了一次，但这并不影响SDK在iOS 6中的使用。如果你介意，并且不会使用 Bitcode，可以将MixdeskSDK中使用 `opencore-amr` 替换为老版本：[传送门](https://github.com/molon/MLAudioRecorder/tree/master/MLRecorder/MLAudioRecorder/amr_en_de/lib)

## Mixdesk静态库的文件大小太大
因为Mixdesk静态库包含5个平台（armv7、arm64、i386、x86_64）+ Bitcode。但这并不代表会严重影响编译后的宿主 App 大小，实际上，这只会增加宿主 App 100kb 左右大小。

## 键盘弹起后输入框和键盘之间有偏移
请检查是否使用了第三方开源库[IQKeyboardManager](https://github.com/hackiftekhar/IQKeyboardManager)，该开源库会和判断输入框的逻辑冲突。

解决办法：（感谢 [RandyTechnology](https://github.com/RandyTechnology) 向我们提供该问题的原因和解决方案）

* 在MXChatViewController的viewWillAppear里加入 `[[IQKeyboardManager sharedManager] setEnable:NO];`，作用是在当前页面禁止IQKeyboardManager
* 在MXChatViewController的viewWillDisappear里加入 `[[IQKeyboardManager sharedManager] setEnable:YES];`，作用是在离开当前页面之前重新启用IQKeyboardManager

## 使用 TabBarController 后，inputBar 高度出现异常

使用了 TabBarController 的 App，视图结构都各相不同，并且可能存在自定义 TabBar 的情况，所以Mixdesk SDK 无法判断并准确调整，需要开发者自行修改 App 或 SDK 代码。自 iOS 7 系统后，大多数情况下只需修改 TabBar 的 `hidden` 和 `translucent` 属性便可以正常使用。

## 如何在聊天界面之外监听新消息的通知

请查看 [如何监听监听收到消息的广播](#监听收到消息的广播)。

## 第三方库冲突

由于「聊天界面」的项目中用到了几个开源库，如果开发者使用相同的库，会产生命名空间冲突的问题。遇到此类问题，开发者可以选择删除「聊天界面 - Vendors」中的相应第三方代码。

**注意**，Mixdesk对几个第三方库进行了自定义修改，如果开发者删除了Mixdesk中的 Vendors，聊天界面将会缺少我们自定义的效果，详细请移步 Github [Mixdesk开源聊天界面](https://github.com/Mixdesk/MXChatViewController#vendors---用到的第三方开源库)。

## 工作台联系人信息显示应用的名称不正确

如果工作台的某对话中的联系人信息 - 访问信息中的「应用」显示的是 App 的 Bundle Name 或显示的是「SDK 无法获取 App 的名字」，则可能是您的 App 的 info.plist 中没有设置 CFBundleDisplayName 这个 Property，导致 SDK 获取不到 App 的名字。

## 编译中出现 undefined symbols

请开发者检查 App Target - Build Settings - Search Path - Framework Search Path 或 Library Search Path 当中是否没有Mixdesk的项目。

## Xcode14上的一些变动需知晓

* Bitcode 废除
* iOS v3.8.5 - v3.9.0 真机只支持arm64

Vendors - 用到的第三方开源库
---
以下是该 Library 用到的第三方开源代码，如果开发者的项目中用到了相同的库，需要删除一份，避免类名冲突：

第三方开源库 | Tag 版本 | 说明
----- | ----- | -----
VoiceConvert |  N/A | AMR 和 WAV 语音格式的互转；没找到出处，哪位童鞋找到来源后，请更新下文档~
[MLAudioRecorder](https://github.com/molon/MLAudioRecorder) | master | 边录边转码，播放网络音频 Button (本地缓存)，实时语音。**注意**，由于该开源项目中的 [lame.framework](https://github.com/molon/MLAudioRecorder/tree/master/MLRecorder/MLAudioRecorder/mp3_en_de/lame.framework) 不支持 `bitCode` ，所以我们去掉了该项目中有关 MP3 的文件；
[GrowingTextView](https://github.com/HansPinckaers/GrowingTextView) | 1.1 | 随文字改变高度的的 textView，用于本项目中的聊天输入框；
[TTTAttributedLabel](https://github.com/TTTAttributedLabel/TTTAttributedLabel) |  | 支持多种效果的 Lable，用于本项目中的聊天气泡的文字 Label；
[CustomIOSAlertView](https://github.com/wimagguc/ios-custom-alertview) | 自定义 | 自定义的 AlertView，用于显示本项目的评价弹出框；**注意**，我们队该开源项目进行了修改，增加了按钮之间的分隔线条、判断当前是否已经有 AlertView 在显示、以及键盘弹出时界面 frame 计算，该修改版本可以见 [CustomIOSAlertView](https://github.com/ijinmao/ios-custom-alertview)；
[AGEmojiKeyboard](https://github.com/ayushgoel/AGEmojiKeyboard)|0.2.0|表情键盘，布局进行自定义，源码可以在工程中查看；

# 九 更新日志
**v1.0.1  2025 年 6 月 11 日**
* SDK 发布

**v1.0.2  2025 年 6 月 27 日**
* SDK 拉取历史对话消息的优化

**v1.0.4  2025 年 6 月 27 日**
* SDK 新增地区限制
* SDK 新增打开窗口事件传递

**v1.0.7  2025 年 9 月 9 日**
* SDK 新增联系人已读和未读功能

**v1.0.9  2025 年 11 月 3 日**
* SDK 解决文本消息中含有超链接报错的情况
