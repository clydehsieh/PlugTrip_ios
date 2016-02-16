//
//  CHMapViewVC.m
//  PlugTrip_ios
//
//  Created by Chin-Hui Hsieh  on 12/23/15.
//  Copyright © 2015 Chin-Hui Hsieh. All rights reserved.
//
/* Tags:
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
 203  indicator mask view
 
 301  tripTitleText
 
 401  moveTV
 */

/* [NSUserDefaults standardUserDefaults]:
 
 isTripCreate
 isShowImagesOnMap
 
 tripInfo (object of keys)
     tripTitle
 
 userInfo (object of keys)
    userID
    UUID
    nickName
 
 roomInfo
    roomID
    roomHostID

 */

#define TAG_modeBtn       102
#define TAG_quickChatView 204

#define TAG_quickChatText 302

#define IMAGEHEIGHT 50
#define MODEBTN_WIDTH 80.0
#define MODEBTN_HEIGHT 44.0

#define BOTTOM_VIEW_FRAME1 CGRectMake(0, _mapDisplayView.frame.size.height-IMAGEHEIGHT, _mapDisplayView.frame.size.width-MODEBTN_WIDTH, IMAGEHEIGHT)
#define BOTTOM_VIEW_FRAME2 CGRectMake(0, _mapDisplayView.frame.size.height-IMAGEHEIGHT, _mapDisplayView.frame.size.width-MODEBTN_WIDTH*2, IMAGEHEIGHT)



#import "CHMapViewVC.h"

@interface CHMapViewVC ()
{
    MapVCSearchView *sView;
    MapVCMenuView *menuView;
    
    
    
    CHScrollView *imageScrollView;
    
    CHFIreBaseAdaptor *fireBaseAdp;
    
    UIActivityIndicatorView *activityIndicator;
    
    //紀錄mode
    NSMutableArray *localImages;
    NSMutableArray *localImgMarkers;
    NSTimer *receivedMsg;
    
    //夥伴mode
    
    NSMutableArray *memberMarkers;
    
    //旅程mode
    NSMutableArray *dlTripItems;
    NSMutableArray *dlTripItemsMarkers;
    
    //通用(紀錄&旅程)
    EasyTableView *horizontalView;
}

@end

NSString *const apiKey = @"AIzaSyDzElpxMxZ4_T7DP6LSYrGfoj8kpLAtgr4";
NSString *const tableName_tripPhoto = @"Trip_Photo_Info";
NSString *const tableName_userGPS = @"user_GPS";

@implementation CHMapViewVC

- (void)viewDidLoad {
    [super viewDidLoad];

    //show & hide keyboard
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    
    _isInitialLayout = NO;//for first load view
    
    //firebase
    fireBaseAdp = [[CHFIreBaseAdaptor alloc]init];
    
    ///!!!:重寫
    //Trip Info
    _tripInfo = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"tripInfo"]];
    if ([_tripInfo count]==0) {
        _tripInfo = [[NSMutableDictionary alloc]init];
        [_tripInfo setObject:@"New Trip Title"            forKey:@"tripTitle"];
        [_tripInfo setObject:[NSNumber numberWithBool:NO] forKey:@"isTripCreate"];
        [_tripInfo setObject:[NSNumber numberWithBool:NO] forKey:@"isSavedOnline"];
        [[NSUserDefaults standardUserDefaults] setObject:_tripInfo forKey:@"tripInfo"];
        
        NSLog(@"Trip info is not exist, create new one");
    }else{
        NSLog(@"\nLoad TripInfo success, start to load photos");
        
    }

    //User Info
    _userInfo = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults]objectForKey: @"userInfo"]];
    if ([_userInfo count]==0) {
        _userInfo = [[NSMutableDictionary alloc]init];
        [_userInfo setObject:@"New User"     forKey:@"userID"];
        [_userInfo setObject:[self loadUUID] forKey:@"UUID"];
        [_userInfo setObject:@"New User"     forKey:@"nickName"];
        [_userInfo setObject:[NSNumber numberWithBool:NO]  forKey:@"isShareGPS"];
        [[NSUserDefaults standardUserDefaults] setObject:_userInfo forKey:@"userInfo"];
        NSLog(@"User info is not exist, create new one");
    }else{
        NSLog(@"Load UserInfo success");
    }
    
    _roomInfo = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults]objectForKey: @"roomInfo"]];
    
    if ([_roomInfo count]==0) {
        _roomInfo = [[NSMutableDictionary alloc]init];
        [_roomInfo setObject:[NSNumber numberWithBool:NO]   forKey:@"isShowOnMap"];
//        [_roomInfo setObject:_roomID     forKey:@"roomID"];
        [[NSUserDefaults standardUserDefaults] setObject:_roomInfo forKey:@"roomInfo"];
        NSLog(@"User info is not exist, create new one");
    }else{
        NSLog(@"Load UserInfo success");
    }
    
    ///=============
    
    
 
    // check is chatRoom joined or not
    _isCheckChatRoomJoin = NO;
    _modes = [[NSArray alloc]initWithObjects:@"分析",@"紀錄",@"同夥",@"旅程", nil];

    
    //GPS init
    [self locationManagerSetting];
    
    
    // to receive push notification info
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveChatRoomMessage:) name:@"ChatRoomInfo" object:nil];
    
    [self indicatorSetting];
    

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
        [self initHorizontalView];
        
        //init data
        [self updateTripCreateState];
    
        
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

#pragma mark
#pragma mark - TripInfo
-(void)tripInfoUpdateObjec:(id)object forKey:(id)key{
    
    [_tripInfo setObject:object forKey:key];
    [[NSUserDefaults standardUserDefaults] setObject:_tripInfo forKey:@"tripInfo"];
    
}

