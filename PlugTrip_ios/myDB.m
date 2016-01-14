//
//  myDB.m
//  CustManager
//
//  Created by Stronger Shen on 2014/10/13.
//  Copyright (c) 2014年 MobileIT. All rights reserved.
//

#import "myDB.h"

myDB *sharedInstance;

@implementation myDB

- (void)loadDB
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [paths firstObject];
    NSString *dbPath = [documentPath stringByAppendingPathComponent:@"mydatabase.sqlite"];
    
    db = [FMDatabase databaseWithPath:dbPath];
    if (![db open]) {
        NSLog(@"Could not open db.");
        return;
    }
}

- (id)init
{
    self=[super init];
    if (self) {
        [self loadDB];
    }
    return self;
}

+ (myDB *)sharedInstance
{
    if (sharedInstance==nil) {
        sharedInstance = [[myDB alloc] init];
    }
    return sharedInstance;
}

#pragma mark - db methods

- (id)queryCust
{
    NSMutableArray *rows = [NSMutableArray arrayWithCapacity:0];
    
    FMResultSet *result = [db executeQuery:@"SELECT * FROM cust ORDER BY rowid"];
    while ([result next]) {
/*
        NSString *cust_no = [result stringForColumn:@"cust_no"];
        NSString *cust_name = [result stringForColumn:@"cust_name"];
        NSString *cust_tel = [result stringForColumn:@"cust_tel"];
        NSString *cust_addr = [result stringForColumn:@"cust_addr"];
        NSString *cust_email = [result stringForColumn:@"cust_email"];

        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                              cust_no, @"cust_no",
                              cust_name, @"cust_name",
                              cust_tel, @"cust_tel",
                              cust_addr, @"cust_addr",
                              cust_email, @"cust_email",
                              nil];
        [rows addObject:dict];
 */
        
        [rows addObject:result.resultDictionary];
    }
    
    return rows;
}

- (id)queryCustName:(NSString *)custname
{
    NSMutableArray *rows = [NSMutableArray arrayWithCapacity:0];
    
    NSString *query = [NSString stringWithFormat:@"%@%%", custname];
    FMResultSet *result = [db executeQuery:@"SELECT * FROM cust where cust_name like ? ORDER BY cust_no", query];
    while ([result next]) {
        NSString *cust_no = [result stringForColumn:@"cust_no"];
        NSString *cust_name = [result stringForColumn:@"cust_name"];
        NSString *cust_tel = [result stringForColumn:@"cust_tel"];
        NSString *cust_addr = [result stringForColumn:@"cust_addr"];
        NSString *cust_email = [result stringForColumn:@"cust_email"];

        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                              cust_no, @"cust_no",
                              cust_name, @"cust_name",
                              cust_tel, @"cust_tel",
                              cust_addr, @"cust_addr",
                              cust_email, @"cust_email",
                              nil];
        
        [rows addObject:dict];
    }
    
    return rows;
}

- (NSString *)newCustNo
{
    int maxno = 1;
    FMResultSet *result = [db executeQuery:@"SELECT max(cust_no) FROM cust ORDER BY cust_no"];
    while ([result next]) {
        maxno = [result intForColumnIndex:0]+1;
    }
    
    return [NSString stringWithFormat:@"%03d", maxno];
}

- (void)insertCustNo:(NSString *)custno andCustName:(NSString *)custname andCustTel:(NSString *)custtel andCustAddr:(NSString *)custaddr andCustEmail:(NSString *)custemail
{
    if (![db executeUpdate:@"INSERT INTO cust (cust_no,cust_name,cust_tel,cust_addr,cust_email) VALUES (?,?,?,?,?)",custno,custname,custtel,custaddr,custemail]) {
        NSLog(@"Could not insert data: %@", [db lastErrorMessage]);
    }
    
}

- (void)updateCustNo:(NSString *)custno andCustName:(NSString *)custname andCustTel:(NSString *)custtel andCustAddr:(NSString *)custaddr andCustEmail:(NSString *)custemail
{
    if (![db executeUpdate:@"UPDATE cust SET cust_name=?,cust_tel=?,cust_addr=?,cust_email=? WHERE cust_no=?",custname,custtel,custaddr,custemail,custno]) {
        NSLog(@"Could not update data: %@", [db lastErrorMessage]);
    }
}

- (void)deleteCustNo:(NSString *)custno
{
    if (![db executeUpdate:@"DELETE FROM cust WHERE cust_no=?", custno]) {
        NSLog(@"Could not delete data: %@", [db lastErrorMessage]);
    }
}

- (void)insertCustDict:(NSDictionary *)dictCust
{
    /*
     "member_addr"   "cust_addr"
     "member_email"  "cust_email"
     "member_id"     "cust_no"
     "member_name"   "cust_name"
     "member_phone"  "cust_tel"
     */
    
    NSString *query = [NSString stringWithFormat:@"%@", [dictCust objectForKey:@"member_id"]];
    FMResultSet *rs = [db executeQuery:@"select count(*) as RECS from cust where cust_no = ?", query];
    
    while ([rs next]) {
        if ([rs intForColumn:@"RECS"]==0)
        {
            if (![db executeUpdate:@"insert into cust (cust_no,cust_name,cust_tel,cust_email,cust_addr) values (?,?,?,?,?)",
                  [dictCust objectForKey:@"member_id"],
                  [dictCust objectForKey:@"member_name"],
                  [dictCust objectForKey:@"member_phone"],
                  [dictCust objectForKey:@"member_email"],
                  [dictCust objectForKey:@"member_addr"]]) {
                NSLog(@"Could not insert data: %@", [db lastErrorMessage]);
            }
        }
    }
}


