//
//  CHReadTripCodeVC.h
//  PlugTrip_ios
//
//  Created by Chin-Hui Hsieh  on 2/3/16.
//  Copyright © 2016 Chin-Hui Hsieh. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CHReadTripCodeVCDelegate <NSObject>

-(void)didLoadTripDate:(id)tripData;
-(void)backBtnAction;
@end




@interface CHReadTripCodeVC : UIViewController

@property (nonatomic, assign) id<CHReadTripCodeVCDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *currentCodeLabel;

@end
