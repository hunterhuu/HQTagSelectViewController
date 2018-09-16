//
//  HQTagView.m
//  thirdtest
//
//  Created by 胡奇 on 2018/6/13.
//  Copyright © 2018年 胡奇. All rights reserved.
//

#define COLOR(r, g, b) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]
#define CellGrayColor COLOR(250, 250, 250)
#define RedColor COLOR(255, 90, 90)
#define LineColor COLOR(243, 243, 243)
#define TextColor COLOR(51, 51, 51)

#define cellHeight 50
#define lineWidth 1/([UIScreen mainScreen].scale)

#import "HQTagView.h"
@interface HQTagView ()

@property (nonatomic, strong) UIView *navigationView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *confirmBackgroundView;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, strong) UIScrollView *selectedScrollView;
@property (nonatomic, strong) UITableView *firstClassTableView;
@property (nonatomic, strong) UITableView *secendClassTableView;

@property (nonatomic, assign) NSInteger currentSelectFirstClass;
@property (nonatomic, assign) NSInteger oldSelectFirstClass;
@property (nonatomic, strong) NSMutableArray <NSDictionary *>* currentSelectedTagArray;
@property (nonatomic, assign) NSInteger maxSelectNumber;

@property (nonatomic, strong) NSMutableArray<NSMutableArray <NSNumber *>*> *selectStateArray;

@property (nonatomic, strong) NSMutableArray <HQTagViewSelectButton *>*selectButtonArray;

@property (nonatomic, strong) NSMutableDictionary *sameDataRelevanceDict;

@end

@implementation HQTagView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initMethod];
        [self ReFreshUI];
    }
    return self;
}

- (void)setSelectButtonWithDict:(NSArray <NSDictionary *>*)selectArray {
    if (selectArray.count <= 0) {
        return;
    }
    [self currentSelectedTagArrayNeedDeleteAll];

    if (self.currentSelectedTagArray.count >= self.maxSelectNumber) {
        return;
    }
    
    for (NSDictionary *tagDict in selectArray) {
        NSInteger tempFirstIndex = 0;
        NSInteger tempSecondIndex = 0;
        BOOL getBreak = NO;
        for (tempFirstIndex = 0; tempFirstIndex < self.dataArray.count; tempFirstIndex ++) {
            getBreak = NO;
            NSDictionary *dataTagDict = self.dataArray[tempFirstIndex];
            NSArray *subList = dataTagDict[@"child"];
            if (subList != nil && subList.count > 0) {
                for (tempSecondIndex = 0; tempSecondIndex < subList.count; tempSecondIndex++) {
                    
                    NSDictionary *dict = subList[tempSecondIndex];
                    
                    if ([HQTagView tagDictisEqual:dict tagDict2:tagDict]) {
                 
                        if (self.currentSelectedTagArray.count >= self.maxSelectNumber) {
                            [self needReFreshConfirmButtonBackgroundView];
                            return;
                        }
                        [self currentSelectedTagArrayNeedAddTagDict:tagDict index:tempSecondIndex];
                        [self changeSameSelectStateArrayFirstClassIndex:tempFirstIndex secondClassIndex:tempSecondIndex isSelect:YES];
//                        ((self.selectStateArray[tempFirstIndex])[tempSecondIndex]) = @1;
                        getBreak = YES;
                        break;
                    }
                }
            }
            
            if (getBreak) {
                break;
            }
            
        }
    }
    [self needReFreshConfirmButtonBackgroundView];

}

#pragma mark -
#pragma mark setData

- (NSMutableArray *)reAnalysisDataArray:(NSArray *)originalDataArray {
    NSMutableArray *analysisDataArray = [[NSMutableArray alloc] initWithCapacity:originalDataArray.count];
    
    for (NSDictionary *firstClassDict in originalDataArray) {
        NSMutableDictionary *firstClassMutableDict = [[NSMutableDictionary alloc] initWithDictionary:firstClassDict];
        [firstClassMutableDict removeObjectForKey:@"child"];
        NSMutableArray *childArray = [[NSMutableArray alloc] initWithArray:firstClassDict[@"child"]];
        NSMutableArray *tempFirstClassMutableDict = [firstClassMutableDict mutableCopy];
        [tempFirstClassMutableDict setValue:@[] forKey:@"child"];
        [childArray insertObject:tempFirstClassMutableDict atIndex:0];
        [firstClassMutableDict setValue:childArray forKey:@"child"];
        [analysisDataArray addObject:firstClassMutableDict];
    }
    
    return analysisDataArray;
}

