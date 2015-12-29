//
//  CHImagePickerView.h
//  TestImagePicker
//
//  Created by Chin-Hui Hsieh  on 10/29/15.
//  Copyright © 2015 Chin-Hui Hsieh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "CHImagePickerHeaderView.h"
#import "CHImagePickerViewCell.h"

@protocol CHImagePickerViewDelegate <NSObject>

-(void)finishedPickingImages:(NSMutableArray *)assets;

@end


@interface CHImagePickerView : UIView  <UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout>
{
    __block NSMutableArray *allAssetArray;
    NSUserDefaults *prefs;
}

- (id)initWithFrame:(CGRect)frame owner:(id)owner;
- (void)loadPhotosFromAlbum;//撈本機相簿
- (void)loadPhotosFromAssetArray:(NSMutableArray *)AssetArray;//撈外部資料

@property (nonatomic, assign) id<CHImagePickerViewDelegate> delegate;

@property (assign, nonatomic) IBOutlet UICollectionView *imageDisplayView;
//@property (nonatomic) IBOutlet UIButton *autoUpdateSwitchBtn;
@property (weak, nonatomic) IBOutlet UISwitch *autoUpdateSwitchBtn;
@property (nonatomic) BOOL isAutoUpdate;

@property (nonatomic) PHAsset *pickedAsset;
@property (nonatomic) NSMutableArray *allAssetGroups ;//依照日期區分group,並存入, 後續一個日期對應一個section

@property (nonatomic) NSMutableArray *sectionPickedStatus;//每個section全選狀態,0不是,1是全選
@property (nonatomic) NSMutableArray *pickedCountForSection;//每個section中已選取數量

@property (nonatomic) NSMutableArray *pickedAssets;//存入選取的照片, 後續用delegate傳出

@end
