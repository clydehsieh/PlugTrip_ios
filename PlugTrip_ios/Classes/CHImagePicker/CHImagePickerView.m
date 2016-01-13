//
//  CHImagePickerView.m
//  TestImagePicker
//
//  Created by Chin-Hui Hsieh  on 10/29/15.
//  Copyright © 2015 Chin-Hui Hsieh. All rights reserved.
//
/*
 
 
 */

#import "CHImagePickerView.h"

@implementation CHImagePickerView

- (id)initWithFrame:(CGRect)frame owner:(id)owner {
    
    self = [[[NSBundle mainBundle]loadNibNamed:@"CHImagePickerView" owner:owner options:nil] firstObject];
    
    if (self) {
        
        self.frame = frame;
        
        //initialize
        allAssetArray = [NSMutableArray new];
        prefs = [NSUserDefaults standardUserDefaults];
        isPickAllImage= YES;
        _pickedAsset = [[PHAsset alloc]init];
        _pickedAssets = [[NSMutableArray alloc]init];
        _pickedCountForSection = [[NSMutableArray alloc]init];
//       [_autoUpdateSwitchBtn setOn:[[[NSUserDefaults standardUserDefaults] objectForKey:@"autoUpdate"] boolValue]];
       [_isShowImagesOnMap setOn:[[[NSUserDefaults standardUserDefaults] objectForKey:@"isShowImagesOnMap"] boolValue]];
        
//        [self loadPhotos];
//        [self scrollViewSetting];
//        [self btnSetting];
    
    }
    
    return self;
    
    
}


-(void)loadPhotosFromAlbumAndCompareWithAssets:(NSMutableArray *)AssetArray
{
    if (AssetArray) {
        _pickedAssets = AssetArray;
    }
    
    [self loadPhotos];
    [self scrollViewSetting];
}

-(void)loadPhotosFromAssetArray:(NSMutableArray *)AssetArray
{

    allAssetArray = AssetArray;
    
    //依照日期分類
    _allAssetGroups = [[NSMutableArray alloc]init];
    
    while ([allAssetArray count]>0)
    {
        NSMutableArray *tempArray = [[NSMutableArray alloc]init];
        
        PHAsset *firstAsset = allAssetArray[0];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"YYYY-MM-dd"];
        NSString *lastDate = [dateFormat stringFromDate:firstAsset.creationDate];
        
        [allAssetArray enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL * _Nonnull stop)
         {
             if ([[dateFormat stringFromDate:asset.creationDate] isEqualToString:lastDate])
             {
                 [tempArray addObject:asset];
                 
             }
         }];
        
        [tempArray enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL * _Nonnull stop)
         {
             if ([allAssetArray containsObject:asset])
             {
                 [allAssetArray removeObject:asset];
             }
         }];
        
        [_allAssetGroups addObject:tempArray];
        
    };
    
    
    [self scrollViewSetting];
}

#pragma mark - loading Photos
-(void)loadPhotos
{
    //照片全部取出來
    PHFetchOptions *allPhotosfetchOption = [[PHFetchOptions alloc]init];
    allPhotosfetchOption.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    
    allPhotosfetchOption.predicate = [NSPredicate predicateWithFormat:@"mediaType == 1"];
    
    
    PHFetchResult *result = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:allPhotosfetchOption];
    [result enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
        [allAssetArray addObject:asset];
    }];
    
    
    
    //MyCam Album
    NSString *string = @"MyCam";
    PHFetchOptions *albumFetchOption = [[PHFetchOptions alloc]init];
    
    albumFetchOption.predicate = [NSPredicate predicateWithFormat:@"title == %@",string];
    
    PHFetchResult *albumResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:albumFetchOption];
    
    [albumResult enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop)
     {
         PHFetchResult *loftAssetResult = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
         [loftAssetResult enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
             if ([allAssetArray containsObject:asset]) {
                 [allAssetArray removeObject:asset];
             }
         }];
     }];
    
    
    
    //依照日期分類
    _allAssetGroups = [[NSMutableArray alloc]init];
    
    while ([allAssetArray count]>0)
    {
        NSMutableArray *tempArray = [[NSMutableArray alloc]init];
        
        PHAsset *firstAsset = allAssetArray[0];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"YYYY-MM-dd"];
        NSString *lastDate = [dateFormat stringFromDate:firstAsset.creationDate];
        
        [allAssetArray enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL * _Nonnull stop)
         {
             if ([[dateFormat stringFromDate:asset.creationDate] isEqualToString:lastDate])
             {
                 [tempArray addObject:asset];
                 
             }
         }];
        
        [tempArray enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL * _Nonnull stop)
         {
             if ([allAssetArray containsObject:asset])
             {
                 [allAssetArray removeObject:asset];
             }
         }];
        
        [_allAssetGroups addObject:tempArray];
        
    };
    
    
}