- (void)setDataArray:(NSArray *)dataArray {
    if ((![dataArray isKindOfClass:[NSArray class]]) || dataArray.count <= 0) {
        NSLog(@"error1");
        return;
    }
    
    if (![dataArray.firstObject isKindOfClass:[NSDictionary class]] || (((NSDictionary *)dataArray.firstObject)[@"child"] == nil)) {
        NSLog(@"error2");
        return;
    }
    
    
    
    _dataArray = [self reAnalysisDataArray:dataArray];
    
    [self.selectStateArray removeAllObjects];
    [self.sameDataRelevanceDict removeAllObjects];
    
    NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] initWithCapacity:0];
    
    for (int i = 0; i < _dataArray.count; i++) {
        NSDictionary *firstClassDict = _dataArray[i];
        NSArray *subList = firstClassDict[@"child"];
        NSMutableArray *secondClassStateSrray = [[NSMutableArray alloc] initWithCapacity:0];
        for (int j = 0; j < subList.count; j++) {
            [secondClassStateSrray addObject:@0];
            NSDictionary *tagDict = subList[j];
            [self addSameDataRelevanceDict:tagDict withTempDict:tempDict firstClassIndex:i secondClassIndex:j];
        }
        
        [self.selectStateArray addObject:secondClassStateSrray];
        
    }
    
    [tempDict removeAllObjects];
    tempDict = nil;
    
    [self.firstClassTableView reloadData];
    [self.secendClassTableView reloadData];
}

- (void)initMethod {
    self.clipsToBounds = YES;
//  Data
    self.currentSelectFirstClass = 0;
    self.oldSelectFirstClass = 0;
    self.maxSelectNumber = 5;
    self.selectStateArray = [[NSMutableArray alloc] initWithCapacity:0];
    self.currentSelectedTagArray = [[NSMutableArray alloc] initWithCapacity:0];
    self.selectButtonArray = [[NSMutableArray alloc] initWithCapacity:0];
    self.sameDataRelevanceDict = [[NSMutableDictionary alloc] initWithCapacity:0];
//  UI
    self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
    self.backgroundView.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.backgroundView];
    
//    self.navigationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), 44 + [UIApplication sharedApplication].statusBarFrame.size.height)];
    self.navigationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), 0)];
    self.navigationView.backgroundColor = COLOR(246, 246, 246);
    [self.backgroundView addSubview:self.navigationView];
    
//    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds) - 100, 20)];
//    self.titleLabel.font = [UIFont systemFontOfSize:17];
//    self.titleLabel.textColor = COLOR(51, 51, 51);
//    self.titleLabel.textAlignment = NSTextAlignmentCenter;
//    self.titleLabel.center = CGPointMake(CGRectGetWidth(self.navigationView.bounds) / 2, CGRectGetHeight(self.navigationView.bounds) - 24);
//    self.titleLabel.text = @"定制职位标签(可多选)";
//    [self.navigationView addSubview:self.titleLabel];
//
//    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
//    closeButton.center = CGPointMake(26, self.titleLabel.center.y);
//    [closeButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
//    [closeButton addTarget:self action:@selector(closeButtonClick) forControlEvents:UIControlEventTouchUpInside];
//    [self.navigationView addSubview:closeButton];
    
    self.confirmButton = [[UIButton alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.backgroundView.bounds) - 50, CGRectGetWidth(self.bounds), 50)];
    [self.confirmButton setTitle:[NSString stringWithFormat:@"确定 %ld/%ld", self.currentSelectedTagArray.count, self.maxSelectNumber] forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = RedColor;
    self.confirmButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.confirmButton addTarget:self action:@selector(confirmButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.backgroundView addSubview:self.confirmButton];

    self.firstClassTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.navigationView.bounds), CGRectGetWidth(self.bounds) / 2, CGRectGetHeight(self.bounds) - CGRectGetHeight(self.navigationView.bounds) - CGRectGetHeight(self.confirmButton.bounds)) style:UITableViewStylePlain];
    self.firstClassTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
