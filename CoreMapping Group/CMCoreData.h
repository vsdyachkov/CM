//
//  CMCoreData.h
//  CoreMapping
//
//  Created by Dyachkov Victor on 25.10.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreMapping.h"

@interface CMCoreData : NSObject

// CoreData methods with background safe working

+ (NSPersistentStoreCoordinator*) persistentStoreCoordinator;
+ (NSManagedObjectModel*) managedObjectModel;
+ (NSManagedObjectContext*) managedObjectContext;

+ (void) saveContext;
+ (void) clearDatabase;
+ (void) status;
+ (void) shortStatus;

// Helper method

+ (void) databaseOperationInBackground: (void(^)()) block completion:(void(^)()) completion;

@end