-(void)updateTripCreateState{
    
    BOOL isTripCreate = [[_tripInfo objectForKey:@"isTripCreate"] boolValue];
    
    if (!isTripCreate) {
        
        //尚未建立local旅程, 初始模式為分析
        _currentModeType = 0;
        NSLog(@"尚未建立旅程, 開始分析模式");
        
    }else{
        
        //建立local旅程, 初始模式為紀錄
        _currentModeType = 1;
        NSLog(@"已經建立旅程, 開始紀錄模式");
        
        //開啟menuBtn
        UIButton *menuBtn = (UIButton *)[_mapDisplayView viewWithTag:101];
        menuBtn.hidden = NO;
        NSLog(@"開啟menuBtn");
        
        //show Trip title text
        UITextField *tripTitleText = (UITextField *)[_mapDisplayView viewWithTag:301];
        tripTitleText.hidden = NO;
        
        UIView *coverTripTitleView = (UIView *)[_mapDisplayView viewWithTag:202];
        coverTripTitleView.hidden = NO;
     
        [self loadDBPhotos];
        
//        ///!!!:開始記錄ＧＰＳ！！
//        receivedMsg = [NSTimer scheduledTimerWithTimeInterval:5.0f
//                                                       target:self selector:@selector(locationManager: didUpdateLocations:) userInfo:nil repeats:YES];
//        [receivedMsg isValid];
    }
    
    [self updateModeBtnState];
    
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

#pragma mark
#pragma mark - UserInfo
-(NSString *)loadUUID{
    
    //load UUID
    NSString *uuid;
    uuid = [BCKeychainManager loadUUID];
    if (!uuid) {
        uuid = [[NSUUID UUID]UUIDString];
        [BCKeychainManager saveUUID:uuid];
    }
    NSLog(@"UUID:%@",uuid);
    
    return uuid;
}

-(void)updateUserInfoWithUserID:(NSString *)userID andUserNickName:(NSString *)userNickName andUUID:(NSString *)UUID{
    
    if (userID) {
        _userInfo[@"userID"]=userID;
    }
    
    if (userNickName) {
        _userInfo[@"nickName"]=userNickName;
    }
    
    if (UUID) {
        _userInfo[@"UUID"]=UUID;
    }
    
    [[NSUserDefaults standardUserDefaults]setObject:_userInfo forKey:@"userInfo"];
    
}


//- (void)loadUUID {
//    
//    [self indicatorStart];
//    
//    
//    //load UUID
//    _userUUID = [BCKeychainManager loadUUID];
//    if (!_userUUID) {
//        _userUUID = [[NSUUID UUID]UUIDString];
//        [BCKeychainManager saveUUID:_userUUID];
//    }
//    NSLog(@"UUID:%@",_userUUID);
//    
//    
//    // User registration by using uuid, send back user.objectID
//    PFQuery *query_Users = [PFQuery queryWithClassName:@"Users"];
//    
//    [query_Users whereKey:@"UUID" equalTo:_userUUID];
//    [query_Users findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
//       
//        [self indicatorStop];
//        
//        if (!error) {
//            
//            if (objects.count==0) {
//                
//                NSLog(@"\nCreate new Users by UUID:\n%@\n\n",_userUUID);
//    
//                // regist new user
//                [self indicatorStart];
//                
//                PFObject *newUser = [PFObject objectWithClassName:@"Users"];
//                newUser[@"UUID"] = _userUUID;
//                newUser[@"nickName"] = @"New User";
//                
//                [newUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
//                    
//                    [self indicatorStop];
//                    
//                    if (succeeded) {
//                        NSLog(@"\ncreate new user succeeded");
//                        NSLog(@"userID:%@",newUser.objectId);
//                        NSLog(@"nickName:%@",[newUser objectForKey:@"nickName"]);
//                        
//                        [self updateUserInfoWithUserID:newUser.objectId andUserNickName:[newUser objectForKey:@"nickName"] andUUID:_userUUID];
//                        
////                        [self updateUserInfoWhereKey:@"UUID" equalTo:_userUUID];
//                    }else{
//                        NSLog(@"fail to create new user,error:\n%@\n\n",error.description);
//                    }
//                }];
//                
//            }else if (objects.count ==1){
//                
//                PFObject *newUser = [objects firstObject];
//                [self updateUserInfoWithUserID:newUser.objectId andUserNickName:[newUser objectForKey:@"nickName"] andUUID:_userUUID];
//                
////                [self updateUserInfoWhereKey:@"UUID" equalTo:_userUUID];
//            }else{
//                NSLog(@"Error:UUID is repeat");
//            }
//
//            
//        }else{
//            NSLog(@"\nError:\n%@\n",error.debugDescription);
//            if (error.code == 100) {
//                [self showOfflineAlert:error];
//            }
//        }
//        
//    
//    }];
//
//}

-(void)updateUserInfoWhereKey:(NSString *)keyValue equalTo:(NSString *)objectValue{

    [self indicatorStart];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Users"];
    [query whereKey:keyValue equalTo:objectValue];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        
        [self indicatorStop];
        
        if (objects.count ==1) {
            
            PFObject *obj = [objects firstObject];
            if ([_userInfo isKindOfClass:[NSMutableDictionary class]]) {
                [_userInfo setObject:obj.objectId     forKey:@"userID"  ];
                [_userInfo setObject:obj[@"UUID"]     forKey:@"UUID"    ];
                [_userInfo setObject:obj[@"nickName"] forKey:@"nickName"];
                [[NSUserDefaults standardUserDefaults] setObject:_userInfo forKey:@"userInfo"];
                NSLog(@"userInfo updated");
            }
        }else{
            NSLog(@"\nfail update, the result count is %lu",objects.count);
        }
        
    }];
    
}

-(void)updateRoomInfoWhereKey:(NSString *)keyValue equalTo:(NSString *)objectValue{
    
    [self indicatorStart];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Rooms"];
    [query whereKey:keyValue equalTo:objectValue];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        
        [self indicatorStop];
        
        if (objects.count ==1) {
            
            PFObject *obj = [objects firstObject];
            if ([_roomInfo isKindOfClass:[NSMutableDictionary class]]) {
                [_roomInfo setObject:obj.objectId       forKey:@"roomID"    ];
                [_roomInfo setObject:obj[@"roomHostID"] forKey:@"roomHostID"];
                [[NSUserDefaults standardUserDefaults] setObject:_roomInfo forKey:@"roomInfo"];
                NSLog(@"roomInfo updated");
            }
        }else{
            NSLog(@"\nfail update, the result count is %lu",objects.count);
        }
    }];
}


#pragma mark 
#pragma mark - Search View
-(void)initSearchView{
    sView = [[MapVCSearchView alloc]initWithFrame:CGRectMake(54, 5, _mapDisplayView.frame.size.width-(54+5), 44*5) owner:nil andApiServerKey:apiKey];
    sView.delegate = self;
    [_mapDisplayView insertSubview:sView atIndex:4];
}

#pragma mark - MapVCSeachViewDelegate
-(void)didSelectTableSearchResultLocationAtLatitude:(NSString *)latitude andLongitude:(NSString *)longitude{
    [_mapView animateToLocation:CLLocationCoordinate2DMake(latitude.doubleValue, longitude.doubleValue)];
    
    
}


#pragma mark
#pragma mark - CHScrollView
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
//    [_mapDisplayView addSubview:chsrollViewBackground];
//    [_mapDisplayView addSubview:imageScrollView];

    
}

-(void)showImageDisplayScrollViewWithImages:(NSArray *)images {
    
    //show Image scrollView
    UIView *modeBtnBackgroundView = (UIView *)[_mapDisplayView viewWithTag:201];
    modeBtnBackgroundView.hidden = NO;
    
    [imageScrollView setImageAry:images];
    //    [self setImageDisplayScrollView:images];
    
}
-(void)scrollView:(UIScrollView *)scrollView didSelectedImage:(UIImageView *)selectedView{
    
    _isShowImagesOnMap = [[[NSUserDefaults standardUserDefaults] objectForKey:@"isShowImagesOnMap"] boolValue];
    
    if (_isShowImagesOnMap) {
        NSInteger tag = selectedView.tag-1;
        [self mapView:_mapView didTapMarker:localImgMarkers[tag]];
        NSLog(@"\nYou selected chScollView the no.%ld Image",(long)selectedView.tag);
    }else{
        //無marker, 不動作
    }
 
}

#pragma mark
#pragma mark - horizontalView (EasyTableview) delegate
-(void)initHorizontalView{

    EasyTableView *view	= [[EasyTableView alloc] initWithFrame:BOTTOM_VIEW_FRAME2 ofWidth:IMAGEHEIGHT];
    horizontalView  = view;
    horizontalView.delegate= self;
    horizontalView.tableView.backgroundColor= [UIColor clearColor];
    horizontalView.tableView.allowsSelection= YES;
    horizontalView.tableView.separatorColor	= [UIColor darkGrayColor];
    horizontalView.autoresizingMask			= UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [_mapDisplayView addSubview:horizontalView];
    
}

- (NSUInteger)numberOfSectionsInEasyTableView:(EasyTableView*)easyTableView{
    
    if (_currentModeType == 1) {
        return 1;
    }else if(_currentModeType == 3 ){
        return [dlTripItemsMarkers count];
    }else{
        return 0;
    }
    
}

- (NSInteger)easyTableView:(EasyTableView *)easyTableView numberOfRowsInSection:(NSInteger)section{

    if (_currentModeType == 1) {
        return [localImages count];
    }else if(_currentModeType == 3 ){
        return [dlTripItemsMarkers[section] count];
    }else{
        return 0;
    }
    
}
- (UITableViewCell *)easyTableView:(EasyTableView *)easyTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    static NSString *cellIdentifier = @"EasyTableViewCell";
    
    //init cell
    UITableViewCell *cell = [easyTableView.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    UIImageView *imgView;
    UILabel *locNoLabel;
    
    //移除所有subview
    NSArray *subViews = cell.subviews;
    [subViews enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    
    if (!cell) {
        // Create a new table view cell
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor clearColor];
       
    }
    
    float downsize = 5;
    CGRect imgViewRect		= CGRectMake(downsize, downsize, cell.frame.size.width - downsize*2, cell.frame.size.height - downsize*2);
    
    // ImgView
    
    imgView = [[UIImageView alloc]initWithFrame:imgViewRect];
    imgView.center = cell.center;
    imgView.contentMode = UIViewContentModeScaleAspectFit;
    imgView.autoresizingMask  = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    imgView.tag = 1101;
    [cell addSubview:imgView];
    
    //Label
    
    locNoLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, cell.frame.size.height - 20, cell.frame.size.height,20)]
    //        locNoLabel = [[UILabel alloc]initWithFrame:imgViewRect];
    ;
    locNoLabel.textAlignment   = NSTextAlignmentCenter;
    locNoLabel.backgroundColor = [UIColor clearColor];
    locNoLabel.textColor       = [UIColor whiteColor];
    locNoLabel.layer.cornerRadius = 5.0f;
    locNoLabel.layer.borderWidth  = 2.0f;
    locNoLabel.layer.borderColor  = [UIColor lightGrayColor].CGColor;
    locNoLabel.tag = 1102;
    [cell addSubview:locNoLabel];
    
    
    
    // ... LOAD DATA ...
    
    // ImgView
    if (_currentModeType == 1) {
        
        imgView.image = localImages[indexPath.row];
        
    }else if(_currentModeType == 3 ){
        
        imgView.image = [UIImage imageNamed:@"Locicon.png"];
    }
    
    // Location No label
    locNoLabel.text   = [NSString stringWithFormat:@"%ld-%ld",indexPath.section , indexPath.row];
    locNoLabel.hidden = (_currentModeType == 3)? NO:YES;
    
    
    return cell;
}


