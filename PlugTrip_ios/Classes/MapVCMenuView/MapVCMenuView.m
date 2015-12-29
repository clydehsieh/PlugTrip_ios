//
//  MapVCMenuView.m
//  adventrip_ios
//
//  Created by Chin-Hui Hsieh  on 12/3/15.
//  Copyright © 2015 twoyears44. All rights reserved.
//

#import "MapVCMenuView.h"

@implementation MapVCMenuView

- (id)initWithFrame:(CGRect)frame owner:(id)owner {
    NSArray *xibs = [[NSBundle mainBundle]loadNibNamed:@"MapVCMenuView" owner:self options:nil];
    self = xibs[0];
    
    if (self) {
        
        [self setFrame:frame];
        self.layer.borderColor = [[UIColor colorWithRed:70/255.0f green:171/255.0f blue:247/255.0f alpha:1.0] CGColor];
        self.layer.borderWidth = 2.0f;
        self.layer.cornerRadius = 5.0f;
        
        
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"identifer"];
        _tableView.delegate = self;
        _tableView.dataSource = self;

        
        
        
//        NSArray *array = [self subviews];
//        for (int i=0 ; i< [array count]; i++) {
//            if ([array[i] isKindOfClass:[UIButton class]]) {
//                UIButton *btn = (UIButton *)array[i];
//                CALayer *layer=[[CALayer alloc]init];
//                layer.frame = btn.bounds;
//                layer.opacity = 0.4f;
//                layer.backgroundColor=[UIColor blackColor].CGColor;
//                btn.layer.mask = layer;
//                
//            }
//        }
        
    }
    return self;
}

-(IBAction)menuActions:(UIButton *)sender
{
    NSArray *array = [self subviews];
    
    for (int i=0 ; i< [array count]; i++) {
        if ([array[i] isKindOfClass:[UIButton class]]) {
            UIButton *btn = (UIButton *)array[i];
            if (![btn isEqual:sender]) {
                btn.layer.mask.opacity = 0.4f;
            }else
            {
                btn.layer.mask.opacity = 1.0f;
            }
        }
    }
    
    
    if ([self.delegate respondsToSelector:@selector(didSelectTheMenu:)]) {
        [self.delegate didSelectTheMenu:sender];
    }
    
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"identifier"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"identifier"];
        
        UILabel *label = [[UILabel alloc] initWithFrame:cell.frame];
        label.tag = 1;
        label.center = cell.center;
        [cell addSubview:label];
    }
    
    UILabel *label = (UILabel *)[cell viewWithTag:1];
    label.text = [NSString stringWithFormat:@"旅程%ld", (long)indexPath.row];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 34;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSLog(@"Select indexPath:%ld", (long)indexPath.row);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
