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
 103  addPhotoBtn
 104  chatRoomBtn
 
 201  modeBtnBackgroundView
 202  coverTripTitleView
 
 301  tripTitleText
 
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
NSString *const tableName_tripPhoto = @"Trip_Photo_Info";
NSString *const tableName_userGPS = @"user_GPS";

@implementation CHMapViewVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //
    _isInitialLayout = NO;
    
    // check is trip created or not
    _isTripCreate =  [[[NSUserDefaults standardUserDefaults] objectForKey:@"isTripCreate"] boolValue];
    _tripInfo = [[NSUserDefaults standardUserDefaults] objectForKey:@"tripInfo"];
    if (!_tripInfo) {
        _tripInfo = [[NSMutableDictionary alloc]init];
        [_tripInfo setObject:@"Trip title" forKey:@"tripTitle"];
    }
    
    // check is chatRoom joined or not
    _isCheckChatRoomJoin = NO;
    [self checkJoinChatRoomState:@"000A"];
//     _isChatRoomJoin =  [[[NSUserDefaults standardUserDefaults] objectForKey:@"isChatRoomJoin"] boolValue];
    
    _modes = [[NSArray alloc]initWithObjects:@"分析",@"紀錄",@"同夥",@"旅程", nil];

    
    //GPS init
    if (_locationManager == nil)
    {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.desiredAccuracy =
        kCLLocationAccuracyNearestTenMeters;
        _locationManager.delegate = self;
        [_locationManager requestAlwaysAuthorization];
        
    }
    
    //init trip state
    if (!_isTripCreate) {
        //尚未建立local旅程, 初始模式為分析
        _currentModeType = 0;
        NSLog(@"Trip Is Not Created!Start 分析 mode");
    }else{
        //建立local旅程, 初始模式為紀錄
        _currentModeType = 1;
        NSLog(@"Trip Created!Start 紀錄 mode");
    }
    
    // to receive push notification info
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveChatRoomMessage:) name:@"ChatRoomInfo" object:nil];
    

}

-(void)viewDidAppear:(BOOL)animated{
    
    if (!_isInitialLayout) {

        //init layout
        [self initMapView];
        [self initSearchView];
        [self initTripTitleText];
        [self initMenuView];
        [self initButtons];
        [self initScrollView];
        
        
        //init data
        if (!_isTripCreate) {
            //mode setting
            UIView *modeBtnBackgroundView = (UIView *)[_mapDisplayView viewWithTag:201];
            modeBtnBackgroundView.hidden = YES;
        }else{
            [self LoadInitData];
            
        }
    
        _isInitialLayout = YES;
    }
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Turn off the location manager to save power.
    [_locationManager stopUpdatingLocation];
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

-(void)initTripTitleText{
    
    UITextField *tripTitleText = [[UITextField alloc]initWithFrame:CGRectMake(54, 5 + 44 +5, 100, 22)];
    tripTitleText.text = _tripInfo[@"tripTitle"];
    tripTitleText.backgroundColor = [UIColor clearColor];
    tripTitleText.layer.borderWidth = 0.5f;
    tripTitleText.layer.borderColor = [[UIColor clearColor]CGColor];
    tripTitleText.tag = 301;
    tripTitleText.delegate = self;
    tripTitleText.hidden = YES;
//    tripTitleText.enabled = NO;
    [_mapDisplayView addSubview:tripTitleText];
    
    UIView *coverTripTitleView = [[UIView alloc]initWithFrame:tripTitleText.frame];
    coverTripTitleView.tag = 202;
    coverTripTitleView.hidden = YES;
    [_mapDisplayView addSubview:coverTripTitleView];
    UILongPressGestureRecognizer *recog = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(editTripTitle:)];
    [coverTripTitleView addGestureRecognizer:recog];
    
}

