//
//  CHChatRoomVC.m
//  PlugTrip_ios
//
//  Created by Chin-Hui Hsieh  on 1/20/16.
//  Copyright © 2016 Chin-Hui Hsieh. All rights reserved.
//

#import "CHChatRoomVC.h"

@interface CHChatRoomVC ()

@end

@implementation CHChatRoomVC

- (void)viewDidLoad {
    [super viewDidLoad];

    //show & hide keyboard
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    
    
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


#pragma mark - Btn actions

- (IBAction)backBtnAction:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)sendBtnAction:(id)sender {

    _messageTextField.text = @"";
    [_messageTextField resignFirstResponder];
    

    // Write data to cloud
    PFObject *messageTable = [PFObject objectWithClassName:@"Messages"];
    messageTable[@"roomID"] = @"0002";
    messageTable[@"messageContent"] = @"TEXT001";
    messageTable[@"messageOwnerID"] = @"000A";
    [messageTable saveInBackground];
    
    //retrive data from cloud
    PFQuery *query = [PFQuery queryWithClassName:@"Messages"];
    [query whereKey:@"roomID" equalTo:@"0002"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            // The find succeeded.
            NSLog(@"Successfully retrieved %lu rows data.", (unsigned long)objects.count);
            
            // Do something with the found objects
            for (PFObject *object in objects) {
                NSLog(@"%@", object.objectId);
                NSLog(@"%@", [object objectForKey:@"roomID"]);
                NSLog(@"%@", [object objectForKey:@"messageContent"]);
                NSLog(@"%@\n", [object objectForKey:@"messageOwnerID"]);
            }
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