#pragma mark - Images
-(void)createTripTable:(NSString *)tableName{
    
    NSString *createInfo = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (imageLatitude TEXT, imageLongtitude TEXT, imagePath TEXT,comments TEXT,voicePath TEXT,interaction BOOL)",tableName];
    
    if(![db executeUpdate:createInfo])
    {
        NSLog(@"Could not create table: %@", [db lastErrorMessage]);
    }
}

-(void)createGPSTable:(NSString *)tableName{
    
    NSString *createInfo = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (imageLatitude TEXT, imageLongtitude TEXT, createTime TEXT)",tableName];
    
    if(![db executeUpdate:createInfo])
    {
        NSLog(@"Could not create table: %@", [db lastErrorMessage]);
    }
}

-(void)deleteTable:(NSString *)tableName{
    
    NSString *deleteInfo = [NSString stringWithFormat:@"DROP TABLE %@ ",tableName];
    
    if(![db executeUpdate:deleteInfo])
    {
        NSLog(@"Could not delete table: %@", [db lastErrorMessage]);
    }
}

-(void)insertTable:(NSString *)tableName andImageLatitude:(NSString *)imageLatitude andImageLongtitude:(NSString *)imageLongtitude ImagePath:(NSString *)imagePath andComments:(NSString *)comments andVoicePath:(NSString *)voicePath andHiddenState:(NSString *)Hidden{
    
    NSString *insertInfo = [NSString stringWithFormat:@"INSERT INTO %@ (imageLatitude,imageLongtitude,imagePath,comments,voicePath) VALUES (?,?,?,?,?)",tableName];
    
    if (![db executeUpdate:insertInfo,imageLatitude,imageLongtitude,imagePath,comments,voicePath]) {
        NSLog(@"Could not insert data: %@", [db lastErrorMessage]);
    }

}

-(void)insertGPSTable:(NSString *)tableName andLatitude:(NSString *)latitude andLongtitude:(NSString *)longtitude{
    
    NSString *insertInfo = [NSString stringWithFormat:@"INSERT INTO %@ (imageLatitude,imageLongtitude) VALUES (?,?)",tableName];
    
    if (![db executeUpdate:insertInfo,latitude,longtitude]) {
        NSLog(@"Could not insert data: %@", [db lastErrorMessage]);
    }
    
}


-(void)updateTable:(NSString *)tableName andRowid:(NSString *)rowid andImageLatitude:(NSString *)imageLatitude andImageLongtitude:(NSString *)imageLongtitude ImagePath:(NSString *)imagePath andComments:(NSString *)comments andVoicePath:(NSString *)voicePath andHiddenState:(NSString *)Hidden{
    
    NSString *insertInfo = [NSString stringWithFormat:@"UPDATE %@ SET imageLatitude=?,imageLongtitude=?, imagePath=?,comments=?,voicePath=? WHERE rowid=?",tableName];

    if (![db executeUpdate:insertInfo,imageLatitude,imageLongtitude,imagePath,comments,voicePath,rowid]) {
        NSLog(@"Could not update data: %@", [db lastErrorMessage]);
    }
    
}

- (id)queryWithTableName:(NSString *)tableName{
    
    NSMutableArray *rows = [NSMutableArray arrayWithCapacity:0];
    NSString *queryRequest = [NSString stringWithFormat:@"SELECT * FROM %@ ORDER BY rowid",tableName];
    
    FMResultSet *result = [db executeQuery:queryRequest];
    while ([result next]) {
        /*
         NSString *cust_no = [result stringForColumn:@"cust_no"];
         NSString *cust_name = [result stringForColumn:@"cust_name"];
         NSString *cust_tel = [result stringForColumn:@"cust_tel"];
         NSString *cust_addr = [result stringForColumn:@"cust_addr"];
         NSString *cust_email = [result stringForColumn:@"cust_email"];
         
         NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
         cust_no, @"cust_no",
         cust_name, @"cust_name",
         cust_tel, @"cust_tel",
         cust_addr, @"cust_addr",
         cust_email, @"cust_email",
         nil];
         [rows addObject:dict];
         */
        
        [rows addObject:result.resultDictionary];
    }
    
    return rows;
}

- (void)deleteTripInfo:(NSString *)rowid{
    
//    if (![db executeUpdate:@"DELETE FROM tripInfo WHERE rowid=?", rowid]) {
//        NSLog(@"Could not delete data: %@", [db lastErrorMessage]);
//    }
    
    if (![db executeUpdate:@"DELETE FROM tripInfo WHERE rowid=?", rowid]) {
        NSLog(@"Could not delete data: %@", [db lastErrorMessage]);
    }
    
}





@end
