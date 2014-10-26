//
//  CMHelper.m
//  CoreMapping
//
//  Created by Dyachkov Victor on 29.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "CMHelper.h"

@implementation CMHelper

+ (NSNumber*) relationshipIdFrom: (NSRelationshipDescription*) relation to: (NSRelationshipDescription*) inverse
{
    NSAssert(relation && inverse, @"%@ relation: %@, inverse: %@", errNilParam, relation, inverse);
    [CMTests checkRelationshipDescription:relation];
    [CMTests checkRelationshipDescription:inverse];
    
    if (!relation.isToMany && !inverse.isToMany) return @0;
    if (relation.isToMany && !inverse.isToMany)  return @1;
    if (!relation.isToMany && inverse.isToMany)  return @2;
    if (relation.isToMany && inverse.isToMany)   return @3;
    return nil;
}

+ (NSString*) relationshipNameWithId: (NSNumber*) number
{
    NSAssert(number, @"%@ number: %@", errNilParam, number);
    [CMTests isNumber:number];
    
    switch (number.intValue) {
        case 0: return @"OneToOne"; break;
        case 1: return @"OneToMany"; break;
        case 2: return @"ManyToOne"; break;
        case 3: return @"ManyToMany"; break;
        default: return nil; break;
    }
}


+ (NSDictionary*) jsonWithFileName: (NSString*) name
{
    NSAssert(name, @"%@ name: %@", errNilParam, name);
    [CMTests checkString:name];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:name ofType:@"json"];
    
    [CMTests checkString:filePath];
    
    NSData *myJSON = [NSData dataWithContentsOfFile:filePath];
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:myJSON options:kNilOptions error:nil];
    
    NSAssert(myJSON, @"Json %@ is not valid", filePath);
    return json;
}


@end
