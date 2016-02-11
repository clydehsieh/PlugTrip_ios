//
//  CHFIreBaseAdaptor.m
//  PlugTrip_ios
//
//  Created by Chin-Hui Hsieh  on 2/9/16.
//  Copyright © 2016 Chin-Hui Hsieh. All rights reserved.
//

#import "CHFIreBaseAdaptor.h"



#define FIRE_BASE_URL @"https://flickering-fire-7787.firebaseio.com/"

@interface CHFIreBaseAdaptor()
{
    Firebase *rootRef;
    
    Firebase *messageRef;
    Firebase *usersRef;
    Firebase *membersRef;
    Firebase *roomRef;
}


@end

@implementation CHFIreBaseAdaptor

+ (id)sharedInstance {
    
    static id sharedInstance = nil;
    
    static dispatch_once_t p = 0;
    
    dispatch_once(&p, ^{
        sharedInstance = [[CHFIreBaseAdaptor alloc]init];
    });
    
    return sharedInstance;
}


- (id)init {
    
    self = [super init];
    if (self) {
        
        [self setReference];
        
        
    }
    return self;
}

-(void)setReference{
    
    // root namespace.
    rootRef = [[Firebase alloc] initWithUrl:FIRE_BASE_URL];
    
    // second layer
    messageRef = [rootRef childByAppendingPath: @"message"];
    usersRef   = [rootRef childByAppendingPath: @"user"   ];
    membersRef = [rootRef childByAppendingPath: @"members"];
    roomRef = [rootRef childByAppendingPath: @"room"];
    
}


#pragma mark
#pragma mark - Add
-(void)createUserByUUID:(NSString *)uuid andNickname:(NSString *)nickname success:(void(^)())successBloack failure:(void (^)())failureBlacok{

    //確認ＵＵＩＤ是否重複註冊
    [[[usersRef queryOrderedByChild:@"uuid"] queryEqualToValue:uuid]
     observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
         
         if ([snapshot.value isEqual:[NSNull null]]) {
             
             /// 尚未註冊
             //預設user data
             NSDictionary *valuse =  @{@"uuid":uuid,
                                       @"nickname":nickname,
                                       @"timestamp":@""
                                       };
             //隨機建立obj key
             Firebase *usersLayer2Ref = [usersRef childByAutoId];
             
             //上傳server
             [usersLayer2Ref setValue:valuse withCompletionBlock:^(NSError *error, Firebase *ref)
              {
                  if (error) {
                      NSLog(@"Data could not be saved.");
                  } else {
                      NSLog(@"Data saved successfully.");
                      
                      NSString *postId = ref.key;
                      NSLog(@"Key:%@",postId);
                  }
              }];
             
         }else{
             /// 已經註冊
             NSLog(@"The UUID has been registed!");
         }
     }];
}

-(void)createRoomByUUID:(NSString *)uuid success:(void(^)())successBloack failure:(void (^)())failureBlacok{
    
    //確認ＵＵＩＤ是否重複註冊
    [[[roomRef queryOrderedByChild:@"uuid"] queryEqualToValue:uuid]
     observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
         
         
         if ([snapshot.value isEqual:[NSNull null]]) {

             /// 尚未註冊
             //預設user data
             NSDictionary *valuse =  @{@"uuid":uuid,
                                       };
             //隨機建立obj key
             Firebase *roomLayer2Ref = [roomRef childByAutoId];
             
             //上傳server
             [roomLayer2Ref setValue:valuse withCompletionBlock:^(NSError *error, Firebase *ref)
              {
                  if (error) {
                      
                      NSLog(@"Data could not be saved.");
                      [[NSNotificationCenter defaultCenter] postNotificationName:@"indicatorStop" object:nil];
                      
                  } else {
                      NSLog(@"new room created successfully, start to create member");
                      
                      NSString *roomID = ref.key;
                      [self createMemberByUUID:uuid andNickname:@"New one" andRoomID:roomID isHost:YES success:nil failure:nil];
 
                  }
              }];
             
         }else{
             /// 已經註冊
             NSLog(@"room重複出現uuid");
             [[NSNotificationCenter defaultCenter] postNotificationName:@"indicatorStop" object:nil];
         }
         


     }];
}

