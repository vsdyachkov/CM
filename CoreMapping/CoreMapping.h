//
//  CoreMapping.h
//  CoreMapping
//
//  Created by Dyachkov Victor on 26.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSEntityDescription+mapping.h"
#import "NSAttributeDescription+mapping.h"
#import "NSManagedObject+manager.h"
#import "CMExtensions.h"
#import "NSObject+performing.h"
#import "CMTests.h"
#import "CMHelper.h"

#define errNilParam @"\n### Error: One or more parameters is nil,"
#define errInvalidClassParam @"\n### Error: Invalid parameter class,"

static NSString* SQLFileName = @"CoreMapping";
static NSString* CoreDataPrefix = @"CM";
static NSString* CoreDataIdPrefix = @"CM_ID";


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

+ (void) mapAllEntityWithJson: (NSDictionary*) json;
+ (void) syncWithJson: (NSDictionary*) json;

+ (void) saveInBackgroundWithBlock: (void(^)(NSManagedObjectContext *context))block completion:(void(^)(BOOL success, NSError *error)) completion;


@end
