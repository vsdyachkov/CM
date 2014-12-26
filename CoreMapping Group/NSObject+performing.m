//
//  NSObject+performing.m
//  CoreMapping
//
//  Created by Dyachkov Victor on 28.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "NSObject+performing.h"

@implementation NSObject (performing)

- (BOOL) performSelectorIfResponseFromString: (NSString*) name withObject: (id) object
{
    [CMTests validateValue:name withClass:[NSString class]];
    
    if ([self respondsToSelector:NSSelectorFromString(name)]) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:NSSelectorFromString(name) withObject:object];
        #pragma clang diagnostic pop
        return YES;
    } else {
        return NO;
    }
}

@end
