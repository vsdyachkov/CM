//
//  NSEntityDescription+EntityExtension.m
//  CoreMapping
//
//  Created by Dyachkov Victor on 26.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "NSEntityDescription+mapping.h"

@implementation NSEntityDescription (mapping)

- (NSString*) mappingEntityName
{
    NSString* name = [NSString stringWithFormat:@"%@",self.name];
    NSDictionary* userInfo = [self userInfo];
    NSString* value = userInfo[CMPrefix];
    NSString* mapKey = (value) ? value : name;
    
    NSAssert(mapKey, @"%@ mapKey: %@", errNilParam, mapKey);
    return mapKey;
}


- (NSString*) mappingIdKey
{
    NSDictionary* attributes = [self attributesByName];
    __block NSString* key;
    [[attributes allValues] enumerateObjectsUsingBlock:^(NSAttributeDescription* attr, NSUInteger idx, BOOL *stop) {
        
        if ([attr.userInfo[CMIdPrefix] isEqualToString:@"YES"]) {
            key = attr.name;
        }
        
    }];
    NSAssert(key, @"Table should have '%@ = YES' userinfo", CMIdPrefix);
    return key;
}

- (NSString*) mappingIdValue
{
    NSDictionary* attributes = [self attributesByName];
    __block NSString* key;
    [[attributes allValues] enumerateObjectsUsingBlock:^(NSAttributeDescription* attr, NSUInteger idx, BOOL *stop)
    {
        if ([attr.userInfo[CMIdPrefix] isEqualToString:@"YES"]) {
            NSString* mappingName = attr.userInfo[CMPrefix];
            NSString* realName = attr.name;
            key = (mappingName) ? mappingName : realName;
            *stop = YES;
        }
    }];
    return key;
}

- (BOOL) isNoParse
{
    NSDictionary* userInfo = [self userInfo];
    NSString* value = userInfo[CMNoParse];
    return (value && [value isEqualToString:@"YES"]) ? YES : NO;
}

/*
+ (void) findOfCreateObjectWithPredicate: (NSPredicate*) predicate
{
    //
}
*/

@end
