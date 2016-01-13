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
 102  modeBtn
 
 */
#define IMAGEHEIGHT 80
#define MODEBTN_WIDTH 80.0
#define MODEBTN_HEIGHT 44.0

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
NSString *const tableName = @"tripInfo";

@implementation CHMapViewVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _isInitialLayout = NO;
    
    _modes = [[NSArray alloc]initWithObjects:@"分析",@"紀錄",@"同夥",@"旅程", nil];
    _currentModeType = 0;
    
    [self loadPhotosForInit];

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

-(void)loadPhotosForInit{
    
    NSMutableArray *queryTableResult=[[NSMutableArray alloc]init];
    NSMutableArray *localIdentifier =[[NSMutableArray alloc]init];
    queryTableResult = [[myDB sharedInstance]queryWithTableName:tableName];
    NSLog(@"%@",queryTableResult);
    
    if (queryTableResult) {
//        PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
        [queryTableResult enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL * _Nonnull stop) {
            
            [localIdentifier addObject:dict[@"imagePath"]];
        }];
        
        PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:localIdentifier options:nil];
        
        _pickedAssets = [[NSMutableArray alloc]init];
        
        [result enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL * _Nonnull stop) {
            
            [_pickedAssets addObject:asset];
            
        }];
        
    }
    
    
    
    
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
    UIView *modeBtnBackgroundView = [[UIView alloc]initWithFrame:CGRectMake(0, _mapDisplayView.frame.size.height-MODEBTN_HEIGHT, _mapDisplayView.frame.size.width, MODEBTN_HEIGHT)];
    modeBtnBackgroundView.backgroundColor = [UIColor blueColor];
    [_mapDisplayView addSubview:modeBtnBackgroundView];
    
    UIButton *modeBtn = [[UIButton alloc]initWithFrame:CGRectMake(_mapDisplayView.frame.size.width - MODEBTN_WIDTH, _mapDisplayView.frame.size.height -MODEBTN_HEIGHT, MODEBTN_WIDTH, MODEBTN_HEIGHT)];
    modeBtn.tag = 102;
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
    imageScrollView = [[CHScrollView alloc] initWithFrame:CGRectMake(0, _mapDisplayView.frame.size.height-IMAGEHEIGHT, _mapDisplayView.frame.size.width-MODEBTN_WIDTH, IMAGEHEIGHT)];
    imageScrollView.delegateImage = self;
    imageScrollView.isCentredFirstItem = YES;
    imageScrollView.visibleImageNumber = 5;
    imageScrollView.downSizeRatio = 0.5;
    imageScrollView.imageChangeRange = 0.3;
    imageScrollView.backgroundColor = [UIColor clearColor];
    
    UIImageView *chsrollViewBackground = [[UIImageView alloc]initWithFrame:CGRectMake(0, _mapDisplayView.frame.size.height-IMAGEHEIGHT*0.5, _mapDisplayView.frame.size.width, IMAGEHEIGHT*0.5)];
    chsrollViewBackground.image = [UIImage imageNamed:@"tab_bar_bg.png"];
    [_mapDisplayView addSubview:chsrollViewBackground];
    [_mapDisplayView addSubview:imageScrollView];
    
    [self finishedPickingImages:_pickedAssets];
    
}

-(void)scrollView:(UIScrollView *)scrollView didSelectedImage:(UIImageView *)selectedView{
    
    
    _isShowImagesOnMap = [[[NSUserDefaults standardUserDefaults] objectForKey:@"isShowImagesOnMap"] boolValue];
    if (_isShowImagesOnMap) {
        NSInteger tag = selectedView.tag-1;
        [self mapView:_mapView didTapMarker:markerArray[tag]];
        NSLog(@"\nYou selected chScollView the no.%ld Image",(long)selectedView.tag);
    }else{
        //無marker, 不動作
    }

    
    
    
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
    
    if (_currentModeType == 0) {
        //點選"分析"按鈕時, 跳出照片
//        [self setImagePicker:_pickedAssets];
        
        UIAlertController * alert=   [UIAlertController
                                      alertControllerWithTitle:@""
                                      message:@"是否取用相簿照片"
                                      preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* yesButton = [UIAlertAction
                                    actionWithTitle:@"Yes"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action)
                                    {
                                        
                                        //
                                        switch ([PHPhotoLibrary authorizationStatus]) {
                                            case PHAuthorizationStatusAuthorized:
                                                [self setImagePicker:_pickedAssets];
                                                break;
                                                
                                            default:
                                                [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                                                    switch (status) {
                                                        case PHAuthorizationStatusAuthorized:
                                                        case PHAuthorizationStatusNotDetermined:
                                                            [self setImagePicker:_pickedAssets];
                                                            break;
                                                            
                                                        case PHAuthorizationStatusDenied:
                                                        case PHAuthorizationStatusRestricted:
                                                        {
                                                            //Tell user access to the photos are restricted
                                                            UIAlertController * alertForRestricted=   [UIAlertController
                                                                                          alertControllerWithTitle:@"錯誤"
                                                                                          message:@"無法訪問相簿,請至設定開啟權限"
                                                                                          preferredStyle:UIAlertControllerStyleAlert];
                                                            
                                                            UIAlertAction *okBtn = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                                                [alertForRestricted dismissViewControllerAnimated:YES completion:nil];
                                                            }];
                                                            
                                                            [alertForRestricted addAction:okBtn];
                    
                                                            [self presentViewController:alertForRestricted animated:YES completion:nil];
                                                        }
                                                            break;
                                                            
                                                        default:
                                                            break;
                                                    }
                                                }];
                                                break;
                                        }
                                        
                                        
                                        [alert dismissViewControllerAnimated:YES completion:nil];
                                        
                                    }];
        
        UIAlertAction* noButton = [UIAlertAction
                                   actionWithTitle:@"No"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action)
                                   {
                                       
                                       [alert dismissViewControllerAnimated:YES completion:nil];
                                       
                                   }];
        
        [alert addAction:yesButton];
        [alert addAction:noButton];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        
        
        
        

    }
    
