//
//  NSObject+indexTask.m
//  DVRuploadSdk
//
//  Created by 崔波强 on 17/5/10.
//  Copyright © 2017年 崔波强. All rights reserved.
//

#import "NSObject+indexTask.h"
#import <objc/runtime.h>

static const void *customAnimatingKey = &customAnimatingKey;

static const void *failtimesKey = &failtimesKey;

@implementation NSObject(indexTask)

- (NSNumber *)customAnimating {
    return objc_getAssociatedObject(self, customAnimatingKey);
}

- (void)setCustomAnimating:(NSNumber *)animating{
    objc_setAssociatedObject(self, customAnimatingKey, animating, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)failtimes{
    return [objc_getAssociatedObject(self, failtimesKey) integerValue];
}

- (void)setFailtimes:(NSInteger)failtimes{
    objc_setAssociatedObject(self, failtimesKey, [NSNumber numberWithInteger:failtimes], OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
