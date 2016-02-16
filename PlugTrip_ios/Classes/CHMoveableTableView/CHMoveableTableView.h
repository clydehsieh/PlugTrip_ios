//
//  CHMoveableTableView.h
//  adventrip_ios
//
//  Created by Chin-Hui Hsieh  on 12/3/15.
//  Copyright © 2015 twoyears44. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CHMoveableTableViewCell.h"

@class CHMoveableTableView;

@protocol CHMoveableTableViewDelegate <NSObject>

- (void)moveableTableView:(CHMoveableTableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;

@end


@interface CHMoveableTableView : UITableView <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic)  id<CHMoveableTableViewDelegate>chDelegate;
@property (strong, nonatomic) NSMutableArray *objects;

@end
