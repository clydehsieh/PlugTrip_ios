//
//  CHImagePickerView.m
//  TestImagePicker
//
//  Created by Chin-Hui Hsieh  on 10/29/15.
//  Copyright © 2015 Chin-Hui Hsieh. All rights reserved.
//
#import "CHImagePickerView.h"

@interface CHImagePickerView()
{
    NSMutableArray *localDBPhotoIDs;
    __block NSMutableArray *allAssetArray;//row data
    
    NSInteger allImgCounts;//camera roll內所有照片數量
    
    NSMutableArray *allAssetGroups ;//camera roll內所有照片, 依照日期分到各個section
    
    NSMutableArray *pickedCountForSection;//每個section中已選取數量
    
    PHAsset *pickedAsset;
    NSMutableArray *sectionPickedStatus;//每個section全選狀態,0不是,1是全選
    NSMutableArray *pickedAssets;//存入選取的照片, 後續用delegate傳出
    
    NSUserDefaults *prefs;
    BOOL isPickAllImage;
    
    
}

@end

@implementation CHImagePickerView

- (id)initWithFrame:(CGRect)frame owner:(id)owner {
    
    self = [[[NSBundle mainBundle]loadNibNamed:@"CHImagePickerView" owner:owner options:nil] firstObject];
    
    if (self) {
        
        self.frame = frame;
        
        // ...init
        // 全部相機底片資料
        allAssetArray = [NSMutableArray new];
    
        //
        [self loadDBPhotoID];
        
        //用於cell選取與否判斷
        pickedAsset = [[PHAsset alloc]init];
        pickedAssets = [[NSMutableArray alloc]init];
        
        isPickAllImage= YES;
        
       [_isShowImagesOnMap setOn:[[[NSUserDefaults standardUserDefaults] objectForKey:@"isShowImagesOnMap"] boolValue]];

        [self btnInit];
        
    }
    
    return self;
    
    
}

-(void)btnInit{
    
    NSDictionary *tripInfo = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"tripInfo"]];
    BOOL isTripCreate = [[tripInfo objectForKey:@"isTripCreate"] boolValue];
    
    // ...按鈕初始顯示
    // 未建立local旅程
    _starNewBtn.hidden  = (isTripCreate)? YES: NO;
    // 已建立local旅程
    _okBtn.hidden       = (isTripCreate)? NO :YES;
    _cancelBtn.hidden   = (isTripCreate)? NO :YES;
    
    
    // ...layout setting
    _allPickBtn.layer.cornerRadius = 5.0f;
    _allPickBtn.layer.borderColor  = [UIColor lightGrayColor].CGColor;
    _allPickBtn.layer.borderWidth  = 2.0f;
    
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

//建立imgPicker 方式

-(void)loadPhotosFromAlbum{
    
    [self loadDBPhotoID];
    [self loadPhotos];
    [self scrollViewSetting];
    
}

-(void)loadPhotosFromAlbumAndCompareWithAssets:(NSMutableArray *)AssetArray
{
    if (AssetArray) {
        pickedAssets = AssetArray;
    }
    
    [self loadPhotos];
    [self scrollViewSetting];
}

-(void)loadPhotosFromAssetArray:(NSMutableArray *)AssetArray
{

    allAssetArray = AssetArray;
    
    //依照日期分類
    allAssetGroups = [[NSMutableArray alloc]init];
    
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
        
        [allAssetGroups addObject:tempArray];
        
    };

    [self scrollViewSetting];
}




#pragma mark - Photos process

-(void)savePickedPhotoToDB{
    
    NSString *tableName_tripPhoto = @"Trip_Photo_Info";
    
    //Clear the table
    [[myDB sharedInstance] deleteTable:tableName_tripPhoto];
    [[myDB sharedInstance] createTripTable:tableName_tripPhoto];
    
    //ready to save to database
    __block NSString *imagePath = [[NSString alloc]init];
    __block NSString *imageLatitude     = [[NSString alloc]init];
    __block NSString *imageLongtitude   = [[NSString alloc]init];
    NSString *comment           = [[NSString alloc]init];
    NSString *voicePath         = [[NSString alloc]init];
    NSString *hiddenState       = [[NSString alloc]init];
    
    
    PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:localDBPhotoIDs options:nil];
    
    [result enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL * _Nonnull stop) {
        
        imageLatitude   = [NSString stringWithFormat:@"%f",asset.location.coordinate.latitude];
        imageLongtitude = [NSString stringWithFormat:@"%f",asset.location.coordinate.longitude];
        imagePath       = asset.localIdentifier;
        
        //存入table
        [[myDB sharedInstance]insertTable:tableName_tripPhoto andImageLatitude:imageLatitude andImageLongtitude:imageLongtitude ImagePath:imagePath andComments:comment andVoicePath:voicePath andHiddenState:hiddenState];
        
    }];
    
    NSLog(@"save photo to DB success");
}

