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
#import "myDB.h"
//#import "CHMapViewVC.h"


@protocol CHImagePickerViewDelegate <NSObject>

-(void)finishedPickingImages:(NSMutableArray *)assets;
-(void)didLeftPickingImagesVC;

@end


@interface CHImagePickerView : UIView  <UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout>


- (id)initWithFrame:(CGRect)frame owner:(id)owner;
- (void)loadPhotosFromAlbum;
- (void)loadPhotosFromAlbumAndCompareWithAssets:(NSMutableArray *)AssetArray;//撈本機相簿
- (void)loadPhotosFromAssetArray:(NSMutableArray *)AssetArray;//撈外部資料

@property (nonatomic, assign) id<CHImagePickerViewDelegate> delegate;

@property (assign, nonatomic) IBOutlet UICollectionView *imageDisplayView;


@property (nonatomic) BOOL isAutoUpdate;



// btns & switchs
@property (weak, nonatomic) IBOutlet UIButton *starNewBtn;
@property (weak, nonatomic) IBOutlet UIButton *okBtn;
@property (weak, nonatomic) IBOutlet UIButton *cancelBtn;
@property (weak, nonatomic) IBOutlet UIButton *allPickBtn;
@property (weak, nonatomic) IBOutlet UISwitch *isShowImagesOnMap;



@end
