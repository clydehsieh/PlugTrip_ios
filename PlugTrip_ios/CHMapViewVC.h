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

@interface CHMapViewVC : UIViewController <GMSMapViewDelegate,MapVCSeachViewDelegate,MapVCMenuViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *mapDisplayView;

@property (strong, nonatomic) GMSMapView *mapView;
@property (strong, nonatomic) GMSPlacesClient *placesClient;

@end