//
//- (NSUInteger)numberOfSectionsInEasyTableView:(EasyTableView*)easyTableView{
//    
//}
- (void)easyTableView:(EasyTableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    NSLog(@"did select%ld",(long)indexPath.row);
    
    if (_currentModeType == 1) {
        //紀錄模式
        
        //是否有show照片
        _isShowImagesOnMap = [[[NSUserDefaults standardUserDefaults] objectForKey:@"isShowImagesOnMap"] boolValue];
        if (_isShowImagesOnMap) {
            
            [self mapView:_mapView didTapMarker:localImgMarkers[indexPath.row]];
   
        }else{
            //不動作
        }
        
    }else if(_currentModeType == 3 ){
        //旅程模式
        
        [self mapView:_mapView didTapMarker:dlTripItemsMarkers[indexPath.section][indexPath.row]];
        
    }else{
        
        //
    }
    
}


#pragma mark
#pragma mark - Button
-(void)initButtons{
    
    // menu
    UIButton *menuBtn = [[UIButton alloc]initWithFrame:CGRectMake(5, 5, 44, 44)];
    [menuBtn addTarget:self action:@selector(showMenu:) forControlEvents:UIControlEventTouchDown];
    [menuBtn setTitle:@"Me" forState:UIControlStateNormal];
    [menuBtn setBackgroundColor:[UIColor lightGrayColor]];
//    [menuBtn setBackgroundImage:[UIImage imageNamed:@"s1_1.png"] forState:UIControlStateNormal];
    menuBtn.tag = 101;
    menuBtn.hidden = YES;//旅程建立, 才顯示
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
        
        [self showImagePickerAlert];
        
//        //點選"分析"按鈕時, 跳出照片
////        [self setImagePicker:_pickedAssets];
//        
//        UIAlertController * alert=   [UIAlertController
//                                      alertControllerWithTitle:@""
//                                      message:@"是否取用相簿照片"
//                                      preferredStyle:UIAlertControllerStyleAlert];
//        
//        UIAlertAction* yesButton = [UIAlertAction
//                                    actionWithTitle:@"Yes"
//                                    style:UIAlertActionStyleDefault
//                                    handler:^(UIAlertAction * action)
//                                    {
//                                        
//                                        //
//                                        switch ([PHPhotoLibrary authorizationStatus]) {
//                                            case PHAuthorizationStatusAuthorized:
//                                                [self setImagePicker:_pickedAssets];
//                                                break;
//                                                
//                                            default:
//                                                [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
//                                                    switch (status) {
//                                                        case PHAuthorizationStatusAuthorized:
//                                                        case PHAuthorizationStatusNotDetermined:
//                                                            [self setImagePicker:_pickedAssets];
//                                                            break;
//                                                            
//                                                        case PHAuthorizationStatusDenied:
//                                                        case PHAuthorizationStatusRestricted:
//                                                        {
//                                                            //Tell user access to the photos are restricted
//                                                            UIAlertController * alertForRestricted=   [UIAlertController
//                                                                                          alertControllerWithTitle:@"錯誤"
//                                                                                          message:@"無法訪問相簿,請至設定開啟權限"
//                                                                                          preferredStyle:UIAlertControllerStyleAlert];
//                                                            
//                                                            UIAlertAction *okBtn = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//                                                                [alertForRestricted dismissViewControllerAnimated:YES completion:nil];
//                                                            }];
//                                                            
//                                                            [alertForRestricted addAction:okBtn];
//                    
//                                                            [self presentViewController:alertForRestricted animated:YES completion:nil];
//                                                        }
//                                                            break;
//                                                            
//                                                        default:
//                                                            break;
//                                                    }
//                                                }];
//                                                break;
//                                        }
//                                        
//                                        
//                                        [alert dismissViewControllerAnimated:YES completion:nil];
//                                        
//                                    }];
//        
//        UIAlertAction* noButton = [UIAlertAction
//                                   actionWithTitle:@"No"
//                                   style:UIAlertActionStyleDefault
//                                   handler:^(UIAlertAction * action)
//                                   {
//                                       
//                                       [alert dismissViewControllerAnimated:YES completion:nil];
//                                       
//                                   }];
//        
//        [alert addAction:yesButton];
//        [alert addAction:noButton];
//        
//        [self presentViewController:alert animated:YES completion:nil];

    }else if(_currentModeType == 1){
        //紀錄
        NSLog(@"紀錄mode");
        
        //開啟相簿
        [self setImagePicker:_pickedAssets];
        
    }else if(_currentModeType == 2){
        //同夥
        NSLog(@"同夥mode");
        
    }else if(_currentModeType == 3){
        //旅程
        NSLog(@"旅程mode");
        
    }
    
    [self updateModeBtnState];
    
//    _currentModeType +=1;
//    if (_currentModeType >= [_modes count]) {
//        _currentModeType = 0;
//    }
//    
//    [sender setTitle:_modes[_currentModeType] forState:UIControlStateNormal];
}

