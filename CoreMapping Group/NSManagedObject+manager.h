//
//  NSManagedObject+manager.h
//  CoreMapping
//
//  Created by Dyachkov Victor on 26.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "CoreMapping.h"

@interface NSManagedObject (manager)

+ (NSArray*) findRowsWithPredicate: (NSPredicate*) predicate;
+ (NSArray*) findAllRows;
+ (id) findFirstRowWithPredicate: (NSPredicate*) predicate;

+ (void) deleteAllRows;

@end
