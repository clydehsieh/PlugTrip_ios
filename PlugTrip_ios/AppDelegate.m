//
//  AppDelegate.m
//  PlugTrip_ios
//
//  Created by Chin-Hui Hsieh  on 12/22/15.
//  Copyright © 2015 Chin-Hui Hsieh. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (NSString *)GetDBPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [paths firstObject];
    NSString *dbPath = [documentPath stringByAppendingPathComponent:@"mydatabase.sqlite"];
    
    return dbPath;
}

- (void)CopyDBtoDocumentIfNeeded
{
    //可讀寫 db: Document 內 實際資料
    NSString *dbPath = [self GetDBPath];
    NSLog(@"dbPath: %@",dbPath);
    
    //發佈安裝時，在套件 Bundle 的原始 db, 只可以讀取
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"mydatabase.sqlite"];
    NSLog(@"defaultDBPath: %@",defaultDBPath);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    
    BOOL success = [fileManager fileExistsAtPath:dbPath];
    if (!success) {
        success = [fileManager copyItemAtPath:defaultDBPath toPath:dbPath error:&error];
        if (!success) {
            NSLog(@"Error: %@", [error description]);
        }
    } else {
        /*
         異動 db/table 資料結構 用
         1.連上 db server 詢問 db 版本
         2.如果需要更新，alert 問 user
         3.user 確定更新，下載新的 db 下來，並處理資料異動
         */
    }
}



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    //Google map api key
    [GMSServices provideAPIKey:@"AIzaSyAzolK7vi8CRudWzw42AoYsGH6PDEic8bA"];
    
    //local db
     [self CopyDBtoDocumentIfNeeded];
    
    // Initialize Parse.
    [Parse enableLocalDatastore];
    [Parse setApplicationId:@"nGE6doL5SP4k9DJTWRUeevqVM6iANkL1XFavb7X0"
                  clientKey:@"ZAbh6NUI53puW5CbSDzTq3yksrTp5kTozDKOoyNa"];
    // Register for Push Notitications
    UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                    UIUserNotificationTypeBadge |
                                                    UIUserNotificationTypeSound);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                             categories:nil];
    [application registerUserNotificationSettings:settings];
    [application registerForRemoteNotifications];
    
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
//    [PFPush handlePush:userInfo];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ChatRoomInfo" object:nil userInfo:userInfo];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
