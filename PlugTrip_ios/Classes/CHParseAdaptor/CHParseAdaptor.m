//
//  CHParseAdaptor.m
//  PlugTrip_ios
//
//  Created by Chin-Hui Hsieh  on 1/28/16.
//  Copyright © 2016 Chin-Hui Hsieh. All rights reserved.
//

#import "CHParseAdaptor.h"

@implementation CHParseAdaptor

+ (id)sharedWebApiAdaptor {
    
    static id sharedInstance = nil;
    
    static dispatch_once_t p = 0;
    
    dispatch_once(&p, ^{
        sharedInstance = [[CHParseAdaptor alloc]init];
    });
    
    return sharedInstance;
}


- (id)init {
    
    self = [super init];
    if (self) {
        
    
    }
    return self;
}


//Create new row
-(void)createNewRowWhereClassName:(NSString *)className andColInfo:(NSArray *)colInfo success:(void(^)())successBloack failure:(void (^)(BOOL succeeded, NSError * error))failureBlacok{
    
    PFObject *newObj = [PFObject objectWithClassName:className];

    [colInfo enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSString *colTitle = dict[@"title"];
        NSString *colValue = dict[@"value"];
        
        newObj[colTitle] = colValue ;
        
    }];
    
    [newObj saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {

        if (succeeded) {
            successBloack();
        }else{
            failureBlacok(succeeded,error);
        }
    }];
}

//update row
-(void)updateRowWhereClassName:(NSString *)className andPFObject:(PFObject *)updateObj andColInfo:(NSArray *)colInfo success:(void(^)())successBloack failure:(void (^)(BOOL succeeded, NSError *error))failureBlacok{
    
    [colInfo enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *colTitle = dict[@"title"];
        NSString *colValue = dict[@"value"];
        
        updateObj[colTitle] = colValue ;
    }];
    
    [updateObj saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        
        if (succeeded) {
            successBloack();
        }else{
            failureBlacok(succeeded,error);
        }
    }];
}

//delete row
-(void)deleteRowWhereClassName:(NSString *)className andPFObject:(PFObject *)deleteObj andColTitle:(NSString *)colTitle success:(void(^)())successBloack failure:(void (^)(BOOL succeeded, NSError *error))failureBlacok{
    
    if (colTitle) {
        [deleteObj removeObjectForKey:colTitle];

        [deleteObj saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                successBloack();
            }else{
                failureBlacok(succeeded,error);
            }
        }];
    }
}

//query
-(void)queryRowWhereClassName:(NSString *)className andColTitle:(NSString *)colTitle andQueryValue:(id)queryValue success:(void(^)(NSArray *objects))successBloack failure:(void (^)(NSError *error))failureBlacok{
    
    PFQuery *query = [PFQuery queryWithClassName:className];
    [query whereKey:colTitle equalTo:queryValue];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (!error) {
            successBloack(objects);
        } else {
            // Log details of the failure
            failureBlacok(error);
        }
    }];
}





@end









