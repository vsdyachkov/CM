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
    NSString* value = userInfo[CoreDataPrefix];
    NSString* mapKey = (value) ? value : name;
    
    NSAssert(mapKey, @"%@ mapKey: %@", errNilParam, mapKey);
    return mapKey;
}


- (NSString*) mappingIdKey
{
    NSDictionary* attributes = [self attributesByName];
    __block NSString* key;
    [[attributes allValues] enumerateObjectsUsingBlock:^(NSAttributeDescription* attr, NSUInteger idx, BOOL *stop) {
        
        if ([attr.userInfo[CoreDataIdPrefix] isEqualToString:@"YES"]) {
            key = attr.name;
        }
        
    }];
    
    NSAssert(key, @"Table should have '%@ = YES' userinfo", CoreDataIdPrefix);
    
    return key;
}

- (NSString*) mappingIdValue
{
    NSDictionary* attributes = [self attributesByName];
    __block NSString* key;
    [[attributes allValues] enumerateObjectsUsingBlock:^(NSAttributeDescription* attr, NSUInteger idx, BOOL *stop) {
        
        if ([attr.userInfo[CoreDataIdPrefix] isEqualToString:@"YES"]) {
            NSString* mappingName = attr.userInfo[CoreDataPrefix];
            NSString* realName = attr.name;
            key = (mappingName) ? mappingName : realName;
            *stop = YES;
        }
        
    }];

    return key;
}

+ (void) findOfCreateObjectWithPredicate: (NSPredicate*) predicate
{
    //
}

@end
