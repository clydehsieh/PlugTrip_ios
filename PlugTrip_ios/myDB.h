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

-(void)createTable:(NSString *)tableName;
-(void)deleteTable:(NSString *)tableName;
-(void)insertTable:(NSString *)tableName andImageLatitude:(NSString *)imageLatitude andImageLongtitude:(NSString *)imageLongtitude ImagePath:(NSString *)imagePath andComments:(NSString *)comments andVoicePath:(NSString *)voicePath andHiddenState:(NSString *)Hidden;
-(void)updateTable:(NSString *)tableName andRowid:(NSString *)rowid andImageLatitude:(NSString *)imageLatitude andImageLongtitude:(NSString *)imageLongtitude ImagePath:(NSString *)imagePath andComments:(NSString *)comments andVoicePath:(NSString *)voicePath andHiddenState:(NSString *)Hidden;
- (id)queryWithTableName:(NSString *)tableName;
- (void)deleteTripInfo:(NSString *)rowid;



- (id)queryCust;
- (id)queryCustName:(NSString *)custname;
- (NSString *)newCustNo;

- (void)insertCustNo:(NSString *)custno andCustName:(NSString *)custname andCustTel:(NSString *)custtel andCustAddr:(NSString *)custaddr andCustEmail:(NSString *)custemail;
- (void)updateCustNo:(NSString *)custno andCustName:(NSString *)custname andCustTel:(NSString *)custtel andCustAddr:(NSString *)custaddr andCustEmail:(NSString *)custemail;
- (void)deleteCustNo:(NSString *)custno;

- (void)insertCustDict:(NSDictionary *)dictCust;



@end
