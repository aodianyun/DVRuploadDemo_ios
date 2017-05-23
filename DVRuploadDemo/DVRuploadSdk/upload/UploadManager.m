//
//  UploadManager.m
//  DVRuploadSdk
//
//  Created by 崔波强 on 17/5/9.
//  Copyright © 2017年 崔波强. All rights reserved.
//

#import "UploadManager.h"
#import "FileOperation.h"
#import <AFNetworking.h>
#import "NSObject+indexTask.h"
#import<CommonCrypto/CommonDigest.h>

#define UPLOADURL @"http://114.55.29.116/v3/DVR.UploadPart"

#define UPLOADCOMPELETE @"http://114.55.29.116/v3/DVR.UploadComplete"

@implementation Account

@end

@interface UploadManager()
{
    BOOL bCancel;
}

@property (nonatomic, strong) Account *adAccount;

@property (nonatomic, strong) FileOperation *fileOperation;

@property (nonatomic, strong)  NSMutableArray *taskArray;

@end

@implementation UploadManager

-(instancetype)initWithPath:(NSString *)filePath AndAccount:(Account *)account
{
    //[NSFileHandle fileHandleForReadingAtPath:<#(nonnull NSString *)#>]
    if (self = [super init]) {
        self.adAccount = account;
        self.fileOperation = [[FileOperation alloc] initFileOperationAtPath:filePath forReadOperation:YES];
        if (self.fileOperation == nil) {
            return nil;
        }
        self.taskArray = [NSMutableArray arrayWithCapacity:30];
    }
    
    return self;
}

-(void)upload:(void (^)(float process, int err))upBlock
{
    
     AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer=[AFJSONRequestSerializer serializer];
    
    NSInteger fileFragmentCount = self.fileOperation.fileFragments.count;
    
    NSString *filename = self.fileOperation.fileName;
    Account *account = self.adAccount;
    __weak typeof(self) weakSelf = self;
    
    for (NSInteger i = 0; i < fileFragmentCount; i++ ) {
        if (bCancel) {
            break;
        }
        
        NSData *data = [weakSelf.fileOperation readDateOfFragment:weakSelf.fileOperation.fileFragments[i]];
        NSString *data64 = [data base64EncodedStringWithOptions:0];
        NSString *encodeData = [self encodeString:data64];
//        access_id，接口认证ID
//        expires，有效时间，时间戳
//        signature_nonce，加密随机数
//        signature，加密密文，加密规则=md5(access_key+expires+signature_nonce)
        NSInteger expires = [[NSDate date] timeIntervalSince1970] + 7200;
        int signature_nonce = arc4random() % 100;
        NSString *noEncroy = [NSString stringWithFormat:@"%@%ld%d",account.access_key,(long)expires, signature_nonce];
        NSString *signature = [self md5:noEncroy];
        NSDictionary *dict = @{@"access_id":account.access_id,
                               @"expires":[NSNumber numberWithInteger:expires],
                               @"signature":signature,
                               @"signature_nonce":[NSNumber numberWithInteger:signature_nonce],
                               @"fileName":filename,
                               @"partNum": [NSNumber numberWithInteger:(i+1)],
                               @"part":encodeData};
     NSURLSessionDataTask *task = [manager POST:UPLOADURL parameters:dict progress:^(NSProgress * _Nonnull uploadProgress) {
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSLog(@"sucess:%@:Index:%@",responseObject,task.customAnimating);
            NSDictionary *dictres = (NSDictionary *)responseObject;
            if ([[dictres objectForKey:@"Flag"] intValue] == 100) {
                [self.taskArray removeObject:task];
                if (upBlock) {
                    
                    upBlock((1.0-self.taskArray.count*1.0/fileFragmentCount),0);
                }
                if (self.taskArray.count == 0) {
//                    // 查询完成接口
//                    NSDictionary *dict = @{@"access_id":account.access_id,@"access_key":account.access_key,@"fileName":filename};
//                    [manager POST:UPLOADCOMPELETE parameters:dict progress:^(NSProgress * _Nonnull uploadProgress) {
//                        
//                    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//                        NSLog(@"UPLOADCOMPELETE sucess:%@",responseObject);
//                    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//                        NSLog(@"UPLOADCOMPELETE faild:%@",error);
//                    }];
                    [self queryCompelete:(void (^)(float process, int err))upBlock];
                }
            }

            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"faild:%@",error);
            [self.taskArray removeObject:task];
           NSURLSessionDataTask *retask = [weakSelf uploadFragment:[task.customAnimating integerValue] success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSLog(@"repeat sucess:%@:Index:%@",responseObject,task.customAnimating);
                NSDictionary *dictres = (NSDictionary *)responseObject;
                if ([[dictres objectForKey:@"Flag"] intValue] == 100) {
                    [self.taskArray removeObject:task];
                    if (self.taskArray.count == 0) {
                        [self queryCompelete:upBlock];
                    }
                }
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                if (upBlock) {
                    upBlock(0, -1);
                }
                [self cancel];
            }];
            [self.taskArray addObject:retask];
        }];
        
        task.customAnimating = [NSNumber numberWithInteger:i];
        [self.taskArray addObject:task];
    }
}

