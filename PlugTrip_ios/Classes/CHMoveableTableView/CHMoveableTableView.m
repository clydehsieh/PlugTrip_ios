//
//  CHMoveableTableView.m
//  adventrip_ios
//
//  Created by Chin-Hui Hsieh  on 12/3/15.
//  Copyright © 2015 twoyears44. All rights reserved.
//

#import "CHMoveableTableView.h"

@interface CHMoveableTableView (){
    
}

@end


@implementation CHMoveableTableView

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        // Do something
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognized:)];
        [self addGestureRecognizer:longPress];
        
//        [self initSetting];
        
    }
    return self;
}

- (id) initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        // Do something
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognized:)];
        [self addGestureRecognizer:longPress];
        
//        [self initSetting];
        
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

-(void)setObjects:(NSMutableArray *)objects{
    
    if (objects) {
        
        
        _objects = [[NSMutableArray alloc]init];
        
        [objects enumerateObjectsUsingBlock:^(NSDictionary  *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [_objects addObject:obj[@"items"]];
        }];
 
        [self registerNib:[UINib nibWithNibName:@"CHMoveableTableViewCell" bundle:nil] forCellReuseIdentifier:@"identifier"];
        
        self.backgroundColor = [UIColor clearColor];
        self.rowHeight = 60;
        self.delegate = self;
        self.dataSource = self;
    }

    
}

#pragma mark -
#pragma mark - UITableView data source and delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [_objects count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSArray *items = _objects[section];
    
    return [items count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    
    return 30;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cIdentifier = @"identifier";
    
    //init cells
    CHMoveableTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cIdentifier forIndexPath:indexPath];
    
    if (!cell) {
        cell = [tableView dequeueReusableCellWithIdentifier:cIdentifier];
    }

    
    NSArray      *items    = _objects[indexPath.section];
    id            item   = items[indexPath.row];
    
    NSString *placeName ;
    BOOL isMergeState;
    
    if ([item isKindOfClass:[NSDictionary class]]) {
        
        placeName = item[@"title"];
        isMergeState = NO;
                             
    }else if([item isKindOfClass:[NSArray class]]){
        
        NSDictionary *dic = item[1];
        placeName = dic[@"title"];
        isMergeState = YES;
    }
    

    // Update cell content from data source.
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
    imageView.backgroundColor = [UIColor redColor];
    imageView.hidden = (isMergeState)?NO:YES;
    
    UIView *backgroundView = (UIView *)[cell viewWithTag:2];
    backgroundView.backgroundColor = [UIColor whiteColor];

    UILabel *placeTitle = (UILabel *)[cell viewWithTag:3];
    NSString *object = placeName;
    placeTitle.text = object;
    placeTitle.textColor = [UIColor lightGrayColor];
    
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
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        NSMutableArray *items = _objects[indexPath.section];
        [items removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
}