-(void)updateModeBtnState{
    
    //
    UIButton *modeBtn = (UIButton *)[_mapDisplayView viewWithTag:102];
    [modeBtn setTitle:_modes[_currentModeType] forState:UIControlStateNormal];
    
   
    UIView *modeBtnBackgroundView = (UIView *)[_mapDisplayView viewWithTag:201];
    modeBtnBackgroundView.hidden = (_currentModeType == 0)? YES: NO;
    
    UIButton *addPhotoBtn = (UIButton *)[_mapDisplayView viewWithTag:103];
    addPhotoBtn.hidden = (_currentModeType == 1)? NO: YES;

    UIButton *chatRoomBtn = (UIButton *)[_mapDisplayView viewWithTag:104];
    chatRoomBtn.hidden = (_currentModeType == 2)? NO: YES;

    
    
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



-(void)editTripTitle:(UIGestureRecognizer *)recog{
    
    UITextField *tripTitleText = (UITextField *)[_mapDisplayView viewWithTag:301];
    [tripTitleText becomeFirstResponder];
    
}



#pragma mark
#pragma mark - menu
-(void)initMenuView{
    
    menuView = [[MapVCMenuView alloc]initWithFrame:CGRectMake(5, 54, 44, _mapDisplayView.frame.size.height - (54+80)) owner:nil];
    menuView.delegate = self;
    [_mapDisplayView addSubview: menuView];
    menuView.hidden = YES;
}

-(void)didSelectTheMenu:(UIButton *)btn;
{
    
    // Change mode button
    switch (btn.tag) {
        case 1:
            //紀錄mode
            _currentModeType = 1;
            
            //開啟相簿
            [self setImagePicker:_pickedAssets];
            
            break;
        case 2:
            //同夥mode
            _currentModeType = 2;
            [self joinChatingRoom];
            break;
            
        case 3:
            //旅程mode
            _currentModeType = 3;
            
            ///!!!:wait coding
            [self loadJsonTripData];
            [self showReadTripCodeVC];
//            [self drawPolyLinesOnMap];
            
            break;
        default:
            break;
    }

    [self updateModeBtnState];
    
    
    UIView *quickChatView = (UIView *)[_mapDisplayView viewWithTag:TAG_quickChatView];
    [quickChatView removeFromSuperview];
    
  
}
#pragma mark
#pragma mark - 照片相關管理
-(void)savePickedPhotoToDB{
   
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
    localImgMarkers = [[NSMutableArray alloc]init];
    
    [_mapView clear];
    
    //從PHAsset 解析出UIImage
    for (int i = 0; i < [_pickedAssets count]; i++)
    {
        PHAsset *asset = _pickedAssets[i];
        
        //取值 - 地圖座標
        CLLocationCoordinate2D position = CLLocationCoordinate2DMake(asset.location.coordinate.latitude, asset.location.coordinate.longitude);
        imageLatitude   = [NSString stringWithFormat:@"%f",asset.location.coordinate.latitude];
        imageLongtitude = [NSString stringWithFormat:@"%f",asset.location.coordinate.longitude];
        NSLog(@"imageLatitue:%@,imageLongtitude:%@",imageLatitude,imageLongtitude);
        
        
//        ///!!!:建立markers
//        GMSMarker *marker = [GMSMarker markerWithPosition:position];
//        marker.title =[NSString stringWithFormat:@"%d",i];
//        marker.snippet = @"Population: 8,174,100";
//        marker.infoWindowAnchor = CGPointMake(0.5, 0.5);
//        marker.map = _mapView;
//        [localImgMarkers addObject:marker];
        
        // marker 上放照片
//        UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 200, 300 , 300)];
//        NSInteger retinaMultiplier = [UIScreen mainScreen].scale;
//        CGSize retinaSquare = CGSizeMake(imageView.bounds.size.width * retinaMultiplier, imageView.bounds.size.height * retinaMultiplier);
//        [[PHImageManager defaultManager]
//         requestImageForAsset:_pickedAssets[i]
//         targetSize:retinaSquare
//         contentMode:PHImageContentModeAspectFill
//         options:nil
//         resultHandler:^(UIImage *result, NSDictionary *info) {
//             
//             [images addObject:result];
//             UIGraphicsBeginImageContextWithOptions(CGSizeMake(30, 40), NO, 0.0);
//             [result drawInRect:CGRectMake(0, 0, 30, 40)];
//             UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
//             UIGraphicsEndImageContext();
//             marker.icon = newImage;
//         }];
        ///
        
        //取值 - path
        imagePath = asset.localIdentifier;
        
        //存入table
        [[myDB sharedInstance]insertTable:tableName_tripPhoto andImageLatitude:imageLatitude andImageLongtitude:imageLongtitude ImagePath:imagePath andComments:comment andVoicePath:voicePath andHiddenState:hiddenState];
    }
    
    NSLog(@"save photo to DB success");
}

-(void)loadDBPhotos{
    
    //從資料庫撈assets
    NSMutableArray *queryTableResult=[[NSMutableArray alloc]init];
    NSMutableArray *localIdentifier =[[NSMutableArray alloc]init];
    queryTableResult = [[myDB sharedInstance]queryWithTableName:tableName_tripPhoto];
//    NSLog(@"%@",queryTableResult);
    
    
    if (queryTableResult) {
        //        PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
        [queryTableResult enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL * _Nonnull stop) {
            
            [localIdentifier addObject:dict[@"imagePath"]];
        }];
        
        PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:localIdentifier options:nil];
        //從assets解析出照片images
//        _pickedAssets = [[NSMutableArray alloc]init];
        localImages = [[NSMutableArray alloc]init];
        localImgMarkers = [[NSMutableArray alloc]init];
        
        [result enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL * _Nonnull stop) {
            
//            [_pickedAssets addObject:asset];
            
            // 建立local img markers
            CLLocationCoordinate2D position = CLLocationCoordinate2DMake(asset.location.coordinate.latitude, asset.location.coordinate.longitude);
//            NSLog(@"imageLatitue:%@,imageLongtitude:%@",imageLatitude,imageLongtitude);
            
            GMSMarker *marker = [GMSMarker markerWithPosition:position];
            marker.title =[NSString stringWithFormat:@"%lu",(unsigned long)idx];
            marker.snippet = @"Imgs";
            marker.infoWindowAnchor = CGPointMake(0.5, 0.5);
            marker.map = _mapView;
            [localImgMarkers addObject:marker];
            
            
            // 取 local imgs,
            UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 200, 300 , 300)];
            NSInteger retinaMultiplier = [UIScreen mainScreen].scale;
            CGSize retinaSquare = CGSizeMake(imageView.bounds.size.width * retinaMultiplier, imageView.bounds.size.height * retinaMultiplier);
            [[PHImageManager defaultManager]
             requestImageForAsset:asset
             targetSize:retinaSquare
             contentMode:PHImageContentModeAspectFill
             options:nil
             resultHandler:^(UIImage *result, NSDictionary *info) {
                 
                 [localImages addObject:result];
             }];
            
        }];
        
        [horizontalView.tableView reloadData];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self easyTableView:horizontalView didSelectRowAtIndexPath:indexPath];

    }

//    if (queryTableResult) {
//        //        PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
//        [queryTableResult enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL * _Nonnull stop) {
//            
//            [localIdentifier addObject:dict[@"imagePath"]];
//        }];
//        
//        PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:localIdentifier options:nil];
//        
//        _pickedAssets = [[NSMutableArray alloc]init];
//        
//        [result enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL * _Nonnull stop) {
//            
//            [_pickedAssets addObject:asset];
//            
//        }];
//    }
//    
//    //從assets解析出照片images
//    NSMutableArray *images = [[NSMutableArray alloc]init];
//    
//    for (int i = 0; i < [_pickedAssets count]; i++)
//    {
//        UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 200, 300 , 300)];
//        NSInteger retinaMultiplier = [UIScreen mainScreen].scale;
//        CGSize retinaSquare = CGSizeMake(imageView.bounds.size.width * retinaMultiplier, imageView.bounds.size.height * retinaMultiplier);
//        [[PHImageManager defaultManager]
//         requestImageForAsset:_pickedAssets[i]
//         targetSize:retinaSquare
//         contentMode:PHImageContentModeAspectFill
//         options:nil
//         resultHandler:^(UIImage *result, NSDictionary *info) {
//             
//             [images addObject:result];
//             
//         }];
//    }
//    //展示照片scroll view
//    [self showImageDisplayScrollViewWithImages:images];
    
}


#pragma mark - CHImagePickerView setting & delegate

-(void)showImagePickerAlert{
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

//show Image picker
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
    
    //存照片
    _pickedAssets = assets;
    [self savePickedPhotoToDB];
    
    //建立旅程, 如已經存在, 直接開照片
    BOOL isTripCreate = [[_tripInfo objectForKey:@"isTripCreate"]boolValue];
    if (!isTripCreate) {
        
        [self tripInfoUpdateObjec:[NSNumber numberWithBool:YES] forKey:@"isTripCreate"];
       
        [self updateTripCreateState];

    }else{
        
        [self loadDBPhotos];
    }
    
    
}