-(void)createMemberByUUID:(NSString *)uuid andNickname:(NSString *)nickname andRoomID:(NSString *)roomID isHost:(BOOL)isHost success:(void(^)())successBloack failure:(void (^)())failureBlacok{
    
    //確認ＵＵＩＤ是否重複註冊
    [[[membersRef queryOrderedByChild:@"uuid"] queryEqualToValue:uuid]
     observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
         
         if ([snapshot.value isEqual:[NSNull null]]) {
             
             /// 尚未註冊
             //預設user data
             NSDictionary *valuse =  @{@"uuid":uuid,
                                       @"userNickname":nickname,
                                       @"roomID":roomID,
                                       @"isHost":[NSNumber numberWithBool:isHost]
                                       };
             //隨機建立obj key
             Firebase *memberLayer2Ref = [membersRef childByAutoId];
             
             //上傳server
             [memberLayer2Ref setValue:valuse withCompletionBlock:^(NSError *error, Firebase *ref)
              {
                  if (error) {
                      NSLog(@"Data could not be saved.");
                  } else {
                      NSLog(@"new member create successfully.");
                  }
                  [[NSNotificationCenter defaultCenter] postNotificationName:@"indicatorStop" object:nil];
              }];
             
         }else{
             /// 已經註冊
             NSLog(@"member重複出現uuid");
             [[NSNotificationCenter defaultCenter] postNotificationName:@"indicatorStop" object:nil];
         }
     }];
}

-(void)createMsgByUUID:(NSString *)uuid andMSg:(NSString *)msg andRoomID:(NSString *)roomID success:(void(^)())successBloack failure:(void (^)())failureBlacok{
    
    //預設user data
    NSDictionary *valuse =  @{@"uuid":uuid,
                              @"message":msg,
                              @"roomID":roomID,
                              };
    
    //隨機建立obj key
    Firebase *messageLayer2Ref = [messageRef childByAutoId];
    
    [messageLayer2Ref setValue:valuse withCompletionBlock:^(NSError *error, Firebase *ref) {
        
        if (error) {
            NSLog(@"Message could not be saved.");
        } else {
            NSLog(@"new message create successfully.");
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"indicatorStop" object:nil];
    }];

    
}



#pragma mark
#pragma mark - remove




#pragma mark
#pragma mark - update
-(void)updateMemberBykey:(NSString *)key andValue:(id)value success:(void(^)(FDataSnapshot *snapshot))successBloack failure:(void (^)())failureBlacok{
    
    //User Info
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults]objectForKey: @"userInfo"]];
    
    //先找member位置
    [self queryMemberByUUID:userInfo[@"UUID"] success:^(FDataSnapshot *snapshot) {
        
        //有的話更新
        Firebase *member = [membersRef childByAppendingPath: [[snapshot.value allKeys] firstObject]];
        NSDictionary *inputValue =  @{key:value};
        [member updateChildValues:inputValue withCompletionBlock:^(NSError *error, Firebase *ref) {
            
            if (!error) {
                
                NSLog(@"Update success,\n %@",ref);
                successBloack(snapshot);
                
            }else{
                NSLog(@"update memeber FAIL!, \nerror:/n%@",error.description);
                failureBlacok();
            }
           
            
        }];
        
    } failure:^{
        NSLog(@"會員不存在, 更新失敗");
        failureBlacok();
        
    }];

}


#pragma mark
#pragma mark - query
//-(void)startChattingWithMessage:{
//    
//    __block BOOL initialAdds = YES;
//    
//    [messageRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
//        
//        tableAddedCounts +=1;
//        NSLog(@"tableAddedCounts:%d", tableAddedCounts);
//        
//        // Add the chat message to the array.
//        if (newMessagesOnTop) {
//            [self.chat insertObject:snapshot.value atIndex:0];
//        } else {
//            [self.chat addObject:snapshot.value];
//        }
//        
//        
//        
//        // Reload the table view so the new message will show up.
//        if (!initialAdds) {
//            
//            reloadCounts+=1;
//            NSLog(@"reloadCounts:%d", reloadCounts);
//            [self.tableView reloadData];
//        }
//    }];
//    
//    // Value event fires right after we get the events already stored in the Firebase repo.
//    // We've gotten the initial messages stored on the server, and we want to run reloadData on the batch.
//    // Also set initialAdds=NO so that we'll reload after each additional childAdded event.
//    [self.firebase observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
//        
//        reloadCounts+=1;
//        NSLog(@"reloadCounts:%d", reloadCounts);
//        
//        // Reload the table view so that the intial messages show up
//        [self.tableView reloadData];
//        initialAdds = NO;
//    }];
//    
//    
//    [messageRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
//        
//        NSLog(@"%@",snapshot.value);
//    }];
//}