- (IBAction)longPressGestureRecognized:(id)sender {
    
    UILongPressGestureRecognizer *longPress = (UILongPressGestureRecognizer *)sender;
    UIGestureRecognizerState state = longPress.state;
    
    CGPoint location = [longPress locationInView:self];
    NSIndexPath *indexPath = [self indexPathForRowAtPoint:location];
    
    
    static UIView       *snapshot = nil;        ///< A snapshot of the row user is moving.
    static NSIndexPath  *sourceIndexPath = nil; ///< Initial index path, where gesture begins.
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
            
//            UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
//            float distanceOfCellAndLoc = location.y - cell.center.y;
//            float mergeRange = cell.frame.size.height * 0.1;
//            NSLog(@"%f",distanceOfCellAndLoc);
            
            if (indexPath && ![indexPath isEqual:sourceIndexPath]){
                
                NSLog(@"exchange cell with (set:%ld,row:%ld)",(long)indexPath.section,(long)indexPath.row);
                
                [self beginUpdates];
                
                if (indexPath.section == sourceIndexPath.section) {
                    
                    NSLog(@"moveing to the same section");
                    
                    // ... update data source.
                    NSMutableArray       *items    = [NSMutableArray arrayWithArray:_objects[indexPath.section]];
                    [items exchangeObjectAtIndex:indexPath.row withObjectAtIndex:sourceIndexPath.row];
                    _objects[indexPath.section] = items;
                    
                    [items enumerateObjectsUsingBlock:^(NSDictionary *item, NSUInteger idx, BOOL * _Nonnull stop) {
                        NSLog(@"%@",item[@"title"]);
                    }];
                    
                    // ... move the rows.
                    [self moveRowAtIndexPath:sourceIndexPath toIndexPath:indexPath];
                    
                    
                }else {
                    
                    NSMutableArray       *sourceItems         = [NSMutableArray arrayWithArray:_objects[sourceIndexPath.section]];
                    NSMutableArray       *destinationItems    = [NSMutableArray arrayWithArray:_objects[indexPath.section]];
                    id item = sourceItems[sourceIndexPath.row];
                    NSIndexPath *destinationIndexPath;
                    
                    if (indexPath.section > sourceIndexPath.section){
                        NSLog(@"moveing to next section");
                        [sourceItems removeObject:item];
                        [destinationItems insertObject:item atIndex:0];
                        destinationIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
                      
                    }else {
                        NSLog(@"moveing to previous section");
                        [sourceItems removeObject:item];
                        [destinationItems addObject:item];
                        destinationIndexPath = [NSIndexPath indexPathForRow:indexPath.row+1 inSection:indexPath.section];
                    }
                    
                    indexPath = destinationIndexPath;
                    
                    _objects[sourceIndexPath.section] = sourceItems;
                    _objects[indexPath.section]       = destinationItems;
                    
                    [self deleteRowsAtIndexPaths:[NSArray arrayWithObject: sourceIndexPath] withRowAnimation:UITableViewRowAnimationNone];
                    [self insertRowsAtIndexPaths:[NSArray arrayWithObject: indexPath]       withRowAnimation:UITableViewRowAnimationNone];
                    
                }
                
                [self endUpdates];
                
                // ... and update source so it is in sync with UI changes.
                sourceIndexPath = indexPath;
                UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
                cell.hidden = YES;
                
//                if (fabs(distanceOfCellAndLoc) < mergeRange) {
//                    
//                    //
//                    NSLog(@"Show Merge state");
//                    
//                }else{
//                    
//                    //
//                    NSLog(@"exchange cell");
//                    // ... and update source so it is in sync with UI changes.
//                    sourceIndexPath = indexPath;
//                    
//                }
                
                
                
            }
   
            //merge state animation
            [UIView animateWithDuration:0.25 animations:^{
                
                snapshot.alpha = (isMergeState)? 0.7:0.98;
                
            } completion:^(BOOL finished) {
                
            }];
            
         
            break;
        }
            
        default: {
            // Clean up.
            UITableViewCell *cell = [self cellForRowAtIndexPath:sourceIndexPath];
            cell.hidden = NO;
            cell.alpha = 0.0;
            
   
            //merge cell!
            if (isMergeState && self.objects.count !=1 && (indexPath && ![indexPath isEqual:sourceIndexPath]) ) {
                
                NSMutableArray *newArray;
                

                if ([self.objects[indexPath.row] isKindOfClass:[NSDictionary class]]) {
                    
                    NSDictionary *dic_target = self.objects[indexPath.row];
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
                    
                    
                }else if([self.objects[indexPath.row] isKindOfClass:[NSString class]]){
                    
                    NSString *placeName = self.objects[indexPath.row];
                    
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
                self.objects[indexPath.row] = newDic;//目標更新資料
                [self.objects removeObjectAtIndex:sourceIndexPath.row];//原本檔案刪除

                
            }

            
//            //merge cell!
//            if (isMergeState) {
//                ///!!!: wait for coding :merge cell
//                if (sourceIndexPath) {
//                    NSLog(@"merge cell: %ld",targetIndexPath.row);
//                    
//                    NSMutableArray *newArray;
//                    
//                    
//                    if ([self.objects[targetIndexPath.row] isKindOfClass:[NSDictionary class]]) {
//                        
//                        NSDictionary *dic_target = self.objects[targetIndexPath.row];
//                        NSArray *ary_target = dic_target[@"placeName"];
//                        
//                        //merge後的地名arry
//                        newArray = [[NSMutableArray alloc]initWithArray:ary_target];
//                        
//                        if ([self.objects[sourceIndexPath.row] isKindOfClass:[NSDictionary class]]){
//                            
//                            //目標是dictionary , 自己也是dictionary
//                            NSDictionary *dic_source = self.objects[sourceIndexPath.row];
//                            NSArray *ary_source = dic_source[@"placeName"];
//                            
//                            [ary_source enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//                                [newArray addObject:obj];
//                            }];
//                        }else if([self.objects[sourceIndexPath.row] isKindOfClass:[NSString class]]){
//                            
//                            //目標是dictionary , 自己是nsstring
//                            [newArray addObject:self.objects[sourceIndexPath.row]];
//                        }
//                        
//                        
//                    }else if([self.objects[targetIndexPath.row] isKindOfClass:[NSString class]]){
//                        
//                        NSString *placeName = self.objects[targetIndexPath.row];
//                        
//                        //merge後的地名arry
//                        newArray = [[NSMutableArray alloc]initWithObjects:placeName, nil];
//                        
//                        if ([self.objects[sourceIndexPath.row] isKindOfClass:[NSDictionary class]]){
//                            
//                            //目標是NSString , 自己是dictionary
//                            NSDictionary *dic_source = self.objects[sourceIndexPath.row];
//                            NSArray *ary_source = dic_source[@"placeName"];
//                            
//                            [ary_source enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//                                [newArray addObject:obj];
//                            }];
//                            
//                        }else if([self.objects[sourceIndexPath.row] isKindOfClass:[NSString class]]){
//                            
//                            //目標是NSString , 自己是NSString
//                            [newArray addObject:self.objects[sourceIndexPath.row]];
//                            
//                        }
//                    }
//                    
//                    NSDictionary *newDic = [NSDictionary dictionaryWithObjectsAndKeys:
//                                            newArray,@"placeName",
//                                            [NSNumber numberWithLong:newArray.count-1],@"number",
//                                            nil];
//                    self.objects[targetIndexPath.row] = newDic;
//                    [self.objects removeObjectAtIndex:sourceIndexPath.row];
//                }
//            }
            
            
            
            
            
            
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
                
                [_objects enumerateObjectsUsingBlock:^(NSArray *items, NSUInteger idx, BOOL * _Nonnull stop) {
                    [items enumerateObjectsUsingBlock:^(NSDictionary *item, NSUInteger idx, BOOL * _Nonnull stop) {
                        NSLog(@"%@",item[@"title"]);
                    }];
                }];
                
                [self reloadData];
                
                [self selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            }];
            
            break;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([self.chDelegate respondsToSelector:@selector(moveableTableView: didSelectRowAtIndexPath:)]) {
        [self.chDelegate moveableTableView:self didSelectRowAtIndexPath:indexPath];
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

-(NSInteger)turnToIndexFromIndexPath:(NSIndexPath *)indexPath andArray:(NSArray *)array{
    
    NSInteger result;
    
    int num = 0;
    for (int i=0 ; i < indexPath.section ; i++) {
        num += [array[i] count];
    }
    
    result = num + indexPath.row;
    
//    if (indexPath.section ==0) {
//        result = indexPath.row;
//
//    }else{
//        
//        int num = 0;
//        for (int i=0 ; i < indexPath.section ; i++) {
//            num += [array[i] count];
//        }
//        
//        result = num + indexPath.row;
//    }
    
    
    return result;
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
