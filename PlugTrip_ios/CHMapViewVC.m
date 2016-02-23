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

//#define TAG_menuBtn       101
//#define TAG_modeBtn       102
//#define TAG_addPhotoBtn   103
//#define TAG_chatRoomBtn   104
//#define TAG_modeBtnBackgroundView 201
//#define TAG_coverTripTitleView    202
//#define TAG_indicator_maskView    203
//#define TAG_quickChatView         204
//#define TAG_tripTitleText 301
//#define TAG_quickChatText 302
//#define TAG_moveTV 401
//#define TAG_horizontalView_CellImgView   501
//#define TAG_horizontalView_CellLabel     502
//
//#define WIDTH_moveTV 88
//#define IMAGEHEIGHT    50
//#define MODEBTN_WIDTH  80.0
//#define MODEBTN_HEIGHT 44.0
//#define MEMBER_MapMarker_SIZE 20
//
//
//#define BOTTOM_VIEW_FRAME1 CGRectMake(0, _mapDisplayView.frame.size.height-IMAGEHEIGHT, _mapDisplayView.frame.size.width-MODEBTN_WIDTH, IMAGEHEIGHT)
//#define BOTTOM_VIEW_FRAME2 CGRectMake(0, _mapDisplayView.frame.size.height-IMAGEHEIGHT, _mapDisplayView.frame.size.width-MODEBTN_WIDTH*2, IMAGEHEIGHT)



#import "CHMapViewVC.h"

@interface CHMapViewVC ()
{
    MapVCSearchView *sView;
    MapVCMenuView *menuView;
    
    
    
    CHScrollView *imageScrollView;
    
    CHFIreBaseAdaptor *fireBaseAdp;
    
    UIActivityIndicatorView *activityIndicator;
    
    //紀錄mode
    NSMutableArray *localImgData_orderByDate;
//    NSMutableArray *localImages;
//    NSMutableArray *localImgMarkers;
    NSTimer *receivedMsg;
    
    //夥伴mode
    
    NSMutableArray *memberMarkers;
    
    //旅程mode
    NSMutableArray *dlTripItems;
    NSMutableArray *dlTripItemsMarkers;
    
    //通用(紀錄&旅程)
    EasyTableView *horizontalView;
    
    
    //縮放cell
    CGFloat ratio;
    CGFloat horizonTVOffset;
    NSIndexPath *resizeIndexPath;
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

    [self initTripInfo];
    [self initUserInfo];
    [self initRoomInfo];
 
    
    _isInitialLayout = NO;//for first load view
    
    //firebase
    fireBaseAdp = [[CHFIreBaseAdaptor alloc]init];
    
    // check is chatRoom joined or not
    _isCheckChatRoomJoin = NO;
    
    
    _modes = [[NSArray alloc]initWithObjects:@"分析",@"紀錄",@"同夥",@"旅程", nil];

    
    //GPS init
    [self locationManagerSetting];
    
    
    // to receive push notification info
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveChatRoomMessage:) name:@"ChatRoomInfo" object:nil];

    
    [self indicatorSetting];
    

}

-(void)viewWillAppear:(BOOL)animated{
    // Turn on the location manager to update location.
    [_locationManager startUpdatingLocation];
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

- (void)viewWillDisappear:(BOOL)animated{
    // Turn off the location manager to save power.
    [_locationManager stopUpdatingLocation];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark
#pragma mark - ...初始資料...
#pragma mark - TripInfo
-(void)initTripInfo{
    
    //Trip Info
    _tripInfo = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"tripInfo"]];
    
    if ([_tripInfo count]==0) {
        _tripInfo = [[NSMutableDictionary alloc]init];
        [_tripInfo setObject:@"未命名"            forKey:@"tripTitle"];
        [_tripInfo setObject:[NSNumber numberWithBool:NO] forKey:@"isTripCreate"];
        [_tripInfo setObject:[NSNumber numberWithBool:NO] forKey:@"isSavedOnline"];
        [[NSUserDefaults standardUserDefaults] setObject:_tripInfo forKey:@"tripInfo"];
        
        NSLog(@"Trip info is not exist, create new one");
    }else{
        NSLog(@"\nLoad TripInfo success, start to load photos");
        
    }
}

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
        UIButton *menuBtn = (UIButton *)[_mapDisplayView viewWithTag:TAG_menuBtn];
        menuBtn.hidden = NO;
        NSLog(@"開啟menuBtn");
        
        //show Trip title text
        UITextField *tripTitleText = (UITextField *)[_mapDisplayView viewWithTag:TAG_tripTitleText];
        tripTitleText.hidden = NO;
        
        UIView *coverTripTitleView = (UIView *)[_mapDisplayView viewWithTag:TAG_coverTripTitleView];
        coverTripTitleView.hidden = NO;
     
        [self loadDBPhotos];
    }
    
    [self updateModeBtnState];
    
}

-(void)initTripTitleText{
    
    UITextField *tripTitleText = [[UITextField alloc]initWithFrame:CGRectMake(54, 5 + 44 +5, 150, 22)];
    tripTitleText.text = _tripInfo[@"tripTitle"];
    tripTitleText.backgroundColor = [UIColor clearColor];
    tripTitleText.layer.borderWidth = 0.5f;
    tripTitleText.layer.borderColor = [[UIColor clearColor]CGColor];
    tripTitleText.tag = TAG_tripTitleText;
    tripTitleText.delegate = self;
    tripTitleText.hidden = YES;
    //    tripTitleText.enabled = NO;
    [_mapDisplayView addSubview:tripTitleText];
    
    UIView *coverTripTitleView = [[UIView alloc]initWithFrame:tripTitleText.frame];
    coverTripTitleView.tag = TAG_coverTripTitleView;
    coverTripTitleView.hidden = YES;
    [_mapDisplayView addSubview:coverTripTitleView];
    UILongPressGestureRecognizer *recog = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(editTripTitle:)];
    [coverTripTitleView addGestureRecognizer:recog];
    
}

#pragma mark - UserInfo
-(void)initUserInfo{
    
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
    
}

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

#pragma mark - roomInfo
-(void)initRoomInfo{
    
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
    
}

#pragma mark 
#pragma mark - ...View layout setting...

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

