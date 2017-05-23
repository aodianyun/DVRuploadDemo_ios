#DVRuploadDemo_ios

##简介
DVRuploadDemo_ios 奥点云dvr 上传sdk ios版本demo

##编译环境
**xcode** 7以上

##支持的系统平台
**iOS** 7.0及以上

##支持的CPU架构
**iOS** armv7 armv7s arm64 i386 x86_64  

##接口说明
* -(instancetype)initWithPath:(NSString *)filePath AndAccount:(Account *)account;
* 实例化上传对象
* -(void)upload:(void(^)(float process,int err)) upBlock;
* 开始上传 并通过block回调上传进度和状态