-(void)loadDBPhotoID{
    
    NSString *tableName_tripPhoto = @"Trip_Photo_Info";
    
    localDBPhotoIDs = [NSMutableArray new];
    
    //從資料庫撈assets
    NSMutableArray *queryTableResult=[[NSMutableArray alloc]init];
    queryTableResult = [[myDB sharedInstance]queryWithTableName:tableName_tripPhoto];
    
    if (queryTableResult) {
        
        // ...撈localIdentifer資料
        [queryTableResult enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL * _Nonnull stop) {
            [localDBPhotoIDs addObject:dict[@"imagePath"]];
        }];
    }
    
    NSLog(@"選取照片數：%lu",(unsigned long)localDBPhotoIDs.count);
}

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
    
    //相機所有照片數量
    allImgCounts = allAssetArray.count;
    
    //依照日期分類
    allAssetGroups = [[NSMutableArray alloc]init];
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
    
        [allAssetGroups addObject:tempArray];
    };
    
    //各個section已被選取的數量
    pickedCountForSection = [[NSMutableArray alloc]init];
    [allAssetGroups enumerateObjectsUsingBlock:^(NSArray *array, NSUInteger idx, BOOL * _Nonnull stop) {
        
        __block int sectionCount = 0;
        
        [array enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if ([localDBPhotoIDs containsObject:asset.localIdentifier]) {
                sectionCount +=1;
            }
        }];
        
        [pickedCountForSection addObject:[NSNumber numberWithInt:sectionCount]];
    }];
    
    NSLog(@"%lu",(unsigned long)pickedCountForSection.count);
  
}



#pragma mark - collection view delegate
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    sectionPickedStatus = [[NSMutableArray alloc]init];
    
    [allAssetGroups enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop)
    {
        [sectionPickedStatus addObject:@0];
    }];
    
    return [allAssetGroups count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [allAssetGroups[section] count];
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
        
        PHAsset *asset = allAssetGroups[indexPath.section][0];
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
    PHAsset *asset = allAssetGroups[indexPath.section][indexPath.row];
    UIImageView *view = (UIImageView *)[cell viewWithTag:1];
    
    if ([localDBPhotoIDs containsObject:asset.localIdentifier]) {
        
        //layout setting
        view.hidden = NO;
        cell.selected = YES;
        [collectionView selectItemAtIndexPath:indexPath animated:nil scrollPosition:UICollectionViewScrollPositionNone];
    }else{
        view.hidden =  YES;
    }
   
    // 放置圖片
    UIImageView *imageView = (UIImageView*)[cell viewWithTag:2];
    
    NSInteger retinaMultiplier = [UIScreen mainScreen].scale;
    CGSize retinaSquare = CGSizeMake(imageView.bounds.size.width * retinaMultiplier, imageView.bounds.size.height * retinaMultiplier);
    
    // PHAsset turn to UIImage
    [[PHImageManager defaultManager]
     requestImageForAsset:asset
     targetSize:retinaSquare
     contentMode:PHImageContentModeAspectFill
     options:nil
     resultHandler:^(UIImage *result, NSDictionary *info) {
         
         // The result is not square, but correctly displays as a square using AspectFill
         imageView.image = result;
         
     }];
    
    
    return cell;
    
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath  {


        CHImagePickerViewCell *cell = (CHImagePickerViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
        //選取小勾勾
        UIImageView *view = (UIImageView *)[cell viewWithTag:1];
        view.hidden = NO;
    
        //cell上的照片asset
        PHAsset *asset =  allAssetGroups[indexPath.section][indexPath.row];
    
        if (![localDBPhotoIDs containsObject:asset.localIdentifier]) {
    
            //新增
            [localDBPhotoIDs addObject:asset.localIdentifier];
    
            //更新section資訊
            NSInteger selectedCount = [pickedCountForSection[indexPath.section] integerValue];
            selectedCount +=1;
            pickedCountForSection[indexPath.section] = [NSNumber numberWithInteger:selectedCount] ;
        }
        
        NSLog(@"選取照片數：%lu",(unsigned long)localDBPhotoIDs.count);
    
}

-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {

    CHImagePickerViewCell *cell = (CHImagePickerViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    //選取小勾勾
    UIImageView *view = (UIImageView *)[cell viewWithTag:1];
    view.hidden = YES;
    
    //cell上的照片asset
    PHAsset *asset =  allAssetGroups[indexPath.section][indexPath.row];
    
    if ([localDBPhotoIDs containsObject:asset.localIdentifier]) {
        
        //減少
        [localDBPhotoIDs removeObject:asset.localIdentifier];
        
        //更新section資訊
        NSInteger selectedCount = [pickedCountForSection[indexPath.section] integerValue];
        selectedCount -=1;
        pickedCountForSection[indexPath.section] = [NSNumber numberWithInteger:selectedCount] ;
    }
    
    NSLog(@"選取照片數：%lu",(unsigned long)localDBPhotoIDs.count);
    
//    //移動至選取區域
//    [_imageDisplayView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
//    
//    CHImagePickerViewCell *cell = (CHImagePickerViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
//    
//    if (!cell) {
//        [_imageDisplayView layoutIfNeeded];
//        cell = (CHImagePickerViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
//    }
//    
//    //取消選取小勾勾
//    UIImageView *view = (UIImageView *)[cell viewWithTag:1];
//    view.hidden = YES;
//    
//    if ([localDBPhotoIDs containsObject:cell.imgLocalID]) {
//        
//        //減少
//        [localDBPhotoIDs removeObject:cell.imgLocalID];
//        
//        //更新section資訊
//        NSInteger selectedCount = [pickedCountForSection[indexPath.section] integerValue];
//        selectedCount -=1;
//        pickedCountForSection[indexPath.section] = [NSNumber numberWithInteger:selectedCount] ;
//    }
//    
//    NSLog(@"選取照片數：%lu",(unsigned long)localDBPhotoIDs.count);
    
}

-(BOOL)isSectionImgAllPicled{
    
    return YES;
}

-(void)pickAllSectionImages:(UITapGestureRecognizer *)recognizer
{
    // ...section 全選
    
    UICollectionReusableView *header = (UICollectionReusableView *)recognizer.view.superview;
    
    NSInteger section = header.tag / 100;
    
    if ([pickedCountForSection[section] integerValue] == [allAssetGroups[section] count]) {
        
        //取消所有cell
        for (int i =0; i< [allAssetGroups[section] count]; i++)
            {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:section];

                [self collectionView:_imageDisplayView didDeselectItemAtIndexPath:indexPath];
            }
        
    }else{
        
        //選所有cell
        for (int i =0; i< [allAssetGroups[section] count]; i++)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:section];
            
            [self collectionView:_imageDisplayView didSelectItemAtIndexPath:indexPath];
            
            
        }
        
    }

    
}

