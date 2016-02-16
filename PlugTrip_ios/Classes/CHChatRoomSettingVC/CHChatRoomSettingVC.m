//
//  CHChatRoomSettingVC.m
//  PlugTrip_ios
//
//  Created by Chin-Hui Hsieh  on 1/21/16.
//  Copyright © 2016 Chin-Hui Hsieh. All rights reserved.
//

#import "CHChatRoomSettingVC.h"


@interface CHChatRoomSettingVC ()
{
    NSMutableArray *members;
    
    UIActivityIndicatorView *activityIndicator;
    
    CLLocationManager *locationManager;
    int countNo;
    
}

@end

static NSString *cellIdentifier = @"cell";

@implementation CHChatRoomSettingVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    countNo = 0;
    _userInfo = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"userInfo"]];
    _roomInfo = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults]objectForKey: @"roomInfo"]];

    
    
    //GPS setting
//    [self gpsSetting];

    _userNicknameTF.delegate = self;
    
    
}

-(void)viewWillLayoutSubviews{
    
    if (countNo == 0) {
        [self indicatorSetting];
        [self indicatorStart];
    }
    countNo +=1;
    
}

-(void)viewWillAppear:(BOOL)animated{
    
//    [self indicatorStart];
}

-(void)viewDidAppear:(BOOL)animated{
    [self loadChatMember];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)gpsSetting{
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    [locationManager startUpdatingLocation];
}

// ...load data and build tableview
-(void)loadChatMember{
    
    
    [[CHFIreBaseAdaptor sharedInstance]queryMemberByRoomID:_roomInfo[@"roomID"] success:^(FDataSnapshot *snapshot) {
        
        NSLog(@"setting room 載入member成功, 開始建立table");
        NSDictionary *dic = snapshot.value;
        _chatRoomMembers = [NSMutableArray arrayWithArray:[dic allValues]];
        
        [self initUserTableView];
        
        
    } failure:^{
        
        //
        NSLog(@"setting room 載入member失敗");
        [self dismissViewControllerAnimated:YES completion:nil];
        
    }];
    
}

#pragma mark - UITableView
-(void)initUserTableView{
    
    NSString *uuid = _userInfo[@"UUID"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@",uuid];
    NSArray *result = [_chatRoomMembers filteredArrayUsingPredicate:predicate];
    NSDictionary *locUser = [result firstObject];
    
    //init switch
    [_isShareGPSSwitch  setOn:[locUser[@"isShareGPS"] boolValue]];
    [_isShowOnMapSwitch setOn:[_roomInfo[@"isShowOnMap"] boolValue]];
    _roomIDLabel.text = _roomInfo[@"roomID"];
    
    [_usersTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:cellIdentifier];
    _usersTableView.delegate = self;
    _usersTableView.dataSource = self;
    [_usersTableView reloadData];
    [self indicatorStop];

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    members = [[NSMutableArray alloc]init];
    
    [_chatRoomMembers enumerateObjectsUsingBlock:^(NSDictionary *dic, NSUInteger idx, BOOL * _Nonnull stop) {
        
        //不是房主時
        if (![[dic objectForKey:@"uuid"] isEqualToString:_userInfo[@"UUID"]]) {
            [members addObject:dic];
            
        }else{
            
            _userNicknameTF.text = dic[@"userNickname"];
//            _userNicknameLabel.text = _userNicknameTF.text;
        }
    
    }];
    
    return members.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    //重複使用cell reuseidentifier
//    static NSString *cellIdentifier = @"cell";
    
    //客製化cell
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }else{
        
        NSArray *array = [cell subviews];
        for (UIView *v in array)
        {
            [v removeFromSuperview];
        }
    }
    
    //load data
    UILabel *userName = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 200, cell.frame.size.height)];
    NSDictionary *dic = members[indexPath.row];
    userName.text = [dic objectForKey:@"userNickname"];
    [cell addSubview:userName];
    
//    //不是房主時
//    if (![[dic objectForKey:@"isHost"]boolValue]) {
//        userName.text = [dic objectForKey:@"userNickname"];
//        [cell addSubview:userName];
//
//    }
    
    return cell;
}

