//
//  CMTest.h
//  CoreMapping
//
//  Created by Dyachkov Victor on 29.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CMTests : NSObject

+ (id) validateValue: (id) value withClass: (Class) myClass;

+ (void) CFLog:(NSString*)format, ...;

@end
