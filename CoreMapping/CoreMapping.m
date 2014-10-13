//
//  CoreMapping.m
//  CoreMapping
//
//  Created by Dyachkov Victor on 26.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "CoreMapping.h"
#import "City.h"

@implementation CoreMapping

#pragma mark - Core Data stack

+ (NSManagedObjectModel *)managedObjectModel
{
    if (managedObjectModel != nil)
        return managedObjectModel;
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:SQLFileName withExtension:@"momd"];
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return managedObjectModel;
}

+ (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (persistentStoreCoordinator != nil)
        return persistentStoreCoordinator;
    NSString* pathComponent = [NSString stringWithFormat:@"%@.sqlite", SQLFileName];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:pathComponent];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    NSError *error = nil;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    return persistentStoreCoordinator;
}

+ (NSManagedObjectContext *)managedObjectContext
{
    if (managedObjectContext != nil)
        return managedObjectContext;
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return managedObjectContext;
}

+ (NSManagedObjectContext *)childManagedObjectContext
{
    if (childManagedObjectContext != nil)
        return childManagedObjectContext;
    childManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [childManagedObjectContext setParentContext:[self managedObjectContext]];
    return childManagedObjectContext;
}

+ (void)saveContext
{
    if ([NSThread isMainThread]) {
        [self saveMainContext];
    } else {
        [self saveChildContext];
        [[self managedObjectContext] performBlock:^{
            [self saveMainContext];
        }];
    }
}

+ (NSError*) saveMainContext
{
    NSError* error;
    [[self managedObjectContext] save:&error];
    if (error) NSLog(@"Can't save context, error: %@", error.localizedDescription);
    return error;
}

+ (NSError*) saveChildContext
{
    NSError* error;
    [[self childManagedObjectContext] save:&error];
    if (error)
        NSLog(@"Can't save child context, error: %@", error.localizedDescription);
    return error;
}

+ (NSManagedObjectContext*) contextForCurrentThread
{
    return ([NSThread isMainThread]) ? [self managedObjectContext] : [self childManagedObjectContext];
}



#pragma mark - Application's Documents directory


+ (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}



#pragma mark - Core Mapping stack


+ (void) status
{
    [self fullPrint:YES];
}

+ (void) shortStatus
{
    [self fullPrint:NO];
}

+ (void) fullPrint: (BOOL) full
{
    NSMutableString* report = @"Current Core Data status:\n".mutableCopy;
    for (NSEntityDescription* entityDescription in [self.managedObjectModel entities])
    {
        
        NSFetchRequest* request = [[NSFetchRequest alloc]initWithEntityName:entityDescription.name];
        NSArray* arr = [[self contextForCurrentThread] executeFetchRequest:request error:nil];
        if (full)
            [report appendString:@"\n"];
        [report appendFormat:@"Entity: %@ {%lu rows} \n", entityDescription.name, (unsigned long)arr.count];
        if (full) {
            [report appendString:@"\n"];
        } else {
            continue;
        }
        [arr enumerateObjectsUsingBlock:^(NSManagedObject* obj, NSUInteger idx, BOOL *stop) {
            [report appendFormat:@"- %@\n\n", obj];
        }];
        if (arr.count < 1)
            [report appendString:@"- <Empty>"];
    }
    NSLog(@"%@",report);
}

+ (void)clearDatabase
{
    NSArray *entities = [[self.managedObjectModel entities] valueForKey:@"name"];
    
    for (NSString* entityName in entities)
    {
        NSFetchRequest *fetchRequest = [NSFetchRequest new];
        NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        NSError *error;
        NSArray *items = [[self contextForCurrentThread] executeFetchRequest:fetchRequest error:&error];
        for (NSManagedObject *managedObject in items) {
            [[self contextForCurrentThread] deleteObject:managedObject];
        }
        if (![[self contextForCurrentThread] save:&error]) {
            NSLog(@"Error: %@",error.localizedDescription);
        }
    }
}

