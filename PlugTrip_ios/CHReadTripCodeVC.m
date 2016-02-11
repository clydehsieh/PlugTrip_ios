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
    
    //確認code存不存在
    ///!!!:wait for coding:確認code存不存在

    
    //如存在, 下載Json
    ///!!!:暫時使用local Json for test
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"plugtrip" ofType:@"json"];
    NSError *error = nil;
    NSData *JSONData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
    id JSONObject = [NSJSONSerialization
                     JSONObjectWithData:JSONData
                     options:NSJSONReadingAllowFragments
                     error:&error];
    
    //傳值
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate didLoadTripDate:JSONObject];
    }];
    
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
        
        // code 不能是空白
        if (![tripCode.text isEqualToString:@""]) {
             NSLog(@"You are search room code:%@",tripCode.text);
            [self readCode:tripCode.text];
        }else{
            
            UIAlertController *warningAC = [UIAlertController alertControllerWithTitle:@"請輸入Code" message:nil preferredStyle:UIAlertControllerStyleAlert];
            
            [self presentViewController:warningAC animated:YES completion:nil];
        }
   
        
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