//-(void)finishedPickingImages:(NSMutableArray *)assets{
//    
//    _pickedAssets = assets;
//    
//    //Clear the table
//    [[myDB sharedInstance] deleteTable:tableName_tripPhoto];
//    [[myDB sharedInstance] createTripTable:tableName_tripPhoto];
//    
//    [[myDB sharedInstance] deleteTable:tableName_userGPS];
//    [[myDB sharedInstance] createGPSTable:tableName_userGPS];
//    
//    //ready to save to database
//    __block NSString *imagePath = [[NSString alloc]init];
//    NSString *imageLatitude     = [[NSString alloc]init];
//    NSString *imageLongtitude   = [[NSString alloc]init];
//    NSString *comment           = [[NSString alloc]init];
//    NSString *voicePath         = [[NSString alloc]init];
//    NSString *hiddenState       = [[NSString alloc]init];
//    
//    //
//    NSMutableArray *images = [[NSMutableArray alloc] init];
//    localImgMarkers = [[NSMutableArray alloc]init];
//    
//    [_mapView clear];
//    
//    //從PHAsset 解析出UIImage
//    for (int i = 0; i < [assets count]; i++)
//    {
//        PHAsset *asset = assets[i];
//        
//        //取值 - 地圖座標
//        CLLocationCoordinate2D position = CLLocationCoordinate2DMake(asset.location.coordinate.latitude, asset.location.coordinate.longitude);
//        imageLatitude   = [NSString stringWithFormat:@"%f",asset.location.coordinate.latitude];
//        imageLongtitude = [NSString stringWithFormat:@"%f",asset.location.coordinate.longitude];
//        NSLog(@"imageLatitue:%@,imageLongtitude:%@",imageLatitude,imageLongtitude);
//        
//        GMSMarker *marker = [GMSMarker markerWithPosition:position];
//        marker.title =[NSString stringWithFormat:@"%d",i];
//        marker.snippet = @"Population: 8,174,100";
//        marker.infoWindowAnchor = CGPointMake(0.5, 0.5);
//        marker.map = _mapView;
//        [localImgMarkers addObject:marker];
//        
//        //取值 - 圖片 & marker
//        UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 200, 300 , 300)];
//        NSInteger retinaMultiplier = [UIScreen mainScreen].scale;
//        CGSize retinaSquare = CGSizeMake(imageView.bounds.size.width * retinaMultiplier, imageView.bounds.size.height * retinaMultiplier);
//        [[PHImageManager defaultManager]
//         requestImageForAsset:assets[i]
//         targetSize:retinaSquare
//         contentMode:PHImageContentModeAspectFill
//         options:nil
//         resultHandler:^(UIImage *result, NSDictionary *info) {
//             
//             [images addObject:result];
//             UIGraphicsBeginImageContextWithOptions(CGSizeMake(30, 40), NO, 0.0);
//             [result drawInRect:CGRectMake(0, 0, 30, 40)];
//             UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
//             UIGraphicsEndImageContext();
//             marker.icon = newImage;
//         }];
//        
//        //取值 - path
//        imagePath = asset.localIdentifier;
//        
////        PHImageRequestOptions * imageRequestOptions = [[PHImageRequestOptions alloc] init];
////        imageRequestOptions.synchronous = YES;
////        [[PHImageManager defaultManager]
////         requestImageDataForAsset:asset
////         options:imageRequestOptions
////         resultHandler:^(NSData *imageData, NSString *dataUTI,
////                         UIImageOrientation orientation,
////                         NSDictionary *info)
////         {
//////             NSLog(@"info = %@", info);
////             if ([info objectForKey:@"PHImageFileURLKey"]) {
////                 // path looks like this -
////                 // file:///var/mobile/Media/DCIM/###APPLE/IMG_####.JPG
////                 NSURL *path = [info objectForKey:@"PHImageFileURLKey"];
////                 imagePath = [NSString stringWithFormat:@"%@",path];
////             }
////         }];
//
//        //存入table
//        [[myDB sharedInstance]insertTable:tableName_tripPhoto andImageLatitude:imageLatitude andImageLongtitude:imageLongtitude ImagePath:imagePath andComments:comment andVoicePath:voicePath andHiddenState:hiddenState];
//        
//    }
//    
//    //是否放照片在地圖上
//    _isShowImagesOnMap = [[[NSUserDefaults standardUserDefaults] objectForKey:@"isShowImagesOnMap"] boolValue];
//    if (_isShowImagesOnMap) {
//        NSLog(@"show Images On Map");
//    }else{
//        [_mapView clear];
//        NSLog(@"Don't show Images On Map ");
//    }
//    
//    //show Image scrollView
//    UIView *modeBtnBackgroundView = (UIView *)[_mapDisplayView viewWithTag:201];
//    modeBtnBackgroundView.hidden = NO;
//    
//    [imageScrollView setImageAry:images];
////    [self setImageDisplayScrollView:images];
//
//
//    
//    //Create  Trip
//    if (!_isTripCreate) {
//
//        _isTripCreate = YES;
//        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:_isTripCreate] forKey:@"isTripCreate"];
//        
//        
//        [self updateTripCreateState];
//        
//        
//        ///!!!:wait for coding
//        //show Trip title text
//        UITextField *tripTitleText = (UITextField *)[_mapDisplayView viewWithTag:301];
//        tripTitleText.hidden = NO;
//        
//        UIView *coverTripTitleView = (UIView *)[_mapDisplayView viewWithTag:202];
//        coverTripTitleView.hidden = NO;
//        ///
//        
//        
//        
//        NSLog(@"Trip Created!");
//    }
//
//    //Start to record GPS
//    [_locationManager startUpdatingLocation];
//    NSLog(@"GPS recording start");
//}

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


#pragma mark
#pragma mark - Map (GMSMapView Settings & Delegate)

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

-(void)createMarker{
    
    CLLocationCoordinate2D position = CLLocationCoordinate2DMake(24.081446, 120.538854);
    GMSMarker *marker = [GMSMarker markerWithPosition:position];
    marker.title =[NSString stringWithFormat:@"Marker title"];
    marker.snippet = @"Marker snippet";
    marker.infoWindowAnchor = CGPointMake(0.5, 0.5);
    marker.map = _mapView;
    [localImgMarkers addObject:marker];
}


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

#pragma mark - GPS & locationManager

-(void)locationManagerSetting{
    
    if (_locationManager == nil)
    {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.desiredAccuracy =
        kCLLocationAccuracyNearestTenMeters;
        _locationManager.delegate = self;
        [_locationManager requestAlwaysAuthorization];
        
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
    //    NSLog(@"/n lat: %f",_locationManager.location.coordinate.latitude);
    //    NSLog(@" lon: %f/n",_locationManager.location.coordinate.longitude);
    
    //存入table
    [[myDB sharedInstance]insertGPSTable:tableName_userGPS
                             andLatitude:[NSString stringWithFormat:@"%f",
                                          _locationManager.location.coordinate.latitude]
                           andLongtitude:[NSString stringWithFormat:@"%f",_locationManager.location.coordinate.longitude]];
    
    double lat = _locationManager.location.coordinate.latitude;
    double lon = _locationManager.location.coordinate.longitude;
    
    
    //update server
    [[CHFIreBaseAdaptor sharedInstance]updateMemberBykey:@"lastGPSLocation" andValue:[NSArray arrayWithObjects:[NSNumber numberWithDouble:lat],[NSNumber numberWithDouble:lon],nil] success:^(FDataSnapshot *snapshot) {
        
        ///!!!:update member marker
        [self addMemberMarker];
        
    } failure:^{
        
        //
        NSLog(@"");
    }];
    
    
    [self drawPolyLinesOnMap];
    
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"locationManager didFailWithError: %@", error);
    
}

//- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
//{
//    NSLog(@"didUpdateToLocation: %@", newLocation);
//    CLLocation *currentLocation = newLocation;
//    
//    if (currentLocation != nil) {
//        
//        NSLog(@"\n\n(lat:%@,Long:%@)",[NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude],[NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude]);
//        
//    }
//}


#pragma mark - draw path on map
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
    
    if (textField.tag == TAG_quickChatText) {
        //
    }else{
        textField.backgroundColor = [UIColor whiteColor];
        textField.layer.borderColor = [[UIColor blackColor]CGColor];
    }
    
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    
    if (textField.tag == TAG_quickChatText) {
        //
    }else{
        
        textField.backgroundColor = [UIColor clearColor];
        textField.layer.borderColor = [[UIColor clearColor]CGColor];
        
        if ([textField.text isEqualToString:@""]) {
            textField.text = _tripInfo[@"tripTitle"];
        }else{
            NSString *string = textField.text;
            [_tripInfo setObject:string forKey:@"tripTitle"];
            [[NSUserDefaults standardUserDefaults] setObject:_tripInfo forKey:@"tripInfo"];
        }
    }
    
    
    
}

#pragma mark - Notification 
-(void)didReceiveChatRoomMessage:(NSNotification *)notification{
    
    NSDictionary *userInfo = [notification userInfo];
    NSString *receivedMessage = userInfo[@"aps"][@"alert"];
    
    NSLog(@"%@", receivedMessage);
}


#pragma mark 
#pragma mark - 同夥模式
#pragma mark - Chat room actions
/*
 流程：
 
 確認是否已有member

 建立/確認 user,
 獲得userID(uuid) & nickname
 
 建立/確認 room,
 獲得roomID,
 
 使用roomID & userID(uuid)建立member
 
 2.建立 room有兩種方式
    a. 加入 (搜尋現有roomID,再以roomID & userID(uuid)建立member)
    b. 自創 (以userID(uuid)建立room, 再以roomID & userID(uuid)建立member)
 */


//FireBase
-(void)joinChatingRoom{

    [self indicatorStart];

    [[CHFIreBaseAdaptor sharedInstance] queryMemberByUUID:_userInfo[@"UUID"] success:^(FDataSnapshot *snapshot) {
        
        //UUID搜尋是否已經建立member
        //否, 則進入 "加入" or "自創"選單, 建立memeber後, 進入setting VC
        //是, 則進入setting VC
        
        NSDictionary *dic = (NSDictionary *)snapshot.value ;

        //存在member
        if (dic.count == 1) {
            //正常：1個uuid對應1個member
            
            //撈roomID
            NSDictionary *dic2 = [[dic allValues] firstObject];
            _roomID = [dic2 objectForKey:@"roomID"];
            
            //存到default
            [_roomInfo setObject:_roomID     forKey:@"roomID"];
            [[NSUserDefaults standardUserDefaults] setObject:_roomInfo forKey:@"roomInfo"];
            
            //開啟setting VC
            [self showChatRoomSettingVC];
            [self indicatorStop];
            
        }else{
            //不正常：1個uuid對應多個member
            
            NSLog(@"member uuid重複");
        }
        
        
        
    } failure:^{
        //不存在member
        
        //確認uuid是否建立user
        //否, 建立user, 然後開啟"加入" or "自創"選單
        //是, 開啟"加入" or "自創"選單
        
        [[CHFIreBaseAdaptor sharedInstance] queryUserByUUID:_userInfo[@"UUID"] exist:^(FDataSnapshot *snapshot) {
            
            
            NSLog(@"UUID尚未建立Member, 但已建立user");
            [self showChatRoomActionSheet];
            
        } notExist:^{
             NSLog(@"UUID尚未建立Member & user");
            
            [[CHFIreBaseAdaptor sharedInstance]createUserByUUID:_userInfo[@"UUID"] andNickname:@"New User" success:^{
                
                NSLog(@"New user create success");
                
                [self showChatRoomActionSheet];
                
            } failure:^{
                
                NSLog(@"New user create Failuer");
            }];
            
        }];
        
        
        
        
    }];
    
    
}