- (IBAction)allPickBtn:(UIButton *)sender {
    
    // ... camera roll 全選
   
    if (localDBPhotoIDs.count == allImgCounts) {
        
         // 全取消
        [allAssetGroups enumerateObjectsUsingBlock:^(NSArray *group, NSUInteger section, BOOL * _Nonnull stop) {
            
            [group enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger row, BOOL * _Nonnull stop) {
                
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                
                [self collectionView:_imageDisplayView didDeselectItemAtIndexPath:indexPath];
                
            }];
        }];
        
    }else{
        
        // 全選
        [allAssetGroups enumerateObjectsUsingBlock:^(NSArray *group, NSUInteger section, BOOL * _Nonnull stop) {
            
            [group enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger row, BOOL * _Nonnull stop) {
                
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                
                [self collectionView:_imageDisplayView didSelectItemAtIndexPath:indexPath];
                
            }];
        }];
    }
    
    NSLog(@"選取照片數：%lu",(unsigned long)localDBPhotoIDs.count);
    

    
}


#pragma mark - Btn Actions

- (IBAction)cancelBtnAction:(id)sender {
    
    NSLog(@"Cancel");
    
    if ([_delegate respondsToSelector:@selector(didLeftPickingImagesVC)]) {
        [_delegate didLeftPickingImagesVC];
    }
    
    [self removeFromSuperview];
}

- (IBAction)okBtnAction:(id)sender {
    
    [self savePickedPhotoToDB];
    NSLog(@"選取了( %lu )張照片", (unsigned long)[localDBPhotoIDs count]);
    
    if ([self.delegate respondsToSelector:@selector(finishedPickingImages:)]) {
        [self.delegate finishedPickingImages:nil];
    }
    
    [self removeFromSuperview];
}

- (IBAction)changeAutoUpdateState:(id)sender {

    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:_isShowImagesOnMap.isOn] forKey:@"isShowImagesOnMap"];

    BOOL showImagesOnMap = [[[NSUserDefaults standardUserDefaults] objectForKey:@"isShowImagesOnMap"] boolValue];
    
    if (showImagesOnMap) {
        NSLog(@"show Images On Map");
    }else{
        NSLog(@"Don't show Images On Map ");
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
