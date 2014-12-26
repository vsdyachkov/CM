//
//  NSManagedObject+manager.h
//  CoreMapping
//
//  Created by Dyachkov Victor on 26.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreMapping.h"

@interface NSManagedObject (manager)

# pragma mark - Finding

+ (NSArray*) findRowsWithPredicate: (NSPredicate*) predicate andSortDescriptor: (NSSortDescriptor*) sortDescriptor;
+ (NSArray*) findRowsWithPredicate: (NSPredicate*) predicate;
+ (NSArray*) findAllRows;

# pragma mark - Finding first

+ (id) findFirstRowWithPredicate: (NSPredicate*) predicate andSortDescriptor: (NSSortDescriptor*) sortDescriptor;
+ (id) findFirstRowWithPredicate: (NSPredicate*) predicate;

# pragma mark - Inserting

+ (id) insert;

# pragma mark - Deleting

- (void) deleteObjects: (NSSet*) set;
- (void) deleteRow;
+ (void) deleteAllRows;


@end
