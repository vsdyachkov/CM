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

+ (void) getJsonFromUrl: (NSURL*) url success:(void(^)(NSDictionary* json)) success failure: (void(^)(NSError *error)) failure;
{
    [CMExtensions validateValue:url withClass:[NSURL class]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    op.responseSerializer = [AFJSONResponseSerializer serializer];
    NSMutableSet* responseTypes = [NSMutableSet setWithSet:op.responseSerializer.acceptableContentTypes];
    [responseTypes addObject:@"text/html"];
    op.responseSerializer.acceptableContentTypes = responseTypes;
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, NSDictionary* json)
    {
        success (json);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        printf ("%s\n", [[NSString stringWithFormat:@"[!] Json not downloaded from url:\n%@\nerror: %@", url.absoluteString, error.localizedDescription] UTF8String]);
         failure(error);
    }];
    
    [[NSOperationQueue mainQueue] cancelAllOperations];
    [[NSOperationQueue mainQueue] addOperation:op];
    
}

+ (void) stringFromJsonWithUrl: (NSURL*) url andPath: (NSString*) path success:(void(^)(NSString* string)) success failure: (void(^)(NSError *error)) failure;
{
    [CMExtensions validateValue:url withClass:[NSURL class]];
    [CMExtensions validateValue:path withClass:[NSString class]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    op.responseSerializer = [AFJSONResponseSerializer serializer];
    NSMutableSet* responseTypes = [NSMutableSet setWithSet:op.responseSerializer.acceptableContentTypes];
    [responseTypes addObject:@"text/html"];
    op.responseSerializer.acceptableContentTypes = responseTypes;
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, NSDictionary* json)
    {
        id obj;
        NSError* error = [NSError errorWithDomain:CMPathError code:-1 userInfo:nil];
        
        @try {
            obj = [json valueForKeyPath:path];
        }
        
        @finally {
            if (obj && [obj isKindOfClass:[NSArray class]] && [(NSArray*)obj count] > 0) {
                NSString* str = [(NSArray*)obj objectAtIndex:0];
                ([str isKindOfClass:[NSString class]]) ? success(str) : failure (error);
            } else {
                failure (error);
            }
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        printf ("%s\n", [[NSString stringWithFormat:@"[!] Json not downloaded from url:\n%@\nerror: %@", url.absoluteString, error.localizedDescription] UTF8String]);
        failure(error);
    }];
    
    [[NSOperationQueue mainQueue] cancelAllOperations];
    [[NSOperationQueue mainQueue] addOperation:op];
}

@end