///!!!:待刪除
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
    UIView *modeBtnBackgroundView = (UIView *)[_mapDisplayView viewWithTag:TAG_modeBtnBackgroundView];
    modeBtnBackgroundView.hidden = NO;
    
    [imageScrollView setImageAry:images];
    //    [self setImageDisplayScrollView:images];
    
}
-(void)scrollView:(UIScrollView *)scrollView didSelectedImage:(UIImageView *)selectedView{
    
    _isShowImagesOnMap = [[[NSUserDefaults standardUserDefaults] objectForKey:@"isShowImagesOnMap"] boolValue];
    
    if (_isShowImagesOnMap) {
//        NSInteger tag = selectedView.tag-1;
//        [self mapView:_mapView didTapMarker:localImgMarkers[tag]];
        NSLog(@"\nYou selected chScollView the no.%ld Image",(long)selectedView.tag);
    }else{
        //無marker, 不動作
    }
 
}

#pragma mark - horizontalView (EasyTableview) delegate

-(void)initHorizontalView{

    EasyTableView *view;
    view = (EasyTableView *)[_mapDisplayView viewWithTag:TAG_horizonTableView];
    if (view) {
        [view removeFromSuperview];
    }
    
    if (_currentModeType ==1 || _currentModeType == 0) {
        view	= [[EasyTableView alloc] initWithFrame:BOTTOM_VIEW_FRAME2 ofWidth:IMAGEHEIGHT];
    }else if (_currentModeType ==3){
        view	= [[EasyTableView alloc] initWithFrame:BOTTOM_VIEW_FRAME1 ofWidth:IMAGEHEIGHT];
    }
    
    
//    EasyTableView *view	= [[EasyTableView alloc] initWithFrame:BOTTOM_VIEW_FRAME2 ofWidth:IMAGEHEIGHT];
    horizontalView  = view;
    horizontalView.tag = TAG_horizonTableView;
    horizontalView.delegate= self;
    horizontalView.tableView.backgroundColor= [UIColor clearColor];
    horizontalView.tableView.allowsSelection= YES;
//    horizontalView.tableView.separatorColor	= [UIColor darkGrayColor];
    horizontalView.autoresizingMask			= UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    ratio = 2;
    horizonTVOffset = 0;
    [horizontalView.tableView setContentInset:UIEdgeInsetsMake(horizonTVOffset,0,horizontalView.frame.size.width/2,0)];
    [_mapDisplayView addSubview:horizontalView];
    
}

- (NSUInteger)numberOfSectionsInEasyTableView:(EasyTableView*)easyTableView{
    
    if (_currentModeType == 1) {
        return [localImgData_orderByDate count];
        
    }else if(_currentModeType == 3 ){
        
        return [dlTripItems count];
    }else{
        
        return 0;
    }
    
}

- (NSInteger)easyTableView:(EasyTableView *)easyTableView numberOfRowsInSection:(NSInteger)section{

    if (_currentModeType == 1) {
        NSArray *items = localImgData_orderByDate[section][@"items"];
        return [items count];
        
    }else if(_currentModeType == 3 ){
        return [dlTripItems[section] count];
    }else{
        
        return 0;
    }
}



- (UIView*)easyTableView:(EasyTableView*)easyTableView viewForHeaderInSection:(NSInteger)section{
    
    static NSString *headerViewIdentifier = @"EasyTableViewHeader";
    
    //init cell
    UITableViewHeaderFooterView *header = [easyTableView.tableView dequeueReusableHeaderFooterViewWithIdentifier:headerViewIdentifier];
    
    if (!header) {
        header = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:headerViewIdentifier];
        header.frame = CGRectMake(0, 0, WIDTH_horizonTV_header, IMAGEHEIGHT);
        
//        header.backgroundColor = [UIColor yellowColor];
        
        UILabel *textSection = [[UILabel alloc] init];
        textSection.transform = CGAffineTransformMakeRotation(-M_PI/2);
        textSection.frame     = CGRectMake(0, 0, WIDTH_horizonTV_header, IMAGEHEIGHT);
        textSection.center    = header.center;
        textSection.backgroundColor = [UIColor yellowColor];
        textSection.text = [NSString stringWithFormat:@"Day%ld",(long)section+1];
        textSection.font = [UIFont systemFontOfSize:20.0f];
        [header addSubview:textSection];
        
    }else{
        
        
    }

    return header;
    
}


- (UITableViewCell *)easyTableView:(EasyTableView *)easyTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    static NSString *cellIdentifier = @"EasyTableViewCell";
    
    //init cell
    UITableViewCell *cell = [easyTableView.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    UIImageView *imgView;
    UILabel *locNoLabel;
    
    
    if (!cell) {
        // Create a new table view cell
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor clearColor];
        
        float downsize = cell.frame.size.height*0.3;
        CGRect imgViewRect		= CGRectMake(downsize, downsize, cell.frame.size.width - downsize*2, cell.frame.size.height - downsize*2);
        
        // ImgView
        
        imgView = [[UIImageView alloc]initWithFrame:imgViewRect];
        imgView.center = cell.center;
        imgView.tag = TAG_horizontalView_CellImgView;
        imgView.contentMode = UIViewContentModeScaleAspectFit;
        imgView.autoresizingMask  = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [cell addSubview:imgView];
        
        //Label
        
        locNoLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, cell.frame.size.height - 20, cell.frame.size.height,20)];
        locNoLabel.tag = TAG_horizontalView_CellLabel;
        ;
        locNoLabel.textAlignment   = NSTextAlignmentCenter;
        locNoLabel.backgroundColor = [UIColor clearColor];
        locNoLabel.textColor       = [UIColor whiteColor];
        locNoLabel.layer.cornerRadius = 5.0f;
        locNoLabel.layer.borderWidth  = 2.0f;
        locNoLabel.layer.borderColor  = [UIColor lightGrayColor].CGColor;
        [cell addSubview:locNoLabel];
        
       
    }else{
        imgView    = (UIImageView *)[cell viewWithTag:TAG_horizontalView_CellImgView];
        locNoLabel = (UILabel *)    [cell viewWithTag:TAG_horizontalView_CellLabel];
        
    }
    
    // ... LOAD DATA ...
    
    // ImgView
    if (_currentModeType == 1) {
        
        NSDictionary *item = localImgData_orderByDate[indexPath.section][@"items"][indexPath.row];
        
        imgView.image = item[@"image"];
        
    }else if(_currentModeType == 3 ){
        
        imgView.image = [UIImage imageNamed:@"Locicon.png"];
    }
    
    // Location No label
    locNoLabel.text   = [NSString stringWithFormat:@"%ld-%ld",indexPath.section , indexPath.row];
    locNoLabel.hidden = (_currentModeType == 3)? NO:YES;
    
    
    return cell;
}


