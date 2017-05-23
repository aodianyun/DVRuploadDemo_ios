//
//  GMWorkSignTableViewCell.h
//  GMAlbumVideoImageDemo
//
//  Created by gamin on 15/6/2.
//  Copyright (c) 2015年 gamin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GMWorkSignTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *cellImgView;
@property (weak, nonatomic) IBOutlet UILabel     *titleLab;
@property (weak, nonatomic) IBOutlet UILabel     *descriptionLab;
@property (strong, nonatomic) NSDictionary       *valueDict;
@property (weak, nonatomic) IBOutlet UIProgressView *upProgress;


//赋值
-(void)setValueDictionary:(NSDictionary *)theDict;

@end
