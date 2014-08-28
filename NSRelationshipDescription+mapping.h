//
//  CMExtensions.h
//  CoreMapping
//
//  Created by Dyachkov Victor on 28.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "CoreMapping.h"

@interface NSRelationshipDescription (mapping)

- (NSString*) mappingName;

@end
