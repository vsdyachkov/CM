//
//  NSEntityDescription+EntityExtension.h
//  CoreMapping
//
//  Created by Dyachkov Victor on 26.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSEntityDescription (EntityExtension)

- (NSString*) mappingName;
- (NSString*) idKeyString;

+ (void) findOfCreateObjectWithPredicate: (NSPredicate*) predicate;

@end