-(void)showChatRoom:(UIButton *)sender{
    
    CHChatRoomVC *vc = [[CHChatRoomVC alloc]init];
    [self presentViewController:vc animated:YES completion:nil];
    
}

//Parse
//-(void)joinChatingRoom{
//    
//    [self indicatorStart];
//    
//    PFQuery *query = [PFQuery queryWithClassName:@"Member"];
//    [query whereKey:@"userID" equalTo:_userInfo[@"userID"]];
//    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
//        [self indicatorStop];
//        
//        if (!error) {
//        
//            if (objects.count ==0) {
//                [self showChatRoomActionSheet];
//            }else{
//                
//                PFObject *member = [objects firstObject];
//                _roomID = [member objectForKey:@"roomID"];
//                
//                [self showChatRoomSettingVC];
//            }
//        }else{
//            NSLog(@"Error:%@",error.description);
//        }
//        
//        
//        
//
//    }];
//}



//-(void)joinChatRoomWhereRoomID:(NSString *)roomID{
//    
//    [self indicatorStart];
//    
//    PFQuery *query = [PFQuery queryWithClassName:@"Member"];
//    [query whereKey:@"roomID" equalTo:roomID];
//    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
//        
//        if (objects.count!=0) {
//            PFObject *newMember = [PFObject objectWithClassName:@"Member"];
//            newMember[@"roomID"] = roomID;
//            newMember[@"userID"] = _userInfo[@"userID"];
//            newMember[@"nickName"] = _userInfo[@"nickName"];
//            newMember[@"isHost"] = [NSNumber numberWithBool:NO];
//            
//            [newMember saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//                if (succeeded) {
//                    // The object has been saved.
//                    NSLog(@"New member created");
//                } else {
//                    // There was a problem, check error.description
//                    NSLog(@"Fail room created\n\n%@",error.description);
//                }
//            }];
//        }
//    }];
//}

//確認是否已加入聊天室
//-(void)checkJoinChatRoomStateWithUserID:(NSString *)userID{
//    
//    //retrive data from cloud
//    PFQuery *query = [PFQuery queryWithClassName:@"Member"];
//    [query whereKey:@"userID" equalTo:userID];
//    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
//
//        if (objects.count ==0) {
//            _isChatRoomJoin = NO;
//            NSLog(@"使用者%@ 尚未加入聊天室",userID);
//            
//        }else if (objects.count ==1) {
//            
//            // get the roomID
//            PFObject *memberObject = objects[0];
//            _chatRoomID = [memberObject objectForKey:@"roomID"];
//            NSLog(@"使用者%@ 已加入%@聊天室",[memberObject objectForKey:@"userID"],[memberObject objectForKey:@"roomID"]);
//           
//            // 第一次開啟app, 只確認狀態不開啟setting
//            if (_isCheckChatRoomJoin) {
//                [self showChatRoomSettingVC];
//            }
//            _isChatRoomJoin = YES;
//            
//        }else{
//            NSLog(@"錯誤：使用者同時存在%lu個聊天室",(unsigned long)objects.count);
//        }
//        
//        _isCheckChatRoomJoin = YES;
//
//    }];
//    
//    
//}


-(void)createChatRoom{
    
    [fireBaseAdp createRoomByUUID:_userInfo[@"UUID"] success:^{
        
        //開啟setting VC
        NSLog(@"自創room成功, 開啟setting VC");
        [self showChatRoomSettingVC];
        
    } failure:^{
        
        //開啟setting VC
        NSLog(@"自創room失敗");

    } ];
    
}


//Parse
//-(void)createChatRoom{
//    
//    [self indicatorStart];
//
//    //使用userID 創建 Rooms
//    PFObject *newRoom = [PFObject objectWithClassName:@"Rooms"];
//    newRoom[@"roomHostID"] = _userInfo[@"userID"];
//    [newRoom saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//        
//        [self indicatorStop];
//        
//        if (succeeded) {
//            
//            _roomID = newRoom.objectId;
//            NSLog(@"New room(ID:%@) created",_roomID);
//            
//            //創建成功,則繼續新建Member
//            [self createMemberWhereUserID:_userInfo[@"userID"] andNickname:_userInfo[@"nickName"] inTheRoom:_roomID isHost:YES];
//            
//        } else {
//            // There was a problem, check error.description
//            NSLog(@"Fail room created\n\n%@",error.description);
//        }
//        
//    }];
//    
//}



-(void)createMemberWhereUserID:(NSString*)userID andNickname:(NSString*)nickname inTheRoom:(NSString*)roomID isHost:(BOOL)isHost{
    
    [self indicatorStart];
    
    PFObject *obj = [PFObject objectWithClassName:@"Member"];
    [obj setValue:roomID forKey:@"roomID"];
    [obj setValue:userID forKey:@"userID"];
    [obj setValue:nickname forKey:@"nickName"];
    [obj setValue:[NSNumber numberWithBool:isHost] forKey:@"isHost"];
    [obj saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        
        [self indicatorStop];

        if (succeeded) {
            NSLog(@"New memeber create");
            
            [self showChatRoomSettingVC];
        }else{
            NSLog(@"fait to create New memeber\n\n%@",error.description);
        }
    }];
    
    
//    PFQuery *queryRoomObjectID = [PFQuery queryWithClassName:@"Rooms"];
//    [queryRoomObjectID whereKey:@"roomHostID" equalTo:_userInfo[@"userID"]];
//    PFObject *roomObj = [[queryRoomObjectID findObjects] firstObject];
//    _chatRoomID = roomObj.objectId;
//    
//    PFObject *newMember = [PFObject objectWithClassName:@"Member"];
//    newMember[@"userID"] = _deviceUserIDOfChatRoom;
//    newMember[@"isHost"] = [NSNumber numberWithBool:YES];
//    newMember[@"roomID"] = _chatRoomID;
//    
//    [newMember saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//        if (succeeded) {
//            // The object has been saved.
//            NSLog(@"New member created");
//            
//            [self checkJoinChatRoomStateWithUserID:_deviceUserIDOfChatRoom];
//        } else {
//            // There was a problem, check error.description
//            NSLog(@"Fail room created\n\n%@",error.description);
//        }
//    }];
    
}

-(void)showChatRoomActionSheet{
    
    UIAlertController *allyChatRoom = [[UIAlertController alloc]init];
    
    UIAlertAction *joinChatRoom = [UIAlertAction actionWithTitle:@"加入" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"Join chat room  Action");
        
        [self showJoinAlert];
        
    }];
    
    UIAlertAction *createChatRoom = [UIAlertAction actionWithTitle:@"新開群組" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"Create chat room  Action");
        
        [self createChatRoom];
       
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"cancel chat room Action");
    }];
    
    [allyChatRoom addAction:joinChatRoom];
    [allyChatRoom addAction:createChatRoom];
    [allyChatRoom addAction:cancel];
    
    [self presentViewController:allyChatRoom animated:YES completion:nil];

}

