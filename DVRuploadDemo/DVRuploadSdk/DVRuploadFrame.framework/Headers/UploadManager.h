//
//  UploadManager.h
//  DVRuploadSdk
//
//  Created by 崔波强 on 17/5/9.
//  Copyright © 2017年 崔波强. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Account : NSObject

@property(nonatomic, strong) NSString *access_id;

@property(nonatomic, strong) NSString *access_key;

@end

@interface UploadManager : NSObject

-(instancetype)initWithPath:(NSString *)filePath AndAccount:(Account *)account;

-(void)upload:(void(^)(float process, int err, NSString *finishUrl)) upBlock;

-(void)pause;

-(void)resume;

-(void)cancel;

@end
