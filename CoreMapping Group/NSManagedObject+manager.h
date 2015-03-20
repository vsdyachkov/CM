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

+ (NSArray*) findRowsWithPredicate:(NSPredicate*)predicate andSortDescriptors:(NSArray*)sortDescriptors;
+ (NSArray*) findRowsWithPredicate:(NSPredicate*)predicate;
+ (NSArray*) findAllRowsWithSortDescriptors:(NSArray*)sortDescriptors;
+ (NSArray*) findAllRowsSortedBy:(NSString*)sortProperty ascending:(BOOL)ascending;
+ (NSArray*) findAllRows;

# pragma mark - Finding first

+ (id) findFirstRowWithPredicate:(NSPredicate*)predicate andSortDescriptors:(NSArray*)sortDescriptors;
+ (id) findFirstRowWithPredicate:(NSPredicate*)predicate sortedBy:(NSString*)sortProperty ascending:(BOOL)ascending;
+ (id) findFirstRowWithPredicate:(NSPredicate*)predicate;

# pragma mark - Inserting

+ (id) insert;

# pragma mark - Deleting

- (void) deleteObjects:(NSSet*)set;
- (void) deleteRow;
+ (void) deleteAllRows;


@end