-(void)scrollViewSetting
{
    [self.imageDisplayView registerNib:[UINib nibWithNibName:@"CHImagePickerViewCell" bundle:nil] forCellWithReuseIdentifier:@"cell"];
    [self.imageDisplayView registerNib:[UINib nibWithNibName:@"CHImagePickerHeaderView" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"headerView"];
    self.imageDisplayView.delegate = self;
    self.imageDisplayView.dataSource = self;
    self.imageDisplayView.backgroundColor = [UIColor clearColor];
    self.imageDisplayView.allowsMultipleSelection = YES;

}

#pragma mark - collection view delegate
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    _sectionPickedStatus = [[NSMutableArray alloc]init];
    
    [_allAssetGroups enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop)
    {
        [_sectionPickedStatus addObject:@0];
        [_pickedCountForSection addObject:@0];
    }];
    
    return [_allAssetGroups count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [_allAssetGroups[section] count];
}

// header or footer setting
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    
    UICollectionReusableView *header  = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"headerView" forIndexPath:indexPath];


    if (kind == UICollectionElementKindSectionHeader)
    {
        if (!header)
        {
            header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"headerView" forIndexPath:indexPath];
        }
        
        header.tag = indexPath.section *100;
        
        
        //title setting
        UILabel *label = (UILabel *)[header viewWithTag:1];
        
        PHAsset *asset = _allAssetGroups[indexPath.section][0];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"YYYY-MM-dd"];
        NSString *lastDate = [dateFormat stringFromDate:asset.creationDate];
        label.text = [NSString stringWithFormat:@"%@", lastDate];
        
        UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pickAllSectionImages:)];
//        [label addGestureRecognizer:singleTapGestureRecognizer];

        
        UIImageView *imageView = (UIImageView *)[header viewWithTag:2];
        [imageView addGestureRecognizer:singleTapGestureRecognizer];
        
//        if ([_sectionPickedStatus[indexPath.section]  isEqual:@1])
//        {
//            imageView.hidden = NO;
//        }else
//        {
//            imageView.hidden = YES;
//        }
        
    }
    
    return header;
    
}

// cell setting
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //重複使用cell reuseidentifier
    static NSString *cellIdentifier = @"cell";
    
    //客製化cell
    CHImagePickerViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if (!cell)
    {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    }
    
    //設定邊框
    cell.layer.borderWidth = 1.0;
    cell.layer.borderColor = [[UIColor blackColor] CGColor];
    
    // 右上小圖顯示選取,如果已經選取, 則打勾
    _pickedAsset = _allAssetGroups[indexPath.section][indexPath.row];
    UIImageView *view = (UIImageView *)[cell viewWithTag:1];
    if ([_pickedAssets containsObject:_pickedAsset])
    {
        view.hidden = NO;
    }else
    {
        view.hidden =  YES;
    }

//    if (cell.selected) {
//        
//        view.hidden =  NO;//show
//    }
//    else
//    {
//        view.hidden = YES;//hide
//    }
    
    
    // 放置圖片
    UIImageView *imageView = (UIImageView*)[cell viewWithTag:2];
    
    NSInteger retinaMultiplier = [UIScreen mainScreen].scale;
    CGSize retinaSquare = CGSizeMake(imageView.bounds.size.width * retinaMultiplier, imageView.bounds.size.height * retinaMultiplier);
    
    // PHAsset turn to UIImage
    [[PHImageManager defaultManager]
     requestImageForAsset:_allAssetGroups[indexPath.section][indexPath.row]
     targetSize:retinaSquare
     contentMode:PHImageContentModeAspectFill
     options:nil
     resultHandler:^(UIImage *result, NSDictionary *info) {
         
         // The result is not square, but correctly displays as a square using AspectFill
         imageView.image = result;
         
     }];
    
    
    return cell;
    
}

//選照片時, show右上角小圖,將圖存入矩陣
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath  {
    
    UICollectionViewCell *cell =[collectionView cellForItemAtIndexPath:indexPath];
    
    _pickedAsset = _allAssetGroups[indexPath.section][indexPath.row];
    
    if (![_pickedAssets containsObject:_pickedAsset])
    {
        [_pickedAssets addObject:_pickedAsset];
        
        
    }
    
    UIImageView *view = (UIImageView *)[cell viewWithTag:1];
    view.hidden = NO;
    
    NSInteger pickedCount = [_pickedCountForSection[indexPath.section] integerValue];
    pickedCount+=1;
    _pickedCountForSection[indexPath.section] = [NSNumber numberWithInteger:pickedCount];
    
    if ([_pickedCountForSection[indexPath.section] integerValue] == [_allAssetGroups[indexPath.section] count]) {
        _sectionPickedStatus[indexPath.section] = @1;
        
//        [_imageDisplayView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]];
        
    }

    NSLog(@"\nPicked number:%@\nsectionStatus:%@",_pickedCountForSection[indexPath.section],_sectionPickedStatus[indexPath.section]);
    
}