-(void)initButtons{
    
    // menu
    UIButton *menuBtn = [[UIButton alloc]initWithFrame:CGRectMake(5, 5, 44, 44)];
    [menuBtn addTarget:self action:@selector(showMenu:) forControlEvents:UIControlEventTouchDown];
    [menuBtn setTitle:@"Me" forState:UIControlStateNormal];
    [menuBtn setBackgroundImage:[UIImage imageNamed:@"s1_1.png"] forState:UIControlStateNormal];
    menuBtn.tag = 101;
    [_mapDisplayView addSubview:menuBtn];
    
    //mode setting
    UIView *modeBtnBackgroundView = [[UIView alloc]initWithFrame:CGRectMake(0, _mapDisplayView.frame.size.height-MODEBTN_HEIGHT, _mapDisplayView.frame.size.width, MODEBTN_HEIGHT)];
    modeBtnBackgroundView.tag = 201;
    modeBtnBackgroundView.backgroundColor = [UIColor blueColor];
    [_mapDisplayView addSubview:modeBtnBackgroundView];
    
    UIButton *modeBtn = [[UIButton alloc]initWithFrame:CGRectMake(_mapDisplayView.frame.size.width - MODEBTN_WIDTH, _mapDisplayView.frame.size.height -MODEBTN_HEIGHT, MODEBTN_WIDTH, MODEBTN_HEIGHT)];
    modeBtn.tag = 102;
    [modeBtn addTarget:self action:@selector(didSelectModeBtn:) forControlEvents:UIControlEventTouchDown];
    [modeBtn setTitle:_modes[_currentModeType] forState:UIControlStateNormal];
    [modeBtn setBackgroundColor:[UIColor blueColor]];
//    [modeBtn setBackgroundImage:[UIImage imageNamed:@"s1_1.png"] forState:UIControlStateNormal];
    [_mapDisplayView addSubview:modeBtn];
    
    //add photo btn
    UIButton *addPhotoBtn = [[UIButton alloc]initWithFrame:CGRectMake(_mapDisplayView.frame.size.width - MODEBTN_WIDTH*2, _mapDisplayView.frame.size.height -MODEBTN_HEIGHT, MODEBTN_WIDTH, MODEBTN_HEIGHT)];
    addPhotoBtn.tag = 103;
    [addPhotoBtn addTarget:self action:@selector(addPhotoBtnAction:) forControlEvents:UIControlEventTouchDown];
    [addPhotoBtn setTitle:@"+" forState:UIControlStateNormal];
    [addPhotoBtn setBackgroundColor:[UIColor blueColor]];
    [_mapDisplayView addSubview:addPhotoBtn];
    
    // chat room btn
    UIButton *chatRoomBtn = [[UIButton alloc]initWithFrame:CGRectMake(_mapDisplayView.frame.size.width - MODEBTN_WIDTH, _mapDisplayView.frame.size.height -MODEBTN_HEIGHT*2, MODEBTN_WIDTH, MODEBTN_HEIGHT)];
    chatRoomBtn.tag = 104;
    [chatRoomBtn addTarget:self action:@selector(showChatRoom:) forControlEvents:UIControlEventTouchDown];
    [chatRoomBtn setTitle:@"聊天室" forState:UIControlStateNormal];
    [chatRoomBtn setBackgroundColor:[UIColor blueColor]];
    [_mapDisplayView addSubview:chatRoomBtn];
    
}

-(void)initMenuView{
    
    menuView = [[MapVCMenuView alloc]initWithFrame:CGRectMake(5, 54, 44, _mapDisplayView.frame.size.height - (54+80)) owner:nil];
    menuView.delegate = self;
    [_mapDisplayView addSubview: menuView];
    menuView.hidden = YES;
}

-(void)LoadInitData{
    
    ///!!!:wait for coding
    [self loadUserGps];
    [self loadTripInfo];
    [self loadPhotosForInit];

    
}

