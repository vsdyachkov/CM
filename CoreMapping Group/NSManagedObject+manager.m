//
//  NSManagedObject+manager.m
//  CoreMapping
//
//  Created by Dyachkov Victor on 26.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "NSManagedObject+manager.h"

@implementation NSManagedObject (manager)

# pragma mark - Helper method

+ (NSFetchRequest*) requestWithPredicate:(NSPredicate*)predicate
{
    NSString* className = NSStringFromClass(self);
    NSEntityDescription* entity = [NSEntityDescription entityForName:className inManagedObjectContext:[CMCoreData managedObjectContext]];
    NSFetchRequest* request = [[NSFetchRequest alloc]initWithEntityName:entity.name];
    [request setPredicate:predicate];
    return request;
}

# pragma mark - Finding

+ (NSArray*) findRowsWithPredicate:(NSPredicate*)predicate andSortDescriptors:(NSArray*)sortDescriptors
{
    NSFetchRequest* request = [self requestWithPredicate:predicate];
    if (sortDescriptors) [request setSortDescriptors:sortDescriptors];
    NSError* error;
    NSArray* arr = [[CMCoreData managedObjectContext] executeFetchRequest:request error:&error];
    if (error) printf ("%s\n", [[NSString stringWithFormat:@"[!] Error finding: %@",error.localizedDescription] UTF8String]);
    return arr;
}

+ (NSArray*) findRowsWithPredicate: (NSPredicate*) predicate
{
    return [self findRowsWithPredicate:predicate andSortDescriptors:nil];
}

+ (NSArray*) findAllRows
{
    return [self findRowsWithPredicate:nil];
}

# pragma mark - Finding first

+ (id) findFirstRowWithPredicate:(NSPredicate*)predicate andSortDescriptors:(NSArray*)sortDescriptors
{
    NSFetchRequest* request = [self requestWithPredicate:predicate];
    if (sortDescriptors) [request setSortDescriptors:sortDescriptors];
    [request setFetchLimit:1];
    NSError* error;
    NSArray* results = [[CMCoreData managedObjectContext] executeFetchRequest:request error:&error];
    if (error) printf ("%s\n", [[NSString stringWithFormat:@"[!] Find object error: %@",error.localizedDescription] UTF8String]);
    if (results.count > 0) {
        return results [0];
    } else {
        return nil;
    }
}

+ (id) findFirstRowWithPredicate:(NSPredicate*)predicate
{
    return [self findFirstRowWithPredicate:predicate andSortDescriptors:nil];
}

# pragma mark - Inserting

+ (id) insert
{
    NSString* className = NSStringFromClass([self class]);
    return [NSEntityDescription insertNewObjectForEntityForName:className inManagedObjectContext:[CMCoreData managedObjectContext]];
}

# pragma mark - Deleting

- (void) deleteObjects:(NSSet*)set
{
    NSString* className;
    for (NSManagedObject* obj in set) {
        className = NSStringFromClass([obj class]);
        [obj deleteRow];
    }
    NSString* selectorName = [NSString stringWithFormat:@"remove%@s:", className];
    [self performSelectorIfResponseFromString:selectorName withObject:set];
    NSError* error;
    if (![[CMCoreData managedObjectContext] save:&error]) {
        if (error) printf ("%s\n", [[NSString stringWithFormat:@"[!] Delete object error: %@",error.localizedDescription] UTF8String]);
    }
    
}

- (void) deleteRow
{
    [[CMCoreData managedObjectContext] deleteObject:self];
}

+ (void) deleteAllRows
{
    NSArray *items = [self findAllRows];
    for (NSManagedObject *managedObject in items) {
        [[CMCoreData managedObjectContext] deleteObject:managedObject];
    }
    NSError* error;
    if (![[CMCoreData managedObjectContext] save:&error]) {
        printf ("%s\n", [[NSString stringWithFormat:@"[!] Delete objects error: %@",error.localizedDescription] UTF8String]);
    }
}

@end
