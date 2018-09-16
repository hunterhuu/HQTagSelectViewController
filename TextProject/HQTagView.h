//
//  HQTagView.h
//  thirdtest
//
//  Created by 胡奇 on 2018/6/13.
//  Copyright © 2018年 胡奇. All rights reserved.
//

#define TagCellGrayArrowsImageNamed @"Fill 1 Copy"
#define TagCellRedCheckMarkImageNamed @"select"
#define TagCellRedXImageNamed @"job_red_x"

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, HQTagViewTableViewCellState) {
    HQTagViewFirstCellStateNormal,
    HQTagViewFirstCellStateHasSelect,
    HQTagViewFirstCellStateCurrentSelect,
    HQTagViewSecondCellStateNormal,
    HQTagViewSecondCellStateIsSelect
};

@class HQTagViewSelectButton;
@interface HQTagView : UIView <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, copy) void (^confirmButtonClickBlock)(NSArray <NSDictionary *>*selectTagArray);
@property (nonatomic, copy) void (^closeButtonClickBlock)(NSArray <NSDictionary *>*selectTagArray);
@property (nonatomic, copy) void (^overflowMaxSelectNumberWarningBlock)(void);

@property (nonatomic, strong) NSArray *dataArray;

- (instancetype)initWithFrame:(CGRect)frame;
- (void)setSelectButtonWithDict:(NSArray <NSDictionary *>*)selectArray;



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


@end

@interface HQTagViewTableviewCell : UITableViewCell

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *markImageView;
@property (nonatomic, assign) HQTagViewTableViewCellState cellState;

- (void)initMethod;
- (void)refreshWithTitle:(NSString *)title cellState:(HQTagViewTableViewCellState)cellState;
@end

@interface HQTagViewSelectButton : UIView
@property (nonatomic, weak) HQTagView *tagView;
@property (nonatomic, strong) NSDictionary *dataDict;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *closeImageView;
@property (nonatomic, strong) UIControl *buttonControl;
@end


@interface HQTagViewSameDataModel : NSObject

@property (nonatomic, copy) NSString *mainkey;
@property (nonatomic, assign) NSInteger firstClassIndex;
@property (nonatomic, assign) NSInteger secondClassIndex;

@end
