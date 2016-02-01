//
//  CHChatRoomVC.m
//  PlugTrip_ios
//
//  Created by Chin-Hui Hsieh  on 1/20/16.
//  Copyright © 2016 Chin-Hui Hsieh. All rights reserved.
//
#define FONTSIZE 12.0f
#define IMAGE_WIDE   44.0f
#define IMAGE_HEIGHT  44.0f
#define editingMovement 100.0f

#define R_Color [UIColor colorWithRed:24/255.0f green:89/255.0f blue:36/255.0f alpha:0.9]
#define P_Color [UIColor colorWithRed:24/255.0f green:89/255.0f blue:36/255.0f alpha:0.9]



#import "CHChatRoomVC.h"

@interface CHChatRoomVC (){
    
    NSMutableArray	*messages;
    NSTimer *receivedMsg;
}

@end

static NSString *identifier = @"identifier";

@implementation CHChatRoomVC

- (void)viewDidLoad {
    [super viewDidLoad];

    //inits
    messages = [[NSMutableArray alloc]init];
    
    
    //show & hide keyboard
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    //timer setting
    receivedMsg = [NSTimer scheduledTimerWithTimeInterval:5.0f
                                                   target:self selector:@selector(loadMsgFromServer:) userInfo:nil repeats:YES];
    [receivedMsg invalidate];
    
    //Msg tableView
    [_messageContentTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:identifier];
    _messageContentTableView.delegate = self;
    _messageContentTableView.dataSource = self;
    
}

-(void)viewDidAppear:(BOOL)animated{
    
    [receivedMsg isValid];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - TextField

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //touch other view will hide keyboard
    if (![_messageTextField isExclusiveTouch]) {
        [_messageTextField resignFirstResponder];
    }
   
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    NSValue *kbFrame = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect keyboardFrame = [kbFrame CGRectValue];
    CGFloat height = keyboardFrame.size.height;
    
    // we need to set a negative constant value here.
    _messageViewShiftForYaxis.constant = height;
    
    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    _messageViewShiftForYaxis.constant = 0;
    
    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - UITableView delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    NSLog(@"messages:%lu",(unsigned long)messages.count);
    
    return [messages count];
    /*
    messages contain dictionary, the keys are
     
     content
     userId
     userImage
     
     */
    
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //load data
    PFObject *object = messages[indexPath.row];
    NSString *msg = [object objectForKey:@"messageContent"];
    NSString *userID = [object objectForKey:@"messageOwnerID"];
    NSString *roomID = [object objectForKey:@"roomID"];


    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    
    NSArray *array = [cell subviews];
    for (UIView *v in array)
    {
        [v removeFromSuperview];
    }
    
    //強制更新為裝置螢幕大小
    CGRect newCellFrame = cell.frame;
    newCellFrame.size.width = tableView.frame.size.width;
    cell.frame = newCellFrame;
    
    //設定寬度
    float chatContentWidth_Max = cell.frame.size.width - (IMAGE_WIDE *3);
    
    //判斷行高
    UIFont *font = [UIFont systemFontOfSize:FONTSIZE];
    
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          font, NSFontAttributeName,
                                          nil];
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:msg attributes:attributesDictionary];
    
    // chatContent width max = cell width - 3*imageWidth
    CGRect rect = [string boundingRectWithSize:CGSizeMake(chatContentWidth_Max,CGFLOAT_MAX)
                                       options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                       context:nil];
    
    NSMutableAttributedString *string_userID = [[NSMutableAttributedString alloc] initWithString:userID attributes:attributesDictionary];
    CGRect rect_userID = [string_userID boundingRectWithSize:CGSizeMake(chatContentWidth_Max,CGFLOAT_MAX)
                                                     options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                                     context:nil];
    
    
    float labelWidth = MAX(rect.size.width, rect_userID.size.width) + 20 ;
    
    //接收跟發送者
    float userImageLocationX = 0;
    float chatContentLocationX = 0;
    UIColor *chatcontentColor ;
    ///!!!:wait for coding :使用者ＩＤ
    if (![userID isEqualToString:@"user"])
    {
        //received message, left side
        userImageLocationX = 0;
        chatContentLocationX = IMAGE_WIDE;
        chatcontentColor = [UIColor lightGrayColor];
        
    }
    else
    {
        userImageLocationX = cell.frame.size.width - IMAGE_WIDE;
        chatContentLocationX = userImageLocationX - labelWidth;
        chatcontentColor = [UIColor greenColor];
        
    }
    
    //User Image View
    UIImageView *userImageView = [[UIImageView alloc]initWithFrame:CGRectMake(userImageLocationX, 0, IMAGE_WIDE, IMAGE_HEIGHT)];
    userImageView.image = [UIImage imageNamed:messages[indexPath.row][@"userImage"]];
    userImageView.layer.cornerRadius = IMAGE_WIDE /2.0;
    userImageView.layer.masksToBounds=YES;
    [cell addSubview:userImageView];
    
    //Label
    //width_min > userID | Content ; width_nax < chatContentWidth_Max
    
    UILabel *chatContentLabel = [[UILabel alloc]initWithFrame:CGRectMake(chatContentLocationX, FONTSIZE, labelWidth, rect.size.height+rect_userID.size.height)];
    
    chatContentLabel.font = font;
    //    chatContentLabel.textAlignment = NSTextAlignmentLeft;
    
    NSString *str= [NSString stringWithFormat:@" %@:\n %@", userID,msg];
    
    chatContentLabel.text = str;
    chatContentLabel.layer.borderWidth  = 0.5f;
    chatContentLabel.layer.cornerRadius = 5.0f;
    chatContentLabel.backgroundColor  = chatcontentColor;
    [chatContentLabel setNumberOfLines:0];
    chatContentLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [cell addSubview:chatContentLabel];
    
    return cell;
    
    
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PFObject *object = messages[indexPath.row];
    NSString *msg = [object objectForKey:@"messageContent"];
    NSString *userID = [object objectForKey:@"messageOwnerID"];
    NSString *roomID = [object objectForKey:@"roomID"];
    
    
    //設定chatContent max width
    float chatContentWidth_Max = tableView.frame.size.width - (IMAGE_WIDE *3);
    
    //判斷行高
    UIFont *font = [UIFont systemFontOfSize:FONTSIZE];
    
    NSString *chatContentString = msg;
    
    
    
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          font, NSFontAttributeName,
                                          nil];
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:chatContentString attributes:attributesDictionary];
    
    // chatContent width max = cell width - 3*imageWidth
    CGRect rect = [string boundingRectWithSize:CGSizeMake(chatContentWidth_Max,CGFLOAT_MAX)
                                       options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                       context:nil];
    
    float height = rect.size.height + FONTSIZE + FONTSIZE + 10 ;
    
    return ( height >= (FONTSIZE*3) ) ? height:(FONTSIZE*3);
}



