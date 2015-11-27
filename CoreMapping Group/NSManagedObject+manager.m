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

# pragma mark - Finding with id

+ (instancetype) findObjectWithId:(NSNumber*)idObj
{
    NSString* className = NSStringFromClass(self);
    NSEntityDescription* entity = [NSEntityDescription entityForName:className inManagedObjectContext:[CMCoreData managedObjectContext]];
    
    NSFetchRequest* req = [[NSFetchRequest alloc]initWithEntityName:className];
    NSString* idKey = [entity mappingIdKey];
    NSPredicate* myPred = [NSPredicate predicateWithFormat:@"%K == %@", idKey, idObj];
    [req setPredicate:myPred];
    
    NSArray* arr = [[CMCoreData managedObjectContext] executeFetchRequest:req error:nil];
    return (arr.count > 0) ? arr[0] : nil;
}

# pragma mark - Finding

+ (NSArray*) findRowsWithPredicate:(NSPredicate*)predicate andSortDescriptors:(NSArray*)sortDescriptors
{
    NSFetchRequest* request = [self requestWithPredicate:predicate];
    if (sortDescriptors) [request setSortDescriptors:sortDescriptors];
    NSError* error;
    NSArray* arr;
    @try {
        arr = [[CMCoreData managedObjectContext] executeFetchRequest:request error:&error];
    }
    @catch (NSException *exception) {
        if (exception) printf ("%s\n", [[NSString stringWithFormat:@"[!] Request error: %@", exception.description] UTF8String]);
    }
    @finally {
        if (error) printf ("%s\n", [[NSString stringWithFormat:@"[!] Error finding: %@",error.localizedDescription] UTF8String]);
        return arr;
    }
}

+ (NSArray*) findRowsWithPredicate:(NSPredicate*)predicate sortedBy:(NSString*)sortProperty ascending:(BOOL)ascending
{
    NSString* className = NSStringFromClass(self);
    NSEntityDescription* entity = [NSEntityDescription entityForName:className inManagedObjectContext:[CMCoreData managedObjectContext]];
    NSArray* arrayOfProperties = entity.attributesByName.allKeys;
    
    if (![arrayOfProperties containsObject:sortProperty]) {
        printf ("%s\n", [[NSString stringWithFormat:@"[!] Entity '%@' don't contain property: '%@'", entity.name, sortProperty] UTF8String]);
        return nil;
    } else {
        NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:sortProperty ascending:ascending];
        return [self findRowsWithPredicate:predicate andSortDescriptors:@[sortDescriptor]];
    }
}

+ (NSArray*) findRowsWithPredicate:(NSPredicate*)predicate
{
    return [self findRowsWithPredicate:predicate andSortDescriptors:nil];
}

+ (NSArray*) findAllRowsWithSortDescriptors:(NSArray*)sortDescriptors
{
    return [self findRowsWithPredicate:nil andSortDescriptors:sortDescriptors];
}

+ (NSArray*) findAllRowsSortedBy:(NSString*)sortProperty ascending:(BOOL)ascending
{
    NSString* className = NSStringFromClass(self);
    NSEntityDescription* entity = [NSEntityDescription entityForName:className inManagedObjectContext:[CMCoreData managedObjectContext]];
    NSArray* arrayOfProperties = entity.attributesByName.allKeys;
    
    if (![arrayOfProperties containsObject:sortProperty]) {
        printf ("%s\n", [[NSString stringWithFormat:@"[!] Entity '%@' don't contain property: '%@'", entity.name, sortProperty] UTF8String]);
        return nil;
    } else {
        NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:sortProperty ascending:ascending];
        return [self findRowsWithPredicate:nil andSortDescriptors:@[sortDescriptor]];
    }
}

+ (NSArray*) findAllRows
{
    return [self findRowsWithPredicate:nil];
}

# pragma mark - Finding first

+ (instancetype) findFirstRowWithPredicate:(NSPredicate*)predicate andSortDescriptors:(NSArray*)sortDescriptors
{
    NSFetchRequest* request = [self requestWithPredicate:predicate];
    if (sortDescriptors) [request setSortDescriptors:sortDescriptors];
    [request setFetchLimit:1];
    NSError* error;
    NSArray* results;
    @try {
        results = [[CMCoreData managedObjectContext] executeFetchRequest:request error:&error];
    }
    @catch (NSException *exception) {
        if (exception) printf ("%s\n", [[NSString stringWithFormat:@"[!] Request error: %@", exception.description] UTF8String]);
    }
    @finally {
        if (error) printf ("%s\n", [[NSString stringWithFormat:@"[!] Find object error: %@",error.localizedDescription] UTF8String]);
        if (results.count > 0) {
            return results [0];
        } else {
            return nil;
        }
    }
}

+ (instancetype) findFirstRowWithPredicate:(NSPredicate*)predicate sortedBy:(NSString*)sortProperty ascending:(BOOL)ascending
{
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:sortProperty ascending:ascending];
    return [self findFirstRowWithPredicate:predicate andSortDescriptors:@[sortDescriptor]];
}

+ (instancetype) findFirstRowWithPredicate:(NSPredicate*)predicate
{
    return [self findFirstRowWithPredicate:predicate andSortDescriptors:nil];
}

# pragma mark - Inserting

+ (instancetype) insert
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