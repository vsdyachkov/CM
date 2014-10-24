//
//  CoreMapping.m
//  CoreMapping
//
//  Created by Dyachkov Victor on 26.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "CoreMapping.h"
#import <AFNetworking.h>

@implementation CoreMapping


#pragma mark - Core Data stack

+ (NSURL*) defaultStoreName;
{
    NSString* fileName = [[[NSBundle mainBundle] infoDictionary] valueForKey:(id)kCFBundleNameKey];
    if (fileName == nil) fileName = SQLFileName;
    if (![fileName hasSuffix:@"sqlite"]) fileName = [fileName stringByAppendingPathExtension:@"sqlite"];
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:fileName];
    return storeURL;
}

+ (NSManagedObjectModel*) managedObjectModel
{
    if (managedObjectModel != nil)
        return managedObjectModel;
    
    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    return managedObjectModel;
}


+ (NSPersistentStoreCoordinator*) persistentStoreCoordinator
{
    if (persistentStoreCoordinator != nil)
        return persistentStoreCoordinator;
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    NSError *error = nil;
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[self defaultStoreName] options:options error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        NSAssert(error, @"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    return persistentStoreCoordinator;
}

+ (NSManagedObjectContext*) managedObjectContext
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

+ (NSManagedObjectContext *) childManagedObjectContext
{
    if (childManagedObjectContext != nil)
        return childManagedObjectContext;
    childManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [childManagedObjectContext setParentContext:[self managedObjectContext]];
    return childManagedObjectContext;
}

+ (void) saveContext
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


+ (NSURL*) applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

/*
+ (NSURL*) applicationDbDirectory
{
    NSString* bundleName = [[[NSBundle mainBundle] infoDictionary] valueForKey:(id)kCFBundleNameKey];
    if (bundleName == nil) bundleName = @"DB";
    if ([bundleName hasSuffix:@"sqlite"]) bundleName = [bundleName stringByDeletingLastPathComponent];
    
    NSString *supportDirectory = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:bundleName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:supportDirectory])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:supportDirectory withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    return [[[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:bundleName];
}
*/

+ (void) createDirectory:(NSString *)directoryName atFilePath:(NSString *)filePath
{
    NSString *filePathAndDirectory = [filePath stringByAppendingPathComponent:directoryName];
    NSError *error;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:filePathAndDirectory withIntermediateDirectories:NO attributes:nil error:&error])
    {
        NSLog(@"Create directory error: %@", error);
    }
}


#pragma mark - Core Mapping stack

+ (NSMutableDictionary*) addRelationshipIfNeed: (NSString*) name andRelationship: (NSRelationshipDescription*) relationship
{
    if (relationshipDictionary != nil) {
        if (![relationshipDictionary.allKeys containsObject:name]) {
            [relationshipDictionary setObject:relationship forKey:name];
            return relationshipDictionary;
        }
        return relationshipDictionary;
    }
    
    relationshipDictionary = [NSMutableDictionary new];
    [relationshipDictionary setObject:relationship forKey:name];
    return relationshipDictionary;
}

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
    NSMutableString* report = @"\n\nCurrent Core Data status:\n".mutableCopy;
    for (NSEntityDescription* entityDescription in [self.managedObjectModel entities])
    {
        
        NSFetchRequest* request = [[NSFetchRequest alloc]initWithEntityName:entityDescription.name];
        NSArray* arr = [[self contextForCurrentThread] executeFetchRequest:request error:nil];
        if (full)
            [report appendString:@"\n"];
        [report appendFormat:@"[i] %@: %lu rows\n", entityDescription.name, (unsigned long)arr.count];
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
    NSLog(@"%@\n\n",report);
}

+ (void) clearDatabase
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
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    [format setDateFormat: defaultDateFormat];
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
        case NSDateAttributeType: convertedValue =       [format dateFromString:strValue]; break;
        case NSBinaryDataAttributeType: convertedValue = [strValue dataUsingEncoding:NSUTF8StringEncoding]; break;
            
        default: [NSException raise:@"Invalid attribute type" format:@"This type is not supported in database"]; break;
    }
    
    NSAssert(convertedValue || key, @"%@ convertedValue: %@, key: %@", errNilParam, convertedValue, key);
    [obj setValue:convertedValue forKey:key];
}

