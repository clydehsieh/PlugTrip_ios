//
//  CHReadTripCodeVC.m
//  PlugTrip_ios
//
//  Created by Chin-Hui Hsieh  on 2/3/16.
//  Copyright © 2016 Chin-Hui Hsieh. All rights reserved.
//

#import "CHReadTripCodeVC.h"

@interface CHReadTripCodeVC ()

@end

@implementation CHReadTripCodeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)readCode:(NSString *)tripCode{
    
    if (![tripCode isEqualToString:@""]) {
        
        [self dismissViewControllerAnimated:YES completion:^{
            [self.delegate didLoadTheTripDate];
        }];
        
    }else{
        NSLog(@"Load data fail");
    }
    
    
    
}


#pragma mark
#pragma Btn Actions

- (IBAction)backBtnAction:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)readCodeBtnAction:(id)sender {
    
    UIAlertController *readTripCodeAC = [UIAlertController alertControllerWithTitle:@"輸入聊天室代號" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    // set textfield to AC
    [readTripCodeAC addTextFieldWithConfigurationHandler:^(UITextField *textField){
        textField.placeholder = @"enter trip code";
    }];
    
    // set cancel btn to AC
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        //
    }];
    
    // set ok btn to AC
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        UITextField *tripCode = readTripCodeAC.textFields.firstObject;
        NSLog(@"You are search room code:%@",tripCode.text);
        [self readCode:tripCode.text];
        
    }];
        
    // apply btns to AC
    [readTripCodeAC addAction:cancelAction];
    [readTripCodeAC addAction:okAction];
    
    // show AC
    [self presentViewController:readTripCodeAC animated:YES completion:nil];
    
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