-(void)showJoinAlert{
    
    UIAlertController *joinRoomAC = [UIAlertController alertControllerWithTitle:@"輸入聊天室代號" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    // set textfield to AC
    [joinRoomAC addTextFieldWithConfigurationHandler:^(UITextField *textField){
        textField.placeholder = @"enter room code";
    }];
    
    // set cancel btn to AC
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        //
    }];
    
    // set ok btn to AC
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"加入" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        UITextField *roomCodeTF = joinRoomAC.textFields.firstObject;
        NSLog(@"You are search room code:%@",roomCodeTF.text);
        
        //確認房號是否存在,
        //如是, 則創造Member以示加入,否則跳警告
        //現有userInfo來創房
        
        [[CHFIreBaseAdaptor sharedInstance] queryRoomByRoomID:roomCodeTF.text success:^(FDataSnapshot *snapshot) {
            
            //房間存在, 創造member
            [fireBaseAdp createMemberByUUID:_userInfo[@"UUID"] andNickname:_userInfo[@"nickName"] andRoomID:roomCodeTF.text isHost:NO success:^{
                
                //存到default
                [_roomInfo setObject:roomCodeTF.text forKey:@"roomID"];
                [[NSUserDefaults standardUserDefaults] setObject:_roomInfo forKey:@"roomInfo"];
                
                //開啟setting VC
                NSLog(@"Member 創立成功, 開啟setting VC");
                [self showChatRoomSettingVC];
                
            } failure:^{
                //
                NSLog(@"Member 創立失敗");
                
            }];
            
        } failure:^{
            
            //房間不存在
            UIAlertController *noRoomExist = [UIAlertController alertControllerWithTitle:@"錯誤" message:@"查無此聊天室" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"瞭解" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                //
            }];
            [noRoomExist addAction:cancelAction];
            [self presentViewController:noRoomExist animated:YES completion:nil];
            
        }];
        
//        [fireBaseAdp queryRoomByRoomID:roomCodeTF.text success:^(FDataSnapshot *snapshot) {
//            
//            //房間存在, 創造member
//            [fireBaseAdp createMemberByUUID:_userInfo[@"UUID"] andNickname:_userInfo[@"nickName"] andRoomID:roomCodeTF.text isHost:NO success:^{
//                //
//                
//                //開啟setting VC
//                NSLog(@"Member 創立成功, 開啟setting VC");
//                [self showChatRoomSettingVC];
//                
//            } failure:^{
//                //
//                NSLog(@"Member 創立失敗");
//                
//            }];
//            
//        } failure:^{
//            
//            //房間不存在
//            UIAlertController *noRoomExist = [UIAlertController alertControllerWithTitle:@"錯誤" message:@"查無此聊天室" preferredStyle:UIAlertControllerStyleAlert];
//            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"瞭解" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
//                //
//            }];
//            [noRoomExist addAction:cancelAction];
//            [self presentViewController:noRoomExist animated:YES completion:nil];
//
//        }];

        
        
        
        
//        PFQuery *query = [PFQuery queryWithClassName:@"Rooms"];
//        [query whereKey:@"objectId" equalTo:roomCodeTF.text];
//        [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
//            
//            [self indicatorStop];
//            if (objects.count ==0) {
//                
//                // 房間不存在, show alert
//                UIAlertController *noRoomExist = [UIAlertController alertControllerWithTitle:@"錯誤" message:@"查無此聊天室" preferredStyle:UIAlertControllerStyleAlert];
//                
//                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"瞭解" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
//                    //
//                }];
//                [noRoomExist addAction:cancelAction];
//                [self presentViewController:noRoomExist animated:YES completion:nil];
//                
//            }else{
//                //房間存在, 創造member
//                [self createMemberWhereUserID:_userInfo[@"userID"] andNickname:_userInfo[@"nickName"] inTheRoom:roomCodeTF.text isHost:NO];
//            }
//            
//        }];
        
        
        
        
    }];
    
    
    // apply btns to AC
    [joinRoomAC addAction:cancelAction];
    [joinRoomAC addAction:okAction];
    
    // show AC
    [self presentViewController:joinRoomAC animated:YES completion:nil];
}

-(void)showChatRoomSettingVC{
 
    
    CHChatRoomSettingVC *vc = [[CHChatRoomSettingVC alloc]init];
    vc.delegate = self ;
    [self presentViewController:vc animated:YES completion:nil];

    
    
//    [[CHFIreBaseAdaptor sharedInstance] queryMemberByRoomID:_roomID success:^(FDataSnapshot *snapshot) {
//        
//        // Query members
//        NSDictionary *dic = snapshot.value;
//        NSMutableArray *memberAry = [NSMutableArray arrayWithArray:[dic allValues]];
//        //        NSArray *keyAry = [dic allKeys];
//        
//        
//        //        [keyAry enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL * _Nonnull stop) {
//        //            [memberAry addObject:dic[key]];
//        //        }];
//        
//        CHChatRoomSettingVC *vc = [[CHChatRoomSettingVC alloc]init];
//        vc.chatRoomMembers = memberAry;
//        [self presentViewController:vc animated:YES completion:nil];
//        vc.roomIDLabel.text =_roomID;
//        
//    } failure:^{
//        //
//    }];
    
    
    
//    [fireBaseAdp queryMemberByRoomID:_roomID success:^(FDataSnapshot *snapshot) {
//        
//        // Query members
//        NSDictionary *dic = snapshot.value;
//        NSMutableArray *memberAry = [NSMutableArray arrayWithArray:[dic allValues]];
////        NSArray *keyAry = [dic allKeys];
//        
//
////        [keyAry enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL * _Nonnull stop) {
////            [memberAry addObject:dic[key]];
////        }];
//        
//        CHChatRoomSettingVC *vc = [[CHChatRoomSettingVC alloc]init];
//        vc.chatRoomMembers = memberAry;
//        [self presentViewController:vc animated:YES completion:nil];
//        vc.roomIDLabel.text =_roomID;
//        
//    } failure:^{
//        //
//    }];
}


//parse
//-(void)showChatRoomSettingVC{
//    
//    [self indicatorStart];
//    
//    // Query members
//    PFQuery *queryResult = [PFQuery queryWithClassName:@"Member"];
//    
//    // query all members
//    [queryResult whereKey:@"roomID" equalTo:_roomID];
//    [queryResult findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
//        
//        [self indicatorStop];
//
//        if (!error) {
//            if (objects.count !=0) {
//                
//                CHChatRoomSettingVC *vc = [[CHChatRoomSettingVC alloc]init];
//                vc.chatRoomMembers = [NSMutableArray arrayWithArray:objects];
//                [self presentViewController:vc animated:YES completion:nil];
//                
//                vc.roomIDLabel.text =_roomID;
//    
//            }
//        }else{
//            NSLog(@"Error:%@",error.description);
//        }
//        
//        
//        
//        
//    }];
//
//}


#pragma mark - ChatRoom delegate

-(void)didLeftSettingVC{
    
    NSLog(@"left Setting View");
    
    _roomInfo = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults]objectForKey: @"roomInfo"]];
    
    [self quickChatTextInit];

    receivedMsg = [NSTimer scheduledTimerWithTimeInterval:10.0f
                                                   target:self selector:@selector(locationManager: didUpdateLocations:) userInfo:nil repeats:YES];
    
    
    if ([_roomInfo[@"isShowOnMap"] boolValue]) {
        
       [receivedMsg isValid];
//        [self addMemberMarker];
    }else{
       [receivedMsg invalidate];
    }

    
    
}


///!!!:開始更新member marker on map
-(void)removeMemberMarker{
    
    // ... remove member marker
    [memberMarkers enumerateObjectsUsingBlock:^(GMSMarker *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.map = nil;
    }];
    
    [memberMarkers removeAllObjects];
}

-(void)addMemberMarker{
    
    
    // ... remove member marker
    [self removeMemberMarker];
    
    [[CHFIreBaseAdaptor sharedInstance] queryMemberByRoomID:_roomInfo[@"roomID"] success:^(FDataSnapshot *snapshot) {
        
        NSLog(@"success");
        
        if ([snapshot.value isEqual:[NSNull null]]) {
            
            //not exsit
            
        }else{
            
            //exsit
            
            NSDictionary *members = snapshot.value;
            memberMarkers = [[NSMutableArray alloc]init];
            
            [members enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSDictionary *member, BOOL * _Nonnull stop) {
                
                NSArray *locGPS = member[@"lastGPSLocation"];
                float lat = [locGPS[0] floatValue];
                float lon = [locGPS[1] floatValue];
                
                // 建立 member markers
                CLLocationCoordinate2D position = CLLocationCoordinate2DMake(lat,lon);
                GMSMarker *marker = [GMSMarker markerWithPosition:position];
                marker.title = member[@"userNickname"];
                marker.snippet = @"User";
                marker.infoWindowAnchor = CGPointMake(0.5, 0.5);
                marker.userData = member[@"uuid"];
                
                marker.map = (member[@"isShowOnMap"])? _mapView : nil;
                [memberMarkers addObject:marker];
                
                
                
            }];
            
            [self addMsgOnMemberMarker];
            NSLog(@"memberMarke 有%ld個",memberMarkers.count);
        }
        
        
    } failure:^{
        //
        NSLog(@"fail");
        
    }];
    
}