#pragma mark - Btn actions

- (IBAction)backBtnAction:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)sendBtnAction:(id)sender {

    // Write data to cloud
    PFObject *messageTable = [PFObject objectWithClassName:@"Messages"];
    messageTable[@"roomID"] = @"0002";
    messageTable[@"messageContent"] = _messageTextField.text;
    messageTable[@"messageOwnerID"] = @"000A";
    [messageTable saveInBackground];
    
    // clear input
    _messageTextField.text = @"";
    [_messageTextField resignFirstResponder];
    
    //retrive data from cloud
    PFQuery *query = [PFQuery queryWithClassName:@"Messages"];
    [query whereKey:@"roomID" equalTo:@"0002"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            // The find succeeded.
            NSLog(@"Successfully retrieved %lu rows data.", (unsigned long)objects.count);
            
            // Do something with the found objects
            for (PFObject *object in objects) {
//                NSLog(@"%@", object.objectId);
//                NSLog(@"%@", [object objectForKey:@"roomID"]);
//                NSLog(@"%@", [object objectForKey:@"messageContent"]);
//                NSLog(@"%@\n", [object objectForKey:@"messageOwnerID"]);
            }
            
            messages = [NSMutableArray arrayWithArray:objects];
            [_messageContentTableView reloadData];
            
            
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
    
    
    // When users indicate they are Giants fans, we subscribe them to that channel.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation addUniqueObject:@"Giants" forKey:@"channels"];
    [currentInstallation saveInBackground];
    
    // Send a notification to all devices subscribed to the "Giants" channel.
    PFPush *push = [[PFPush alloc] init];
    [push setChannel:@"Giants"];
    [push setMessage:@"The Giants just scored!"];
    [push sendPushInBackground];
    
    

}


- (void)loadMsgFromServer:(NSTimer*)timer {

    NSLog(@"Received Msg every 5s");
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
