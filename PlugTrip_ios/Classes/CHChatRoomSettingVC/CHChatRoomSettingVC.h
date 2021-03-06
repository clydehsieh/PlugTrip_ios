//
//  CHChatRoomSettingVC.h
//  PlugTrip_ios
//
//  Created by Chin-Hui Hsieh  on 1/21/16.
//  Copyright © 2016 Chin-Hui Hsieh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CHFIreBaseAdaptor.h"

#import <Parse/Parse.h>


@protocol CHChatRoomSettingVCDelegate <NSObject>

-(void)didLeftSettingVC;

@end



@interface CHChatRoomSettingVC : UIViewController <UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate,CLLocationManagerDelegate>

@property (nonatomic) id<CHChatRoomSettingVCDelegate>delegate;

@property (weak, nonatomic) IBOutlet UIButton *backBtn;
@property (weak, nonatomic) IBOutlet UIButton *leftBtn;
@property (weak, nonatomic) IBOutlet UISwitch *isShowOnMapSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *isShareGPSSwitch;

@property (weak, nonatomic) IBOutlet UITextField *userNicknameTF;
@property (weak, nonatomic) IBOutlet UILabel *roomIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *userNicknameLabel;

@property (nonatomic)NSMutableArray *chatRoomMembers;//contain PFObject
@property (weak, nonatomic) IBOutlet UITableView *usersTableView;

@property (nonatomic, retain) NSMutableDictionary *userInfo; // 紀錄user 資料
@property (nonatomic, retain) NSMutableDictionary *roomInfo; // 紀錄user 資料

@end