//    _currentModeType +=1;
//    if (_currentModeType >= [_modes count]) {
//        _currentModeType = 0;
//    }
//    
//    [sender setTitle:_modes[_currentModeType] forState:UIControlStateNormal];
}




#pragma mark - MapVCSeachViewDelegate
-(void)didSelectTableSearchResultLocationAtLatitude:(NSString *)latitude andLongitude:(NSString *)longitude{
    [_mapView animateToLocation:CLLocationCoordinate2DMake(latitude.doubleValue, longitude.doubleValue)];
    
    
}

#pragma mark - menu
-(void)didSelectTheMenu:(UIButton *)btn;
{
    switch (btn.tag) {
        case 1:
            //紀錄mode
            _currentModeType = 1;
            break;
        case 2:
            //同夥mode
            _currentModeType = 2;
            break;
        case 3:
            //旅程mode
            break;
        default:
            break;
    }

    UIButton *modeBtn = (UIButton *)[_mapDisplayView viewWithTag:102];
    [modeBtn setTitle:_modes[_currentModeType] forState:UIControlStateNormal];
    

}

#pragma mark - CHImagePickerView setting & delegate
-(void)setImagePicker:(NSMutableArray *)assetArray
{
    
    //CHImagePickerView
    CGRect frame = CGRectMake(_mapDisplayView.frame.origin.x, _mapDisplayView.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height - _mapDisplayView.frame.origin.y);
    
    CHImagePickerView *imagePicker = [[CHImagePickerView alloc]initWithFrame:frame owner:self];

    
    [imagePicker loadPhotosFromAlbumAndCompareWithAssets:assetArray];
//    if (assetArray)
//        [imagePicker loadPhotosFromAssetArray:assetArray];
//    else
//        [imagePicker loadPhotosFromAlbum];
    
    imagePicker.backgroundColor = [UIColor whiteColor];
    imagePicker.layer.borderWidth = 2.0f;
    imagePicker.layer.borderColor = [[UIColor blueColor]CGColor];
    imagePicker.layer.cornerRadius = 10.0f;
    
    imagePicker.delegate = self;
    [self.view addSubview:imagePicker];
    
}

-(void)finishedPickingImages:(NSMutableArray *)assets{
    
    _pickedAssets = assets;
    NSString *tableName =@"tripInfo";
    
    //Clear the table
    [[myDB sharedInstance] deleteTable:tableName];
    [[myDB sharedInstance] createTable:tableName];
    
    //ready to save to database
    __block NSString *imagePath = [[NSString alloc]init];
    NSString *imageLatitude     = [[NSString alloc]init];
    NSString *imageLongtitude   = [[NSString alloc]init];
    NSString *comment           = [[NSString alloc]init];
    NSString *voicePath         = [[NSString alloc]init];
    NSString *hiddenState       = [[NSString alloc]init];
    
    //
    NSMutableArray *images = [[NSMutableArray alloc] init];
    markerArray = [[NSMutableArray alloc]init];
    
    [_mapView clear];
    
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
        imagePath = asset.localIdentifier;
        
//        PHImageRequestOptions * imageRequestOptions = [[PHImageRequestOptions alloc] init];
//        imageRequestOptions.synchronous = YES;
//        [[PHImageManager defaultManager]
//         requestImageDataForAsset:asset
//         options:imageRequestOptions
//         resultHandler:^(NSData *imageData, NSString *dataUTI,
//                         UIImageOrientation orientation,
//                         NSDictionary *info)
//         {
////             NSLog(@"info = %@", info);
//             if ([info objectForKey:@"PHImageFileURLKey"]) {
//                 // path looks like this -
//                 // file:///var/mobile/Media/DCIM/###APPLE/IMG_####.JPG
//                 NSURL *path = [info objectForKey:@"PHImageFileURLKey"];
//                 imagePath = [NSString stringWithFormat:@"%@",path];
//             }
//         }];

        //存入table
        [[myDB sharedInstance]insertTable:tableName andImageLatitude:imageLatitude andImageLongtitude:imageLongtitude ImagePath:imagePath andComments:comment andVoicePath:voicePath andHiddenState:hiddenState];
        
    }
    
    //是否放照片在地圖上
    _isShowImagesOnMap = [[[NSUserDefaults standardUserDefaults] objectForKey:@"isShowImagesOnMap"] boolValue];
    if (_isShowImagesOnMap) {
        NSLog(@"show Images On Map");
    }else{
        [_mapView clear];
        NSLog(@"Don't show Images On Map ");
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














