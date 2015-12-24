//
//  MapVCSearchView.h
//  adventrip_ios
//
//  Created by Chin-Hui Hsieh  on 12/3/15.
//  Copyright © 2015 twoyears44. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SelectedLocation.h"

typedef NS_ENUM(NSUInteger, TableViewSection){
    TableViewSectionMain,
    TableViewSectionCount
};

@protocol MapVCSeachViewDelegate <NSObject>

-(void)didSelectTableSearchResultLocationAtLatitude:(NSString *)latitude andLongitude:(NSString *)longitude;

@end

@interface MapVCSearchView : UIView <UITextFieldDelegate,UISearchBarDelegate,UITableViewDataSource,UITableViewDelegate>
@property (nonatomic) id<MapVCSeachViewDelegate> delegate;

@property (weak, nonatomic) IBOutlet UISearchBar *inputSearchBar;
@property NSMutableArray *pastSearchResults;
@property NSMutableArray *pastSearchWords;
@property NSMutableArray *localSearchQueries;
@property NSTimer *autoCompleteTimer;
@property NSString *substring;
@property CLLocationManager *locationManager;
@property NSString *apiKey;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property SelectedLocation *selectedLocation;

@property (weak, nonatomic) IBOutlet UITextField *inputText;
@property (weak, nonatomic) IBOutlet UIButton *loginBtn;


- (id)initWithFrame:(CGRect)frame owner:(id)owner andApiServerKey:(NSString *)apikey;
-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar;

@end
