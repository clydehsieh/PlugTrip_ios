//
//  BCKeychainManager.m
//  Q_Send
//
//  Created by POWEN CHENG on 9/11/15.
//  Copyright (c) 2015 POWEN CHENG. All rights reserved.
//

#import "BCKeychainManager.h"
#import <Security/Security.h>

static NSString * const KEY_UUID = @"com.ktb.uuid";

@implementation BCKeychainManager

+ (void)saveUUID:(NSString *)uuid {
    
    NSDictionary *uuidDic = @{@"UUID":uuid};
    [BCKeychainManager save:KEY_UUID data:uuidDic];
}

+ (NSString *)loadUUID {
    
    NSDictionary *uuidDic = (NSDictionary *)[BCKeychainManager load:KEY_UUID];
    return uuidDic[@"UUID"];
}

+ (NSMutableDictionary *)getKeyChainQuery:(NSString *)serivce {
    
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            (__bridge id)kSecClassGenericPassword,(__bridge id)kSecClass,
            serivce,(__bridge id)kSecAttrService,
            serivce,(__bridge id)kSecAttrAccount,
            (__bridge id)kSecAttrAccessibleAfterFirstUnlock,(__bridge id)kSecAttrAccessible,
            nil];
}

+ (void)save:(NSString *)service data:(id)data {
    
    NSMutableDictionary *keychainQuery = [BCKeychainManager getKeyChainQuery:service];
    SecItemDelete((__bridge CFDictionaryRef)(keychainQuery));
    [keychainQuery setObject:[NSKeyedArchiver archivedDataWithRootObject:data] forKey:(__bridge id)kSecValueData];
    SecItemAdd((__bridge CFDictionaryRef)keychainQuery, NULL);
}

+ (id)load:(NSString *)service {
    
    id ret = nil;
    NSMutableDictionary *keychainQuery = [BCKeychainManager getKeyChainQuery:service];
    [keychainQuery setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [keychainQuery setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
//    CFDataRef keyData = NULL;
    CFTypeRef result;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, &result) == noErr) {
        @try {
            ret = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)result];
        }
        @catch (NSException *exception) {
            NSLog(@"unarchive of %@ failed %@",service,exception);
        }
        @finally {
            
        }
    }
//    if (result) {
//        CFRelease(result);
//    }
    return ret;
}

@end