#pragma mark - Load Data
-(void)loadPhotosForInit{
    
    NSMutableArray *queryTableResult=[[NSMutableArray alloc]init];
    NSMutableArray *localIdentifier =[[NSMutableArray alloc]init];
    queryTableResult = [[myDB sharedInstance]queryWithTableName:tableName_tripPhoto];
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
    
    [self finishedPickingImages:_pickedAssets];
    
}

-(void)loadUserGps{
    
    ///!!!:wait for coding
}

-(void)loadTripInfo{
    
    ///!!!:wait for coding
}

#pragma mark - CHScrollView setting & setters & delegate
-(void)initScrollView
{
 
    //底層照片scrollview, 設定參數
    imageScrollView = [[CHScrollView alloc] initWithFrame:CGRectMake(0, _mapDisplayView.frame.size.height-IMAGEHEIGHT, _mapDisplayView.frame.size.width-MODEBTN_WIDTH*2, IMAGEHEIGHT)];
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

-(void)didSelectModeBtn:(UIButton *)sender{
    
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

    }else if(_currentModeType == 1){
        //紀錄
        NSLog(@"紀錄mode");
        
    }else if(_currentModeType == 2){
        //同夥
        NSLog(@"同夥mode");
        
    }else if(_currentModeType == 3){
        //旅程
        NSLog(@"旅程mode");
        
    }
    
//    _currentModeType +=1;
//    if (_currentModeType >= [_modes count]) {
//        _currentModeType = 0;
//    }
//    
//    [sender setTitle:_modes[_currentModeType] forState:UIControlStateNormal];
}

-(void)addPhotoBtnAction:(UIButton *)sender{
    
    NSLog(@"Adding photo");
    
    UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
    imgPicker.sourceType = UIImagePickerControllerCameraDeviceFront;
    imgPicker.delegate = self;
    [self presentViewController:imgPicker animated:YES completion:^{
        //
    }];
    
}

-(void)showChatRoom:(UIButton *)sender{
    
    CHChatRoomVC *vc = [[CHChatRoomVC alloc]init];
    [self presentViewController:vc animated:YES completion:nil];
    
}

-(void)editTripTitle:(UIGestureRecognizer *)recog{
    
    UITextField *tripTitleText = (UITextField *)[_mapDisplayView viewWithTag:301];
    [tripTitleText becomeFirstResponder];
    
}

#pragma mark - MapVCSeachViewDelegate
-(void)didSelectTableSearchResultLocationAtLatitude:(NSString *)latitude andLongitude:(NSString *)longitude{
    [_mapView animateToLocation:CLLocationCoordinate2DMake(latitude.doubleValue, longitude.doubleValue)];
    
    
}

