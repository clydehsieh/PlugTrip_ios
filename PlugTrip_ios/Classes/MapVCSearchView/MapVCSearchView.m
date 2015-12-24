//
//  MapVCSearchView.m
//  adventrip_ios
//
//  Created by Chin-Hui Hsieh  on 12/3/15.
//  Copyright © 2015 twoyears44. All rights reserved.
//

#import "MapVCSearchView.h"




@implementation MapVCSearchView

- (id)initWithFrame:(CGRect)frame owner:(id)owner andApiServerKey:(NSString *)apiKey {
    NSArray *xibs = [[NSBundle mainBundle]loadNibNamed:@"MapVCSearchView" owner:self options:nil];
    self = xibs[0];
    
    if (self) {
        [self setFrame:frame];
        
        _inputText.delegate = self;
        _localSearchQueries = [NSMutableArray array];
        _pastSearchWords = [NSMutableArray array];
        _pastSearchResults = [NSMutableArray array];
        _apiKey = apiKey;
        
        _inputSearchBar.delegate = self;

        
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"SearchCell"];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.hidden = YES;
        
    }
    return self;
}

#pragma mark - 
#pragma mark - UISearch bar

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //touch other view
    if (![_inputSearchBar isExclusiveTouch]) {
        [_inputSearchBar resignFirstResponder];
    }

}

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
    _inputSearchBar.showsCancelButton = YES;
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    
    //確認字數是否>0
    NSString *searchWordProtection = [_inputSearchBar.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"Length: %lu",(unsigned long)searchWordProtection.length);
    
    if (searchWordProtection.length != 0) {
        
        [self runScript];
        
    } else {
        NSLog(@"The searcTextField is empty.");
        [self hideTableView:YES];
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar{
    NSLog(@"End Editing");
}

-(BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    
    //空白改為+d,
    _substring = [NSString stringWithString:_inputSearchBar.text];
    _substring= [_substring stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    _substring = [_substring stringByReplacingCharactersInRange:range withString:text];
    
    if ([self.substring hasPrefix:@"+"] && self.substring.length >1) {
        self.substring  = [self.substring substringFromIndex:1];
        NSLog(@"This string: %@ had a space at the begining.",self.substring);
    }
    
    return YES;
}

-(BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    _inputSearchBar.showsCancelButton = NO;
    [self hideTableView:YES];
    return YES;
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    
    [_autoCompleteTimer invalidate];
    [self searchAutocompleteLocationsWithSubstring:self.substring];
    [_inputSearchBar resignFirstResponder];
    [self.tableView reloadData];
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    _inputSearchBar.text = @"";
    [_inputSearchBar resignFirstResponder];
    [self.localSearchQueries removeAllObjects];
}

- (void)runScript{
    
    [self.autoCompleteTimer invalidate];
    self.autoCompleteTimer = [NSTimer scheduledTimerWithTimeInterval:0.65f
                                                              target:self
                                                            selector:@selector(searchAutocompleteLocationsWithSubstring:)
                                                            userInfo:nil
                                                             repeats:NO];
}



#pragma mark - Google API Requests


-(void)retrieveGooglePlaceInformation:(NSString *)searchWord withCompletion:(void (^)(NSArray *))complete{
    NSString *searchWordProtection = [searchWord stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (searchWordProtection.length != 0) {
        
        CLLocation *userLocation = self.locationManager.location;
        NSString *currentLatitude = @(userLocation.coordinate.latitude).stringValue;
        NSString *currentLongitude = @(userLocation.coordinate.longitude).stringValue;
        
        NSString *urlString = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/autocomplete/json?input=%@&types=establishment|geocode&location=%@,%@&radius=500&language=en&key=%@",searchWord,currentLatitude,currentLongitude,_apiKey];
        NSLog(@"AutoComplete URL: %@",urlString);
        NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
        NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *delegateFreeSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: nil delegateQueue: [NSOperationQueue mainQueue]];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        NSURLSessionDataTask *task = [delegateFreeSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            NSDictionary *jSONresult = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            NSArray *results = [jSONresult valueForKey:@"predictions"];
            
            if (error || [jSONresult[@"status"] isEqualToString:@"NOT_FOUND"] || [jSONresult[@"status"] isEqualToString:@"REQUEST_DENIED"]){
                if (!error){
                    NSDictionary *userInfo = @{@"error":jSONresult[@"status"]};
                    NSError *newError = [NSError errorWithDomain:@"API Error" code:666 userInfo:userInfo];
                    complete(@[@"API Error", newError]);
                    return;
                }
                complete(@[@"Actual Error", error]);
                return;
            }else{
                complete(results);
            }
        }];
        
        [task resume];
    }
    
}

-(void)retrieveJSONDetailsAbout:(NSString *)place withCompletion:(void (^)(NSArray *))complete {
    NSString *urlString = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/details/json?placeid=%@&key=%@",place,_apiKey];
    NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *delegateFreeSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: nil delegateQueue: [NSOperationQueue mainQueue]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionDataTask *task = [delegateFreeSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSDictionary *jSONresult = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        NSArray *results = [jSONresult valueForKey:@"result"];
        
        if (error || [jSONresult[@"status"] isEqualToString:@"NOT_FOUND"] || [jSONresult[@"status"] isEqualToString:@"REQUEST_DENIED"]){
            if (!error){
                NSDictionary *userInfo = @{@"error":jSONresult[@"status"]};
                NSError *newError = [NSError errorWithDomain:@"API Error" code:666 userInfo:userInfo];
                complete(@[@"API Error", newError]);
                return;
            }
            complete(@[@"Actual Error", error]);
            return;
        }else{
            complete(results);
        }
    }];
    
    [task resume];
}

