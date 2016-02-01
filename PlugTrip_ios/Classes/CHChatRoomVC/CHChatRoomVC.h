//
//  CHChatRoomVC.h
//  PlugTrip_ios
//
//  Created by Chin-Hui Hsieh  on 1/20/16.
//  Copyright © 2016 Chin-Hui Hsieh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface CHChatRoomVC : UIViewController <UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *backBtn;
@property (weak, nonatomic) IBOutlet UITableView *messageContentTableView;
@property (weak, nonatomic) IBOutlet UIButton *sendMessageBtn;
@property (weak, nonatomic) IBOutlet UITextField *messageTextField;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageViewShiftForYaxis;



@end