#pragma mark - menu
-(void)didSelectTheMenu:(UIButton *)btn;
{
    
    // Change mode button
    switch (btn.tag) {
        case 1:
            //紀錄mode
            _currentModeType = 1;
            break;
        case 2:
            //同夥mode
            _currentModeType = 2;
            
            // check if in chatroom when viewdidload
            // when finish check block, isCheckChatRoomJoin = YES
            // if not finish check block yet, unable to call action sheet
            // if not in chatroom, show action sheet to start to join
            if (_isCheckChatRoomJoin) {
                if (!_isChatRoomJoin) {
                    [self showChatRoomActionSheet];
                }
            }else{
                NSLog(@"尚未完成ChatRoomJoin block");
            }
            
            break;
            
        case 3:
            //旅程mode
            _currentModeType = 3;
            [self drawPolyLinesOnMap];
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
    
    //Clear the table
    [[myDB sharedInstance] deleteTable:tableName_tripPhoto];
    [[myDB sharedInstance] createTripTable:tableName_tripPhoto];
    
    [[myDB sharedInstance] deleteTable:tableName_userGPS];
    [[myDB sharedInstance] createGPSTable:tableName_userGPS];
    
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
        [[myDB sharedInstance]insertTable:tableName_tripPhoto andImageLatitude:imageLatitude andImageLongtitude:imageLongtitude ImagePath:imagePath andComments:comment andVoicePath:voicePath andHiddenState:hiddenState];
        
    }
    
    //是否放照片在地圖上
    _isShowImagesOnMap = [[[NSUserDefaults standardUserDefaults] objectForKey:@"isShowImagesOnMap"] boolValue];
    if (_isShowImagesOnMap) {
        NSLog(@"show Images On Map");
    }else{
        [_mapView clear];
        NSLog(@"Don't show Images On Map ");
    }
    
    //show Image scrollView
    UIView *modeBtnBackgroundView = (UIView *)[_mapDisplayView viewWithTag:201];
    modeBtnBackgroundView.hidden = NO;
    
    [imageScrollView setImageAry:images];
//    [self setImageDisplayScrollView:images];

    //show Trip title text
    UITextField *tripTitleText = (UITextField *)[_mapDisplayView viewWithTag:301];
    tripTitleText.hidden = NO;
    
    UIView *coverTripTitleView = (UIView *)[_mapDisplayView viewWithTag:202];
    coverTripTitleView.hidden = NO;

    //Create  Trip
    _isTripCreate = YES;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:_isTripCreate] forKey:@"isTripCreate"];
    NSLog(@"Trip Created!");
    
    
    //Start to record GPS
    [_locationManager startUpdatingLocation];
    NSLog(@"GPS recording start");
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
    
    UITextField *tripTitleText = (UITextField *)[_mapDisplayView viewWithTag:301];
    [tripTitleText resignFirstResponder];
    

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

-(void)drawPolyLinesOnMap{
    
    
    NSMutableArray *queryGPSTableResult=[[NSMutableArray alloc]init];
    __block float latitude;
    __block float longitude;

    
    queryGPSTableResult = [[myDB sharedInstance]queryWithTableName:tableName_userGPS];
//    NSLog(@"%@",queryGPSTableResult);
    
    GMSMutablePath *path = [GMSMutablePath path];
    
    if (queryGPSTableResult) {
        [queryGPSTableResult enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL * _Nonnull stop) {
            latitude  = [dict[@"userLatitude"]   floatValue];
            longitude = [dict[@"userLongtitude"] floatValue];
            [path addCoordinate:CLLocationCoordinate2DMake(latitude, longitude)];
        }];
        
        GMSPolyline *rectangle = [GMSPolyline polylineWithPath:path];
        rectangle.map = _mapView;
        NSLog(@"Drawing path on map");
    }


}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UIImagePickerController
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(nullable NSDictionary<NSString *,id> *)editingInfo NS_DEPRECATED_IOS(2_0, 3_0){
    
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    
    UIImage *img = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    
    // Save image
    UIImageWriteToSavedPhotosAlbum(img, self, nil, nil);
    
    //等1秒後, 
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        // get camera roll
        PHAssetCollection *cameraRoll = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil].lastObject;
        PHAsset *asset = [[PHAsset fetchAssetsInAssetCollection:cameraRoll options:nil] lastObject];
        [_pickedAssets addObject:asset];
        [self finishedPickingImages:_pickedAssets];
        
    });
    
    //圖庫選圖完之後，自動關閉圖庫
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    
}

#pragma mark - locationManager Delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
//    NSLog(@"/n lat: %f",_locationManager.location.coordinate.latitude);
//    NSLog(@" lon: %f/n",_locationManager.location.coordinate.longitude);
    
    //存入table
    [[myDB sharedInstance]insertGPSTable:tableName_userGPS andLatitude:[NSString stringWithFormat:@"%f",_locationManager.location.coordinate.latitude] andLongtitude:[NSString stringWithFormat:@"%f",_locationManager.location.coordinate.longitude]];

}

