//
//  CHMoveableTableViewCell.m
//  adventrip_ios
//
//  Created by Chin-Hui Hsieh  on 12/3/15.
//  Copyright © 2015 twoyears44. All rights reserved.
//

#define VIEWCOLOR [UIColor colorWithRed:70/255.0f green:171/255.0f blue:247/255.0f alpha:1.0]

#import "CHMoveableTableViewCell.h"

@implementation CHMoveableTableViewCell

- (void)awakeFromNib {
    // Initialization code
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    UIView *view = (UIView *)[self viewWithTag:2];
    UILabel *subTitleLabel = (UILabel *)[self viewWithTag:3];
    
    if (selected) {
        view.backgroundColor = [UIColor redColor];
        subTitleLabel.textColor = [UIColor redColor];

    }else
    {
        view.backgroundColor = VIEWCOLOR;
        subTitleLabel.textColor = [UIColor blackColor];
    }
    
    // Configure the view for the selected state
}

@end
