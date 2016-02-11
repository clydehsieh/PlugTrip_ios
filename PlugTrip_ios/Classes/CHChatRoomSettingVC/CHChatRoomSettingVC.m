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
}

@end

static NSString *cellIdentifier = @"cell";

@implementation CHChatRoomSettingVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _userInfo = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"userInfo"]];
    _userNicknameTF.text = _userInfo[@"nickName"];
    _userNicknameLabel.text = _userNicknameTF.text;
    _userNicknameTF.delegate = self;
    
    [self initUserTableView];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableView
-(void)initUserTableView{
    
    [_usersTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:cellIdentifier];
    _usersTableView.delegate = self;
    _usersTableView.dataSource = self;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    members = [[NSMutableArray alloc]init];
    
    [_chatRoomMembers enumerateObjectsUsingBlock:^(NSDictionary *dic, NSUInteger idx, BOOL * _Nonnull stop) {
        
        //不是房主時
        if (![[dic objectForKey:@"isHost"]boolValue]) {
            [members addObject:dic];
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
           _userNicknameLabel.text = _userNicknameTF.text;
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

#pragma mark - switch actions
- (IBAction)showOnMapSwitchStateChange:(UISwitch *)sender {
    
    if (sender.isOn) {
        NSLog(@"show on map!");
    }else{
        NSLog(@"not show on map!");
    }
    
}

- (IBAction)shareGPSSwitchStateChange:(UISwitch *)sender {
    
    if (sender.isOn) {
        NSLog(@"share GPS!");
    }else{
        NSLog(@"not share GPS!");
    }
    
}


#pragma mark - Button actions

- (IBAction)backBtnAction:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)leftChatRoomBtnAction:(id)sender {
    
    
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
