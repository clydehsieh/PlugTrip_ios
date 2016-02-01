//
//  CHMapViewVC.h
//  PlugTrip_ios
//
//  Created by Chin-Hui Hsieh  on 12/23/15.
//  Copyright © 2015 Chin-Hui Hsieh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMaps/GoogleMaps.h>
#import <CoreLocation/CoreLocation.h>
#import <Parse/Parse.h>
#import "MapVCSearchView.h"
#import "MapVCMenuView.h"
#import "CHImagePickerView.h"
#import "CHScrollView.h"
#import "myDB.h"
#import "CHChatRoomSettingVC.h"
#import "CHChatRoomVC.h"
#import "XMPP.h"
#import "BCKeychainManager.h"


@interface CHMapViewVC : UIViewController <GMSMapViewDelegate,MapVCSeachViewDelegate,MapVCMenuViewDelegate,CHImagePickerViewDelegate,CHScrollViewDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,CLLocationManagerDelegate,UITextFieldDelegate>

@property (nonatomic) BOOL isTripCreate;//確認是否已經建立local旅程, 初始化判斷用

//device user info
@property (nonatomic, retain) NSMutableDictionary *userInfo; // 紀錄user 資料
@property (nonatomic) NSString *userID;//裝置使用者ID
@property (nonatomic) NSString *userNickName;//裝置使用者ID 暱稱
@property (nonatomic) NSString *userUUID;//裝置UUID

// Chating room
@property (nonatomic, retain) NSMutableDictionary *roomInfo; // 紀錄user 資料
@property (nonatomic) BOOL isChatRoomJoin;//確認是否已經加入聊天室, 初始化判斷用
@property (nonatomic) BOOL isCheckChatRoomJoin;//確認是否完成加入聊天室判斷, 初始化判斷用
@property (nonatomic) NSString *roomID;//現有加入的聊天室ID
@property (nonatomic) NSMutableArray *chatRoomMembers;//現有加入的聊天室成員, 內包PFObject資料

//Trip info
@property (nonatomic, retain) NSMutableDictionary *tripInfo; // 紀錄Trip 資料

//GPS
@property (nonatomic, retain) CLLocationManager *locationManager; // 紀錄GPS


@property (weak, nonatomic) IBOutlet UIView *mapDisplayView;
@property (strong, nonatomic) GMSMapView *mapView;
@property (strong, nonatomic) GMSPlacesClient *placesClient;
@property (nonatomic) BOOL isInitialLayout;
@property (nonatomic) NSArray *modes; //紀錄 同夥 分析
@property (nonatomic) int currentModeType;
@property (nonatomic) NSMutableArray *pickedAssets;

@property (nonatomic) BOOL isShowImagesOnMap;

@end
