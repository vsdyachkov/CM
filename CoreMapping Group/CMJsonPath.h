//
//  CMJsonPath.h
//  CoreMapping
//
//  Created by Dyachkov Victor on 04.11.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "CoreMapping.h"

@interface CMJsonPath : NSObject

+ (void) getJsonFromUrl:(NSURL*)url withParameters:(NSDictionary*)parameters success:(void(^)(NSDictionary* json))success failure:(void(^)(NSError *error))failure;

// Example: get value from "alias" key
// Json: {"message":[{"event":{"alias":"queen"}}]}
// Path: @"message.event.alias"
+ (void) stringFromJsonWithUrl:(NSURL*)url parameters:(NSDictionary*)parameters jsonPath:(NSString*)path success:(void(^)(NSString* string))success failure:(void(^)(NSError *error))failure;

@end
