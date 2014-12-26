//
//  CMCoreData.m
//  CoreMapping
//
//  Created by Dyachkov Victor on 25.10.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "CMCoreData.h"

@implementation CMCoreData

static NSPersistentStoreCoordinator* persistentStoreCoordinator;
static NSManagedObjectContext* managedObjectContext;
static NSManagedObjectContext* childManagedObjectContext;
static NSManagedObjectModel* managedObjectModel;

#pragma mark - SQL database configuration

+ (NSURL*) SQLFilePath;
{
    NSString* fileName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleNameKey];
    if (fileName == nil) fileName = CMSqlFileName;
    if (![fileName hasSuffix:@"sqlite"]) fileName = [fileName stringByAppendingPathExtension:@"sqlite"];
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:fileName];
    return storeURL;
}

+ (NSManagedObjectModel*) managedObjectModel
{
    if (managedObjectModel != nil)
        return managedObjectModel;
    
    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    
    if (managedObjectModel.entities.count == 0) {
        [CMTests CFLog:CMModelError];
        abort();
    }
    
    return managedObjectModel;
}

+ (NSPersistentStoreCoordinator*) persistentStoreCoordinator
{
    if (persistentStoreCoordinator != nil)
        return persistentStoreCoordinator;
    
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES};
    
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    NSError *error = nil;
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[self SQLFilePath] options:options error:&error]) {
        [[NSFileManager defaultManager] removeItemAtURL:[self SQLFilePath] error:nil];
        [CMTests CFLog:CMMigrationError];
        if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[self SQLFilePath] options:options error:&error]) {
            [CMTests CFLog:@"%@: %@", CMPersistentStoreError, error.localizedDescription];
            abort();
        } else {
            [CMTests CFLog:CMMigrationSuccess];
        }
        
    }
    
    return persistentStoreCoordinator;
}

#pragma mark - ManagedObjectContext configuration

+ (NSManagedObjectContext*) mainManagedObjectContext
{
    if (managedObjectContext != nil)
        return managedObjectContext;
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return managedObjectContext;
}

+ (NSManagedObjectContext *) childManagedObjectContext
{
    if (childManagedObjectContext != nil)
        return childManagedObjectContext;
    childManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [childManagedObjectContext setParentContext:[self mainManagedObjectContext]];
    return childManagedObjectContext;
}

+ (NSManagedObjectContext*) managedObjectContext
{
    return ([NSThread isMainThread]) ? [self mainManagedObjectContext] : [self childManagedObjectContext];
}

#pragma mark - Save context configuration

+ (void) saveMainContext
{
    NSError* error;
    [[self mainManagedObjectContext] save:&error];
    if (error) {
        [CMTests CFLog:@"%@: %@", CMSavingMainContextError, error.localizedDescription];
        abort();
    }
}

+ (void) saveChildContext
{
    NSError* error;
    [[self childManagedObjectContext] save:&error];
    if (error) {
        [CMTests CFLog:@"%@: %@", CMSavingChildContextError, error.localizedDescription];
        abort();
    }
}

+ (void) saveContext
{
    if ([NSThread isMainThread]) {
        [self saveMainContext];
    } else {
        [self saveChildContext];
        [[self mainManagedObjectContext] performBlock:^{
            [self saveMainContext];
        }];
    }
}

#pragma mark - Async database operation method

+ (void) databaseOperationInBackground: (void(^)()) block completion:(void(^)()) completion
{
    NSAssert([NSThread isMainThread], CMThreadError);
    
    NSManagedObjectContext *childManagedObjectContext = [CMCoreData childManagedObjectContext];
    [childManagedObjectContext performBlock:^{
        if (block) {
            block();
            [[CMCoreData mainManagedObjectContext] performBlock:^{
                completion();
            }];
        }
    }];
}

#pragma mark - Application's Documents directory


+ (NSURL*) applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - Helper methods

+ (void) clearDatabase
{
    NSArray *entities = [[[CMCoreData managedObjectModel] entities] valueForKey:@"name"];
    
    for (NSString* entityName in entities)
    {
        NSFetchRequest *fetchRequest = [NSFetchRequest new];
        NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:[CMCoreData mainManagedObjectContext]];
        [fetchRequest setEntity:entity];
        NSError *error;
        NSArray *items = [[CMCoreData managedObjectContext] executeFetchRequest:fetchRequest error:&error];
        for (NSManagedObject *managedObject in items) {
            [[CMCoreData managedObjectContext] deleteObject:managedObject];
        }
        if (![[CMCoreData managedObjectContext] save:&error]) {
            [CMTests CFLog:@"Error: %@",error.localizedDescription];
        }
    }
}

+ (void) status
{
    [self fullPrint:YES];
}

+ (void) shortStatus
{
    [self fullPrint:NO];
}

+ (void) fullPrint: (BOOL) full
{
    [CMTests CFLog:@"\nCurrent Core Data status:"];
    for (NSEntityDescription* entityDescription in [[CMCoreData managedObjectModel] entities])
    {
        
        NSFetchRequest* request = [[NSFetchRequest alloc]initWithEntityName:entityDescription.name];
        
        NSArray* arr = [[CMCoreData managedObjectContext] executeFetchRequest:request error:nil];
        if (full)
            [CMTests CFLog:@"\n"];
        [CMTests CFLog:@"[i] %@: %lu rows\n", entityDescription.name, (unsigned long)arr.count];
        if (full) {
            [CMTests CFLog:@"\n"];
        } else {
            continue;
        }
        [arr enumerateObjectsUsingBlock:^(NSManagedObject* obj, NSUInteger idx, BOOL *stop) {
            [CMTests CFLog:@"- %@\n\n", obj];
        }];
        if (arr.count < 1)
            [CMTests CFLog:@"- <Empty>"];
    }
}

@end
