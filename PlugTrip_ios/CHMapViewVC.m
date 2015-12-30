//
//  CHMapViewVC.m
//  PlugTrip_ios
//
//  Created by Chin-Hui Hsieh  on 12/23/15.
//  Copyright © 2015 Chin-Hui Hsieh. All rights reserved.
//
/*
 tiers:
 0  _mapView
 4  sView (MapVCSearchView)
 
 tags:
 101  menuBtn
 
 */
#define IMAGEHEIGHT 80

#import "CHMapViewVC.h"

@interface CHMapViewVC ()
{
    MapVCSearchView *sView;
    MapVCMenuView *menuView;
    
    NSMutableArray *markerArray;
    
    CHScrollView *imageScrollView;
}

@end

NSString *const apiKey = @"AIzaSyDzElpxMxZ4_T7DP6LSYrGfoj8kpLAtgr4";


@implementation CHMapViewVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _isInitialLayout = NO;
    
    _modes = [[NSArray alloc]initWithObjects:@"紀錄",@"同夥",@"分析", nil];
    _currentModeType = 0;

}

-(void)viewDidAppear:(BOOL)animated{
    
    if (!_isInitialLayout) {
        [self initMapView];
        [self initSearchView];
        [self initMenuView];
        [self initButtons];
        [self initScrollView];
        
        _isInitialLayout = YES;
    }
    

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)initMapView{
    
    int initalZoomLevel = 14;
    // init mapView
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:24.081446
                                                            longitude:120.538854
                                                                 zoom:initalZoomLevel];
    
    _mapView = [GMSMapView mapWithFrame:_mapDisplayView.bounds camera:camera];
    [_mapDisplayView insertSubview:_mapView atIndex:0];

    //_mapView basic setting
//    _mapView.myLocationEnabled = YES;
    _mapView.settings.compassButton = YES;
//    _mapView.settings.myLocationButton = YES;
    _mapView.delegate = self;
    
}

-(void)initSearchView{
    sView = [[MapVCSearchView alloc]initWithFrame:CGRectMake(54, 5, _mapDisplayView.frame.size.width-(54+5), 44*5) owner:nil andApiServerKey:apiKey];
    sView.delegate = self;
    [_mapDisplayView insertSubview:sView atIndex:4];
}

-(void)initButtons{
    //
    UIButton *menuBtn = [[UIButton alloc]initWithFrame:CGRectMake(5, 5, 44, 44)];
    [menuBtn addTarget:self action:@selector(showMenu:) forControlEvents:UIControlEventTouchDown];
    [menuBtn setTitle:@"Me" forState:UIControlStateNormal];
    [menuBtn setBackgroundImage:[UIImage imageNamed:@"s1_1.png"] forState:UIControlStateNormal];
    menuBtn.tag = 101;
    [_mapDisplayView addSubview:menuBtn];
    
    //mode setting
    float modeBtnWidth = 80;
    float modeBtnHeight = 44;
    UIButton *modeBtn = [[UIButton alloc]initWithFrame:CGRectMake(_mapDisplayView.frame.size.width-modeBtnWidth, _mapDisplayView.frame.size.height-modeBtnHeight, modeBtnWidth, modeBtnHeight)];
    [modeBtn addTarget:self action:@selector(changeMode:) forControlEvents:UIControlEventTouchDown];
    [modeBtn setTitle:_modes[_currentModeType] forState:UIControlStateNormal];
    [modeBtn setBackgroundColor:[UIColor blueColor]];
//    [modeBtn setBackgroundImage:[UIImage imageNamed:@"s1_1.png"] forState:UIControlStateNormal];
    [_mapDisplayView addSubview:modeBtn];
    
}

-(void)initMenuView{
    
    menuView = [[MapVCMenuView alloc]initWithFrame:CGRectMake(5, 54, 44, _mapDisplayView.frame.size.height - (54+80)) owner:nil];
    menuView.delegate = self;
    [_mapDisplayView addSubview: menuView];
    menuView.hidden = YES;
}