+ (void) mapValue:(id) value withJsonKey: (NSString*) key andType: (NSAttributeType) type andManagedObject: (NSManagedObject*) obj
{
    NSAssert(value || key || type || obj, @"%@ value: %@, key: %@, type: %lu, obj: %@", errNilParam, value, key, (long)type, obj);
    [CMTests checkString:key];
    [CMTests checkManagedObject:obj];
    
    id convertedValue;
    NSString* strValue = [NSString stringWithFormat:@"%@",value];
    switch (type) {
        case NSUndefinedAttributeType: convertedValue =  nil; break;
        case NSInteger16AttributeType: convertedValue =  [NSNumber numberWithInt:[strValue intValue]]; break;
        case NSInteger32AttributeType: convertedValue =  [NSNumber numberWithInt:[strValue intValue]]; break;
        case NSInteger64AttributeType: convertedValue =  [NSNumber numberWithInt:[strValue intValue]]; break;
        case NSDecimalAttributeType: convertedValue =    [NSNumber numberWithInt:[strValue doubleValue]]; break;
        case NSDoubleAttributeType: convertedValue =     [NSNumber numberWithInt:[strValue doubleValue]]; break;
        case NSFloatAttributeType: convertedValue =      [NSNumber numberWithInt:[strValue floatValue]]; break;
        case NSStringAttributeType: convertedValue =     strValue; break;
        case NSBooleanAttributeType: convertedValue =    [NSNumber numberWithInt:[strValue boolValue]]; break;
        case NSDateAttributeType: convertedValue =       nil; break;
        case NSBinaryDataAttributeType: convertedValue = [strValue dataUsingEncoding:NSUTF8StringEncoding]; break;

        default: [NSException raise:@"Invalid attribute type" format:@"This type is not supported in database"]; break;
    }
    
    NSAssert(convertedValue || key, @"%@ convertedValue: %@, key: %@", errNilParam, convertedValue, key);
    [obj setValue:convertedValue forKey:key];
}

+ (NSManagedObject*) findOrCreateObjectInEntity: (NSEntityDescription*) entity withId: (NSNumber*) idNumber
{
    NSAssert(entity || idNumber, @"%@ entity: %@, idNumber: %@", errNilParam, entity, idNumber);
    [CMTests checkEntityDescription:entity];
    [CMTests checkNumber:idNumber];

    NSFetchRequest* req = [[NSFetchRequest alloc]initWithEntityName:entity.name];
    NSString* idKey = [entity mappingIdKey];
    NSPredicate* myPred = [NSPredicate predicateWithFormat:@"%K == %@", idKey, idNumber];
    [req setPredicate:myPred];

    NSArray* arr = [[self contextForCurrentThread] executeFetchRequest:req error:nil];
    if (arr.count > 0) {
        return arr[0];
    } else {
        return [NSEntityDescription insertNewObjectForEntityForName:entity.name inManagedObjectContext:[self contextForCurrentThread]];
    }
}

+ (NSManagedObject*) mapSingleRowInEntity: (NSEntityDescription*) desc andJsonDict: (NSDictionary*) json
{
    NSAssert(desc || json, @"%@ desc: %@, json: %@", errNilParam, desc, json);
    [CMTests checkEntityDescription:desc];
    [CMTests checkDictionary:json];
    
    NSString* mappingIdKey = [desc mappingIdValue];
    
    NSNumber* idFromJson;
    if (mappingIdKey)
    {
        if (json[mappingIdKey]) {
            idFromJson = @([json[mappingIdKey] integerValue]);
        } else {
            idFromJson = @([json[@"id"] integerValue]);
        }
    }
    
    NSManagedObject* obj = [self findOrCreateObjectInEntity:desc withId:idFromJson];
    
    NSDictionary* attributes = [desc attributesByName];
    [[attributes allValues] enumerateObjectsUsingBlock:^(NSAttributeDescription* attr, NSUInteger idx, BOOL *stop) {
        NSString* mappingAttrName = [attr mappingName];
        // if "id" of entity != mappingAttrName in json
        id valueFromJson = (json [mappingAttrName]) ? json [mappingAttrName] : json[@"id"];
        [self mapValue:valueFromJson withJsonKey:attr.name andType:attr.attributeType andManagedObject:obj];
    }];

    [self mapRelationshipsWithObject:obj andJsonDict:json];
    
    NSAssert(obj, @"%@ json: %@", errNilParam, obj);
    return obj;
}

+ (void) mapRelationshipsWithObject: (NSManagedObject*) obj andJsonDict: (NSDictionary*) json
{
    NSAssert(obj || json, @"%@ obj: %@, json: %@", errNilParam, obj, json);
    [CMTests checkManagedObject:obj];
    [CMTests checkDictionary:json];

    // perform Relationships: ManyToOne & OneToOne & OneToMane
    NSEntityDescription* desc = obj.entity;
    for (NSString* name in desc.relationshipsByName) {
        NSRelationshipDescription* relationFromChild = desc.relationshipsByName[name];
        NSRelationshipDescription* inverseFromParent = relationFromChild.inverseRelationship;
        // This (many) Childs to -> (one) Parent
        NSEntityDescription* destinationEntity = relationFromChild.destinationEntity;
        NSString* relationMappedName = [relationFromChild mappingName];
        NSNumber* idObjectFormJson = json[relationMappedName];
        if (idObjectFormJson) {
            // Relationship found
            NSManagedObject* toObject = [self findOrCreateObjectInEntity:destinationEntity withId:idObjectFormJson];
            NSString* selectorName = [NSString stringWithFormat:@"add%@Object:", inverseFromParent.name.capitalizedString];
            [toObject performSelectorIfResponseFromString:selectorName withObject:obj];
        } else {
            // Relationship not found
            //NSLog(@"In Entity '%@' relation key %@ not fount (%@=%@)", [desc name], relationMappedName, relationMappedName, idObjectFormJson);
        }

    }
}

