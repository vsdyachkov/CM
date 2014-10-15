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
    if (![self isArray:object]) NSLog(@"%@ %@ is not NSArray", errInvalidClassParam, NSStringFromClass([object class]));
    NSAssert([self isArray:object], @"%@ %@ is not NSArray", errInvalidClassParam, NSStringFromClass([object class]));
}

+ (void) checkDictionary: (id) object
{
    if (![self isDictionary:object]) NSLog(@"%@ %@ is not NSDictionary", errInvalidClassParam, NSStringFromClass([object class]));
    NSAssert([self isDictionary:object], @"%@ %@ is not NSDictionary", errInvalidClassParam, NSStringFromClass([object class]));
}

+ (void) checkNumber: (id) object
{
    if (![self isNumber:object]) NSLog(@"%@ %@ is not NSNumber", errInvalidClassParam, NSStringFromClass([object class]));
    NSAssert([self isNumber:object], @"%@ %@ is not NSNumber", errInvalidClassParam, NSStringFromClass([object class]));
}

+ (void) checkString: (id) object
{
    if (![self isString:object]) NSLog(@"%@ %@ is not NSString", errInvalidClassParam, NSStringFromClass([object class]));
    NSAssert([self isString:object], @"%@ %@ is not NSString", errInvalidClassParam, NSStringFromClass([object class]));
}

+ (void) checkEntityDescription: (id) object
{
    if (![self isEntityDescription:object]) NSLog(@"%@ %@ is not NSEntityDescription", errInvalidClassParam, NSStringFromClass([object class]));
    NSAssert([self isEntityDescription:object], @"%@ %@ is not NSEntityDescription", errInvalidClassParam, NSStringFromClass([object class]));
}

+ (void) checkManagedObject: (id) object
{
    if (![self isManagedObject:object]) NSLog(@"%@ %@ is not NSManagedObject", errInvalidClassParam, NSStringFromClass([object class]));
    NSAssert([self isManagedObject:object], @"%@ %@ is not NSManagedObject", errInvalidClassParam, NSStringFromClass([object class]));
}

+ (void) checkRelationshipDescription: (id) object
{
    if (![self isRelationshipDescription:object]) NSLog(@"%@ %@ is not NSRelationshipDescription", errInvalidClassParam, NSStringFromClass([object class]));
    NSAssert([self isRelationshipDescription:object], @"%@ %@ is not NSRelationshipDescription", errInvalidClassParam, NSStringFromClass([object class]));
}


@end
