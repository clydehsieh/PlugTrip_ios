//
//  CHScrollView.m
//  CHScrollView
//
//  Created by Chin-Hui Hsieh  on 10/22/15.
//  Copyright © 2015 Chin-Hui Hsieh. All rights reserved.
//

#import "CHScrollView.h"

@implementation CHScrollView

@synthesize imageAry = _imageAry;
@synthesize itemSize = _itemSize;
@synthesize downSizeRatio;
@synthesize imageChangeRange;
@synthesize visibleImageNumber;
@synthesize isCentredFirstItem;
@synthesize itemAltitude;

-(id)initWithFrame:(CGRect)frame 
{
    self = [super initWithFrame:frame];
    
    if (self) {
        // Initialization code
        
        self.backgroundColor = [UIColor clearColor];
      
        _imageAry  = [[NSMutableArray alloc] init];
        imageStore = [[NSMutableArray alloc] init];
        downSizeRatio = 1;
        imageChangeRange = 0;
        visibleImageNumber = 3;
        isCentredFirstItem = NO;
        itemAltitude = lowerLocatioin;
        
        self.pagingEnabled = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;


    }
    return self;
    
    
}


#pragma mark - setter
- (void)setImageAry:(NSArray *)imageAry
{
    _imageAry = imageAry;
    
    NSArray *viewsToRemove = [self subviews];
    for (UIView *v in viewsToRemove) {
        [v removeFromSuperview];
    }
    
    self.contentOffset = CGPointMake(0, 0);
    
    [self initScrollView];
}

#pragma mark - ScorllViewSetting

-(void)initScrollView
{
    //Image setting 圖片最大高度限制
    float imageWidth = self.frame.size.width/visibleImageNumber;
    
    if (imageWidth > self.frame.size.height*0.9) {
        imageWidth = self.frame.size.height*0.9;
    }
    
    _itemSize = CGSizeMake(imageWidth, imageWidth);
    
    NSAssert((_itemSize.height <= self.frame.size.height), @"item's height must not bigger than scrollpicker's height");
    
    //第一圖片是否置中
    float shiftValueForFirstItem =0.0;
    if (isCentredFirstItem) {
        shiftValueForFirstItem = self.frame.size.width/2;
    }else
    {
        shiftValueForFirstItem = _itemSize.width/2;
    }
    
    if (downSizeRatio >=1) {
        downSizeRatio = 1;
    }else if (downSizeRatio <=0.5)
    {
        downSizeRatio = 0.5;
    }
    
    
    if (_imageAry.count !=0)
    {
        for ( int i=0; i < (_imageAry.count); i++)
        {
            UIImageView *temp = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, _itemSize.width*downSizeRatio, _itemSize.height*downSizeRatio)];
            temp.center = CGPointMake(shiftValueForFirstItem + (i*_itemSize.width) , self.frame.size.height/2);
            temp.image = [_imageAry objectAtIndex:i];
            temp.tag = i+1;
            
            UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didSelectedImage:)];
            [temp addGestureRecognizer:singleTapGestureRecognizer];
            temp.userInteractionEnabled = YES;
            
            [imageStore addObject:temp];
            [self addSubview:temp];
        }

    }
    
    //collectionview末端增加寬度, 讓末件能移至最前
    self.contentSize = CGSizeMake(((_imageAry.count-1) * _itemSize.width) + self.frame.size.width, self.frame.size.height);
    
    self.delegate = self;
    
    //預設不移動位置
    [self reloadView:0.0];
}

-(void)didSelectedImage:(UITapGestureRecognizer *)recognizer
{
    
    UIImageView *view = (UIImageView *)recognizer.view;
    
    [_delegateImage scrollView:self didSelectedImage:view];

    if (isCentredFirstItem) {

        [self setContentOffset:CGPointMake(view.center.x - self.frame.size.width/2, 0) animated:YES];

    }
    
}



- (void)reloadView:(float)offset
{
    //判斷變化範圍
    if (imageChangeRange <=0)
    {
        imageChangeRange = 0;
        downSizeRatio = 1;
    }
    else if (imageChangeRange >=1)
    {
        imageChangeRange = 1;
    }
    
    float rangeRatio = imageChangeRange;
    float rangeMid = self.frame.size.width * 0.5;
    float rangeMin = self.frame.size.width * (0.5-rangeRatio/2);
    float rangeMax = self.frame.size.width * (0.5+rangeRatio/2);
    
    //以下為計算cell 與visble area位置,來做圖片大小變化
    for (int i = 0; i < imageStore.count; i++)
    {
        
        UIImageView *view = [imageStore objectAtIndex:i];
        
        float xCenter = view.center.x - offset;
        CGPoint centerPt = view.center;
        
        if (xCenter > rangeMin && xCenter <= rangeMid )
        {
            
            float addHeightRatio = (((xCenter - rangeMid)/self.frame.size.width) * (1-downSizeRatio) /(rangeRatio/2))+(1-downSizeRatio);
            
            
            if (addHeightRatio >=0.5) addHeightRatio=0.5;
            else if (addHeightRatio <=0) addHeightRatio=0;
            
            view.frame = CGRectMake(0,0,_itemSize.width*(downSizeRatio+addHeightRatio), _itemSize.width*(downSizeRatio+addHeightRatio));
            
        }else if (xCenter > rangeMid && xCenter < rangeMax)
        {
            
            float addHeightRatio = (((xCenter - rangeMid)/self.frame.size.width) * (-(1-downSizeRatio)) / (rangeRatio/2))+(1-downSizeRatio);
            
            if (addHeightRatio >=0.5) addHeightRatio=0.5;
            else if (addHeightRatio <=0) addHeightRatio=0;
            
            view.frame = CGRectMake(0,0,_itemSize.width*(downSizeRatio+addHeightRatio), _itemSize.width*(downSizeRatio+addHeightRatio));
            
        }
        else
        {
            view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, _itemSize.width*downSizeRatio, _itemSize.width*downSizeRatio);
        }
        
        //設定高度
        switch (itemAltitude) {
            case 1:
                view.center = centerPt;
                break;
            case 2:
                view.center = CGPointMake(centerPt.x,view.frame.size.height*0.5);
                break;
            default:
                view.center = CGPointMake(centerPt.x, self.frame.size.height-view.frame.size.height*0.5);
                break;
        }
        
        
        
    }
    
    
    
}

#pragma mark - UIScrollViewDelegate


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    //移動改變圖片
    [self reloadView:scrollView.contentOffset.x];
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSLog(@"%f",scrollView.contentOffset.x);
}


@end