#pragma mark - CHScrollView setting & setters & delegate
-(void)initScrollView
{
 
    //底層照片scrollview, 設定參數
    imageScrollView = [[CHScrollView alloc] initWithFrame:CGRectMake(0, _mapDisplayView.frame.size.height-IMAGEHEIGHT, _mapDisplayView.frame.size.width, IMAGEHEIGHT)];
    imageScrollView.delegateImage = self;
    imageScrollView.isCentredFirstItem = YES;
    imageScrollView.visibleImageNumber = 7;
    imageScrollView.downSizeRatio = 0.5;
    imageScrollView.imageChangeRange = 0.3;
    imageScrollView.backgroundColor = [UIColor clearColor];
    
    UIImageView *chsrollViewBackground = [[UIImageView alloc]initWithFrame:CGRectMake(0, _mapDisplayView.frame.size.height-IMAGEHEIGHT*0.5, _mapDisplayView.frame.size.width, IMAGEHEIGHT*0.5)];
    chsrollViewBackground.image = [UIImage imageNamed:@"tab_bar_bg.png"];
    [_mapDisplayView addSubview:chsrollViewBackground];
    [_mapDisplayView addSubview:imageScrollView];
    
}

-(void)scrollView:(UIScrollView *)scrollView didSelectedImage:(UIImageView *)selectedView{
    
    NSInteger tag = selectedView.tag-1;
    [self mapView:_mapView didTapMarker:markerArray[tag]];
    NSLog(@"\nYou selected chScollView the no.%ld Image",(long)selectedView.tag);
    
}

#pragma mark - Btn Actions
-(void)showMenu:(UIButton *)sender{
    
    if (menuView.hidden) {
        menuView.hidden = NO;
        NSLog(@"Show Menu");
    }else
    {
        menuView.hidden = YES;
        NSLog(@"Hide Menu");
    }
    
    //other subview action
    [sView searchBarCancelButtonClicked:nil];

}

-(void)changeMode:(UIButton *)sender{
    
    _currentModeType +=1;
    if (_currentModeType >= [_modes count]) {
        _currentModeType = 0;
    }
    
    [sender setTitle:_modes[_currentModeType] forState:UIControlStateNormal];
}




#pragma mark - MapVCSeachViewDelegate
-(void)didSelectTableSearchResultLocationAtLatitude:(NSString *)latitude andLongitude:(NSString *)longitude{
    [_mapView animateToLocation:CLLocationCoordinate2DMake(latitude.doubleValue, longitude.doubleValue)];
    
    
}

#pragma mark - menu
-(void)didSelectTheMenu:(UIButton *)btn;
{
    
    NSLog(@"\n MAP VC Tapped:%ld",btn.tag);
    
    [self setImagePicker:nil];

}

#pragma mark - CHImagePickerView setting & delegate
-(void)setImagePicker:(NSMutableArray *)assetArray
{
//    if (!_assets)
//        _assets = [[NSMutableArray alloc] init];
    
    //CHImagePickerView
    CGRect frame = CGRectMake(_mapDisplayView.frame.origin.x, _mapDisplayView.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height - _mapDisplayView.frame.origin.y);
    
    CHImagePickerView *imagePicker = [[CHImagePickerView alloc]initWithFrame:frame owner:self];
    
    if (assetArray)
        [imagePicker loadPhotosFromAssetArray:assetArray];
    else
        [imagePicker loadPhotosFromAlbum];
    
    imagePicker.backgroundColor = [UIColor whiteColor];
    imagePicker.layer.borderWidth = 2.0f;
    imagePicker.layer.borderColor = [[UIColor blueColor]CGColor];
    imagePicker.layer.cornerRadius = 10.0f;
    
    imagePicker.delegate = self;
    [self.view addSubview:imagePicker];
    
}

