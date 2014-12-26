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
    NSString* value = userInfo[CMPrefix];
    NSString* mapKey = (value) ? value : name;
    
    return mapKey;
}

- (NSString*) manyToManyTableName
{
    NSString* name = [NSString stringWithFormat:@"%@",self.name];
    NSDictionary* userInfo = [self userInfo];
    NSString* value = userInfo[CMManyToManyName];
    NSString* mapKey = (value) ? value : name;
    
    return mapKey;
}

- (NSNumber*) relationshipType
{
    NSRelationshipDescription* relation = self;
    NSRelationshipDescription* inverse = relation.inverseRelationship;
    
    if (!relation.isToMany && !inverse.isToMany) return @(CMOneToOne);
    if (relation.isToMany && !inverse.isToMany)  return @(CMOneToMany);
    if (!relation.isToMany && inverse.isToMany)  return @(CMManyToOne);
    if (relation.isToMany && inverse.isToMany)   return @(CMManyToMany);
    
    return nil;
}

- (NSString*) relationshipString
{
    NSRelationshipDescription* relation = self;
    NSRelationshipDescription* inverse = relation.inverseRelationship;
    
    if (!relation.isToMany && !inverse.isToMany) return @"OneToOne";
    if (relation.isToMany && !inverse.isToMany)  return @"OneToMany";
    if (!relation.isToMany && inverse.isToMany)  return @"ManyToOne";
    if (relation.isToMany && inverse.isToMany)   return @"ManyToMany";
    
    return nil;
}

@end