//取消照片時, hide右上角小圖,將圖移出矩陣
-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell =[collectionView cellForItemAtIndexPath:indexPath];
    
    _pickedAsset = _allAssetGroups[indexPath.section][indexPath.row];
    
    if ([_pickedAssets containsObject:_pickedAsset]) {
         [_pickedAssets removeObject:_pickedAsset];
    }
   
    UIImageView *view = (UIImageView *)[cell viewWithTag:1];
    view.hidden = YES;
    
    NSInteger pickedCount = [_pickedCountForSection[indexPath.section] integerValue];
    pickedCount-=1;
    _pickedCountForSection[indexPath.section] = [NSNumber numberWithInteger:pickedCount];
    
    _sectionPickedStatus[indexPath.section] = @0;
    
    NSLog(@"\nPicked number:%@\nsectionStatus:%@",_pickedCountForSection[indexPath.section],_sectionPickedStatus[indexPath.section]);
    
}



#pragma mark - Actions

- (IBAction)cancelBtnAction:(id)sender {
    
    NSLog(@"Cancel");
    
    [self removeFromSuperview];
}

- (IBAction)okBtnAction:(id)sender {
    
    if (_pickedAssets.count >0) {
        
        if ([self.delegate respondsToSelector:@selector(finishedPickingImages:)]) {
            [self.delegate finishedPickingImages:_pickedAssets];

        }
    }
    
    NSLog(@"ok with Picked num:%lu", (unsigned long)[_pickedAssets count]);
    
    [self removeFromSuperview];
}
- (IBAction)allPickBtn:(UIButton *)sender {
    
    if (isPickAllImage) {
        [_allAssetGroups enumerateObjectsUsingBlock:^(NSMutableArray *sectionArray, NSUInteger section, BOOL * _Nonnull stop) {
            [sectionArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (![_pickedAssets containsObject:obj]) {
                    [_pickedAssets addObject:obj];
                    
                    
                    [_imageDisplayView selectItemAtIndexPath:[NSIndexPath indexPathForItem:idx inSection:section] animated:YES scrollPosition:UICollectionViewScrollPositionNone];
                    
                    [_imageDisplayView.delegate collectionView:_imageDisplayView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:idx inSection:section]];
                }
            }];
        }];
        
        isPickAllImage=NO;
        
    }else{
        [_allAssetGroups enumerateObjectsUsingBlock:^(NSMutableArray *sectionArray, NSUInteger section, BOOL * _Nonnull stop) {
            [sectionArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([_pickedAssets containsObject:obj]) {
                    [_pickedAssets removeObject:obj];
                    
                    [_imageDisplayView deselectItemAtIndexPath:[NSIndexPath indexPathForItem:idx inSection:section] animated:YES];
                    
                    [_imageDisplayView.delegate collectionView:_imageDisplayView didDeselectItemAtIndexPath:[NSIndexPath indexPathForItem:idx inSection:section]];
                }
            }];
        }];
        
        isPickAllImage=YES;
    }
    
    
    
    
}

///!!!:wait coding
- (IBAction)changeAutoUpdateState:(id)sender {

    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:_isShowImagesOnMap.isOn] forKey:@"isShowImagesOnMap"];

    BOOL showImagesOnMap = [[[NSUserDefaults standardUserDefaults] objectForKey:@"isShowImagesOnMap"] boolValue];
    
    if (showImagesOnMap) {
        NSLog(@"show Images On Map");
    }else{
        NSLog(@"Don't show Images On Map ");
    }
    
}

//判斷該欄照片全選or not
-(void)pickAllSectionImages:(UITapGestureRecognizer *)recognizer
{
    UICollectionReusableView *header = (UICollectionReusableView *)recognizer.view.superview;
    
    NSInteger indexPathSection = header.tag / 100;
    
    if ([_sectionPickedStatus[indexPathSection] isEqual:@1])
    {
        
        for (int i =0; i< [_allAssetGroups[indexPathSection] count]; i++)
        {
            if ([_pickedAssets containsObject:_allAssetGroups[indexPathSection][i]]) {
                [_pickedAssets removeObject:_allAssetGroups[indexPathSection][i]];
           
                [_imageDisplayView deselectItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:indexPathSection] animated:YES];
                
                [_imageDisplayView.delegate collectionView:_imageDisplayView didDeselectItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:indexPathSection]];
                
            }
            
        }
    }
    else
    {
        
        for (int i =0; i< [_allAssetGroups[indexPathSection] count]; i++)
        {
            if (![_pickedAssets containsObject:_allAssetGroups[indexPathSection][i]]) {
                [_pickedAssets addObject:_allAssetGroups[indexPathSection][i]];
                
                
                [_imageDisplayView selectItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:indexPathSection] animated:YES scrollPosition:UICollectionViewScrollPositionNone];
                
                [_imageDisplayView.delegate collectionView:_imageDisplayView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:indexPathSection]];
                
                
            }
            
        }
        
    }

    
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/




@end
