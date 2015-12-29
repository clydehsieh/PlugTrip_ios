//
//  CHMapViewVC.h
//  PlugTrip_ios
//
//  Created by Chin-Hui Hsieh  on 12/23/15.
//  Copyright © 2015 Chin-Hui Hsieh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMaps/GoogleMaps.h>
#import "MapVCSearchView.h"
#import "MapVCMenuView.h"
#import "CHImagePickerView.h"
#import "myDB.h"

@interface CHMapViewVC : UIViewController <GMSMapViewDelegate,MapVCSeachViewDelegate,MapVCMenuViewDelegate,CHImagePickerViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *mapDisplayView;
@property (strong, nonatomic) GMSMapView *mapView;
@property (strong, nonatomic) GMSPlacesClient *placesClient;
@property (nonatomic) BOOL isInitialLayout;
@property (nonatomic) NSArray *modes; //紀錄 同夥 分析
@property (nonatomic) int currentModeType;

@end
