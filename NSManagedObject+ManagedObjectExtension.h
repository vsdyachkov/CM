//
//  NSManagedObject+manager.h
//  CoreMapping
//
//  Created by Dyachkov Victor on 26.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (ManagedObjectExtension)

+ (NSArray*)findWithPredicate: (NSPredicate*) predicate;
+ (NSArray*)findAll;
+ (id)findFirstWithPredicate: (NSPredicate*) predicate;
+ (void)deleteAll;

@end
