//
//  CoreMapping.h
//  CoreMapping
//
//  Created by Dyachkov Victor on 26.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "CMExtensions.h"
#import "NSAttributeDescription+mapping.h"
#import "NSEntityDescription+mapping.h"
#import "NSManagedObject+manager.h"
#import "NSObject+performing.h"
#import "CMConstants.h"
#import "CMCoreData.h"
#import "CMHelper.h"
#import "CMTests.h"

static NSMutableDictionary* relationshipDictionary;

@interface CoreMapping : NSObject

// All methods with completion block are async

// Parse from NSDictionary
+ (void) syncWithJson: (NSDictionary*) json;
+ (void) syncWithJson: (NSDictionary*) json completion:(void(^)(NSDictionary* json)) completion;

// Parse from bundle
+ (void) syncWithJsonByName: (NSString*) name;
+ (void) syncWithJsonByName: (NSString*) name completion:(void(^)(NSDictionary* json)) completion;

// Parse from url
+ (void) syncWithJsonByUrl: (NSURL*) url completion:(void(^)(NSDictionary* json)) completion;

// Async working with coredata in background
+ (void) databaseOperationInBackground: (void(^)(NSManagedObjectContext *context))block completion:(void(^)(BOOL success, NSError *error)) completion;

@end
