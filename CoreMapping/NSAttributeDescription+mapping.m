//
//  NSAttributeDescription+AttributeExtension.m
//  CoreMapping
//
//  Created by Dyachkov Victor on 26.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "NSAttributeDescription+mapping.h"

@implementation NSAttributeDescription (mapping)

- (NSString*) mappingName
{
    NSString* name = [NSString stringWithFormat:@"%@",self.name];
    NSDictionary* userInfo = [self userInfo];
    NSString* value = userInfo[CoreDataPrefix];
    NSString* mapKey = (value) ? value : name;
    
    NSAssert(mapKey, @"%@ mapKey: %@", errParameter, mapKey);
    return mapKey;
}

@end