- (void)easyTableView:(EasyTableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    NSLog(@"did select(section:%ld,row%ld)",(long)indexPath.section,(long)indexPath.row);
    
    if (_currentModeType == 1) {
        
        //紀錄模式
        _isShowImagesOnMap = [[[NSUserDefaults standardUserDefaults] objectForKey:@"isShowImagesOnMap"] boolValue];
        if (_isShowImagesOnMap) {
            
            CLLocation *posi = localImgData_orderByDate[indexPath.section][@"items"][indexPath.row][@"position"];
            CLLocationCoordinate2D position = [posi coordinate];
            
            if (position.latitude ==0 || position.longitude ==0) {
                
                [self showImgNoLocationAlert:nil];
                
            }else{
                
                GMSCameraPosition *tapedLocation = [GMSCameraPosition cameraWithLatitude:position.latitude
                                                                               longitude:position.longitude
                                                                                    zoom:_mapView.camera.zoom];
                [_mapView setCamera:tapedLocation];
                
                
            }
        }
        
    }else if(_currentModeType == 3 ){
        //旅程模式
        [self mapView:_mapView didTapMarker:dlTripItemsMarkers[indexPath.section][indexPath.row]];
        
    }else{
        
        //
    }
    
    [horizontalView.tableView scrollToRowAtIndexPath:indexPath
                                    atScrollPosition:UITableViewScrollPositionTop animated:YES];
    
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{

    if (scrollView.contentOffset.y + horizonTVOffset >= -IMAGEHEIGHT/2) {
        
        //計算放大倍率
        CGFloat contentOffsetY = fabs(scrollView.contentOffset.y + horizonTVOffset);
        while (contentOffsetY > IMAGEHEIGHT) {
            contentOffsetY -= IMAGEHEIGHT;
        }
        
        //變更大小cell位置
        contentOffsetY -= IMAGEHEIGHT/2;
        ratio = fabs(contentOffsetY)/(IMAGEHEIGHT/2);
        
        CGPoint location = CGPointMake(0, scrollView.contentOffset.y + horizonTVOffset + IMAGEHEIGHT*0.5 +WIDTH_horizonTV_header);
        resizeIndexPath    = [horizontalView.tableView indexPathForRowAtPoint:location];
        
        
        UITableViewCell *cell = [horizontalView.tableView cellForRowAtIndexPath:resizeIndexPath];
        UIImageView *imgView  = (UIImageView*)[cell viewWithTag:TAG_horizontalView_CellImgView];
        
        float downsize = cell.frame.size.height*(0.3 - 0.3*ratio) ;
        CGRect imgViewRect		= CGRectMake(downsize, downsize, cell.frame.size.width - downsize*2, cell.frame.size.height - downsize*2);
        imgView.frame = imgViewRect;
        
        NSLog(@"offset:%f,indexRow:%ld, Ratio:%f",(scrollView.contentOffset.y + horizonTVOffset),(long)resizeIndexPath.row,ratio);
    }
}

-(void)scrollViewDidEndScrolling:(UIScrollView *)scrollView{
    
    [self easyTableView:horizontalView didSelectRowAtIndexPath:resizeIndexPath];
        
}


#pragma mark - Button
-(void)initButtons{
    
    // menu
    UIButton *menuBtn = [[UIButton alloc]initWithFrame:CGRectMake(5, 5, 44, 44)];
    [menuBtn addTarget:self action:@selector(showMenu:) forControlEvents:UIControlEventTouchDown];
    [menuBtn setTitle:@"Me" forState:UIControlStateNormal];
    [menuBtn setBackgroundColor:[UIColor lightGrayColor]];
//    [menuBtn setBackgroundImage:[UIImage imageNamed:@"s1_1.png"] forState:UIControlStateNormal];
    menuBtn.tag = TAG_menuBtn;
    menuBtn.hidden = YES;//旅程建立, 才顯示
    [_mapDisplayView addSubview:menuBtn];
    
    //mode setting
    UIView *modeBtnBackgroundView = [[UIView alloc]initWithFrame:CGRectMake(0, _mapDisplayView.frame.size.height-MODEBTN_HEIGHT, _mapDisplayView.frame.size.width, MODEBTN_HEIGHT)];
    modeBtnBackgroundView.tag = TAG_modeBtnBackgroundView;
    modeBtnBackgroundView.backgroundColor = [UIColor blueColor];
    [_mapDisplayView addSubview:modeBtnBackgroundView];
    
    UIButton *modeBtn = [[UIButton alloc]initWithFrame:CGRectMake(_mapDisplayView.frame.size.width - MODEBTN_WIDTH, _mapDisplayView.frame.size.height -MODEBTN_HEIGHT, MODEBTN_WIDTH, MODEBTN_HEIGHT)];
    modeBtn.tag = TAG_modeBtn;
    [modeBtn addTarget:self action:@selector(didSelectModeBtn:) forControlEvents:UIControlEventTouchDown];
    [modeBtn setTitle:_modes[_currentModeType] forState:UIControlStateNormal];
    [modeBtn setBackgroundColor:[UIColor blueColor]];
    //    [modeBtn setBackgroundImage:[UIImage imageNamed:@"s1_1.png"] forState:UIControlStateNormal];
    [_mapDisplayView addSubview:modeBtn];
    
    //add photo btn
    UIButton *addPhotoBtn = [[UIButton alloc]initWithFrame:CGRectMake(_mapDisplayView.frame.size.width - MODEBTN_WIDTH*2, _mapDisplayView.frame.size.height -MODEBTN_HEIGHT, MODEBTN_WIDTH, MODEBTN_HEIGHT)];
    addPhotoBtn.tag = TAG_addPhotoBtn;
    [addPhotoBtn addTarget:self action:@selector(addPhotoBtnAction:) forControlEvents:UIControlEventTouchDown];
    [addPhotoBtn setTitle:@"+" forState:UIControlStateNormal];
    [addPhotoBtn setBackgroundColor:[UIColor blueColor]];
    [_mapDisplayView addSubview:addPhotoBtn];
    
    // chat room btn
    UIButton *chatRoomBtn = [[UIButton alloc]initWithFrame:CGRectMake(_mapDisplayView.frame.size.width - MODEBTN_WIDTH, _mapDisplayView.frame.size.height -MODEBTN_HEIGHT*2, MODEBTN_WIDTH, MODEBTN_HEIGHT)];
    chatRoomBtn.tag = TAG_chatRoomBtn;
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
        
        _currentModeType += 1;
        [self updateModeBtnState];
        [self showImagePickerAlert];

    }else {
        
        // 如果超過mode3則從1開始
        _currentModeType += 1;
        _currentModeType = (_currentModeType >3)? 1 :_currentModeType;
        [self updateModeBtnState];
        
        UIView *quickChatView = (UIView *)[_mapDisplayView viewWithTag:TAG_quickChatView];
        [quickChatView removeFromSuperview];
        
        
        if(_currentModeType == 1){
            //紀錄
            NSLog(@"紀錄mode");
            
            //直接匯入data
            [self loadDBPhotos];
            
        }else if(_currentModeType == 2){
            //同夥
            NSLog(@"同夥mode");
            
            //直接略過setting VC開始執行
            [self didLeftSettingVC];
            
        }else if(_currentModeType == 3){
            //旅程
            NSLog(@"旅程mode");
            
            if (dlTripItems && [dlTripItems count]>0) {
                [self didLoadTripDate:dlTripItems];
            }
        }
        
        
    }
}


