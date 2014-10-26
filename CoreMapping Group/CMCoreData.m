//
//  CMCoreData.m
//  CoreMapping
//
//  Created by Dyachkov Victor on 25.10.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "CMCoreData.h"

@implementation CMCoreData

#pragma mark - Core Data stack

+ (NSURL*) defaultStoreName;
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
    return managedObjectModel;
}


+ (NSPersistentStoreCoordinator*) persistentStoreCoordinator
{
    if (persistentStoreCoordinator != nil)
        return persistentStoreCoordinator;
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    NSError *error = nil;
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[self defaultStoreName] options:options error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        NSAssert(error, @"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    return persistentStoreCoordinator;
}

+ (NSManagedObjectContext*) managedObjectContext
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
    [childManagedObjectContext setParentContext:[self managedObjectContext]];
    return childManagedObjectContext;
}

+ (void) saveContext
{
    if ([NSThread isMainThread]) {
        [self saveMainContext];
    } else {
        [self saveChildContext];
        [[self managedObjectContext] performBlock:^{
            [self saveMainContext];
        }];
    }
}

+ (NSError*) saveMainContext
{
    NSError* error;
    [[self managedObjectContext] save:&error];
    if (error) NSLog(@"Can't save context, error: %@", error.localizedDescription);
    return error;
}

+ (NSError*) saveChildContext
{
    NSError* error;
    [[self childManagedObjectContext] save:&error];
    if (error)
        NSLog(@"Can't save child context, error: %@", error.localizedDescription);
    return error;
}

+ (NSManagedObjectContext*) contextForCurrentThread
{
    return ([NSThread isMainThread]) ? [self managedObjectContext] : [self childManagedObjectContext];
}


#pragma mark - Application's Documents directory


+ (NSURL*) applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

/*
 + (NSURL*) applicationDbDirectory
 {
 NSString* bundleName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleNameKey];
 if (bundleName == nil) bundleName = @"DB";
 if ([bundleName hasSuffix:@"sqlite"]) bundleName = [bundleName stringByDeletingLastPathComponent];
 
 NSString *supportDirectory = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:bundleName];
 if (![[NSFileManager defaultManager] fileExistsAtPath:supportDirectory])
 {
 [[NSFileManager defaultManager] createDirectoryAtPath:supportDirectory withIntermediateDirectories:NO attributes:nil error:nil];
 }
 
 return [[[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:bundleName];
 }
 */

+ (void) createDirectory:(NSString *)directoryName atFilePath:(NSString *)filePath
{
    NSString *filePathAndDirectory = [filePath stringByAppendingPathComponent:directoryName];
    NSError *error;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:filePathAndDirectory withIntermediateDirectories:NO attributes:nil error:&error])
    {
        NSLog(@"Create directory error: %@", error);
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
    NSMutableString* report = @"\n\nCurrent Core Data status:\n".mutableCopy;
    for (NSEntityDescription* entityDescription in [[CMCoreData managedObjectModel] entities])
    {
        
        NSFetchRequest* request = [[NSFetchRequest alloc]initWithEntityName:entityDescription.name];
        
        NSArray* arr = [[CMCoreData contextForCurrentThread] executeFetchRequest:request error:nil];
        if (full)
            [report appendString:@"\n"];
        [report appendFormat:@"[i] %@: %lu rows\n", entityDescription.name, (unsigned long)arr.count];
        if (full) {
            [report appendString:@"\n"];
        } else {
            continue;
        }
        [arr enumerateObjectsUsingBlock:^(NSManagedObject* obj, NSUInteger idx, BOOL *stop) {
            [report appendFormat:@"- %@\n\n", obj];
        }];
        if (arr.count < 1)
            [report appendString:@"- <Empty>"];
    }
    NSLog(@"%@\n\n",report);
}

+ (void) clearDatabase
{
    NSArray *entities = [[[CMCoreData managedObjectModel] entities] valueForKey:@"name"];
    
    for (NSString* entityName in entities)
    {
        NSFetchRequest *fetchRequest = [NSFetchRequest new];
        NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:[CMCoreData managedObjectContext]];
        [fetchRequest setEntity:entity];
        NSError *error;
        NSArray *items = [[CMCoreData contextForCurrentThread] executeFetchRequest:fetchRequest error:&error];
        for (NSManagedObject *managedObject in items) {
            [[CMCoreData contextForCurrentThread] deleteObject:managedObject];
        }
        if (![[CMCoreData contextForCurrentThread] save:&error]) {
            NSLog(@"Error: %@",error.localizedDescription);
        }
    }
}

@end
