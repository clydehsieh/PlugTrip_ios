//
//  BCKeychainManager.h
//  Q_Send
//
//  Created by POWEN CHENG on 9/11/15.
//  Copyright (c) 2015 POWEN CHENG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BCKeychainManager : NSObject

+ (void)saveUUID:(NSString *)uuid;
+ (NSString *)loadUUID;

@end
