//
//  CHParseAdaptor.h
//  PlugTrip_ios
//
//  Created by Chin-Hui Hsieh  on 1/28/16.
//  Copyright © 2016 Chin-Hui Hsieh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface CHParseAdaptor : NSObject


-(void)createNewRowWhereClassName:(NSString *)className andColInfo:(NSArray *)colInfo success:(void(^)())successBloack failure:(void(^)(BOOL succeeded, NSError *error))failureBlacok;

-(void)updateRowWhereClassName:(NSString *)className andPFObject:(PFObject *)updateObj andColInfo:(NSArray *)colInfo success:(void(^)())successBloack failure:(void (^)(BOOL succeeded, NSError *error))failureBlacok;

-(void)deleteRowWhereClassName:(NSString *)className andPFObject:(PFObject *)deleteObj andColTitle:(NSString *)colTitle success:(void(^)())successBloack failure:(void (^)(BOOL succeeded, NSError *  error))failureBlacok;

-(void)queryRowWhereClassName:(NSString *)className andColTitle:(NSString *)colTitle andQueryValue:(id)queryValue success:(void(^)(NSArray *objects))successBloack failure:(void (^)(NSError *  error))failureBlacok;

@end
