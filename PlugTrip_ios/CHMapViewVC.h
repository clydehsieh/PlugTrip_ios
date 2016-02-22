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
#import "CHReadTripCodeVC.h"
#import "CHMoveableTableView.h"
#import "BCKeychainManager.h"
#import "EasyTableView.h"
#import "CHFIreBaseAdaptor.h"

#define TAG_menuBtn       101
#define TAG_modeBtn       102
#define TAG_addPhotoBtn   103
#define TAG_chatRoomBtn   104
#define TAG_modeBtnBackgroundView 201
#define TAG_coverTripTitleView    202
#define TAG_indicator_maskView    203
#define TAG_quickChatView         204
#define TAG_horizonTableView      205
#define TAG_tripTitleText 301
#define TAG_quickChatText 302
#define TAG_moveTV 401
#define TAG_horizontalView_CellImgView   501
#define TAG_horizontalView_CellLabel     502

#define WIDTH_moveTV 88
#define IMAGEHEIGHT    50
#define MODEBTN_WIDTH  80.0
#define MODEBTN_HEIGHT 44.0
#define MEMBER_MapMarker_SIZE 20


#define BOTTOM_VIEW_FRAME1 CGRectMake(0, _mapDisplayView.frame.size.height-IMAGEHEIGHT, _mapDisplayView.frame.size.width-MODEBTN_WIDTH, IMAGEHEIGHT)
#define BOTTOM_VIEW_FRAME2 CGRectMake(0, _mapDisplayView.frame.size.height-IMAGEHEIGHT, _mapDisplayView.frame.size.width-MODEBTN_WIDTH*2, IMAGEHEIGHT)


@interface CHMapViewVC : UIViewController <GMSMapViewDelegate,MapVCSeachViewDelegate,MapVCMenuViewDelegate,CHImagePickerViewDelegate,CHScrollViewDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,CLLocationManagerDelegate,UITextFieldDelegate,CHReadTripCodeVCDelegate,EasyTableViewDelegate,CHMoveableTableViewDelegate,CHChatRoomSettingVCDelegate>

@property (nonatomic) BOOL isTripCreate;//確認是否已經建立local旅程, 初始化判斷用

//device user info
@property (nonatomic, retain) NSMutableDictionary *userInfo; // 紀錄user 資料

// Chating room
@property (nonatomic, retain) NSMutableDictionary *roomInfo; // 紀錄user 資料
@property (nonatomic) NSMutableArray *chatRoomMembers;//現有加入的聊天室成員, 內包PFObject資料
@property (nonatomic) NSString *roomID;//現有加入的聊天室ID

@property (nonatomic) BOOL isChatRoomJoin;//確認是否已經加入聊天室, 初始化判斷用
@property (nonatomic) BOOL isCheckChatRoomJoin;//確認是否完成加入聊天室判斷, 初始化判斷用


//Trip info
@property (nonatomic, retain) NSMutableDictionary *tripInfo; // 紀錄Trip 資料

//GPS
@property (nonatomic, retain) CLLocationManager *locationManager; // 紀錄GPS


@property (weak, nonatomic) IBOutlet UIView *mapDisplayView;
@property (strong, nonatomic) GMSMapView *mapView;
@property (strong, nonatomic) GMSPlacesClient *placesClient;
@property (nonatomic) BOOL isInitialLayout;

@property (nonatomic) NSArray *modes; //@"分析",@"紀錄",@"同夥",@"旅程"
@property (nonatomic) int currentModeType;



@property (nonatomic) NSMutableArray *pickedAssets;

@property (nonatomic) BOOL isShowImagesOnMap;

@end



//NSString *const tableName_tripPhoto = @"Trip_Photo_Info";
//NSString *const tableName_userGPS = @"user_GPS";