-(void)updateModeBtnState{
    
    _roomInfo = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults]objectForKey: @"roomInfo"]];
   
    
    
    //淨空map
    [_mapView clear];
    
    //
    UIButton *modeBtn               = (UIButton *)[_mapDisplayView viewWithTag:TAG_modeBtn];
    [modeBtn setTitle:_modes[_currentModeType] forState:UIControlStateNormal];
    
   
    UIView *modeBtnBackgroundView   = (UIView *)[_mapDisplayView viewWithTag:TAG_modeBtnBackgroundView];
    modeBtnBackgroundView.hidden    = (_currentModeType == 0)? YES: NO;
    
    UIButton *addPhotoBtn           = (UIButton *)[_mapDisplayView viewWithTag:TAG_addPhotoBtn];
    addPhotoBtn.hidden              = (_currentModeType == 1)? NO: YES;

    UIButton *chatRoomBtn           = (UIButton *)[_mapDisplayView viewWithTag:TAG_chatRoomBtn];
    chatRoomBtn.hidden              =  YES;
    
    UIView *quickChatView           = (UIView *)[_mapDisplayView viewWithTag:TAG_quickChatView];
    [quickChatView removeFromSuperview];
    
    CHMoveableTableView *moveTV     = (CHMoveableTableView *)[_mapDisplayView viewWithTag:TAG_moveTV];
    [moveTV removeFromSuperview];
    
    UIButton *hideMoveTVBtn         = (UIButton *)[_mapDisplayView viewWithTag:TAG_hideMoveTVBtn];
    [hideMoveTVBtn removeFromSuperview];
    
    horizontalView.hidden           = (_currentModeType== 1)? NO:YES;
    
}

-(void)addPhotoBtnAction:(UIButton *)sender{
    
    NSLog(@"Adding photo");
    
    UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
//    imgPicker.sourceType = UIImagePickerControllerCameraDeviceFront;
    imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    imgPicker.delegate = self;
    [self presentViewController:imgPicker animated:NO completion:^{
        //
    }];
    
}



-(void)editTripTitle:(UIGestureRecognizer *)recog{
    
    UITextField *tripTitleText = (UITextField *)[_mapDisplayView viewWithTag:TAG_tripTitleText];
    [tripTitleText becomeFirstResponder];
    
}

#pragma mark - menu
-(void)initMenuView{
    
    menuView = [[MapVCMenuView alloc]initWithFrame:CGRectMake(5, 54, 44, _mapDisplayView.frame.size.height - (54+80)) owner:nil];
    menuView.delegate = self;
    [_mapDisplayView addSubview: menuView];
    menuView.hidden = YES;
}

-(void)didSelectTheMenu:(UIButton *)btn;
{
    [_mapView clear];
    BOOL shouldUpdate;
    
    // Change mode button
    switch (btn.tag) {
        case 1:
            //紀錄mode
            shouldUpdate = (_currentModeType == 1)? NO:YES;
            
            //開啟相簿
            [self setImagePicker:_pickedAssets];
            
            break;
        case 2:
            //同夥mode
//            _currentModeType = 2;
            shouldUpdate = (_currentModeType == 2)? NO:YES;
            [self joinChatingRoom];
            break;
            
        case 3:
            //旅程mode
//            _currentModeType = 3;
            shouldUpdate = (_currentModeType == 3)? NO:YES;
            
            ///!!!:wait coding
//            [self loadJsonTripData];
            [self showReadTripCodeVC];
            
            break;
        default:
            break;
    }
    
    
    if (shouldUpdate) {
        _currentModeType = (int)btn.tag  ;
        [self updateModeBtnState];
    }

    UIView *quickChatView = (UIView *)[_mapDisplayView viewWithTag:TAG_quickChatView];
    [quickChatView removeFromSuperview];
}



#pragma mark
#pragma mark - ...地圖相關設定...
#pragma mark - Map (Settings & Delegate)

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

//僅紀錄create marker方式
-(void)createMarker:(CLLocationCoordinate2D)position{
    
    GMSMarker *marker = [GMSMarker markerWithPosition:position];
    marker.title            =[NSString stringWithFormat:@"Marker title"];
    marker.snippet          = @"Marker snippet";
    marker.infoWindowAnchor = CGPointMake(0.5, 0.5);
    marker.map              = _mapView;
    marker.icon             = [UIImage imageNamed:@"house"];
//    [localImgMarkers addObject:marker];
}

//tap map時的反應
- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    NSLog(@"You tapped at %f,%f", coordinate.latitude, coordinate.longitude);
}

//tap marker時的反應
- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker {
    
    mapView.selectedMarker = marker;
    
    if (marker.position.latitude!=0 && marker.position.longitude!=0) {
        GMSCameraPosition *tapedLocation = [GMSCameraPosition cameraWithLatitude:marker.position.latitude
                                                                       longitude:marker.position.longitude
                                                                            zoom:_mapView.camera.zoom];
        NSLog(@"\nTapped image\nimageLatitue:%f,imageLongtitude:%f",marker.position.latitude,marker.position.longitude
              );
        [_mapView setCamera:tapedLocation];
        return YES;
        
    }else{
        
        _isShowImagesOnMap = [[[NSUserDefaults standardUserDefaults] objectForKey:@"isShowImagesOnMap"] boolValue];
        
        if (_currentModeType ==1 && _isShowImagesOnMap) {
            [self showImgNoLocationAlert:nil];
        }

        return NO;
    }
    

}

