//
//  CHScrollView.h
//  CHScrollView
//
//  Created by Chin-Hui Hsieh  on 10/22/15.
//  Copyright © 2015 Chin-Hui Hsieh. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CHScrollViewDelegate <NSObject>

-(void)scrollView:(UIScrollView *)scrollView didSelectedImage:(UIImageView *)selectedView;

@end


enum ItemCenterLocation{
    lowerLocatioin = 0,
    middleLocation,
    upperLocation,
};

@interface CHScrollView : UIScrollView<UIScrollViewDelegate>
{
    //儲存ScrollView上的image, 用以調整大小
    NSMutableArray *imageStore;
}
@property (nonatomic) id<CHScrollViewDelegate>delegateImage;

//接收圖片後, 開始佈置
@property (nonatomic, strong) NSArray *imageAry;

@property (nonatomic) CGSize itemSize;

//圖片縮放差[1-->0.5] [non-->max];預設1
@property (nonatomic) float downSizeRatio;

//縮放範圍, 中心為準, 整個view寬度為0; 預設為1, [0-->1] [non -->max];
@property (nonatomic) float imageChangeRange;@property (nonatomic) int visibleImageNumber;

@property (nonatomic) BOOL isCentredFirstItem;//首件是否置中
@property (nonatomic) int itemAltitude;//預設0,lowerLocatioin

@end