//    self.firstClassTableView.separatorInset = UIEdgeInsetsZero;
//    self.firstClassTableView.separatorColor = LineColor;
    self.firstClassTableView.delegate = self;
    self.firstClassTableView.dataSource = self;
    self.firstClassTableView.showsVerticalScrollIndicator = NO;
    [self.backgroundView addSubview:self.firstClassTableView];
    
    self.secendClassTableView = [[UITableView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.bounds) / 2, CGRectGetHeight(self.navigationView.bounds), CGRectGetWidth(self.bounds) / 2, CGRectGetHeight(self.bounds) - CGRectGetHeight(self.navigationView.bounds) - CGRectGetHeight(self.confirmButton.bounds)) style:UITableViewStylePlain];
    self.secendClassTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
//    self.secendClassTableView.separatorInset = UIEdgeInsetsZero;
//    self.secendClassTableView.separatorColor = LineColor;
    self.secendClassTableView.delegate = self;
    self.secendClassTableView.dataSource = self;
    self.secendClassTableView.showsVerticalScrollIndicator = NO;
    self.secendClassTableView.backgroundColor = CellGrayColor;
    [self.backgroundView addSubview:self.secendClassTableView];
    
//    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.bounds) / 2, CGRectGetHeight(self.navigationView.bounds), lineWidth, CGRectGetHeight(self.bounds) - CGRectGetHeight(self.navigationView.bounds))];
//    lineView.backgroundColor = LineColor;
//    [self.backgroundView addSubview:lineView];
    
//    CGFloat tempConfirmBGHeight = (([UIApplication sharedApplication].statusBarFrame.size.height == 44) ? 134 : 100);
    CGFloat tempConfirmBGHeight = 50;
    self.confirmBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.bounds) - tempConfirmBGHeight, CGRectGetWidth(self.backgroundView.bounds), tempConfirmBGHeight)];
    self.confirmBackgroundView.backgroundColor = [UIColor whiteColor];
    [self.backgroundView addSubview:self.confirmBackgroundView];
    
    UILabel *confirmLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 50)];
    confirmLabel.text = @"已选";
    confirmLabel.textAlignment = NSTextAlignmentCenter;
    confirmLabel.textColor = TextColor;
    confirmLabel.font = [UIFont systemFontOfSize:15];
    [self.confirmBackgroundView addSubview:confirmLabel];
    
    UIView *lineView1 = [[UIView alloc] initWithFrame:CGRectMake(60, 0, lineWidth, 25)];
    lineView1.center = CGPointMake(lineView1.center.x, 25);
    lineView1.backgroundColor = COLOR(227, 227, 228);
    [self.confirmBackgroundView addSubview:lineView1];
    
    UIView *lineView2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.confirmBackgroundView.bounds), lineWidth)];
    lineView2.backgroundColor = COLOR(227, 227, 228);
    [self.confirmBackgroundView addSubview:lineView2];
    
    self.selectedScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(confirmLabel.frame) + 20, 0, CGRectGetWidth(self.confirmBackgroundView.bounds) - CGRectGetMaxX(confirmLabel.frame) - 20, 50)];
    self.selectedScrollView.showsVerticalScrollIndicator = NO;
    self.selectedScrollView.showsHorizontalScrollIndicator = NO;
    [self.confirmBackgroundView addSubview:self.selectedScrollView];
    
    
    [self.backgroundView bringSubviewToFront:self.confirmButton];
}

- (void)ReFreshUI {
    
}

- (void)closeButtonClick {
    if (self.closeButtonClickBlock) {
        self.closeButtonClickBlock(self.currentSelectedTagArray);
    }
}

- (void)confirmButtonClick {
    if (self.confirmButtonClickBlock) {
        self.confirmButtonClickBlock(self.currentSelectedTagArray);
    }
}

