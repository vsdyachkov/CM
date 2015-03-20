//
//  CoreMapping.h
//  CoreMapping
//
//  Created by Dyachkov Victor on 26.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

/*
For customize automatic Json parsing, create categories from your CoreData NSManagedObject subcalss
If your class response to @selector(customizeWithJson:) CoreMapping perform it for each

 - (void) customizeWithJson: (NSDictionary*) json;
 
Progress notification:

name = CMProgressNotificationName
userInfo = @{CMStatus:<CMStatusType>, CMProgress:<NSNumber>, CMEntityName:<NSSrring>};
 
(CMEntityName is optional)
*/

#import <CoreData/CoreData.h>
#import <AFNetworking.h>
#import "CMConstants.h"
#import "CMExtensions.h"
#import "CMCoreData.h"
#import "CMJsonPath.h"
#import "NSManagedObject+manager.h"

@interface CoreMapping : NSObject

// All methods with completion or success/failure block are async

// Parse Json from NSDictionary
+ (void) syncWithJson: (NSDictionary*) json;
+ (void) syncWithJson: (NSDictionary*) json completion:(void(^)(NSDictionary* json)) completion;
 
// Parse Json from bundle
+ (void) syncWithJsonByName: (NSString*) name error: (NSError*) error;
+ (void) syncWithJsonByName: (NSString*) name success:(void(^)(NSDictionary* json)) success failure: (void(^)(NSError *error)) failure;

// Parse Json from url
+ (void) syncWithJsonByUrl: (NSURL*) url success:(void(^)(NSDictionary* json)) success failure: (void(^)(NSError *error)) failure;
+ (void) syncWithJsonByUrl: (NSURL*) url withParameters:(NSDictionary*)parameters success:(void(^)(NSDictionary* json)) success failure: (void(^)(NSError *error)) failure;

@end
