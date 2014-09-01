//
//  NSRelationshipDescription+mapping.m
//  CoreMapping
//
//  Created by Dyachkov Victor on 28.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "CMExtensions.h"

@implementation NSRelationshipDescription (mapping)

- (NSString*) mappingName
{
    NSString* name = [NSString stringWithFormat:@"%@",self.name];
    NSDictionary* userInfo = [self userInfo];
    NSString* value = userInfo[CoreDataPrefix];
    NSString* mapKey = (value) ? value : name;
    
    NSAssert(mapKey, @"%@ mapKey: %@", errNilParam, mapKey);
    return mapKey;
}

@end