- (void)changeSelectStateArray:(BOOL)isSelect withDict:(NSDictionary *)dict {
    for (NSInteger firstClassIndex = 0; firstClassIndex < self.selectStateArray.count; firstClassIndex++) {
        NSMutableArray *firstArray = self.selectStateArray[firstClassIndex];
        for (NSInteger secendClassIndex = 0; secendClassIndex < firstArray.count; secendClassIndex++) {
            NSDictionary *tagDict = (((NSArray *)(((NSDictionary *)(self.dataArray[firstClassIndex]))[@"child"]))[secendClassIndex]);
            if ([HQTagView tagDictisEqual:dict tagDict2:tagDict]) {
                [self changeSameSelectStateArrayFirstClassIndex:firstClassIndex secondClassIndex:secendClassIndex isSelect:isSelect];
                
//                if (isSelect) {
//                    (self.selectStateArray[firstClassIndex])[secendClassIndex] = @1;
//                } else {
//                    (self.selectStateArray[firstClassIndex])[secendClassIndex] = @0;
//                }
                
                break;
            }
            
        }
    }
    
}

+ (BOOL) tagDictisEqual:(NSDictionary *)tagDict1 tagDict2:(NSDictionary *)tagDict2 {

    if (([tagDict1[@"name"] isEqualToString:tagDict2[@"name"]]) && (((NSNumber *)tagDict1[@"parent"]).integerValue ==((NSNumber *)tagDict2[@"parent"]).integerValue) && (((NSNumber *)tagDict1[@"id"]).integerValue ==((NSNumber *)tagDict2[@"id"]).integerValue)) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark -
#pragma mark needReFreshConfirmButtonBackgroundView

- (void)needReFreshConfirmButtonBackgroundView {
    if (self.currentSelectedTagArray.count == 0) {
        CGFloat tempConfirmBGHeight = 50;
        self.confirmBackgroundView.frame = CGRectMake(0, CGRectGetHeight(self.bounds) - tempConfirmBGHeight, CGRectGetWidth(self.bounds), tempConfirmBGHeight);
        self.firstClassTableView.frame = CGRectMake(0, CGRectGetHeight(self.navigationView.bounds), CGRectGetWidth(self.bounds) / 2, CGRectGetHeight(self.bounds) - CGRectGetHeight(self.navigationView.bounds) - CGRectGetHeight(self.confirmButton.bounds));
        self.secendClassTableView.frame = CGRectMake(CGRectGetWidth(self.bounds) / 2, CGRectGetHeight(self.navigationView.bounds), CGRectGetWidth(self.bounds) / 2, CGRectGetHeight(self.bounds) - CGRectGetHeight(self.navigationView.bounds) - CGRectGetHeight(self.confirmButton.bounds));
    } else {
        CGFloat tempConfirmBGHeight = 50;
        self.confirmBackgroundView.frame = CGRectMake(0, CGRectGetHeight(self.bounds) - CGRectGetHeight(self.confirmBackgroundView.frame) - tempConfirmBGHeight, CGRectGetWidth(self.bounds), tempConfirmBGHeight);
        self.firstClassTableView.frame = CGRectMake(0, CGRectGetHeight(self.navigationView.bounds), CGRectGetWidth(self.bounds) / 2, CGRectGetHeight(self.bounds) - CGRectGetHeight(self.navigationView.bounds) - CGRectGetHeight(self.confirmBackgroundView.frame) - CGRectGetHeight(self.confirmButton.bounds));
        self.secendClassTableView.frame = CGRectMake(CGRectGetWidth(self.bounds) / 2, CGRectGetHeight(self.navigationView.bounds), CGRectGetWidth(self.bounds) / 2, CGRectGetHeight(self.bounds) - CGRectGetHeight(self.navigationView.bounds) - CGRectGetHeight(self.confirmBackgroundView.frame) - CGRectGetHeight(self.confirmButton.bounds));
    }
    
    [self.confirmButton setTitle:[NSString stringWithFormat:@"确定 %ld/%ld", self.currentSelectedTagArray.count, self.maxSelectNumber] forState:UIControlStateNormal];
    
    [self reFreshSelectedScrollView];
}

- (void)reFreshSelectedScrollView {
    for (HQTagViewSelectButton *selectButton in self.selectButtonArray) {
        [selectButton removeFromSuperview];
    }
    CGFloat tempX = 0;
    for (NSDictionary *selectDict in self.currentSelectedTagArray) {
        HQTagViewSelectButton *button = [[HQTagViewSelectButton alloc] initWithFrame:CGRectMake(tempX, 12, 0, 26)];
        button.tagView = self;
        button.dataDict = selectDict;
        tempX += button.frame.size.width + 10;
        [self.selectedScrollView addSubview:button];
        [self.selectButtonArray addObject:button];
    }
    if (tempX > 0) {
        tempX -= 10;
    }
    self.selectedScrollView.contentSize = CGSizeMake(tempX, CGRectGetHeight(self.selectedScrollView.bounds));
    if (self.selectedScrollView.contentSize.width > CGRectGetWidth(self.selectedScrollView.bounds)) {
        self.selectedScrollView.contentOffset = CGPointMake(self.selectedScrollView.contentSize.width - CGRectGetWidth(self.selectedScrollView.bounds), 0);
    }
    
}

#pragma mark -
#pragma mark deleagte & datasurce

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"cellID";
    HQTagViewTableviewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[HQTagViewTableviewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    
    
    if (tableView == self.firstClassTableView) {
        NSString *title = ((NSDictionary *)(self.dataArray[indexPath.row]))[@"name"];
        
        HQTagViewTableViewCellState state;

        if (indexPath.row == self.currentSelectFirstClass) {
            state = HQTagViewFirstCellStateCurrentSelect;
        } else  {
            state = HQTagViewFirstCellStateNormal;
            for (NSNumber *stateNumber in self.selectStateArray[indexPath.row]) {
                if (stateNumber.integerValue == 1) {
                    state = HQTagViewFirstCellStateHasSelect;
                    break;
                }
            }
        }
        
        [cell refreshWithTitle:title cellState:state];
        
        
    } else if (tableView == self.secendClassTableView) {
        NSArray *subList = ((NSDictionary *)(self.dataArray[self.currentSelectFirstClass]))[@"child"];
        NSString *title = ((NSDictionary *)subList[indexPath.row])[@"name"];
        
        HQTagViewTableViewCellState state;

        if (((self.selectStateArray[self.currentSelectFirstClass])[indexPath.row]).integerValue == 0) {
            state = HQTagViewSecondCellStateNormal;
        } else {
            state = HQTagViewSecondCellStateIsSelect;
        }
        if (indexPath.row == 0) {
            title = @"不限";
        }
        [cell refreshWithTitle:title cellState:state];
        
        
    } else {
        [cell refreshWithTitle:@"" cellState:HQTagViewFirstCellStateNormal];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (tableView == self.firstClassTableView) {
        self.currentSelectFirstClass = indexPath.row;
        [tableView reloadRowsAtIndexPaths:@[indexPath, [NSIndexPath indexPathForRow:self.oldSelectFirstClass inSection:0]] withRowAnimation:UITableViewRowAnimationNone];

        self.oldSelectFirstClass = indexPath.row;
        [self.secendClassTableView reloadData];
        [self.secendClassTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];

        
    } else if (tableView == self.secendClassTableView) {
        
        NSDictionary *tagDict = (NSDictionary *)((NSArray *)(((NSDictionary *)self.dataArray[self.currentSelectFirstClass])[@"child"])[indexPath.row]);

        if (((self.selectStateArray[self.currentSelectFirstClass])[indexPath.row]).integerValue == 0) {
        //  点击
            
            if (self.currentSelectedTagArray.count >= self.maxSelectNumber) {
                if (indexPath.row == 0) {
                    BOOL needReturn = YES;
                    for (NSNumber *tagNumber in self.selectStateArray[self.currentSelectFirstClass]) {
                        if (tagNumber.integerValue == 1) {
                            needReturn = NO;
                            break;
                        }
                    }
                    if (needReturn) {
                        if (self.overflowMaxSelectNumberWarningBlock) {
                            self.overflowMaxSelectNumberWarningBlock();
                        }
                        return;
                    }
                } else {
                    if (self.overflowMaxSelectNumberWarningBlock) {
                        self.overflowMaxSelectNumberWarningBlock();
                    }
                    return;
                }

            }
            
            
            [self currentSelectedTagArrayNeedAddTagDict:tagDict index:indexPath.row];
            [self needReFreshConfirmButtonBackgroundView];
            [self changeSameSelectStateArrayFirstClassIndex:self.currentSelectFirstClass secondClassIndex:indexPath.row isSelect:YES];

//            ((self.selectStateArray[self.currentSelectFirstClass])[indexPath.row]) = @1;
        } else {
        //  取消点击
            for (NSDictionary *temDict in self.currentSelectedTagArray) {
                if ([HQTagView tagDictisEqual:temDict tagDict2:tagDict]) {

                    [self currentSelectedTagArrayNeedDeleteTagDict:temDict index:indexPath.row];
                    [self needReFreshConfirmButtonBackgroundView];
                    [self changeSameSelectStateArrayFirstClassIndex:self.currentSelectFirstClass secondClassIndex:indexPath.row isSelect:NO];

//                    ((self.selectStateArray[self.currentSelectFirstClass])[indexPath.row]) = @0;
                    break;
                }
            }
        }

        [self.secendClassTableView reloadData];
//        [self.secendClassTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.firstClassTableView reloadData];
    }
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.firstClassTableView) {
        return self.dataArray.count;
    } else if (tableView == self.secendClassTableView) {
        NSArray *subList = ((NSDictionary *)self.dataArray[self.currentSelectFirstClass])[@"child"];
        return (subList == nil ? 0 : subList.count);
    }
    return 0;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return cellHeight;
}

#pragma mark - 关联相同数据

- (void)addSameDataRelevanceDict:(NSDictionary *)tagDict withTempDict:(NSMutableDictionary *)tempDict firstClassIndex:(NSInteger) firstClassIndex secondClassIndex:(NSInteger)secondClassIndex{
    if (tempDict && tagDict) {
        NSString *keyString = [NSString stringWithFormat:@"%@_%@_%@", tagDict[@"name"], tagDict[@"parent"], tagDict[@"id"]];
        
        HQTagViewSameDataModel *sameDataModel = [[HQTagViewSameDataModel alloc] init];
        sameDataModel.mainkey = keyString;
        sameDataModel.firstClassIndex = firstClassIndex;
        sameDataModel.secondClassIndex = secondClassIndex;
        
        if ([tempDict objectForKey:keyString]) {
            if ([self.sameDataRelevanceDict objectForKey:keyString]) {
                NSMutableArray *tempArray = [self.sameDataRelevanceDict objectForKey:keyString];
                [tempArray addObject:sameDataModel];
            } else {
                [self.sameDataRelevanceDict setObject:[NSMutableArray arrayWithArray:@[sameDataModel, tempDict[keyString]]] forKey:keyString];
            }
        } else {
            [tempDict setObject:sameDataModel forKey:keyString];
        }
    }
}

- (void)changeSameSelectStateArrayFirstClassIndex:(NSInteger) firstClassIndex secondClassIndex:(NSInteger)secondClassIndex isSelect:(BOOL)isSelect {
    if (self.selectStateArray) {
        if (self.dataArray.count > firstClassIndex) {
            NSDictionary *dataTagDict = self.dataArray[firstClassIndex];
            NSArray *subList = dataTagDict[@"child"];
            if (subList.count > secondClassIndex) {
                NSDictionary *tagDict = subList[secondClassIndex];
                NSString *keyString = [NSString stringWithFormat:@"%@_%@_%@", tagDict[@"name"], tagDict[@"parent"], tagDict[@"id"]];
                NSMutableArray *sameDataArray = [self.sameDataRelevanceDict objectForKey:keyString];
                
                if (sameDataArray) {
                    for (HQTagViewSameDataModel *sameDataModel in sameDataArray) {
                        if (isSelect) {
                            self.selectStateArray[sameDataModel.firstClassIndex][sameDataModel.secondClassIndex] = @1;
                        } else {
                            self.selectStateArray[sameDataModel.firstClassIndex][sameDataModel.secondClassIndex] = @0;
                        }
                    }
                } else {
                    if (isSelect) {
                        self.selectStateArray[firstClassIndex][secondClassIndex] = @1;
                    } else {
                        self.selectStateArray[firstClassIndex][secondClassIndex] = @0;
                    }
                }
                [self checkNoLimitButtonSelectAtFirstIndex:firstClassIndex secondClassIndex:secondClassIndex isSelect:isSelect];

            }
        }
    }
}

#pragma mark - 不限相关代码

- (void)checkNoLimitButtonSelectAtFirstIndex:(NSInteger)firstClassIndex secondClassIndex:(NSInteger)secondClassIndex isSelect:(BOOL)isSelect {
    if ((secondClassIndex == 0) && isSelect) {
        for (int i = 0; i < self.selectStateArray[firstClassIndex].count; i++) {
            if (i == 0) {
                self.selectStateArray[firstClassIndex][i] = @1;
            } else {
                self.selectStateArray[firstClassIndex][i] = @0;
            }
        }
    } else if ((secondClassIndex != 0) && isSelect) {
        self.selectStateArray[firstClassIndex][0] = @0;
    }
}

- (void)checkNoLimitTagSelectWithTagDict:(NSDictionary *)tagDict index:(NSInteger)index{
    if (index == 0) {
        NSInteger parentIntger = ((NSNumber *)(tagDict[@"id"])).integerValue;

        NSMutableArray *deletArray = [[NSMutableArray alloc] initWithCapacity:0];
        for (NSDictionary *tempDict in self.currentSelectedTagArray) {
            if (((NSNumber *)(tempDict[@"parent"])).integerValue == parentIntger) {
                [deletArray addObject:tempDict];
            }
        }
        [self.currentSelectedTagArray removeObjectsInArray:deletArray];

    } else {
        NSInteger parentIntger = ((NSNumber *)(tagDict[@"parent"])).integerValue;
        for (NSDictionary *tempDict in self.currentSelectedTagArray) {
            if (((NSNumber *)(tempDict[@"id"])).integerValue == parentIntger) {
                [self.currentSelectedTagArray removeObject:tempDict];
                break;
            }
        }
    }
}

#pragma mark - 底部标签相关数据
- (void)currentSelectedTagArrayNeedAddTagDict:(NSDictionary *)tagDict index:(NSInteger)index {
    [self.currentSelectedTagArray addObject:tagDict];
    [self checkNoLimitTagSelectWithTagDict:[tagDict mutableCopy] index:index];
}

- (void)currentSelectedTagArrayNeedDeleteTagDict:(NSDictionary *)tagDict index:(NSInteger)index {
    [self.currentSelectedTagArray removeObject:tagDict];

}
- (void)currentSelectedTagArrayNeedDeleteAll {
    [self.currentSelectedTagArray removeAllObjects];
}

@end


@implementation HQTagViewTableviewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initMethod];
    }
    return self;
}

