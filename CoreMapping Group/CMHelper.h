//
//  CMHelper.h
//  CoreMapping
//
//  Created by Dyachkov Victor on 29.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "CoreMapping.h"

@interface CMHelper : NSObject

+ (NSNumber*) relationshipIdFrom: (NSRelationshipDescription*) relation to: (NSRelationshipDescription*) inverse;
+ (NSString*) relationshipNameWithId: (NSNumber*) number;

+ (NSDictionary*) jsonWithFileName: (NSString*) name;

@end