//map 移動前的反應
- (void)mapView:(GMSMapView *)mapView willMove:(BOOL)gesture
{
    //

}

//map 移動時的反應
- (void)mapView:(GMSMapView *)mapView didChangeCameraPosition:(GMSCameraPosition *)position
{
    //
    UITextField *tripTitleText = (UITextField *)[_mapDisplayView viewWithTag:TAG_tripTitleText];
    [tripTitleText resignFirstResponder];

    //
    [_mapView clear];
    
    if (_currentModeType == 1) {
        [self createImgMarkerIdleAtCameraPosition:position];
    }else if (_currentModeType == 3){
        [self createTripItemMarkerIdleAtCameraPosition:position];
    }
    
}

//map 停止時的反應
- (void)mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position{
    //
    
//    if (_currentModeType == 1) {
//        [self createImgMarkerIdleAtCameraPosition:position];
//    }
}

#pragma mark - GPS & locationManager
-(void)locationManagerSetting{
    
    if (_locationManager == nil)
    {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.distanceFilter  = kCLDistanceFilterNone;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;//100m
        _locationManager.delegate = self;
        [_locationManager requestAlwaysAuthorization];
        
        ///!!!:週期性更新GPS location
        receivedMsg = [NSTimer scheduledTimerWithTimeInterval:5.0f
                                                       target:self selector:@selector(updateDeviceLoctionData) userInfo:nil repeats:YES];
//        [receivedMsg isValid];
    }
}

//獲取裝置位置
- (NSString *)deviceLocation
{
    NSString *theLocation = [NSString stringWithFormat:@"latitude: %f longitude: %f", self.locationManager.location.coordinate.latitude, self.locationManager.location.coordinate.longitude];
    return theLocation;
}

//存裝置位置至local db
-(void)updateDeviceLoctionData{
    
    [[myDB sharedInstance]insertGPSTable:tableName_userGPS
                             andLatitude:[NSString stringWithFormat:@"%f",
                                          _locationManager.location.coordinate.latitude]
                           andLongtitude:[NSString stringWithFormat:@"%f",_locationManager.location.coordinate.longitude]];
    
    //    NSLog(@"\n更新DB的LOC:(%f,%f)",_locationManager.location.coordinate.latitude,_locationManager.location.coordinate.longitude);
    
    ///!!!:同夥模式, 且允許顯示地圖member marker
    if ([_roomInfo[@"isShowOnMap"] boolValue]== YES && _currentModeType == 2) {
        [self updateDeviceLocationToServer];
    }
    
    //    [self drawPolyLinesOnMap];
}

//存裝置位置至server
-(void)updateDeviceLocationToServer{
    
    double lat = _locationManager.location.coordinate.latitude;
    double lon = _locationManager.location.coordinate.longitude;
    
    NSLog(@"\nServer的LOC:(%f,%f)",_locationManager.location.coordinate.latitude,_locationManager.location.coordinate.longitude);
    
    //update server
    [[CHFIreBaseAdaptor sharedInstance]updateMemberBykey:@"lastGPSLocation" andValue:[NSArray arrayWithObjects:[NSNumber numberWithDouble:lat],[NSNumber numberWithDouble:lon],nil] success:^(FDataSnapshot *snapshot) {
        
        [self addMemberMarker];
        
    } failure:^{
        
        //
        NSLog(@"");
    }];
}

//locationManager更新位置時反應
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
    //    NSLog(@"\nUpdateLOC:(%f,%f)",_locationManager.location.coordinate.latitude,_locationManager.location.coordinate.longitude);
}

//locationManager更新位置失敗時反應
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    NSLog(@"locationManager didFailWithError: %@", error);
    
}

#pragma mark - 繪製地圖路徑

//local db GPS data 繪製成路徑
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

#pragma mark
#pragma mark - ...分析模式...

#pragma mark - 存取照片
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
//    NSMutableArray *images = [[NSMutableArray alloc] init];
//    localImgMarkers = [[NSMutableArray alloc]init];
    
    [_mapView clear];
    
    //從PHAsset 解析出UIImage
    for (int i = 0; i < [_pickedAssets count]; i++)
    {
        PHAsset *asset = _pickedAssets[i];
        
        //取值 - 地圖座標
//        CLLocationCoordinate2D position = CLLocationCoordinate2DMake(asset.location.coordinate.latitude, asset.location.coordinate.longitude);
        imageLatitude   = [NSString stringWithFormat:@"%f",asset.location.coordinate.latitude];
        imageLongtitude = [NSString stringWithFormat:@"%f",asset.location.coordinate.longitude];
//        NSLog(@"imageLatitue:%@,imageLongtitude:%@",imageLatitude,imageLongtitude);
        
        
//        //建立markers
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
    
    
    if (queryTableResult) {
        // ...撈localIdentifer資料
        [queryTableResult enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL * _Nonnull stop) {
            [localIdentifier addObject:dict[@"imagePath"]];
        }];
        
        // ...設定排序方式 -- 日期
        PHFetchOptions *allPhotosfetchOption = [[PHFetchOptions alloc]init];
        allPhotosfetchOption.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        
        //  ...搜尋結果
        PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:localIdentifier options:allPhotosfetchOption];
        
        // ... 依日期分section
        localImgData_orderByDate = [NSMutableArray arrayWithArray:[self orderImgByDate:result]];
        
        // ...將取得的localImg 建立tableview
        [self initHorizontalView];
        [self scrollViewDidScroll:horizontalView.tableView];

        
    }
    
}