+ (NSManagedObject*) findObjectInEntity: (NSEntityDescription*) entity withId: (NSNumber*) idNumber enableCreating: (BOOL) create
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
        if (create) {
            return [NSEntityDescription insertNewObjectForEntityForName:entity.name inManagedObjectContext:[self contextForCurrentThread]];
        } else {
            return nil;
        }
        
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
    
    NSManagedObject* obj = [self findObjectInEntity:desc withId:idFromJson enableCreating:YES];
    
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
        
        if ((relationFromChild && inverseFromParent) &&  ![[CMHelper relationshipIdFrom:relationFromChild to:inverseFromParent] isEqual: @3]) {
            // This (many) Childs to -> (one) Parent
            NSEntityDescription* destinationEntity = relationFromChild.destinationEntity;
            NSString* relationMappedName = [relationFromChild mappingName];
            NSNumber* idObjectFormJson = json[relationMappedName];
            if (idObjectFormJson) {
                // Relationship found
                NSManagedObject* toObject = [self findObjectInEntity:destinationEntity withId:idObjectFormJson enableCreating:NO];
                NSString* selectorName = [NSString stringWithFormat:@"add%@Object:", inverseFromParent.name.capitalizedString];
                [toObject performSelectorIfResponseFromString:selectorName withObject:obj];
            }
        } else {
            [self addRelationshipIfNeed:[relationFromChild manyToManyTableName] andRelationship:relationFromChild];
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

+ (void) syncWithJson: (NSDictionary*) json
{
    NSAssert(json, @"%@ json: %@", errNilParam, json);
    [CMTests checkDictionary:json];
    
    NSMutableString* report = @"\n\nParsing status:\n".mutableCopy;
    
    __block float progress = 0.0f;
    
    NSArray* entities = [self.managedObjectModel entities];
    [entities enumerateObjectsUsingBlock:^(NSEntityDescription* desc, NSUInteger idx, BOOL *stop) {
        
        progress = (float)(idx+1)/(entities.count+1);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:CMprogressNotificationName object:nil userInfo:@{CMprogressNotificationName:@(progress)}];
        
        if ([CMTests validateDictionary:json[desc.mappingEntityName]])
        {
            NSDictionary* jsonTable = json[desc.mappingEntityName];            
            
            if ([jsonTable.allKeys containsObject:@"add"])
            {
                NSArray* addArray = [CMTests validateArray:json[desc.mappingEntityName][@"add"]];
                [report appendFormat:@"[+] Added %lu '%@'\n", (unsigned long)addArray.count, desc.mappingEntityName];
                if (addArray) [self mapAllRowsInEntity:desc andWithJsonArray:addArray];
            }
            
            if ([jsonTable.allKeys containsObject:@"remove"])
            {
                NSArray* removeArray = [CMTests validateArray:json[desc.mappingEntityName][@"remove"]];
                [report appendFormat:@"[-] Removed %lu '%@'\n", (unsigned long)removeArray.count, desc.mappingEntityName];
                if (removeArray) [self removeRowsInEntity:desc withNumberArray:(NSArray*)removeArray];
            }
        }
        else
        {
            [report appendFormat:@"[!] '%@' is not array or not found\n", desc.mappingEntityName];
        }
        
    }];
    
    
    // Parsing relationship tables
    for (NSString* tableName in [relationshipDictionary.copy  allKeys])
    {
        if (!json[tableName]) {
            [relationshipDictionary removeObjectForKey:tableName];
        }
    }
    
    int relations = 0;
    
    for (NSString* key in relationshipDictionary.allKeys) {
        
        if (![json.allKeys containsObject:key]) return;
        NSDictionary* relationDict = [json objectForKey:key];
        
        if (![relationDict.allKeys containsObject:@"add"]) return;
        NSArray* addArray = [relationDict objectForKey:@"add"];
        
        for (NSDictionary* tmpJson in addArray) {
            
            relations++;
            
            NSRelationshipDescription* relationFromChild = [relationshipDictionary objectForKey:key];
            NSRelationshipDescription* inverseFromParent = relationFromChild.inverseRelationship;
            
            NSEntityDescription* childEntity = relationFromChild.entity;
            NSEntityDescription* destinationEntity = relationFromChild.destinationEntity;
            
            NSString* key1 = [childEntity mappingIdKey];
            NSString* key2 = [destinationEntity mappingIdKey];
            
            NSNumber* value1 = @([tmpJson[key1] integerValue]);
            NSNumber* value2 = @([tmpJson[key2] integerValue]);
            
            if (value1 && value2) {
                // Relationship found
                NSManagedObject* firstObject = [self findObjectInEntity:childEntity withId:value1 enableCreating:NO];
                NSManagedObject* secondObject = [self findObjectInEntity:destinationEntity withId:value2 enableCreating:NO];
                
                if (firstObject && secondObject) {
                    NSString* selectorName = [NSString stringWithFormat:@"add%@Object:", inverseFromParent.name.capitalizedString];
                    [secondObject performSelectorIfResponseFromString:selectorName withObject:firstObject];
                }

            }
            
        }

    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CMprogressNotificationName object:nil userInfo:@{CMprogressNotificationName:@(1)}];
    
    [report appendFormat:@"[+] Add %d relationship from tables: %@", relations, relationshipDictionary.allKeys];
    
    NSLog(@"%@\n\n",report);
    
    [self saveContext];
    
}

+ (void) databaseOperationInBackground: (void(^)(NSManagedObjectContext *context))block completion:(void(^)(BOOL success, NSError *error)) completion
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

+ (void) syncWithJson: (NSDictionary*) json completion:(void(^)()) completion
{
    [self databaseOperationInBackground:^(NSManagedObjectContext *context) {
        [self syncWithJson:json];
    } completion:^(BOOL success, NSError *error) {
        if (success) completion();
    }];
}

+ (void) syncWithJsonByUrl: (NSURL*) url completion:(void(^)()) completion
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setTimeoutInterval:10.0];
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    op.responseSerializer = [AFJSONResponseSerializer serializer];
    NSMutableSet* responseTypes = [NSMutableSet setWithSet:op.responseSerializer.acceptableContentTypes];
    [responseTypes addObject:@"text/html"];
    op.responseSerializer.acceptableContentTypes = responseTypes;
    
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, NSDictionary* responseObject) {
        [self syncWithJson:responseObject completion:completion];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
    }];
    
    [[NSOperationQueue mainQueue] cancelAllOperations];
    [[NSOperationQueue mainQueue] addOperation:op];
}



@end
