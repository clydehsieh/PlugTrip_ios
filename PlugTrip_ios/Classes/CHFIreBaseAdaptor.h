//
//  CHFIreBaseAdaptor.h
//  PlugTrip_ios
//
//  Created by Chin-Hui Hsieh  on 2/9/16.
//  Copyright © 2016 Chin-Hui Hsieh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Firebase/Firebase.h>

@interface CHFIreBaseAdaptor : NSObject

+ (id)sharedInstance ;


//增加
-(void)createUserByUUID:(NSString *)uuid andNickname:(NSString *)nickname success:(void(^)())successBloack failure:(void (^)())failureBlacok;
-(void)createRoomByUUID:(NSString *)uuid success:(void(^)())successBloack failure:(void (^)())failureBlacok;
-(void)createMemberByUUID:(NSString *)uuid andNickname:(NSString *)nickname andRoomID:(NSString *)roomID isHost:(BOOL)isHost success:(void(^)())successBloack failure:(void (^)())failureBlacok;
-(void)createMsgByUUID:(NSString *)uuid andMSg:(NSString *)msg andRoomID:(NSString *)roomID success:(void(^)())successBloack failure:(void (^)())failureBlacok;

//刪除
-(void)deleteMemberByUUID:(NSString *)uuid success:(void(^)())successBloack failure:(void (^)())failureBlacok;
-(void)deleteMemberByRoomID:(NSString *)roomID andUUID:(NSString *)uuid success:(void(^)())successBloack failure:(void (^)())failureBlacok;

//更新
-(void)updateMemberBykey:(NSString *)key andValue:(id)value success:(void(^)(FDataSnapshot *snapshot))successBloack failure:(void (^)())failureBlacok;

//搜尋
-(void)queryUserByUUID:(NSString *)uuid exist:(void(^)(FDataSnapshot *snapshot))existBloack notExist:(void (^)())notExistBlacok;

-(void)queryRoomByUUID:(NSString *)uuid success:(void(^)(FDataSnapshot *snapshot))successBloack failure:(void (^)())failureBlacok;
-(void)queryRoomByRoomID:(NSString *)RoomID success:(void(^)(FDataSnapshot *snapshot))successBloack failure:(void (^)())failureBlacok;

-(void)queryMemberByUUID:(NSString *)uuid success:(void(^)(FDataSnapshot *snapshot))successBloack failure:(void (^)())failureBlacok;
-(void)queryMemberByRoomID:(NSString *)roomID success:(void(^)(FDataSnapshot *snapshot))successBloack failure:(void (^)())failureBlacok;
-(void)queryMemberNotSingleTimeByRoomID:(NSString *)roomID success:(void(^)(FDataSnapshot *snapshot))successBloack failure:(void (^)())failureBlacok;

-(void)queryMsgByRoomID:(NSString *)roomID success:(void(^)(FDataSnapshot *snapshot))successBloack failure:(void (^)())failureBlacok;
-(void)queryMsgRegularlyByRoomID:(NSString *)roomID success:(void(^)(FDataSnapshot *snapshot))successBloack failure:(void (^)())failureBlacok;



-(void)setUserValueWithUUID:(NSString *)uuid andNickname:(NSString *)nickname;
-(void)queryTest;


@end
