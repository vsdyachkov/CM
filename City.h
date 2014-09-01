//
//  City.h
//  CoreMapping
//
//  Created by Dyachkov Victor on 01.09.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Phone;

@interface City : NSManagedObject

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSNumber * city_id;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *phones;
@end

@interface City (CoreDataGeneratedAccessors)

- (void)addPhonesObject:(Phone *)value;
- (void)removePhonesObject:(Phone *)value;
- (void)addPhones:(NSSet *)values;
- (void)removePhones:(NSSet *)values;

@end