-(void)queryRoomByUUID:(NSString *)uuid success:(void(^)(FDataSnapshot *snapshot))successBloack failure:(void (^)())failureBlacok{
    
    //確認ＵＵＩＤ是否重複註冊
    [[[roomRef queryOrderedByChild:@"uuid"] queryEqualToValue:uuid]
     observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
         
         if ([snapshot.value isEqual:[NSNull null]]) {
             //not exsit
             failureBlacok();
         }else{
             //exsit
             successBloack(snapshot);
         }
         
         [[NSNotificationCenter defaultCenter] postNotificationName:@"indicatorStop" object:nil];

     }];
}

-(void)queryRoomByRoomID:(NSString *)RoomID success:(void(^)(FDataSnapshot *snapshot))successBloack failure:(void (^)())failureBlacok{
    
    //確認ＵＵＩＤ是否重複註冊
    
    
    [roomRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        NSDictionary *dic = snapshot.value;
        NSArray *ary = [dic allKeys];
        if ([ary containsObject:RoomID]) {
            successBloack(snapshot);
        }else{
            failureBlacok();
        }
        
         [[NSNotificationCenter defaultCenter] postNotificationName:@"indicatorStop" object:nil];

     }];
}

-(void)queryMemberByUUID:(NSString *)uuid success:(void(^)(FDataSnapshot *snapshot))successBloack failure:(void (^)())failureBlacok{
    
    //確認ＵＵＩＤ是否重複註冊
    [[[membersRef queryOrderedByChild:@"uuid"] queryEqualToValue:uuid]
     observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
         
         if ([snapshot.value isEqual:[NSNull null]]) {
             failureBlacok();
         }else{
             successBloack(snapshot);
         }
         
         [[NSNotificationCenter defaultCenter] postNotificationName:@"indicatorStop" object:nil];

     }];
}

-(void)queryMemberByRoomID:(NSString *)roomID success:(void(^)(FDataSnapshot *snapshot))successBloack failure:(void (^)())failureBlacok{
    
    
    [[[membersRef queryOrderedByChild:@"roomID"] queryEqualToValue:roomID]
     observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
         
         if ([snapshot.value isEqual:[NSNull null]]) {
             failureBlacok();
         }else{
             successBloack(snapshot);
         }
         
         [[NSNotificationCenter defaultCenter] postNotificationName:@"indicatorStop" object:nil];
         
     }];
}

-(void)queryMsgByRoomID:(NSString *)roomID success:(void(^)(FDataSnapshot *snapshot))successBloack failure:(void (^)())failureBlacok{
    
    //首次更新｀
    [[[messageRef queryOrderedByChild:@"roomID"] queryEqualToValue:roomID]
     observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
         
         if ([snapshot.value isEqual:[NSNull null]]) {
             failureBlacok();
         }else{
             successBloack(snapshot);
         }
         
         [[NSNotificationCenter defaultCenter] postNotificationName:@"indicatorStop" object:nil];
     }];
}

-(void)queryMsgRegularlyByRoomID:(NSString *)roomID success:(void(^)(FDataSnapshot *snapshot))successBloack failure:(void (^)())failureBlacok{

    [[[messageRef queryOrderedByChild:@"roomID"] queryEqualToValue:roomID]
     observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
         
         if ([snapshot.value isEqual:[NSNull null]]) {
             failureBlacok();
         }else{
             successBloack(snapshot);
         }
         
         [[NSNotificationCenter defaultCenter] postNotificationName:@"indicatorStop" object:nil];
     }];
}



#pragma mark
#pragma mark - Test
-(void)setUserValueWithUUID:(NSString *)uuid andNickname:(NSString *)nickname{
    

    NSDictionary *valuse =  @{@"uuid":uuid,
                              @"nickname":nickname,
                              @"timestamp":@""
                              };
    Firebase *usersLayer2Ref = [usersRef childByAutoId];

    [usersLayer2Ref setValue:valuse withCompletionBlock:^(NSError *error, Firebase *ref)
    {
        if (error) {
            NSLog(@"Data could not be saved.");
        } else {
            NSLog(@"Data saved successfully.");
            
            NSString *postId = ref.key;
            NSLog(@"Key:%@",postId);
        }
    }];
}

-(void)queryTest{
    
    
    [[usersRef queryOrderedByChild:@"uuid"]
     observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
         
         NSLog(@"child:\n%@", snapshot);
     }];
    
    [[usersRef queryOrderedByChild:@"uuid"]
     observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
         
         
         NSDictionary *dic = snapshot.value;
         NSLog(@"child:\n%@", snapshot);
     }];
    
    [[[usersRef queryOrderedByChild:@"uuid"] queryEqualToValue:@"444"]
     observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
         
         NSLog(@"child:\n%@", snapshot);
     }];
    

    
}














@end



















