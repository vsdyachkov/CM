//
//  NSManagedObject+manager.m
//  CoreMapping
//
//  Created by Dyachkov Victor on 26.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "NSManagedObject+manager.h"

@implementation NSManagedObject (manager)

+ (NSArray*)findRowsWithPredicate: (NSPredicate*) predicate
{
    NSString* className = NSStringFromClass(self);
    NSEntityDescription* entity = [NSEntityDescription entityForName:className inManagedObjectContext:[CMCoreData managedObjectContext]];
    NSFetchRequest* request = [[NSFetchRequest alloc]initWithEntityName:entity.name];
    [request setPredicate:predicate];
    NSError* error;
    NSArray* arr = [[CMCoreData managedObjectContext] executeFetchRequest:request error:&error];
    if (error) NSLog(@"Error finding: %@",error.localizedDescription);
    return arr;
}

+ (NSArray*)findAllRows
{
    return [self findRowsWithPredicate:nil];
}

+ (id) findFirstRowWithPredicate: (NSPredicate*) predicate
{
    NSString* className = NSStringFromClass(self);
    NSEntityDescription* entity = [NSEntityDescription entityForName:className inManagedObjectContext:[CMCoreData managedObjectContext]];
    NSFetchRequest* request = [[NSFetchRequest alloc]initWithEntityName:entity.name];
    [request setFetchLimit:1];
	
	NSArray *results = [self findRowsWithPredicate:predicate];
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
        [[CMCoreData managedObjectContext] deleteObject:managedObject];
    }
    NSError* error;
    if (![[CMCoreData managedObjectContext] save:&error]) {
        NSLog(@"### Error: %@", error.localizedDescription);
    }
}

@end
