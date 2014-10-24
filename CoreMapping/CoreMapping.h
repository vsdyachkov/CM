//
//  CoreMapping.h
//  CoreMapping
//
//  Created by Dyachkov Victor on 26.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#define errNilParam @"\n### Error: One or more parameters is nil,"
#define errInvalidClassParam @"\n### Error: Invalid parameter class,"

#import "CMExtensions.h"
#import "NSAttributeDescription+mapping.h"
#import "NSEntityDescription+mapping.h"
#import "NSManagedObject+manager.h"
#import "NSObject+performing.h"
#import "CMHelper.h"
#import "CMTests.h"

static NSString* defaultDateFormat = @"yyyy-LL-dd kk:mm:ss";

static NSString* SQLFileName = @"CoreMapping.sqlite";
static NSString* CoreDataPrefix = @"CM";
static NSString* CoreDataIdPrefix = @"CM_ID";
static NSString* CoreDataManyToManyNameName = @"CM_MM";

static NSString* CMprogressNotificationName = @"CoreMappingProgress";

static NSMutableDictionary* relationshipDictionary;

static NSPersistentStoreCoordinator* persistentStoreCoordinator;
static NSManagedObjectContext* managedObjectContext;
static NSManagedObjectContext* childManagedObjectContext;
static NSManagedObjectModel* managedObjectModel;

@interface CoreMapping : NSObject

+ (NSPersistentStoreCoordinator*) persistentStoreCoordinator;
+ (NSManagedObjectContext*) managedObjectContext;
+ (NSManagedObjectModel*) managedObjectModel;

+ (void) saveContext;
+ (void) clearDatabase;
+ (void) status;
+ (void) shortStatus;

// Sync parsing
+ (void) syncWithJson: (NSDictionary*) json;

// Async parsing with completion block
+ (void) syncWithJson: (NSDictionary*) json completion:(void(^)()) completion;

// Async downloading and parsing with completion block
+ (void) syncWithJsonByUrl: (NSURL*) url completion:(void(^)()) completion;

// Async working with coredata in background
+ (void) databaseOperationInBackground: (void(^)(NSManagedObjectContext *context))block completion:(void(^)(BOOL success, NSError *error)) completion;

@end
