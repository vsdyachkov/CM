//
//  NSManagedObject+manager.m
//  CoreMapping
//
//  Created by Dyachkov Victor on 26.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "NSManagedObject+manager.h"

@implementation NSManagedObject (manager)

+ (NSArray*)findRowWithPredicate: (NSPredicate*) predicate
{
    NSString* className = NSStringFromClass(self);
    NSEntityDescription* entity = [NSEntityDescription entityForName:className inManagedObjectContext:[CoreMapping managedObjectContext]];
    NSFetchRequest* request = [[NSFetchRequest alloc]initWithEntityName:entity.name];
    [request setPredicate:predicate];
    NSError* error;
    NSArray* arr = [[CoreMapping managedObjectContext] executeFetchRequest:request error:&error];
    if (error) NSLog(@"Error finding: %@",error.localizedDescription);
    return arr;
}

+ (NSArray*)findAllRows
{
    return [self findRowWithPredicate:nil];
}

+ (id) findFirstRowWithPredicate: (NSPredicate*) predicate
{
    NSString* className = NSStringFromClass(self);
    NSEntityDescription* entity = [NSEntityDescription entityForName:className inManagedObjectContext:[CoreMapping managedObjectContext]];
    NSFetchRequest* request = [[NSFetchRequest alloc]initWithEntityName:entity.name];
    [request setFetchLimit:1];
	
	NSArray *results = [self findRowWithPredicate:predicate];
	if (results.count > 0) {
		return results [0];
	} else {
        return nil;
    }
}

+ (void)deleteAllRows
{
    NSArray *items = [self findAllRows];
    for (NSManagedObject *managedObject in items) {
        [[CoreMapping managedObjectContext] deleteObject:managedObject];
    }
    NSError* error;
    if (![[CoreMapping managedObjectContext] save:&error]) {
        NSLog(@"Error: %@", error.localizedDescription);
    }
}

@end
