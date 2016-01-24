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
    NSMutableArray *users;
}

@end

static NSString *cellIdentifier = @"cell";

@implementation CHChatRoomSettingVC

- (void)viewDidLoad {
    [super viewDidLoad];

    
    users = [NSMutableArray arrayWithObjects:@"鄭博文",@"謝啟大",@"謝錦輝", nil];
    
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
    
    return _chatRoomMembers.count;
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
    
    UILabel *userName = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 200, cell.frame.size.height)];
    PFObject *obj = _chatRoomMembers[indexPath.row];
    userName.text = [obj objectForKey:@"userID"];
    [cell addSubview:userName];
    
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
