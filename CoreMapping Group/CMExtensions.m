//
//  NSRelationshipDescription+mapping.m
//  CoreMapping
//
//  Created by Dyachkov Victor on 28.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "CMExtensions.h"

#pragma mark - Validate method

@implementation CMExtensions

+ (id) validateValue: (id) value withClass: (Class) myClass
{
    return (!value || ![value isKindOfClass:myClass]) ? nil : value;
}

@end

#pragma mark - NSObject performing method

@implementation NSObject (performing)

- (BOOL) performSelectorIfResponseFromString: (NSString*) name withObject: (id) object
{
    [CMExtensions validateValue:name withClass:[NSString class]];
    
    if ([self respondsToSelector:NSSelectorFromString(name)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        @try { [self performSelector:NSSelectorFromString(name) withObject:object]; }
        @catch (NSException *exception) { return NO; }
        @finally { return YES; }
#pragma clang diagnostic pop
        return YES;
    } else {
        return NO;
    }
}

@end

#pragma mark - NSAttributeDescription mapping method

@implementation NSAttributeDescription (mapping)

- (NSString*) mappingName
{
    NSString* name = [NSString stringWithFormat:@"%@",self.name];
    NSDictionary* userInfo = [self userInfo];
    NSString* value = userInfo[CMPrefix];
    NSString* mapKey = (value) ? value : name;
    
    return mapKey;
}

@end

#pragma mark - NSEntityDescription mapping method

@implementation NSEntityDescription (mapping)

- (NSString*) mappingEntityName
{
    NSString* name = [NSString stringWithFormat:@"%@",self.name];
    NSDictionary* userInfo = [self userInfo];
    NSString* value = userInfo[CMPrefix];
    NSString* mapKey = (value) ? value : name;
    
    return mapKey;
}

- (NSString*) mappingIdKey
{
    NSDictionary* attributes = [self attributesByName];
    __block NSString* key = nil;
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

@end

#pragma mark - NSRelationshipDescription mapping method

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
    NSDictionary* userInfo = [self userInfo];
    NSString* value = userInfo[CMManyToManyName];
    NSString* mapKey = (value) ? value : nil;
    
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