-(NSURLSessionDataTask *)uploadFragment:(NSInteger) fragmentIndex
              success:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
              failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure {
    
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer=[AFJSONRequestSerializer serializer];
    
    NSString *filename = self.fileOperation.fileName;
    Account *account = self.adAccount;
    
    NSData *data = [self.fileOperation readDateOfFragment:self.fileOperation.fileFragments[fragmentIndex]];
    NSString *data64 = [data base64EncodedStringWithOptions:0];
    NSString *encodeData = [self encodeString:data64];
    
    NSInteger expires = [[NSDate date] timeIntervalSince1970] + 7200;
    int signature_nonce = arc4random() % 100;
    NSString *noEncroy = [NSString stringWithFormat:@"%@%ld%d",account.access_key,(long)expires, signature_nonce];
    NSString *signature = [self md5:noEncroy];
    NSDictionary *dict = @{@"access_id":account.access_id,
                           @"expires":[NSNumber numberWithInteger:expires],
                           @"signature":signature,
                           @"signature_nonce":[NSNumber numberWithInteger:signature_nonce],
                           @"fileName":filename,
                           @"partNum": [NSNumber numberWithInteger:(fragmentIndex+1)],
                           @"part":encodeData};
    
    return [manager POST:UPLOADURL parameters:dict progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:success failure:failure];
}

-(void)queryCompelete:(void (^)(float process, int err))upBlock{
    NSString *filename = self.fileOperation.fileName;
    Account *account = self.adAccount;
    __weak typeof(self) weakSelf = self;

    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer=[AFJSONRequestSerializer serializer];
    
    // 查询完成接口
    NSInteger expires = [[NSDate date] timeIntervalSince1970] + 7200;
    int signature_nonce = arc4random() % 100;
    NSString *noEncroy = [NSString stringWithFormat:@"%@%ld%d",account.access_key,(long)expires, signature_nonce];
    NSString *signature = [self md5:noEncroy];
    NSDictionary *dict = @{@"access_id":account.access_id,
                           @"expires":[NSNumber numberWithInteger:expires],
                           @"signature":signature,
                           @"signature_nonce":[NSNumber numberWithInteger:signature_nonce],
                           @"fileName":filename};
    
    [manager POST:UPLOADCOMPELETE parameters:dict progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (upBlock) {
            upBlock(1.0,0);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (upBlock) {
            upBlock(0,-1);
        }
    }];

}

-(void)pause{
    for (NSURLSessionDataTask *task in self.taskArray) {
        [task suspend];
    }
    
}

-(void)resume{
    for (NSURLSessionDataTask *task in self.taskArray) {
        [task resume];
    }
}

-(void)cancel{
    for (NSURLSessionDataTask *task in self.taskArray) {
        [task cancel];
    }
    bCancel = true;
}


-(NSString*)encodeString:(NSString*)unencodedString{
    
    // CharactersToBeEscaped = @":/?&=;+!@#$()~',*";
    
    // CharactersToLeaveUnescaped = @"[].";
    
  return  [unencodedString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
}

- (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
    if (jsonString == nil) {
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err) {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}

- (NSString *) md5:(NSString *) input {
    const char *cStr = [input UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return  output;
}

@end