#pragma mark - TextField

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //touch other view will hide keyboard
    if (![_userNicknameTF isExclusiveTouch]) {
        [_userNicknameTF resignFirstResponder];
    }
    
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    [textField resignFirstResponder];
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    
    
    if ([textField.text isEqualToString:@""]) {
        _userNicknameTF.text = _userInfo[@"nickName"];
    }else{
        
       [[CHFIreBaseAdaptor sharedInstance] updateMemberBykey:@"userNickname" andValue:_userNicknameTF.text success:^(FDataSnapshot *snapshot) {
           
           //
//           _userNicknameLabel.text = _userNicknameTF.text;
           [_userInfo setValue: _userNicknameTF.text forKey:@"nickName"];
           [[NSUserDefaults standardUserDefaults]setObject:_userInfo forKey:@"userInfo"];
           
       } failure:^{
           
           //
           _userNicknameTF.text = _userInfo[@"nickName"];
       }];
        
        
//        PFQuery *query = [PFQuery queryWithClassName:@"Member"];
//        [query whereKey:@"userID" equalTo:_userInfo[@"userID"]];
//        [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
//            
//            if (!error) {
//                
//                PFObject *obj = [objects firstObject];
//                [obj setObject:_userNicknameTF.text forKey:@"nickName"];
//                [obj saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
//                    if (succeeded) {
//                        
//                        _userNicknameLabel.text = _userNicknameTF.text;
//                        [_userInfo setValue: _userNicknameTF.text forKey:@"nickName"];
//                        [[NSUserDefaults standardUserDefaults]setObject:_userInfo forKey:@"userInfo"];
//                        NSLog(@"nickName updated!");
//                    }else{
//                         NSLog(@"fait to update nickName. Error:\n");
//                        _userNicknameTF.text = _userInfo[@"nickName"];
//                    }
//                }];
//                
//                
//                
//            }else{
//                NSLog(@"fait to update nickName. Error:\n");
//                _userNicknameTF.text = _userInfo[@"nickName"];
//            }
//        }];
        
        
//        PFObject *obj = [PFObject objectWithClassName:@"Users"];
//        
//        [obj setValue:_userNicknameTF.text forKey:@"nickName"];
//        [obj saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
//            if (succeeded) {
//                NSLog(@"nickName updated!");
//                
//                _userNicknameLabel.text = _userNicknameTF.text;
//                [_userInfo setValue: _userNicknameTF.text forKey:@"nickName"];
//                [[NSUserDefaults standardUserDefaults]setObject:_userInfo forKey:@"userInfo"];
//                
//            }else{
//                NSLog(@"fait to update nickName. Error:\n");
//            }
//        }];
        

    }
    
    
    
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"locationManager didFailWithError: %@", error);

}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"didUpdateToLocation: %@", newLocation);
    CLLocation *currentLocation = newLocation;
    
    if (currentLocation != nil) {
        
        NSLog(@"\n\n(lat:%@,Long:%@)",[NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude],[NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude]);
    
    }
}

#pragma mark - switch actions
- (IBAction)showOnMapSwitchStateChange:(UISwitch *)sender {
    
    [_roomInfo setObject:[NSNumber numberWithBool:sender.isOn]   forKey:@"isShowOnMap"];
    [[NSUserDefaults standardUserDefaults] setObject:_roomInfo forKey:@"roomInfo"];
    
    if (sender.isOn) {
        NSLog(@"show on map!");
    }else{
        NSLog(@"not show on map!");
    }

    
}

//是否允許他人得到自己位置
- (IBAction)shareGPSSwitchStateChange:(UISwitch *)sender {
    
    if (sender.isOn) {
        NSLog(@"share GPS!");
    }else{
        NSLog(@"not share GPS!");
    }
    
    [[CHFIreBaseAdaptor sharedInstance]updateMemberBykey:@"isShareGPS" andValue:[NSNumber numberWithBool:sender.isOn] success:^(FDataSnapshot *snapshot) {
        NSLog(@"Update member isShareGPS success");
        
    } failure:^{
        NSLog(@"Update member isShareGPS Fail");
    }];
    
    
    

    
}


#pragma mark - Button actions

- (IBAction)backBtnAction:(id)sender {
    
//    [self dismissViewControllerAnimated:YES completion:^{
//
//        if ([self.delegate respondsToSelector:@selector(didLeftSettingVC)]) {
//            [self.delegate didLeftSettingVC];
//        }
//        
//    }];
    
    if ([self.delegate respondsToSelector:@selector(didLeftSettingVC)]) {
        [self.delegate didLeftSettingVC];
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    
    
    
    
}

- (IBAction)leftChatRoomBtnAction:(id)sender {
    
    [[CHFIreBaseAdaptor sharedInstance] deleteMemberByRoomID:_roomInfo[@"roomID"] andUUID:_userInfo[@"UUID"] success:^{
        //
        NSLog(@"Delete success");
        [self dismissViewControllerAnimated:YES completion:nil];
        
    } failure:^{
        
        NSLog(@"Delete fail");
        
        
    }];
    
    
//    [[CHFIreBaseAdaptor sharedInstance] deleteMemberByUUID:_userInfo[@"UUID"] success:^{
//        //
//        NSLog(@"Delete success");
//        [self dismissViewControllerAnimated:YES completion:nil];
//        
//    } failure:^{
//        
//        NSLog(@"Delete fail");
//        
//        
//    }];
    
    
}


-(void)indicatorSetting
{
    activityIndicator = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(0.0f, 0.0f, 32.0f, 32.0f)];
    [activityIndicator setCenter:self.view.center];
    [activityIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
}
- (void)indicatorStart
{
    UIView *view = [[UIView alloc] initWithFrame:self.view.frame];
    [view setTag:203];
    [view setBackgroundColor:[UIColor blackColor]];
    [view setAlpha:0.8];
    [self.view addSubview:view];
    
    [self.view addSubview:activityIndicator];
    [activityIndicator startAnimating];
}

- (void)indicatorStop
{
    UIView *view = (UIView *)[self.view viewWithTag:203];
    [view removeFromSuperview];
    
    [activityIndicator stopAnimating];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
