//
//  CHMoveableTableView.m
//  adventrip_ios
//
//  Created by Chin-Hui Hsieh  on 12/3/15.
//  Copyright © 2015 twoyears44. All rights reserved.
//

#import "CHMoveableTableView.h"

@implementation CHMoveableTableView

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        // Do something
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognized:)];
        [self addGestureRecognizer:longPress];
        
        [self initSetting];
        
    }
    return self;
}

- (id) initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        // Do something
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognized:)];
        [self addGestureRecognizer:longPress];
        
        [self initSetting];
        
    }
    
    
    return self;
}

-(void)initSetting {
    
    _objects = [@[@"高雄",@"旗津",@"鳳山",@"中山"] mutableCopy];

    [self registerNib:[UINib nibWithNibName:@"CHMoveableTableViewCell" bundle:nil] forCellReuseIdentifier:@"identifier"];
    
    self.backgroundColor = [UIColor clearColor];
    self.rowHeight = 60;
    self.delegate = self;
    self.dataSource = self;
    
}

#pragma mark -
#pragma mark - UITableView data source and delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.objects count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cIdentifier = @"identifier";
    
    CHMoveableTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cIdentifier forIndexPath:indexPath];
    
    if (!cell) {
        cell = [tableView dequeueReusableCellWithIdentifier:cIdentifier];
    }
    
    NSString *placeName ;
    BOOL isMergeState;
    
    if ([self.objects[indexPath.row] isKindOfClass:[NSDictionary class]]) {
        
        NSDictionary *dic = self.objects[indexPath.row];
        NSArray *placeArray = dic[@"placeName"];
        long index = [dic[@"number"] longLongValue];
        placeName = placeArray[index];
        isMergeState = YES;
                             
    }else{
        placeName = self.objects[indexPath.row];
        isMergeState = NO;
    }
    
    // Update cell content from data source.
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
    imageView.backgroundColor = [UIColor redColor];
    imageView.hidden = (isMergeState)?NO:YES;
    
    UIView *backgroundView = (UIView *)[cell viewWithTag:2];
    backgroundView.backgroundColor = [UIColor blueColor];

    UILabel *placeTitle = (UILabel *)[cell viewWithTag:3];
    NSString *object = placeName;
    placeTitle.text = object;
    
    UIImageView *markImage = (UIImageView *)[cell viewWithTag:4];
    markImage.backgroundColor = [UIColor redColor];

    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.objects removeObjectAtIndex:indexPath.row];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (IBAction)longPressGestureRecognized:(id)sender {
    
    UILongPressGestureRecognizer *longPress = (UILongPressGestureRecognizer *)sender;
    UIGestureRecognizerState state = longPress.state;
    
    CGPoint location = [longPress locationInView:self];
    NSIndexPath *indexPath = [self indexPathForRowAtPoint:location];
    
    
    static UIView       *snapshot = nil;        ///< A snapshot of the row user is moving.
    static NSIndexPath  *sourceIndexPath = nil; ///< Initial index path, where gesture begins.
    static NSIndexPath  *targetIndexPath = nil; ///<
    static BOOL  isMergeState = NO;
    
    switch (state) {
        case UIGestureRecognizerStateBegan: {
            if (indexPath) {
                sourceIndexPath = indexPath;
                
                UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
                [self selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
                // Take a snapshot of the selected row using helper method.
                snapshot = [self customSnapshoFromView:cell];
                
                // Add the snapshot as subview, centered at cell's center...
                __block CGPoint center = cell.center;
                snapshot.center = center;
                snapshot.alpha = 0.0;
                [self addSubview:snapshot];
                [UIView animateWithDuration:0.25 animations:^{
                    
                    // Offset for gesture location.
                    center.y = location.y;
                    snapshot.center = center;
                    snapshot.transform = CGAffineTransformMakeScale(1.05, 1.05);
                    snapshot.alpha = 0.98;
                    cell.alpha = 0.0;
                    
                } completion:^(BOOL finished) {
                    
                    cell.hidden = YES;
                    
                }];
            }
            break;
        }
            
        case UIGestureRecognizerStateChanged: {
            CGPoint center = snapshot.center;
            center.y = location.y;
            snapshot.center = center;
            
            UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
        
            //make sure the loc range is between -cellHeight/2 ~ cellHeight/2
            float loc = location.y - cell.frame.size.height/2 - cell.frame.size.height * sourceIndexPath.row;
            float margin   = 0.5;
            float mergeMin = cell.frame.size.height * (1.0 - margin);
            float mergeMax = cell.frame.size.height * (1.0 + margin);
            NSLog(@"%f < %f < %f",mergeMin,fabs(loc),mergeMax);
            
            
            if (self.objects.count!=1) {
                
                if (fabs(loc) > mergeMin && fabs(loc) < mergeMax) {
                    
                    //get the mergeIndexPath
                    long shiftRowValue = (loc>0) ? indexPath.row +1 : indexPath.row -1;
                    shiftRowValue = (shiftRowValue <0) ? 0 :shiftRowValue;
                    targetIndexPath = [NSIndexPath indexPathForRow:shiftRowValue inSection:indexPath.section];
                    //                NSLog(@"shiftRowValue:%ld",shiftRowValue);
                    isMergeState = YES;

                }else {
                    
                    if (fabs(loc) > mergeMax){
                        
                        if (indexPath && ![indexPath isEqual:sourceIndexPath]) {
                            
                            // ... update data source.
                            [self.objects exchangeObjectAtIndex:indexPath.row withObjectAtIndex:sourceIndexPath.row];
                            
                            // ... move the rows.
                            [self moveRowAtIndexPath:sourceIndexPath toIndexPath:indexPath];
                            
                            // ... and update source so it is in sync with UI changes.
                            sourceIndexPath = indexPath;
                        }
                    }
                    
                    isMergeState = NO;
                    targetIndexPath = nil;
                }
            }
            
            //merge state animation
            snapshot.alpha = (isMergeState)? 0.3:0.98;
         
            break;
        }
            
        default: {
            // Clean up.
            UITableViewCell *cell = [self cellForRowAtIndexPath:sourceIndexPath];
            cell.hidden = NO;
            cell.alpha = 0.0;
            
            //merge cell!
            if (isMergeState) {
                ///!!!: wait for coding :merge cell
                if (targetIndexPath) {
                    NSLog(@"merge cell: %ld",targetIndexPath.row);
                    
                    NSMutableArray *newArray;
                    
                    
                    if ([self.objects[targetIndexPath.row] isKindOfClass:[NSDictionary class]]) {
                        
                        NSDictionary *dic_target = self.objects[targetIndexPath.row];
                        NSArray *ary_target = dic_target[@"placeName"];
                        
                        //merge後的地名arry
                        newArray = [[NSMutableArray alloc]initWithArray:ary_target];
                        
                        if ([self.objects[sourceIndexPath.row] isKindOfClass:[NSDictionary class]]){
                            
                            //目標是dictionary , 自己也是dictionary
                            NSDictionary *dic_source = self.objects[sourceIndexPath.row];
                            NSArray *ary_source = dic_source[@"placeName"];
                            
                            [ary_source enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                [newArray addObject:obj];
                            }];
                        }else if([self.objects[sourceIndexPath.row] isKindOfClass:[NSString class]]){
                            
                            //目標是dictionary , 自己是nsstring
                            [newArray addObject:self.objects[sourceIndexPath.row]];
                        }
                        
                        
                    }else if([self.objects[targetIndexPath.row] isKindOfClass:[NSString class]]){
                        
                        NSString *placeName = self.objects[targetIndexPath.row];
                        
                        //merge後的地名arry
                        newArray = [[NSMutableArray alloc]initWithObjects:placeName, nil];
                        
                        if ([self.objects[sourceIndexPath.row] isKindOfClass:[NSDictionary class]]){
                            
                            //目標是NSString , 自己是dictionary
                            NSDictionary *dic_source = self.objects[sourceIndexPath.row];
                            NSArray *ary_source = dic_source[@"placeName"];
                            
                            [ary_source enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                [newArray addObject:obj];
                            }];
                            
                        }else if([self.objects[sourceIndexPath.row] isKindOfClass:[NSString class]]){
                            
                            //目標是NSString , 自己是NSString
                            [newArray addObject:self.objects[sourceIndexPath.row]];
                            
                        }
                    }
                    
                    NSDictionary *newDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                            newArray,@"placeName",
                                            [NSNumber numberWithLong:newArray.count-1],@"number",
                                            nil];
                    self.objects[targetIndexPath.row] = newDic;
                    [self.objects removeObjectAtIndex:sourceIndexPath.row];
                }
            }
            
            
            //動畫
            [UIView animateWithDuration:0.25 animations:^{
                
                snapshot.center = cell.center;
                snapshot.transform = CGAffineTransformIdentity;
                snapshot.alpha = 0.0;
                cell.alpha = 1.0;
                
            } completion:^(BOOL finished) {
                
                sourceIndexPath = nil;
                [snapshot removeFromSuperview];
                snapshot = nil;
                NSLog(@"%@",_objects);
                [self reloadData];
                
                [self selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            }];
            
            break;
        }
    }
}

#pragma mark - Helper methods

/** @brief Returns a customized snapshot of a given view. */
- (UIView *)customSnapshoFromView:(UIView *)inputView {
    
    // Make an image from the input view.
    UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, NO, 0);
    [inputView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Create an image view.
    UIView *snapshot = [[UIImageView alloc] initWithImage:image];
    snapshot.layer.masksToBounds = NO;
    snapshot.layer.cornerRadius = 0.0;
    snapshot.layer.shadowOffset = CGSizeMake(-5.0, 0.0);
    snapshot.layer.shadowRadius = 5.0;
    snapshot.layer.shadowOpacity = 0.4;
    
    return snapshot;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