-(void)addMsgOnMemberMarker{
    
    [[CHFIreBaseAdaptor sharedInstance]queryMsgRegularlyByRoomID:_roomInfo[@"roomID"] success:^(FDataSnapshot *snapshot) {
        
        //
        NSLog(@"");
        NSDictionary *dic = snapshot.value;
        
        [memberMarkers enumerateObjectsUsingBlock:^(GMSMarker *marker, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if ([marker.userData isEqualToString:dic[@"uuid"]]) {
                marker.title = dic[@"message"];
                [self mapView:_mapView didTapMarker:marker];
            }
            
        }];
        
        
    } failure:^{
        
        //
        NSLog(@"");
    }];
    
}



#pragma mark - quick msg

-(void)quickChatTextInit{
    
    CGRect frame = BOTTOM_VIEW_FRAME1;
    frame.size.width = _mapDisplayView.frame.size.width;
    UIView *quickChatView = [[UIView alloc]initWithFrame:frame];
    quickChatView.tag = TAG_quickChatView;
    quickChatView.layer.borderWidth = 2.0f;
//    quickChatView.layer.borderColor = [UIColor blackColor].CGColor;
//    quickChatView.backgroundColor = [UIColor whiteColor];
    [_mapDisplayView addSubview:quickChatView];
    
    CGRect frame2 = BOTTOM_VIEW_FRAME1;
    frame2.origin = CGPointMake(0, 0);
    UITextField *quickChat = [[UITextField alloc]initWithFrame:frame2];
    quickChat.tag = TAG_quickChatText;
    quickChat.delegate = self;
    quickChat.layer.borderWidth = 2.0f;
    quickChat.layer.borderColor = [UIColor brownColor].CGColor;
    quickChat.backgroundColor   = [UIColor whiteColor];
    [quickChatView addSubview:quickChat];
    
    CGRect frame3 =CGRectMake(frame2.size.width, frame.size.height*0.15, frame.size.width - frame2.size.width, frame.size.height*0.7);
    UIButton *sendQuickMsgBtn = [[UIButton alloc]initWithFrame:frame3];
    sendQuickMsgBtn.backgroundColor = [UIColor blueColor];
    [sendQuickMsgBtn setTitle:@"Send" forState:UIControlStateNormal];
    [sendQuickMsgBtn addTarget:self action:@selector(didSentQuickMsg) forControlEvents:UIControlEventTouchDown];
    [quickChatView addSubview:sendQuickMsgBtn];
    
    UIButton *modeBtn = (UIButton *)[_mapDisplayView viewWithTag:TAG_modeBtn];
    [_mapDisplayView bringSubviewToFront:modeBtn];
    
}

-(void)didSentQuickMsg{
    
    UITextField *quickChat = (UITextField *)[_mapDisplayView viewWithTag:TAG_quickChatText];
    
    if (![quickChat.text isEqualToString:@""]) {
       
        [[CHFIreBaseAdaptor sharedInstance] createMsgByUUID:_userInfo[@"UUID"] andMSg:quickChat.text andRoomID:_roomInfo[@"roomID"] success:^{
            NSLog(@"create msg success");
        } failure:^{
            NSLog(@"create msg Fail!!");
        }];
        
        quickChat.text = @"";
        
    }
    
    [quickChat resignFirstResponder];

}

- (void)keyboardWillShow:(NSNotification *)notification {
    
    UIView *quickChatView = (UIView *)[_mapDisplayView viewWithTag:TAG_quickChatView];
    CGRect newFrame = quickChatView.frame;
    
    NSDictionary *info = [notification userInfo];
    NSValue *kbFrame = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect keyboardFrame = [kbFrame CGRectValue];
    CGFloat height = keyboardFrame.size.height;
    
    // we need to set a negative constant value here.
    newFrame.origin.y -= height;
    quickChatView.frame = newFrame;
    
    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    // we need to set a negative constant value here.
    UIView *quickChatView = (UIView *)[_mapDisplayView viewWithTag:TAG_quickChatView];
    CGRect newFrame = BOTTOM_VIEW_FRAME1;
    newFrame.size.width = _mapDisplayView.frame.size.width;;
     quickChatView.frame = newFrame;
    
    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}


#pragma mark
#pragma mark - Trip data
-(void)showReadTripCodeVC{
    
    CHReadTripCodeVC *vc = [[CHReadTripCodeVC alloc]init];
    vc.delegate = self;
    [self presentViewController:vc animated:YES completion:nil];
}

-(void)didLoadTripDate:(id)tripData{
    
    NSLog(@"Start to load trip data");
    
    //建立table
    CHMoveableTableView *moveTV = [(CHMoveableTableView *)_mapDisplayView viewWithTag:401];
    
    if (moveTV) {
        [moveTV removeFromSuperview];
    }
    
    float tableWidth = 88;
    float tableHeight = _mapDisplayView.frame.size.height - (54 + IMAGEHEIGHT +44);
    
    moveTV = [[CHMoveableTableView alloc]initWithFrame:CGRectMake(_mapDisplayView.frame.size.width - tableWidth, 54, tableWidth, tableHeight)];
    moveTV.tag = 401;
    [_mapDisplayView addSubview:moveTV];
    moveTV.chDelegate = self;
    
    // fed data
    [moveTV setObjects:[NSMutableArray arrayWithArray:tripData[@"total"]]];
    
}

- (void)moveableTableView:(CHMoveableTableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [self easyTableView:horizontalView didSelectRowAtIndexPath:indexPath];
    
}

-(void)loadJsonTripData{
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"plugtrip" ofType:@"json"];
    
    // Load the file into an NSData object called JSONData
    
    NSError *error = nil;
    
    NSData *JSONData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
    
    // Create an Objective-C object from JSON Data
    
    id JSONObject = [NSJSONSerialization
                     JSONObjectWithData:JSONData
                     options:NSJSONReadingAllowFragments
                     error:&error];
    NSLog(@"%@",JSONObject);
    
    
    // Making markers on map
    
    NSArray *total = JSONObject[@"total"];

    dlTripItemsMarkers = [[NSMutableArray alloc]init];
    
    [total enumerateObjectsUsingBlock:^(NSDictionary *day, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSArray *items = day[@"items"];
        NSMutableArray *day_markers = [[NSMutableArray alloc]init];
        
        [items enumerateObjectsUsingBlock:^(NSDictionary *item, NSUInteger idx, BOOL * _Nonnull stop) {
            
            CLLocationCoordinate2D position = CLLocationCoordinate2DMake([item[@"lat"] floatValue], [item[@"lon"] floatValue]);
            GMSMarker *marker = [GMSMarker markerWithPosition:position];
            marker.title   = [NSString stringWithFormat:@"%@",item[@"title"]];
            marker.snippet = [NSString stringWithFormat:@"%@",item[@"text"]];
            marker.infoWindowAnchor = CGPointMake(0.5, 0.5);
            marker.map = _mapView;
            
            [day_markers addObject:marker];
            
        }];
        
        [dlTripItemsMarkers addObject:day_markers];
        
    }];
    
    [horizontalView.tableView reloadData];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self easyTableView:horizontalView didSelectRowAtIndexPath:indexPath];
}

#pragma mark
#pragma mark - Alerts
-(void)showOfflineAlert:(NSError *)error{
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"瞭解" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"cancel chat room Action");
    }];
    
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];

    
}

#pragma mark - indicator setting
-(void)indicatorSetting
{
    activityIndicator = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(0.0f, 0.0f, 32.0f, 32.0f)];
    [activityIndicator setCenter:self.view.center];
    [activityIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(indicatorStart) name:@"indicatorStart" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(indicatorStop) name:@"indicatorStop" object:nil];
    

}

- (void)indicatorStart
{
    
    UIView *view = [[UIView alloc] initWithFrame:self.view.frame];
    [view setTag:203];
    [view setBackgroundColor:[UIColor blackColor]];
    [view setAlpha:0.8];
    [self.view addSubview:view];
    
    [self.view addSubview:activityIndicator];
    [activityIndicator startAnimating];
}

- (void)indicatorStop
{
    UIView *view = (UIView *)[self.view viewWithTag:203];
    [view removeFromSuperview];
    
    [activityIndicator stopAnimating];
}

@end