-(void)finishedPickingImages:(NSMutableArray *)assets{
    
    NSString *tableName =@"tripInfo";
    
    //Clear the table
    [[myDB sharedInstance] deleteTable:tableName];
    [[myDB sharedInstance] createTable:tableName];
    
    //save to database
    __block NSString *imagePath = [[NSString alloc]init];
    NSString *imageLatitude     = [[NSString alloc]init];
    NSString *imageLongtitude   = [[NSString alloc]init];
    NSString *comment           = [[NSString alloc]init];
    NSString *voicePath         = [[NSString alloc]init];
    NSString *hiddenState       = [[NSString alloc]init];
    
    //
    NSMutableArray *images = [[NSMutableArray alloc] init];
    markerArray = [[NSMutableArray alloc]init];
    
    
    //從PHAsset 解析出UIImage
    for (int i = 0; i < [assets count]; i++)
    {
        PHAsset *asset = assets[i];
        
        //取值 - 地圖座標
        CLLocationCoordinate2D position = CLLocationCoordinate2DMake(asset.location.coordinate.latitude, asset.location.coordinate.longitude);
        imageLatitude   = [NSString stringWithFormat:@"%f",asset.location.coordinate.latitude];
        imageLongtitude = [NSString stringWithFormat:@"%f",asset.location.coordinate.longitude];
        NSLog(@"imageLatitue:%@,imageLongtitude:%@",imageLatitude,imageLongtitude);
        
        GMSMarker *marker = [GMSMarker markerWithPosition:position];
        marker.title =[NSString stringWithFormat:@"%d",i];
        marker.snippet = @"Population: 8,174,100";
        marker.infoWindowAnchor = CGPointMake(0.5, 0.5);
        marker.map = _mapView;
        [markerArray addObject:marker];
        
        //取值 - 圖片 & marker
        UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 200, 300 , 300)];
        NSInteger retinaMultiplier = [UIScreen mainScreen].scale;
        CGSize retinaSquare = CGSizeMake(imageView.bounds.size.width * retinaMultiplier, imageView.bounds.size.height * retinaMultiplier);
        [[PHImageManager defaultManager]
         requestImageForAsset:assets[i]
         targetSize:retinaSquare
         contentMode:PHImageContentModeAspectFill
         options:nil
         resultHandler:^(UIImage *result, NSDictionary *info) {

             [images addObject:result];
             UIGraphicsBeginImageContextWithOptions(CGSizeMake(30, 40), NO, 0.0);
             [result drawInRect:CGRectMake(0, 0, 30, 40)];
             UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
             UIGraphicsEndImageContext();
             marker.icon = newImage;
        }];
        
        
        //取值 - path
        PHImageRequestOptions * imageRequestOptions = [[PHImageRequestOptions alloc] init];
        imageRequestOptions.synchronous = YES;
        [[PHImageManager defaultManager]
         requestImageDataForAsset:asset
         options:imageRequestOptions
         resultHandler:^(NSData *imageData, NSString *dataUTI,
                         UIImageOrientation orientation,
                         NSDictionary *info)
         {
//             NSLog(@"info = %@", info);
             if ([info objectForKey:@"PHImageFileURLKey"]) {
                 // path looks like this -
                 // file:///var/mobile/Media/DCIM/###APPLE/IMG_####.JPG
                 NSURL *path = [info objectForKey:@"PHImageFileURLKey"];
                 imagePath = [NSString stringWithFormat:@"%@",path];
             }
         }];

        //存入table
        [[myDB sharedInstance]insertTable:tableName andImageLatitude:imageLatitude andImageLongtitude:imageLongtitude ImagePath:imagePath andComments:comment andVoicePath:voicePath andHiddenState:hiddenState];
        
    }
    
    
    [imageScrollView setImageAry:images];
//    [self setImageDisplayScrollView:images];
}

#pragma mark - GMSMapView Settings & Delegate
- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    NSLog(@"You tapped at %f,%f", coordinate.latitude, coordinate.longitude);
}

- (BOOL) mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker {
    mapView.selectedMarker = marker;
    
    GMSCameraPosition *tapedLocation = [GMSCameraPosition cameraWithLatitude:marker.position.latitude
                                                                   longitude:marker.position.longitude
                                                                        zoom:_mapView.camera.zoom];
    NSLog(@"\nTapped image\nimageLatitue:%f,imageLongtitude:%f",marker.position.latitude,marker.position.longitude
          );
    [_mapView setCamera:tapedLocation];
    
    return YES;
}

- (void)mapView:(GMSMapView *)mapView willMove:(BOOL)gesture
{
    //
}


- (void)mapView:(GMSMapView *)mapView
didChangeCameraPosition:(GMSCameraPosition *)position
{
    //
}

// 停止
- (void)mapView:(GMSMapView *)mapView
idleAtCameraPosition:(GMSCameraPosition *)position
{
    //    [_mapView clear];
    
    //    [self resetMapMarkers];
    
    //    assignRange = pow(0.5, position.zoom - initalZoomLevel) * assignRangeBase;
    
    //    [self loadAllMarkers];
    
    
    //    NSLog(@"%f",position.zoom);
    //
    //    if (position.zoom > showAllGroupLevel)
    //    {
    //        if(showAllGroup == NO)
    //        {
    //            showAllGroup =YES;
    //
    //            for(GMSMarker *pin in mapMarkers)
    //            {
    //                if(![pin.userData isEqualToString:@"GroupCenter"])
    //                {
    //                    pin.map = _mapView;
    //                }
    //            }
    //        }
    //
    //    }
    //    else if (position.zoom < showAllGroupLevel)
    //    {
    //        if(showAllGroup == YES)
    //        {
    //            showAllGroup =NO;
    //
    //            for(GMSMarker *pin in mapMarkers)
    //            {
    //                if(![pin.userData isEqualToString:@"GroupCenter"])
    //                {
    //                    pin.map = nil;
    //                }
    //            }
    //
    //        }
    //
    //    }
    
    
    
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














