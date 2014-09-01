//
//  CMTest.m
//  CoreMapping
//
//  Created by Dyachkov Victor on 29.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "CMTests.h"

@implementation CMTests

// validate

+ (NSArray*) validateArray: (id) object
{
    if (object && [object isKindOfClass:[NSArray class]]) {
        return (NSArray*) object;
    } else {
        return nil;
    }
}

// detect

+ (BOOL) isArray: (id) object
{
    return (object && [object isKindOfClass:[NSArray class]]) ? YES : NO;
}

+ (BOOL) isDictionary: (id) object
{
    return (object && [object isKindOfClass:[NSDictionary class]]) ? YES : NO;
}

+ (BOOL) isNumber: (id) object
{
    return (object && [object isKindOfClass:[NSNumber class]]) ? YES : NO;
}

+ (BOOL) isString: (id) object
{
    return (object && [object isKindOfClass:[NSString class]]) ? YES : NO;
}

+ (BOOL) isEntityDescription: (id) object
{
    return (object && [object isKindOfClass:[NSEntityDescription class]]) ? YES : NO;
}

+ (BOOL) isManagedObject: (id) object
{
    return (object && [object isKindOfClass:[NSManagedObject class]]) ? YES : NO;
}

+ (BOOL) isRelationshipDescription: (id) object
{
    return (object && [object isKindOfClass:[NSRelationshipDescription class]]) ? YES : NO;
}

// check

+ (void) checkArray: (id) object
{
    BOOL result = [self isArray:object];
    NSAssert(result, @"%@ %@ is not NSArray", errInvalidClassParam, NSStringFromClass([object class]));
}

+ (void) checkDictionary: (id) object
{
    BOOL result = [self isDictionary:object];
    NSAssert(result, @"%@ %@ is not NSDictionary", errInvalidClassParam, NSStringFromClass([object class]));
}

+ (void) checkNumber: (id) object
{
    BOOL result = [self isNumber:object];
    NSAssert(result, @"%@ %@ is not NSNumber", errInvalidClassParam, NSStringFromClass([object class]));
}

+ (void) checkString: (id) object
{
    BOOL result = [self isString:object];
    NSAssert(result, @"%@ %@ is not NSString", errInvalidClassParam, NSStringFromClass([object class]));
}

+ (void) checkEntityDescription: (id) object
{
    BOOL result = [self isEntityDescription:object];
    NSAssert(result, @"%@ %@ is not NSEntityDescription", errInvalidClassParam, NSStringFromClass([object class]));
}

+ (void) checkManagedObject: (id) object
{
    BOOL result = [self isManagedObject:object];
    NSAssert(result, @"%@ %@ is not NSManagedObject", errInvalidClassParam, NSStringFromClass([object class]));
}

+ (void) checkRelationshipDescription: (id) object
{
    BOOL result = [self isRelationshipDescription:object];
    NSAssert(result, @"%@ %@ is not NSRelationshipDescription", errInvalidClassParam, NSStringFromClass([object class]));
}


@end