#pragma mark - UIText hide keyboard & Delegates
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITextField *tripTitleText = (UITextField *)[_mapDisplayView viewWithTag:301];
    
    //touch other view
    if (![tripTitleText isExclusiveTouch]) {
        [tripTitleText resignFirstResponder];
    }
    

    
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField{
    
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    
    textField.backgroundColor = [UIColor whiteColor];
    textField.layer.borderColor = [[UIColor blackColor]CGColor];
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    
    textField.backgroundColor = [UIColor clearColor];
    textField.layer.borderColor = [[UIColor clearColor]CGColor];
    
    if ([textField.text isEqualToString:@""]) {
        textField.text = _tripInfo[@"tripTitle"];
    }else{
        [_tripInfo setObject:textField.text forKey:@"tripTitle"];
        [[NSUserDefaults standardUserDefaults] setObject:_tripInfo forKey:@"tripInfo"];
    }

}

#pragma mark - Notification 
-(void)didReceiveChatRoomMessage:(NSNotification *)notification{
    
    NSDictionary *userInfo = [notification userInfo];
    NSString *receivedMessage = userInfo[@"aps"][@"alert"];
    
    NSLog(@"%@", receivedMessage);
}

#pragma mark - Chat room actions

-(void)checkJoinChatRoomState:(NSString *)userID{
    
    //retrive data from cloud
    PFQuery *query = [PFQuery queryWithClassName:@"Member"];
    [query whereKey:@"userID" equalTo:userID];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {

        if (objects.count ==0) {
            _isChatRoomJoin = NO;
            NSLog(@"使用者%@ 尚未加入聊天室",userID);
        }else if (objects.count ==1) {
            
            // get the roomID
            PFObject *memberObject = objects[0];
            NSLog(@"使用者%@ 已加入%@聊天室",[memberObject objectForKey:@"userID"],[memberObject objectForKey:@"roomID"]);
            
            // use roomID to get host
            PFQuery *queryHost = [PFQuery queryWithClassName:@"Rooms"];
            [queryHost whereKey:@"roomID" equalTo:[memberObject objectForKey:@"roomID"]];
            NSString* host = [[[queryHost findObjects] firstObject] objectForKey:@"roomHostID"];
            NSLog(@"The %@ room host is %@",[memberObject objectForKey:@"roomID"],host);
            
            // use roomID to get all the members
            PFQuery *queryForAllMember = [PFQuery queryWithClassName:@"Member"];
            [queryForAllMember whereKey:@"roomID" equalTo:[memberObject objectForKey:@"roomID"]];
            NSArray* allMembers = [queryForAllMember findObjects];
            [allMembers enumerateObjectsUsingBlock:^(PFObject *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSLog(@"The %@ room member is %@",[memberObject objectForKey:@"roomID"],[obj objectForKey:@"userID"]);
            }];
            
            _isChatRoomJoin = YES;
        }else{
            NSLog(@"錯誤：使用者同時存在%lu個聊天室",(unsigned long)objects.count);
        }

    }];
    
    
}

-(void)showChatRoomActionSheet{
    
//    UIAlertController *allyChatRoom = [UIAlertController alertControllerWithTitle:@"Test" message:@"Mes" preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertController *allyChatRoom = [[UIAlertController alloc]init];
    
    UIAlertAction *joinChatRoom = [UIAlertAction actionWithTitle:@"加入" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"Join chat room  Action");
        [self showChatRoomSettingVC];
        
    }];
    
    UIAlertAction *createChatRoom = [UIAlertAction actionWithTitle:@"新開群組" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"Create chat room  Action");
        [self showChatRoomSettingVC];
        
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"cancel chat room Action");
    }];
    
    [allyChatRoom addAction:joinChatRoom];
    [allyChatRoom addAction:createChatRoom];
    [allyChatRoom addAction:cancel];
    
    [self presentViewController:allyChatRoom animated:YES completion:nil];

}

-(void)showChatRoomSettingVC{
    
    CHChatRoomSettingVC *vc = [[CHChatRoomSettingVC alloc]init];
    [self presentViewController:vc animated:YES completion:nil];
    
}

@end