-(NSArray *)orderImgByDate:(PHFetchResult *)result{
  
    NSMutableArray *rowData = [[NSMutableArray alloc]init];
    NSMutableArray *orderedData = [[NSMutableArray alloc]init];
    
    [result enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
        [rowData addObject:asset];
    }];
    
    //依照日期分類
    while ([rowData count]>0)
    {
        NSMutableArray *tempArray = [[NSMutableArray alloc]init];
        
        PHAsset *firstAsset = rowData[0];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"YYYY-MM-dd"];
        NSString *lastDate = [dateFormat stringFromDate:firstAsset.creationDate];
        
        [rowData enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL * _Nonnull stop)
         {
             if ([[dateFormat stringFromDate:asset.creationDate] isEqualToString:lastDate])
             {
                 [tempArray addObject:asset];
                 
             }
         }];
        
        //當天結果
        NSMutableDictionary *day_result = [[NSMutableDictionary alloc]init];
        NSMutableArray *day_items = [[NSMutableArray alloc]init];
        
        [tempArray enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL * _Nonnull stop)
         {
             //移除已經選取的資料
             if ([rowData containsObject:asset])
             {
                 [rowData removeObject:asset];
             }
             
             // img location
             CLLocation *position = [[CLLocation alloc] initWithLatitude:asset.location.coordinate.latitude longitude:asset.location.coordinate.longitude];
//             CLLocationCoordinate2D coord = [position coordinate];
             
             // 取 local imgs,
             UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 200, 300 , 300)];
             NSInteger retinaMultiplier = [UIScreen mainScreen].scale;
             CGSize retinaSquare = CGSizeMake(imageView.bounds.size.width * retinaMultiplier, imageView.bounds.size.height * retinaMultiplier);
            
             PHImageRequestOptions *option = [PHImageRequestOptions new];
             option.synchronous = YES;
             
             [[PHImageManager defaultManager]
              requestImageForAsset:asset
              targetSize:retinaSquare
              contentMode:PHImageContentModeAspectFill
              options:option
              resultHandler:^(UIImage *imgResult, NSDictionary *info) {
                  
                  NSMutableDictionary *dayItem = [[NSMutableDictionary alloc]init];
                  [dayItem setObject:imgResult forKey:@"image"];
                  [dayItem setObject:position  forKey:@"position"];
//                  NSDictionary *dayItem = [NSDictionary dictionaryWithObjectsAndKeys:
//                                          imgResult,@"image",
//                                          position,@"position",
//                                          nil];
                 [day_items addObject:dayItem];
              }];
             
         }];
        
        [day_result setObject:day_items forKey:@"items"];
        [day_result setObject:lastDate forKey:@"date"];
        
        [orderedData addObject:day_result];
    };
    
    NSLog(@"%lu",(unsigned long)orderedData.count);
    
    return orderedData;
}

#pragma mark - Img marker
-(void)createImgMarkerIdleAtCameraPosition:(GMSCameraPosition *)cameraPosition{
    
    __block int createdMarkerCount = 0;
    
    [localImgData_orderByDate enumerateObjectsUsingBlock:^(NSDictionary *day, NSUInteger indexSection, BOOL * _Nonnull stop) {
        
        [day enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if ([key isEqualToString:@"items"]) {
                NSArray *items = obj;
                
                [items enumerateObjectsUsingBlock:^(NSDictionary *item, NSUInteger indexRow, BOOL * _Nonnull stop) {
                    //
                    //目前視窗範圍
                    GMSVisibleRegion visibleRegion = _mapView.projection.visibleRegion;
                    GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithRegion: visibleRegion];
 
                    // 建立local img markers
                    CLLocation *loc = item[@"position"];
                    CLLocationCoordinate2D position = [loc coordinate];
                    
                    if([bounds containsCoordinate:position]) {
                        
                        GMSMarker *marker = [GMSMarker markerWithPosition:position];
                        marker.title =[NSString stringWithFormat:@"%lu - %lu",(unsigned long)indexSection,(unsigned long)indexRow];
                        marker.snippet = @"Imgs";
                        marker.infoWindowAnchor = CGPointMake(0.5, 0.5);
                        marker.map = _mapView;
                        marker.userData = [NSIndexPath indexPathForRow:indexRow inSection:indexSection];
                        
                        createdMarkerCount +=1;
//                        float camLat = cameraPosition.target.latitude;
//                        float camLog = cameraPosition.target.longitude;
//                        float marLat = position.latitude;
//                        float marLog = position.longitude;
//                        
//                        if (camLat == marLat && camLog == marLog) {
//                            _mapView.selectedMarker = marker;
//                        }
                        
                    }
                }];
            }
        }];
    
    }];
    
    NSLog(@"地圖上有%d個marker",createdMarkerCount);
  
}


#pragma mark - Image Picker

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

    [imagePicker loadPhotosFromAlbum];

//    [imagePicker loadPhotosFromAlbumAndCompareWithAssets:assetArray];
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
    
    //建立旅程, 如已經存在, 直接開照片
    BOOL isTripCreate = [[_tripInfo objectForKey:@"isTripCreate"]boolValue];
    
    if (!isTripCreate) {
        
        // ...update tripInfo
        [_tripInfo setObject:[NSNumber numberWithBool:YES] forKey:@"isTripCreate"];
        [[NSUserDefaults standardUserDefaults] setObject:_tripInfo forKey:@"tripInfo"];
       
        // ...when trip create, start to init created state
        [self updateTripCreateState];

    }else{
        
        [self loadDBPhotos];
    }
}

-(void)didLeftPickingImagesVC{
    
    NSLog(@"開始執行離開PickImgVC 動作");
    [self loadDBPhotos];
    
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
//        //wait for coding
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
    
    //圖庫選圖完之後，自動關閉圖庫
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    [self indicatorStart];
    
    //等1秒後,
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        
        
        // get camera roll
        PHAssetCollection *cameraRoll = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil].lastObject;
        
        // get new asset
        PHAsset *asset = [[PHAsset fetchAssetsInAssetCollection:cameraRoll options:nil] lastObject];
        
        //ready to save to database
        __block NSString *imagePath = [[NSString alloc]init];
        __block NSString *imageLatitude     = [[NSString alloc]init];
        __block NSString *imageLongtitude   = [[NSString alloc]init];
        NSString *comment           = [[NSString alloc]init];
        NSString *voicePath         = [[NSString alloc]init];
        NSString *hiddenState       = [[NSString alloc]init];
    
        imageLatitude   = [NSString stringWithFormat:@"%f",asset.location.coordinate.latitude];
        imageLongtitude = [NSString stringWithFormat:@"%f",asset.location.coordinate.longitude];
        imagePath       = asset.localIdentifier;
        
        //存入table
        [[myDB sharedInstance]insertTable:tableName_tripPhoto andImageLatitude:imageLatitude andImageLongtitude:imageLongtitude ImagePath:imagePath andComments:comment andVoicePath:voicePath andHiddenState:hiddenState];
        [self loadDBPhotos];
        NSLog(@"save adding photo to DB success");
        
        [self indicatorStop];