- (void)searchAutocompleteLocationsWithSubstring:(NSString *)substring
{
    [_localSearchQueries removeAllObjects];
    [_tableView reloadData];
    
    if (![_pastSearchWords containsObject:_substring]) {
        [_pastSearchWords addObject:_substring];
        NSLog(@"Search: %lu",(unsigned long)_pastSearchResults.count);
        [self retrieveGooglePlaceInformation:_substring withCompletion:^(NSArray * results) {
            [_localSearchQueries addObjectsFromArray:results];
            NSDictionary *searchResult = @{@"keyword":self.substring,@"results":results};
            [_pastSearchResults addObject:searchResult];
            [_tableView reloadData];
            [self hideTableView:NO];
            
        }];
        
    }else {
        
        for (NSDictionary *pastResult in _pastSearchResults) {
            if([[pastResult objectForKey:@"keyword"] isEqualToString:_substring]){
                [_localSearchQueries addObjectsFromArray:[pastResult objectForKey:@"results"]];
                [_tableView reloadData];
                [self hideTableView:NO];
            }
        }
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return TableViewSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //    return self.pastSearchQueries.count;
    switch (section) {
        case TableViewSectionMain:
            return self.localSearchQueries.count;
            break;
    }
    
    return 0;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case TableViewSectionMain: {
            //this is where it broke
            NSDictionary *searchResult = [self.localSearchQueries objectAtIndex:indexPath.row];
            NSString *placeID = [searchResult objectForKey:@"place_id"];
            [_inputSearchBar resignFirstResponder];
            [self retrieveJSONDetailsAbout:placeID withCompletion:^(NSArray *place) {
                _selectedLocation.name = [place valueForKey:@"name"];
                _selectedLocation.address = [place valueForKey:@"formatted_address"];
                NSString *latitude = [NSString stringWithFormat:@"%@,",[place valueForKey:@"geometry"][@"location"][@"lat"]];
                NSString *longitude = [NSString stringWithFormat:@"%@",[place valueForKey:@"geometry"][@"location"][@"lng"]];
                
                self.selectedLocation.locationCoordinates = CLLocationCoordinate2DMake(latitude.doubleValue, longitude.doubleValue);
                NSLog(@"Location Info: %@",self.selectedLocation);
                [self.delegate didSelectTableSearchResultLocationAtLatitude:latitude andLongitude:longitude];
                
                
                [self hideTableView:YES];
                
                
            }];
        }break;
            
        default:
            break;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SearchCell" forIndexPath:indexPath];
 
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SearchCell"];
    }
    
    switch (indexPath.section) {
        case TableViewSectionMain: {
            NSDictionary *searchResult = [self.localSearchQueries objectAtIndex:indexPath.row];
            cell.textLabel.text = [searchResult[@"terms"] objectAtIndex:0][@"value"];
            cell.detailTextLabel.text = searchResult[@"description"];
            cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:16.0];
            cell.detailTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:10.0];
        }break;
            
        default:
            break;
    }
    return cell;
}

-(void)hideTableView:(BOOL)isHide
{
    _tableView.hidden = isHide;
}

- (void)createFooterViewForTable{
    UIView *footerView  = [[UIView alloc] initWithFrame:CGRectMake(0, 500, 320, 70)];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"powered-by-google-on-white"]];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    imageView.frame = CGRectMake(110,10,85,12);
    [footerView addSubview:imageView];
    self.tableView.tableFooterView = footerView;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