- (void)initMethod {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, CGRectGetWidth(([UIScreen mainScreen].bounds)) / 2 - 40, cellHeight)];
    self.titleLabel.font = [UIFont systemFontOfSize:14];
    self.titleLabel.textAlignment = NSTextAlignmentLeft;
    [self.contentView addSubview:self.titleLabel];
    
    self.markImageView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetWidth(([UIScreen mainScreen].bounds)) / 2  - 30, 0, 30, cellHeight)];
    self.markImageView.userInteractionEnabled = YES;
    self.markImageView.contentMode = UIViewContentModeCenter;
    [self.contentView addSubview:self.markImageView];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, cellHeight - lineWidth, CGRectGetWidth([UIScreen mainScreen].bounds)/ 2, lineWidth)];
    lineView.backgroundColor = LineColor;
    [self.contentView addSubview:lineView];
}

- (void)refreshWithTitle:(NSString *)title cellState:(HQTagViewTableViewCellState)cellState {

    self.titleLabel.text = title;

    switch (cellState) {
        case HQTagViewFirstCellStateNormal:
        {
            self.markImageView.hidden = YES;
            self.titleLabel.textColor = TextColor;
            self.contentView.backgroundColor = [UIColor whiteColor];
        }
            break;
        case HQTagViewFirstCellStateHasSelect:
        {
            self.markImageView.hidden = YES;
            self.titleLabel.textColor = TextColor;
//            self.markImageView.image = [UIImage imageNamed:@"select"];
            self.contentView.backgroundColor = [UIColor whiteColor];
            
        }
            break;
        case HQTagViewFirstCellStateCurrentSelect:
        {
            self.markImageView.hidden = NO;
            self.titleLabel.textColor = TextColor;
            self.markImageView.image = [UIImage imageNamed:TagCellGrayArrowsImageNamed];
            self.contentView.backgroundColor = CellGrayColor;
        }
            break;
        case HQTagViewSecondCellStateNormal:
        {
            self.markImageView.hidden = YES;
            self.titleLabel.textColor = TextColor;
            self.contentView.backgroundColor = CellGrayColor;
        }
            break;
        case HQTagViewSecondCellStateIsSelect:
        {
            self.markImageView.hidden = NO;
            self.titleLabel.textColor = RedColor;
            self.markImageView.image = [UIImage imageNamed:TagCellRedCheckMarkImageNamed];
            self.contentView.backgroundColor = CellGrayColor;
        }
            break;
            
        default:
            break;
    }
}

