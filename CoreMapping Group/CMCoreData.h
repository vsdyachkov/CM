//
//  CMCoreData.h
//  CoreMapping
//
//  Created by Dyachkov Victor on 25.10.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSPersistentStoreCoordinator* persistentStoreCoordinator;
static NSManagedObjectContext* managedObjectContext;
static NSManagedObjectContext* childManagedObjectContext;
static NSManagedObjectModel* managedObjectModel;

@interface CMCoreData : NSObject

+ (NSPersistentStoreCoordinator*) persistentStoreCoordinator;
+ (NSManagedObjectContext*) managedObjectContext;
+ (NSManagedObjectContext*) childManagedObjectContext;
+ (NSManagedObjectModel*) managedObjectModel;

+ (NSManagedObjectContext*) contextForCurrentThread;

+ (NSError*) saveMainContext;
+ (NSError*) saveChildContext;

+ (void) saveContext;

+ (void) clearDatabase;
+ (void) status;
+ (void) shortStatus;

@end