//        [_pickedAssets addObject:asset];
//        [self finishedPickingImages:_pickedAssets];
        
    });
    
    //圖庫選圖完之後，自動關閉圖庫
//    [picker dismissViewControllerAnimated:YES completion:nil];
    
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/




#pragma mark 
#pragma mark - ...同夥模式...
#pragma mark - 加入Chat room actions
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
}

#pragma mark - ChatRoomSetting delegate

-(void)didLeftSettingVC{
    
    NSLog(@"left Setting View");
    
    _roomInfo = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults]objectForKey: @"roomInfo"]];
    
    NSString *roomID = _roomInfo[@"roomID"];
    if (roomID && ![roomID isEqualToString:@""]) {
        
        // ...顯示quick chat
        [self quickChatTextInit];
 
        //顯示聊天室按鈕
        UIButton *chatRoomBtn = (UIButton *)[_mapDisplayView viewWithTag:TAG_chatRoomBtn];
        chatRoomBtn.hidden    = NO;
        
        // ...展示member
        [self updateDeviceLocationToServer];
    }
}

#pragma mark - member markers
-(void)removeMemberMarker{
    
    // ... remove member marker
    [memberMarkers enumerateObjectsUsingBlock:^(GMSMarker *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.map = nil;
    }];
    
//    [memberMarkers removeAllObjects];
}

-(void)addMemberMarker{
    
    // ... remove member marker
    [self removeMemberMarker];
    
    [[CHFIreBaseAdaptor sharedInstance] queryMemberByRoomID:_roomInfo[@"roomID"] success:^(FDataSnapshot *snapshot) {
        
        if ([snapshot.value isEqual:[NSNull null]]) {
            NSLog(@"no member for member marker");
        }else{
            NSLog(@"Start to build member marker");
            
            NSDictionary *members = snapshot.value;
            memberMarkers = [[NSMutableArray alloc]init];
            
            __block int colorCount = 0;
            
            [members enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSDictionary *member, BOOL * _Nonnull stop) {
                
                NSArray *locGPS = member[@"lastGPSLocation"];
                float lat = [locGPS[0] floatValue];
                float lon = [locGPS[1] floatValue];
                
                // 建立 member markers
                CLLocationCoordinate2D position = CLLocationCoordinate2DMake(lat,lon);
                GMSMarker *marker  = [GMSMarker markerWithPosition:position];
                marker.snippet     = member[@"userNickname"];
                marker.userData    = member[@"uuid"];
                marker.map         = ([member[@"isShareGPS"] boolValue])? _mapView : nil;
                marker.infoWindowAnchor = CGPointMake(0.5, 0.5);

                UIImage *img       = [UIImage imageNamed:[NSString stringWithFormat:@"s1_%d.png",colorCount]];
                img = [self imageWithImage:img scaledToSize:CGSizeMake(MEMBER_MapMarker_SIZE, MEMBER_MapMarker_SIZE)];
                marker.icon        = img;
                marker.groundAnchor = CGPointMake(0.5, 0.5);//調整圖片位置
                [memberMarkers addObject:marker];
                
                colorCount +=1;
                colorCount = (colorCount >5)? 0:colorCount;
                
            }];
            
            [self addMsgOnMemberMarker];
            NSLog(@"memberMarke 有%ld個",memberMarkers.count);
        }
        
        
    } failure:^{
        //
        NSLog(@"fail");
        
    }];
    
}

