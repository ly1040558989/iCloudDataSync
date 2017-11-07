//
//  MyDocument.m
//  ICloudDataSync
//
//  Created by 汤来友 on 2017/11/7.
//  Copyright © 2017年 Teonardo. All rights reserved.
//

#import "MyDocument.h"

@implementation MyDocument

// 读取iCloud 数据调用, 响应 openWithCompletionHandler
- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError {
    self.myData = [contents copy];
    return YES;
}

// 保存数据, 修改数据到iCloud, 响应 save
- (id)contentsForType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError {
    if (!self.myData) {
        self.myData = [[NSData alloc] init];
    }
    return self.myData;
}


@end
