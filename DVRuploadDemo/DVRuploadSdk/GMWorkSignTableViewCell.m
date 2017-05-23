//
//  GMWorkSignTableViewCell.m
//  GMAlbumVideoImageDemo
//
//  Created by gamin on 15/6/2.
//  Copyright (c) 2015年 gamin. All rights reserved.
//

#import "GMWorkSignTableViewCell.h"
#import "DVRuploadFrame/DVRuploadFrame.h"

@implementation GMWorkSignTableViewCell
@synthesize valueDict = _valueDict;

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)dealloc{
    [self releaseAction];
}

-(void)releaseAction{
    [_cellImgView setImage:nil];
    [_titleLab setText:@""];
    [_descriptionLab setText:@""];
    _valueDict = nil;
}

//赋值
-(void)setValueDictionary:(NSDictionary *)theDict{
    [self releaseAction];
    
    if(theDict){
        _valueDict = theDict;
        [_cellImgView setImage:[UIImage imageWithData:[_valueDict objectForKey:@"header"]]];
        [_titleLab setText:[_valueDict objectForKey:@"name"]];
        [_descriptionLab setText:[_valueDict objectForKey:@"type"]];
        Account *account = [[Account alloc] init];
        account.access_id  = @"125444393563";
        account.access_key = @"LM1N4aZ5aDCLa325D5ineenhynqtK6g5";
        UploadManager *up = [[UploadManager alloc] initWithPath:[_valueDict objectForKey:@"path"] AndAccount:account];
        [up upload:^(float process, int err) {
            NSLog(@"process:%f, err:%d",process, err);
            [_upProgress setProgress:process];
        }];
    }
}


@end
