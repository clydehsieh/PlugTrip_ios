//
//  CHMoveableTableView.h
//  adventrip_ios
//
//  Created by Chin-Hui Hsieh  on 12/3/15.
//  Copyright © 2015 twoyears44. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CHMoveableTableViewCell.h"

@interface CHMoveableTableView : UITableView <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSMutableArray *objects;

@end
