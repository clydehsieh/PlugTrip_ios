//
//  myDB.h
//  CustManager
//
//  Created by Stronger Shen on 2014/10/13.
//  Copyright (c) 2014年 MobileIT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"

@interface myDB : NSObject
{
    FMDatabase *db;
}

+ (myDB *)sharedInstance;

-(void)insertImagePath:(NSString *)imagePath andComments:(NSString *)comments andVoicePath:(NSString *)voicePath andHiddenState:(BOOL)Hidden;
-(void)updateImagePath:(NSString *)imagePath andComments:(NSString *)comments andVoicePath:(NSString *)voicePath andHiddenState:(BOOL)Hidden;


- (id)queryCust;
- (id)queryCustName:(NSString *)custname;
- (NSString *)newCustNo;

- (void)insertCustNo:(NSString *)custno andCustName:(NSString *)custname andCustTel:(NSString *)custtel andCustAddr:(NSString *)custaddr andCustEmail:(NSString *)custemail;
- (void)updateCustNo:(NSString *)custno andCustName:(NSString *)custname andCustTel:(NSString *)custtel andCustAddr:(NSString *)custaddr andCustEmail:(NSString *)custemail;
- (void)deleteCustNo:(NSString *)custno;

- (void)insertCustDict:(NSDictionary *)dictCust;



@end