+ (void) mapAllRowsInEntity: (NSEntityDescription*) desc andWithJsonArray: (NSArray*) jsonArray
{
    NSAssert(desc || jsonArray, @"%@ desc: %@, jsonArray: %@", errNilParam, desc, jsonArray);
    [CMTests checkEntityDescription:desc];
    [CMTests checkArray:jsonArray];
    
    [jsonArray enumerateObjectsUsingBlock:^(NSDictionary* singleDict, NSUInteger idx, BOOL *stop) {
        NSManagedObject* obj = [self mapSingleRowInEntity:desc andJsonDict:singleDict];
        [obj performSelectorIfResponseFromString:@"customizeWithJson:" withObject:singleDict];
    }];
}

+ (void) removeRowsInEntity: (NSEntityDescription*) desc withNumberArray: (NSArray*) removeArray
{
    NSAssert(desc || removeArray, @"%@ desc: %@, removeArray: %@", errNilParam, desc, removeArray);
    [CMTests checkEntityDescription:desc];
    [CMTests checkArray:removeArray];
    
    [removeArray enumerateObjectsUsingBlock:^(NSNumber* removeId, NSUInteger idx, BOOL *stop) {
        NSFetchRequest* req = [[NSFetchRequest alloc]initWithEntityName:desc.name];
        NSPredicate* myPred = [NSPredicate predicateWithFormat:@"%K == %@", [desc mappingIdValue], removeId];
        [req setPredicate:myPred];
        NSArray* arr = [[self contextForCurrentThread] executeFetchRequest:req error:nil];
        if (arr.count > 0) {
            [[self contextForCurrentThread] deleteObject:arr[0]];
        }
    }];
}

+ (void) mapAllEntityWithJson: (NSDictionary*) json
{
    NSAssert(json, @"%@ json: %@", errNilParam, json);
    [CMTests checkDictionary:json];
    
    NSArray* entities = [self.managedObjectModel entities];
    [entities enumerateObjectsUsingBlock:^(NSEntityDescription* desc, NSUInteger idx, BOOL *stop) {
        NSArray* arrayWithName = json[desc.mappingEntityName];
        [self mapAllRowsInEntity:desc andWithJsonArray:arrayWithName];
        [self saveContext];
    }];
}

+ (void) syncWithJson: (NSDictionary*) json
{
    NSAssert(json, @"%@ json: %@", errNilParam, json);
    [CMTests checkDictionary:json];
    
    NSArray* entities = [self.managedObjectModel entities];
    [entities enumerateObjectsUsingBlock:^(NSEntityDescription* desc, NSUInteger idx, BOOL *stop) {

        NSArray* addArray = [CMTests validateArray:json[desc.mappingEntityName][@"add"]];
        if (addArray) [self mapAllRowsInEntity:desc andWithJsonArray:addArray];
        
        NSArray* removeArray = [CMTests validateArray:json[desc.mappingEntityName][@"remove"]];
        if (removeArray) [self removeRowsInEntity:desc withNumberArray:(NSArray*)removeArray];

    }];
    [self saveContext];
}

+ (void) saveInBackgroundWithBlock: (void(^)(NSManagedObjectContext *context))block completion:(void(^)(BOOL success, NSError *error)) completion
{
    NSAssert([NSThread isMainThread], @"This function should be called from main thread !");
    
    NSManagedObjectContext *childManagedObjectContext = [self childManagedObjectContext];
    [childManagedObjectContext performBlock:^{
        if (block) {
            block(childManagedObjectContext);
            NSError* error1 = [self saveChildContext];
            [[self managedObjectContext] performBlock:^{
                NSError* error2 = [self saveMainContext];
                BOOL isSuccess = (!error1 && !error2);
                NSString* errorDesc = [NSString stringWithFormat:@"Errors: %@, %@", error1.localizedDescription, error2.localizedDescription];
                NSError* fatalError = [NSError errorWithDomain:errorDesc code:-1 userInfo:nil];
                if (completion) {
                    (isSuccess) ? completion(YES, nil) : completion(NO, fatalError);
                }
            }];
        }
    }];
}



@end
