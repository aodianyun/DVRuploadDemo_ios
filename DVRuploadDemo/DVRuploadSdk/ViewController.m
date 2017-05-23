//
//  ViewController.m
//  DVRuploadSdk
//
//  Created by 崔波强 on 17/5/9.
//  Copyright © 2017年 崔波强. All rights reserved.
//

#import "ViewController.h"
#import <CommonCrypto/CommonDigest.h>
#import "ZYQAssetPickerController.h"
#import "GMWorkSignTableViewCell.h"

//照片存储路径
#define KOriginalPhotoImagePath   \
[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"PhotoImages"]

//视频存储路径
#define KVideoUrlPath   \
[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"VideoURL"]

@interface ViewController ()<UINavigationControllerDelegate, ZYQAssetPickerControllerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property(nonatomic, strong) NSMutableArray     *leftDataArr;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //清空所有缓存
    [self cleanSaveAction];
    _tableview.separatorStyle = NO;
    [_tableview setShowsVerticalScrollIndicator:NO];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onSelect:(id)sender {
    ZYQAssetPickerController *picker = [[ZYQAssetPickerController alloc] init];
    picker.maximumNumberOfSelection = 1;
    picker.assetsFilter = [ALAssetsFilter allVideos];
    picker.showEmptyGroups=NO;
    picker.delegate=self;
    
    picker.selectionFilter = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        if ([[(ALAsset*)evaluatedObject valueForProperty:ALAssetPropertyType] isEqual:ALAssetTypeVideo]) {
            NSTimeInterval duration = [[(ALAsset*)evaluatedObject valueForProperty:ALAssetPropertyDuration] doubleValue];
            return duration >= 5;
        } else {
            return YES;
        }
    }];
    
    [self presentViewController:picker animated:YES completion:NULL];
}

//清空所有缓存
-(void)cleanSaveAction{
   // if(_leftDataArr.count > 0){
    {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:KOriginalPhotoImagePath error:&error];
        [[NSFileManager defaultManager] removeItemAtPath:KVideoUrlPath error:&error];
        [_leftDataArr removeAllObjects];
        [_tableview reloadData];
    }
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _leftDataArr.count;
    
    return 0;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *CellIdentifier = @"GMWorkSignTableViewCell";
    GMWorkSignTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = (GMWorkSignTableViewCell*)[[[NSBundle mainBundle] loadNibNamed:@"GMWorkSignTableViewCell" owner:nil options:nil] objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell setBackgroundColor:[UIColor clearColor]];
    }
    if(_leftDataArr.count > indexPath.row){
        [cell setValueDictionary:[_leftDataArr objectAtIndex:indexPath.row]];
    }else{
        [cell setValueDictionary:nil];
    }
    return cell;
}


#pragma mark - ZYQAssetPickerController Delegate
-(void)assetPickerController:(ZYQAssetPickerController *)picker didFinishPickingAssets:(NSArray *)assets{
    if(!_leftDataArr){
        _leftDataArr = [[NSMutableArray alloc] init];
    }
    
    for (int i=0; i<assets.count; i++) {
        
        ALAsset *asset=assets[i];
        ALAssetRepresentation * representation = asset.defaultRepresentation;
        
        UIImage *tempImg = [UIImage imageWithCGImage:asset.thumbnail];
        NSString *typeStr = @"视频";
        NSData *data = UIImageJPEGRepresentation(tempImg, 1);
        [self videoWithUrl:representation.url withFileName:representation.filename];
        
        NSString* picPath = [NSString stringWithFormat:@"%@/%@",KVideoUrlPath,representation.filename];
        NSMutableDictionary *objDict = [[NSMutableDictionary alloc] init];
        if(data){
            [objDict setObject:data forKey:@"header"];
        }
        [objDict setObject:picPath  forKey:@"path"];
        [objDict setObject:typeStr forKey:@"type"];
        [objDict setObject:representation.filename  forKey:@"name"];
        [_leftDataArr addObject:objDict];
    }

}

// 将原始视频的URL转化为NSData数据,写入沙盒
- (void)videoWithUrl:(NSURL *)url withFileName:(NSString *)fileName
{
    // 解析一下,为什么视频不像图片一样一次性开辟本身大小的内存写入?
    // 想想,如果1个视频有1G多,难道直接开辟1G多的空间大小来写?
    // 创建存放原始图的文件夹--->VideoURL
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:KVideoUrlPath]) {
        [fileManager createDirectoryAtPath:KVideoUrlPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (url) {
            [assetLibrary assetForURL:url resultBlock:^(ALAsset *asset) {
                ALAssetRepresentation *rep = [asset defaultRepresentation];
                NSString * videoPath = [KVideoUrlPath stringByAppendingPathComponent:fileName];
                const char *cvideoPath = [videoPath UTF8String];
                FILE *file = fopen(cvideoPath, "w+");
                if (file) {
                    const int bufferSize = 1024 * 1024;
                    // 初始化一个1M的buffer
                    Byte *buffer = (Byte*)malloc(bufferSize);
                    NSUInteger read = 0, offset = 0, written = 0;
                    NSError* err = nil;
                    if (rep.size != 0)
                    {
                        do {
                            read = [rep getBytes:buffer fromOffset:offset length:bufferSize error:&err];
                            written = fwrite(buffer, sizeof(char), read, file);
                            offset += read;
                        } while (read != 0 && !err);//没到结尾，没出错，ok继续
                    }
                    // 释放缓冲区，关闭文件
                    free(buffer);
                    buffer = NULL;
                    fclose(file);
                    file = NULL;
                    
                    // UI的更新记得放在主线程,要不然等子线程排队过来都不知道什么年代了,会很慢的
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_tableview reloadData];
                    });
                }
            } failureBlock:nil];
        }
    });
}

@end
