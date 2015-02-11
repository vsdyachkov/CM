//
//  CMTest.m
//  CoreMapping
//
//  Created by Dyachkov Victor on 29.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "CMTests.h"

@implementation CMTests

#pragma mark - Validate method

+ (id) validateValue: (id) value withClass: (Class) myClass
{
    return (!value || ![value isKindOfClass:myClass]) ? nil : value;
}

+ (void) CFLog:(NSString*)format, ...
{
    if (!format) {
        return;
    }
    va_list args;
    va_start(args, format);
    CFShow((__bridge CFStringRef)[[NSString alloc] initWithFormat:format arguments:args]);
    va_end(args);
}


@end
