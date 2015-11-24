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
    
    @try {
        managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    }
    
    @catch (NSException *exception)
    {
        printf ("[!] %s\n", exception.description.UTF8String);
        
        NSString *bundleRoot = [[NSBundle mainBundle] bundlePath];
        NSFileManager *fm = [NSFileManager defaultManager];
        NSArray *dirContents = [fm contentsOfDirectoryAtPath:bundleRoot error:nil];
        NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.momd'"];
        NSArray *momdFiles = [dirContents filteredArrayUsingPredicate:fltr];
        
        NSString* momdFileName;
        if (momdFiles.count > 0) {
            momdFileName = momdFiles.firstObject;
        }
        
        NSString *path = [[NSBundle mainBundle] pathForResource:momdFileName.stringByDeletingPathExtension ofType:momdFileName.pathExtension];
        NSURL *momURL = [NSURL fileURLWithPath:path];
        managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
        
        printf ("%s\n", [CMMigrationSuccess UTF8String]);
    }
    
    @finally {
        if (managedObjectModel.entities.count == 0) {
            printf ("%s\n", [CMModelError UTF8String]);
            abort();
        }
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
        printf ("%s\n", [CMMigrationError UTF8String]);
        if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[self SQLFilePath] options:options error:&error]) {
            printf ("%s\n", [[NSString stringWithFormat:@"%@ :%@", CMPersistentStoreError, error.localizedDescription] UTF8String]);
            abort();
        } else {
            printf ("%s\n", [CMMigrationSuccess UTF8String]);
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
        printf ("%s\n", [[NSString stringWithFormat:@"%@: %@", CMSavingMainContextError, error.localizedDescription] UTF8String]);
        abort();
    }
}

+ (void) saveChildContext
{
    NSError* error;
    [[self childManagedObjectContext] save:&error];
    if (error) {
        printf ("%s\n", [[NSString stringWithFormat:@"%@: %@", CMSavingChildContextError, error.localizedDescription] UTF8String]);
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
            printf ("%s\n", [[NSString stringWithFormat:@"[!] Error: %@",error.localizedDescription] UTF8String]);
        }
    }
}

+ (void) clearEntity:(NSString*)name
{
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    NSEntityDescription *entity = [NSEntityDescription entityForName:name inManagedObjectContext:[CMCoreData mainManagedObjectContext]];
    [fetchRequest setEntity:entity];
    NSError *error;
    NSArray *items = [[CMCoreData managedObjectContext] executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *managedObject in items) {
        [[CMCoreData managedObjectContext] deleteObject:managedObject];
    }
    if (![[CMCoreData managedObjectContext] save:&error]) {
        printf ("%s\n", [[NSString stringWithFormat:@"[!] Error: %@",error.localizedDescription] UTF8String]);
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
    printf ("%s\n", [[NSString stringWithFormat:@"Current Core Data status:"] UTF8String]);
    
    NSInteger entitiesCount = [[CMCoreData managedObjectModel] entities].count;
    
    [[[CMCoreData managedObjectModel] entities] enumerateObjectsUsingBlock:^(NSEntityDescription* entityDescription, NSUInteger idx, BOOL * _Nonnull stop)
     {
         NSFetchRequest* request = [[NSFetchRequest alloc]initWithEntityName:entityDescription.name];
         
         NSArray* arr = [[CMCoreData managedObjectContext] executeFetchRequest:request error:nil];
         if (full)
             printf ("\n");
         printf ("%s\n", [[NSString stringWithFormat:@"[i] %@: %lu rows", entityDescription.name, (unsigned long)arr.count] UTF8String]);
         if (full) {
             printf ("\n");
         } else {
             if (idx == entitiesCount-1) {
                 printf ("\n");
             }
             return;
         }
         [arr enumerateObjectsUsingBlock:^(NSManagedObject* obj, NSUInteger idx, BOOL *stop) {
             printf ("%s\n", [[NSString stringWithFormat:@"- %@\n", obj] UTF8String]);
         }];
         if (arr.count < 1)
             printf ("%s\n", [[NSString stringWithFormat:@"- <Empty>"] UTF8String]);
         printf ("\n");
     }];
}

@end
