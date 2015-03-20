//
//  CMExtensions.h
//  CoreMapping
//
//  Created by Dyachkov Victor on 28.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreMapping.h"

@interface CMExtensions : NSObject
+ (id) validateValue: (id) value withClass: (Class) myClass;
@end

@interface NSObject (performing)
- (BOOL) performSelectorIfResponseFromString: (NSString*) name withObject: (id) object;
@end

@interface NSAttributeDescription (mapping)
- (NSString*) mappingName;
@end

@interface NSEntityDescription (mapping)
- (NSString*) mappingEntityName;
- (NSString*) mappingIdKey;
- (NSString*) mappingIdValue;
- (BOOL) isNoParse;
@end

@interface NSRelationshipDescription (mapping)
- (NSString*) mappingName;
- (NSString*) manyToManyTableName;
- (NSNumber*) relationshipType;
- (NSString*) relationshipString;
@end
