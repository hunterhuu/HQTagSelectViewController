//
//  ViewController.m
//  TextProject
//
//  Created by 胡奇 on 2018/6/26.
//  Copyright © 2018年 胡奇. All rights reserved.
//

#import "ViewController.h"
#import "HQTagView.h"

@interface ViewController ()

@property (nonatomic, strong) HQTagView *tagView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"text" ofType:@""];
    NSError *error;
    
    NSString *dataFile = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];

    NSDictionary *dataDict = [self dictionaryWithJsonString:dataFile];
    
    self.view.backgroundColor = [UIColor lightGrayColor];
    self.tagView = [[HQTagView alloc] initWithFrame:self.view.frame];
    
    self.tagView.dataArray = dataDict[@"data"];
    
    
    
    self.tagView.confirmButtonClickBlock = ^(NSArray<NSDictionary *> *selectTagArray) {

        NSLog(@"selectTagArray = %@", selectTagArray);

    };

    self.tagView.overflowMaxSelectNumberWarningBlock = ^{
        NSLog(@"overflow");
    };
    
    [self.view addSubview:self.tagView];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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



@end
