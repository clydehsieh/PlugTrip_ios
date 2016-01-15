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
#import "MapVCSearchView.h"
#import "MapVCMenuView.h"
#import "CHImagePickerView.h"
#import "CHScrollView.h"
#import "myDB.h"

@interface CHMapViewVC : UIViewController <GMSMapViewDelegate,MapVCSeachViewDelegate,MapVCMenuViewDelegate,CHImagePickerViewDelegate,CHScrollViewDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,CLLocationManagerDelegate,UITextFieldDelegate>

@property (nonatomic) BOOL isTripCreate;//確認是否已經建立local旅程, 初始化判斷用

@property (nonatomic, retain) CLLocationManager *locationManager; // 紀錄GPS
@property (nonatomic, retain) NSMutableDictionary *tripInfo; // 紀錄Trip 資料

@property (weak, nonatomic) IBOutlet UIView *mapDisplayView;
@property (strong, nonatomic) GMSMapView *mapView;
@property (strong, nonatomic) GMSPlacesClient *placesClient;
@property (nonatomic) BOOL isInitialLayout;
@property (nonatomic) NSArray *modes; //紀錄 同夥 分析
@property (nonatomic) int currentModeType;
@property (nonatomic) NSMutableArray *pickedAssets;

@property (nonatomic) BOOL isShowImagesOnMap;

@end
