//
//  CMJsonPath.m
//  CoreMapping
//
//  Created by Dyachkov Victor on 04.11.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "CMJsonPath.h"
#import <AFNetworking.h>

@implementation CMJsonPath

+ (void) getJsonFromUrl:(NSURL*)url withParameters:(NSDictionary*)parameters success:(void(^)(NSDictionary* json))success failure:(void(^)(NSError *error))failure;
{
    [CMExtensions validateValue:url withClass:[NSURL class]];
    
    AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html", @"application/json", nil];
    [manager GET:[url absoluteString] parameters:parameters success:^(AFHTTPRequestOperation *operation, NSDictionary* json) {
        success (json);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error)  {
        printf ("%s\n", [[NSString stringWithFormat:@"[!] Json not downloaded from:\n └> url: %@\n └> error: %@", url.absoluteString, error.localizedDescription] UTF8String]);
        failure(error);
    }];
}

+ (void) stringFromJsonWithUrl:(NSURL*)url parameters:(NSDictionary*)parameters jsonPath:(NSString*)path success:(void(^)(NSString* string))success failure:(void(^)(NSError *error))failure;
{
    [CMExtensions validateValue:url withClass:[NSURL class]];
    [CMExtensions validateValue:path withClass:[NSString class]];
    
    AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html", @"application/json", nil];
    [manager GET:[url absoluteString] parameters:parameters success:^(AFHTTPRequestOperation *operation, NSDictionary* json) {
        id obj;
        NSError* error = [NSError errorWithDomain:CMPathError code:-1 userInfo:nil];
        @try {  obj = [json valueForKeyPath:path]; }
        @finally {
            if (obj && [obj isKindOfClass:[NSArray class]] && [(NSArray*)obj count] > 0) {
                NSString* str = [(NSArray*)obj objectAtIndex:0];
                ([str isKindOfClass:[NSString class]]) ? success(str) : failure (error);
            } else {
                failure (error);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error)  {
        printf ("%s\n", [[NSString stringWithFormat:@"[!] Json not downloaded from:\n └> url: %@\n └> error: %@", url.absoluteString, error.localizedDescription] UTF8String]);
        failure(error);
    }];
}

@end