@end

@implementation HQTagViewSelectButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initMethod];
        [self reFreshUI];
    }
    return self;
}

- (void)initMethod {
    self.backgroundColor = COLOR(255, 242, 242);
    self.clipsToBounds = YES;
    self.layer.cornerRadius = CGRectGetMidY(self.bounds);
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(13, 0, 0, 0)];
    self.titleLabel.font = [UIFont systemFontOfSize:13];
    self.titleLabel.textColor = RedColor;
    self.titleLabel.text = @"";
    [self.titleLabel sizeToFit];
    [self addSubview:self.titleLabel];
    
    self.closeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.bounds) - 20, CGRectGetMidY(self.bounds) - 3.5, 7, 7)];
    self.closeImageView.userInteractionEnabled = YES;
    self.closeImageView.image = [UIImage imageNamed:TagCellRedXImageNamed];
    [self addSubview:self.closeImageView];
    
    self.buttonControl = [[UIControl alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.bounds) - CGRectGetHeight(self.bounds), 0, CGRectGetHeight(self.bounds), CGRectGetHeight(self.bounds))];
    [self.buttonControl addTarget:self action:@selector(buttonControlClick) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.buttonControl];
}

- (void)reFreshUI {
    [self.titleLabel sizeToFit];
    self.titleLabel.center = CGPointMake(self.titleLabel.center.x, CGRectGetHeight(self.bounds) / 2);
    CGRect tempFrame = self.frame;
    tempFrame.size.width = CGRectGetWidth(self.titleLabel.bounds) + 20 + tempFrame.size.height;
    
    self.frame = tempFrame;
    self.buttonControl.frame = CGRectMake(CGRectGetWidth(self.bounds) - CGRectGetHeight(self.bounds), 0, CGRectGetHeight(self.bounds), CGRectGetHeight(self.bounds));
    self.closeImageView.frame = CGRectMake(CGRectGetWidth(self.bounds) - 20, CGRectGetMidY(self.bounds) - 3.5, 7, 7);
}

- (void)setDataDict:(NSDictionary *)dataDict {
    _dataDict = dataDict;
    self.titleLabel.text = dataDict[@"name"];
    [self reFreshUI];
}

- (void)buttonControlClick {
    if (self.tagView && self.dataDict) {
        for (NSDictionary *tagDict in self.tagView.currentSelectedTagArray) {
            if ([HQTagView tagDictisEqual:tagDict tagDict2:self.dataDict]) {
                
                [self.tagView currentSelectedTagArrayNeedDeleteTagDict:tagDict index:-1];
                [self.tagView changeSelectStateArray:NO withDict:self.dataDict];
                [self.tagView.firstClassTableView reloadData];
                [self.tagView.secendClassTableView reloadData];
                [self.tagView needReFreshConfirmButtonBackgroundView];
                break;
            }
        }
    }
    
    
    
}
@end

@implementation HQTagViewSameDataModel

@end
