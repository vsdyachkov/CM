//
//  CMTest.h
//  CoreMapping
//
//  Created by Dyachkov Victor on 29.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CMTests : NSObject

+ (NSArray*) validateArray: (id) object;

+ (BOOL) isArray: (id) object;
+ (BOOL) isDictionary: (id) object;
+ (BOOL) isNumber: (id) object;
+ (BOOL) isString: (id) object;
+ (BOOL) isEntityDescription: (id) object;
+ (BOOL) isManagedObject: (id) object;
+ (BOOL) isRelationshipDescription: (id) object;

+ (void) checkArray: (id) object;
+ (void) checkDictionary: (id) object;
+ (void) checkNumber: (id) object;
+ (void) checkString: (id) object;
+ (void) checkEntityDescription: (id) object;
+ (void) checkManagedObject: (id) object;
+ (void) checkRelationshipDescription: (id) object;

@end
