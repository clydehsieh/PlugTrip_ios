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

#import "CHMapViewVC.h"

@interface CHMapViewVC ()
{
    MapVCSearchView *sView;
    MapVCMenuView *menuView;
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
    
    [[myDB sharedInstance]insertImagePath:@"Test1" andComments:@"Test2" andVoicePath:@"Test3" andHiddenState:YES];
    
    

    
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
    //
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














