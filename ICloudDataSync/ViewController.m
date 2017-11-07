//
//  ViewController.m
//  ICloudDataSync
//
//  Created by 汤来友 on 2017/11/7.
//  Copyright © 2017年 Teonardo. All rights reserved.
//

#import "ViewController.h"
#import "MyDocument.h"

#define kUbiquityContainerIdentifier @"iCloud.WuhanNetPower.ICloudDataSync"
#define kTextName @"test.txt"

@interface ViewController ()
@property (nonatomic, strong) NSUbiquitousKeyValueStore *valuesStore;

@property (nonatomic, strong) NSURL *myURL;

@property (nonatomic, strong) NSMetadataQuery *myMetadataQuery;

@end

@implementation ViewController

- (NSUbiquitousKeyValueStore *)valuesStore {
    if (!_valuesStore) {
        // ① 初始化
        _valuesStore = [NSUbiquitousKeyValueStore defaultStore];
    }
    return _valuesStore;
}

- (NSMetadataQuery *)myMetadataQuery {
    if (!_myMetadataQuery) {
        _myMetadataQuery = [[NSMetadataQuery alloc] init];
    }
    return _myMetadataQuery;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self addObservers];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [self removeObservers];
}

#pragma mark -----------------------------------------
#pragma mark - 通知

- (void)addObservers {
    
    // 消息通知
    // 在首次使用软件同步的时候, 或者其他设备也通过iCloud修改数据的时候调用的
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataChange:) name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:self.valuesStore];
    
    // 数据获取完成
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(metadataQueryDidFinishGathering:) name:NSMetadataQueryDidFinishGatheringNotification object:self.myMetadataQuery];
    
    // 数据更新通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(metadataQueryDidUpdate:) name:NSMetadataQueryDidUpdateNotification object:self.myMetadataQuery];

}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:self.valuesStore];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:self.myMetadataQuery];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidUpdateNotification object:self.myMetadataQuery];
    
}


- (void)dataChange:(NSNotification *)noti {
    NSLog(@"dataChange");
}

// 数据拉取成功
- (void)metadataQueryDidFinishGathering:(NSNotification *)noti {
    NSLog(@"metadataQueryDidFinishGathering");
    NSArray *items = self.myMetadataQuery.results; // 查询结果
    // 遍历结果
    [items enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMetadataItem *item = obj;
        // 获取文件名
        NSString *fileName = [item valueForAttribute:NSMetadataItemFSNameKey];
        
        // 获取创建日期
        NSData *date = [item valueForAttribute:NSMetadataItemFSCreationDateKey];
        NSLog(@"%@, %@", fileName, date);
        
        // 读取文件内容
        MyDocument *doc = [[MyDocument alloc] initWithFileURL:[self getUbiquityContainerUrl:fileName]];
        [doc openWithCompletionHandler:^(BOOL success) {
            if (success) {
                NSLog(@"读取数据成功");
                NSString *dataText = [[NSString alloc] initWithData:doc.myData encoding:NSUTF8StringEncoding];
                NSLog(@"数据: %@", dataText);
            }
        }];
    }];
    
}

- (void)metadataQueryDidUpdate:(NSNotification *)noti {
    NSLog(@"icloud数据有更新");
}


#pragma mark -----------------------------------------
#pragma mark - Event
- (IBAction)save:(UIButton *)sender {
    // 保存数据
    [self.valuesStore setObject:@"dong" forKey:@"name"];
    [self.valuesStore synchronize];
}

- (IBAction)read:(UIButton *)sender {
    NSString *str = [self.valuesStore objectForKey:@"name"];
    NSLog(@"读取数据: %@", str);
}

- (IBAction)uploadDocument:(UIButton *)sender {
    [self uploadDoc];
}

- (IBAction)updateDocument:(UIButton *)sender {
    [self editDoc];
}

- (IBAction)removeDocument:(UIButton *)sender {
    [self removeDoc];
}

- (IBAction)readDocument:(UIButton *)sender {
    [self readDoc];
}



/*
 NSFileManager :     文件的操作. 
 初始化: [NSFileManager defautManager];
 
 UIDocument:           文件内容的的操作. 
 必须用 - (instancetype)initWithFileURL:(NSURL *)url 方法初始化
 
 NSMetadataQuery:  文件内容的查询
 [[NSMetadataQuery alloc] init];
 */


// 获取URL
- (NSURL *)getUbiquityContainerUrl:(NSString *)fileName {
    if (!self.myURL) {
        self.myURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:kUbiquityContainerIdentifier];
        if (!self.myURL) {
            NSLog(@"未开启iCloud功能");
            return nil;
        }
    }

    NSURL *url = [self.myURL URLByAppendingPathComponent:@"Documents"];
    url = [url URLByAppendingPathComponent:fileName];
    return url;
}



#pragma mark -----------------------------------------
#pragma mark - 操作
//=============================
// NSMetadataQuery

/*
 文档的上传就是先通过文件名获得或者创建一个文档的URL地址, 然后实例化一个MyDocument, 之后把需要写到文档的数据赋值给MyDoucument 的myData, 通过saveToURL: 中的这个UIDocumentSaveForCreating 保存类去创建一个新文档, 
 调用完这个函数的时候, MyDocument 里面的继承的contentsForType: error: 函数就会自动调用, 就是把创建的myData 保存到了iCloud 的文档.
 */


/// 创建文档并上传
- (void)uploadDoc {
    NSLog(@"uploadDoc");
    // 文档的名字
    NSString *fileName = kTextName;
    NSURL *url = [self getUbiquityContainerUrl:fileName];
    MyDocument *doc = [[MyDocument alloc] initWithFileURL:url];
    // 文档内容
    NSString * str = @"测试文本数据";
    doc.myData = [str dataUsingEncoding:NSUTF8StringEncoding];
    [doc saveToURL:url forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
        if (success) {
            NSLog(@"创建成功");
        } else {
            NSLog(@"创建失败");
        }
    
    }];
}


// 文档的修改
- (void)editDoc {
    NSLog(@"editDoc");
    // 文档的名字
    NSString *fileName = kTextName;
    NSURL *url = [self getUbiquityContainerUrl:fileName];
    MyDocument *doc = [[MyDocument alloc] initWithFileURL:url];
    // 文档内容
    NSString *str = @"修改了数据";
    doc.myData = [str dataUsingEncoding:NSUTF8StringEncoding];
    [doc saveToURL:url forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        if (success) {
            NSLog(@"修改成功");
        } else {
            NSLog(@"修改失败");
        }
    }];

}


/// 文档的读取
- (void)readDoc {
    [self.myMetadataQuery setSearchScopes:@[NSMetadataQueryUbiquitousDocumentsScope]];
    [self.myMetadataQuery startQuery];
}


// 文档的删除
- (void)removeDoc {
    NSLog(@"removeDco");
    NSString *fileName = kTextName;
    NSURL *url = [self getUbiquityContainerUrl:fileName];
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
    if (error) {
        NSLog(@"%@", error.localizedDescription);
    }
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