//quick msg on marker
-(void)addMsgOnMemberMarker{
    
    [[CHFIreBaseAdaptor sharedInstance]queryMsgRegularlyByRoomID:_roomInfo[@"roomID"] success:^(FDataSnapshot *snapshot) {
        
        NSDictionary *dic = snapshot.value;
        
        [memberMarkers enumerateObjectsUsingBlock:^(GMSMarker *marker, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if ([marker.userData isEqualToString:dic[@"uuid"]]) {
                marker.title = dic[@"message"];
//                _mapView.selectedMarker = marker;
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
            NSLog(@"create quick msg success");
        } failure:^{
            NSLog(@"create quick msg Fail!!");
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
#pragma mark - ...旅程模式...

#pragma mark - Trip data
-(void)showReadTripCodeVC{
    
    CHReadTripCodeVC *vc = [[CHReadTripCodeVC alloc]init];
    vc.delegate = self;
    [self presentViewController:vc animated:YES completion:nil];
}

// CHReadTripCodeVC delegate

-(void)didLoadTripDate:(id)tripData{
    
    // ...下載Json data
    dlTripItems = tripData;
    
    // ...建立HorizonView
    [self initHorizontalView];
    [horizontalView reload];
    [self scrollViewDidScroll:horizontalView.tableView];
    

    // ...建立CHMoveableTableView
    //clear view
    CHMoveableTableView *moveTV = (CHMoveableTableView *)[_mapDisplayView viewWithTag:TAG_moveTV];
    UIButton *hideMoveTVBtn = (UIButton *)[_mapDisplayView viewWithTag:TAG_hideMoveTVBtn];
    [moveTV removeFromSuperview];
    [hideMoveTVBtn removeFromSuperview];

    // ... 建立Table
    moveTV = [[CHMoveableTableView alloc]initWithFrame:MOVEABLE_TABLE_FRAME];
    moveTV.tag = TAG_moveTV;
    [_mapDisplayView addSubview:moveTV];
    moveTV.chDelegate = self;
    
    //  fed data
    [moveTV setObjects:[NSMutableArray arrayWithArray:dlTripItems]];
    
    
    // ...建立hidden BTN
    hideMoveTVBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 50, 50)];
    hideMoveTVBtn.tag = TAG_hideMoveTVBtn;
    hideMoveTVBtn.center = moveTV.center;
    CGRect newFrame = hideMoveTVBtn.frame;
    newFrame = CGRectMake(newFrame.origin.x - newFrame.size.width/2 - moveTV.frame.size.width/2, newFrame.origin.y, newFrame.size.width, newFrame.size.height);
    hideMoveTVBtn.frame = newFrame;
    [hideMoveTVBtn setTitle:@"Hide" forState:UIControlStateNormal];
    hideMoveTVBtn.layer.cornerRadius = 2.0f;
    hideMoveTVBtn.layer.borderColor  = [UIColor lightGrayColor].CGColor;
    hideMoveTVBtn.layer.borderWidth  = 1.0f;
    [hideMoveTVBtn addTarget:self action:@selector(changeMoveTVState:) forControlEvents:UIControlEventTouchDown];
    [_mapDisplayView addSubview:hideMoveTVBtn];
}

-(void)backBtnAction{
    
    if (dlTripItems && [dlTripItems count]>0) {
        [self didLoadTripDate:dlTripItems];
    }
}

-(void)changeMoveTVState:(UIButton *)sender{
    
    CHMoveableTableView *moveTV = (CHMoveableTableView *)[_mapDisplayView viewWithTag:TAG_moveTV];
    UIButton *hideMoveTVBtn = (UIButton *)[_mapDisplayView viewWithTag:TAG_hideMoveTVBtn];
    float changeValue = 0;
    NSString *newTitle ;
    
    if ([sender.titleLabel.text isEqualToString:@"Hide"]) {
        changeValue = 1.0;
        newTitle = @"Show";
    }else{
        changeValue = -1.0;
        newTitle = @"Hide";
    }
   
    
    [UIView animateWithDuration:0.5 animations:^{
        
        moveTV.frame        = CGRectOffset(moveTV.frame, moveTV.frame.size.width * changeValue, 0);
        hideMoveTVBtn.frame = CGRectOffset(hideMoveTVBtn.frame, moveTV.frame.size.width * changeValue, 0);
        hideMoveTVBtn.userInteractionEnabled = NO;
        
    } completion:^(BOOL finished) {
        
        [hideMoveTVBtn setTitle:newTitle forState:UIControlStateNormal];
        hideMoveTVBtn.userInteractionEnabled = YES;
    }];
    
}

- (void)moveableTableView:(CHMoveableTableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [self easyTableView:horizontalView didSelectRowAtIndexPath:indexPath];
    
}

//-(void)loadJsonTripData{
//    
//    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"plugtrip" ofType:@"json"];
//    
//    // Load the file into an NSData object called JSONData
//    
//    NSError *error = nil;
//    
//    NSData *JSONData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
//    
//    // Create an Objective-C object from JSON Data
//    
//    id JSONObject = [NSJSONSerialization
//                     JSONObjectWithData:JSONData
//                     options:NSJSONReadingAllowFragments
//                     error:&error];
//    NSLog(@"%@",JSONObject);
//    
//    
//    dlTripItems = [NSMutableArray arrayWithArray:JSONObject[@"total"]];
//
//}

#pragma mark - Img marker
-(void)createTripItemMarkerIdleAtCameraPosition:(GMSCameraPosition *)cameraPosition{
    
    __block int createdMarkerCount = 0;

    [dlTripItems enumerateObjectsUsingBlock:^(NSDictionary *day, NSUInteger indexSection, BOOL * _Nonnull stop) {
        
        [day enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            
            if ([key isEqualToString:@"items"]) {
                NSArray *items = obj;
                
                [items enumerateObjectsUsingBlock:^(NSDictionary *item, NSUInteger indexRow, BOOL * _Nonnull stop) {
                    
                    //
                    //目前視窗範圍
                    GMSVisibleRegion visibleRegion = _mapView.projection.visibleRegion;
                    GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithRegion: visibleRegion];
                    
                    // 建立local img markers
                    CLLocationCoordinate2D position = CLLocationCoordinate2DMake([item[@"lat"] floatValue], [item[@"lon"] floatValue]);
                 
                    if([bounds containsCoordinate:position]) {
                        
                        GMSMarker *marker = [GMSMarker markerWithPosition:position];
                        marker.title =item[@"title"];
                        marker.snippet = [NSString stringWithFormat:@"Trip%lu - %lu",(unsigned long)indexSection,(unsigned long)indexRow];
                        marker.infoWindowAnchor = CGPointMake(0.5, 0.5);
                        marker.map = _mapView;
                        marker.userData = [NSIndexPath indexPathForRow:indexRow inSection:indexSection];

                        //                        float camLat = cameraPosition.target.latitude;
                        //                        float camLog = cameraPosition.target.longitude;
                        //                        float marLat = position.latitude;
                        //                        float marLog = position.longitude;
                        //
                        //                        if (camLat == marLat && camLog == marLog) {
                        //                            _mapView.selectedMarker = marker;
                        //                        }
                        
                        createdMarkerCount += 1;
                    }
                }];
 
            }
            
            
        }];
        
    }];
    
    NSLog(@"地圖上有%d個marker",createdMarkerCount);
    
}



#pragma mark
#pragma mark - 其他

#pragma mark - Alerts
-(void)showOfflineAlert:(NSError *)error{
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"瞭解" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"cancel chat room Action");
    }];
    
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
    
    
}

-(void)showImgNoLocationAlert:(NSError *)error{
    
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width*0.3, self.view.frame.size.width*0.1)];
    
    label.center                = self.view.center;
    CGPoint newCenter           = label.center;
    newCenter.y-= 100;
    
    label.text = @"照片無座標";
    label.layer.borderColor     = [UIColor lightGrayColor].CGColor;
    label.layer.borderWidth     = 2.0f;
    label.layer.cornerRadius    = 5.0f;
    label.textAlignment = NSTextAlignmentCenter;
    //    label.textColor = [UIColor whiteColor];
    
    [self.view addSubview:label];
    
    [UIView animateWithDuration:1.0 animations:^{
        
        label.center = newCenter;
        label.alpha  = 0;
        
    } completion:^(BOOL finished) {
        
        [label removeFromSuperview];
    }];
    
    
}

#pragma mark - 調整照片大小
-(UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
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
    [view setTag:TAG_indicator_maskView];
    [view setBackgroundColor:[UIColor blackColor]];
    [view setAlpha:0.8];
    [self.view addSubview:view];
    
    [self.view addSubview:activityIndicator];
    [activityIndicator startAnimating];
}

- (void)indicatorStop
{
    UIView *view = (UIView *)[self.view viewWithTag:TAG_indicator_maskView];
    [view removeFromSuperview];
    
    [activityIndicator stopAnimating];
}

#pragma mark - UIText hide keyboard & Delegates

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITextField *tripTitleText = (UITextField *)[_mapDisplayView viewWithTag:TAG_tripTitleText];
    
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


-(void)alertDisconnectToServer{
    
    NSString *msg = @"連線錯誤";
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"錯誤" message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirmBtn = [UIAlertAction actionWithTitle:@"了解" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"Join chat room  Action");
        
        [self showJoinAlert];
        
    }];
    
    [alert addAction:confirmBtn];
    [self presentViewController:alert animated:YES completion:nil];
}


@end














