//
//  MapVCMenuView.h
//  adventrip_ios
//
//  Created by Chin-Hui Hsieh  on 12/3/15.
//  Copyright © 2015 twoyears44. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MapVCMenuViewDelegate <NSObject>

-(void)didSelectTheMenu:(UIButton *)btn;

@end

@interface MapVCMenuView : UIView

@property (nonatomic) id<MapVCMenuViewDelegate>delegate;

- (id)initWithFrame:(CGRect)frame owner:(id)owner;
@end
