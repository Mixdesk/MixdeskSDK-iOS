//
//  MXFileDownloadMessage.m
//  Mixdesk-SDK-Demo
//
//  Created by ian luo on 16/4/6.
//  Copyright © 2016年 ijinmao. All rights reserved.
//

#import "MXFileDownloadMessage.h"
#import <MixdeskSDK/MixdeskSDK.h>
@implementation MXFileDownloadMessage

- (id)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        self.fileName = [dictionary objectForKey:@"filename"];
        self.lastDownloadedOn = [dictionary objectForKey:@"last_downloaded_on"];
        self.firstDownloadedOn = [dictionary objectForKey:@"first_downloaded_on"];
        self.refMessageId = [dictionary objectForKey:@"msg_id"];
        self.fileSize = [[dictionary objectForKey:@"size"] integerValue];
        self.conversationId = [dictionary objectForKey:@"conversation_id"];
        self.filePath = [dictionary objectForKey:@"media_url"];
        
        self.expireDate = [MXDateUtil convertToUtcDateFromUTCDateString:[dictionary objectForKey:@"expire_at"]];
    }
    return self;
}

@end
