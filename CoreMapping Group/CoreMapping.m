//
//  CoreMapping.m
//  CoreMapping
//
//  Created by Dyachkov Victor on 26.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "CoreMapping.h"

@implementation CoreMapping

static NSMutableString* report;
static bool hasNewData;
static NSUInteger currentActionsCount;
static NSUInteger totalActionsCount;
static NSDate* parseTime;
static NSMutableDictionary* relationshipDictionary;

#pragma mark - Mapping methods

+ (void) mapValue:(id)value withJsonKey:(NSString*)key andType:(NSAttributeType)type andManagedObject:(NSManagedObject*)obj
{
    
    [CMExtensions validateValue:key withClass:[NSString class]];
    [CMExtensions validateValue:obj withClass:[NSManagedObject class]];
    
    id convertedValue;
    NSString* strValue = [NSString stringWithFormat:@"%@",value];
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    [format setDateFormat: CMDefaultDateFormat];
    switch (type)
    {
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
            
        default: [NSException raise:CMUnsupportedAttrException format:CMUnsupportedAttrFormat]; break;
    }
    
    [CMExtensions validateValue:convertedValue withClass:[convertedValue class]];
    [CMExtensions validateValue:key withClass:[key class]];
    
    [obj setValue:convertedValue forKey:key];
}

+ (NSManagedObject*) findObjectInEntity:(NSEntityDescription*)entity withId:(NSNumber*)idNumber enableCreating:(BOOL)create
{
    [CMExtensions validateValue:entity withClass:[NSEntityDescription class]];
    [CMExtensions validateValue:idNumber withClass:[NSNumber class]];
    
    NSFetchRequest* req = [[NSFetchRequest alloc]initWithEntityName:entity.name];
    NSString* idKey = [entity mappingIdKey];
    NSPredicate* myPred = [NSPredicate predicateWithFormat:@"%K == %@", idKey, idNumber];
    [req setPredicate:myPred];
    
    NSArray* arr = [[CMCoreData managedObjectContext] executeFetchRequest:req error:nil];
    if (arr.count > 0) {
        return arr[0];
    } else {
        if (create) {
            return [NSEntityDescription insertNewObjectForEntityForName:entity.name inManagedObjectContext:[CMCoreData managedObjectContext]];
        } else {
            return nil;
        }
        
    }
}

+ (NSManagedObject*) mapSingleRowInEntity:(NSEntityDescription*)desc andJsonDict:(NSDictionary*)json
{
    [CMExtensions validateValue:desc withClass:[NSEntityDescription class]];
    [CMExtensions validateValue:json withClass:[NSDictionary class]];
    
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
        if (valueFromJson)
        {
            [self mapValue:valueFromJson withJsonKey:attr.name andType:attr.attributeType andManagedObject:obj];
        }
    }];
    
    [self mapRelationshipsWithObject:obj andJsonDict:json];
    
    [CMExtensions validateValue:obj withClass:[NSManagedObject class]];
    
    return obj;
}

+ (NSMutableDictionary*) addRelationshipIfNeed:(NSString*)name andRelationship:(NSRelationshipDescription*)relationship
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

+ (void) mapRelationshipsWithObject:(NSManagedObject*)obj andJsonDict:(NSDictionary*)json
{
    [CMExtensions validateValue:obj withClass:[NSManagedObject class]];
    [CMExtensions validateValue:json withClass:[NSDictionary class]];
    
    // perform all relationships
    NSEntityDescription* desc = obj.entity;
    for (NSString* name in desc.relationshipsByName) {
        NSRelationshipDescription* relationFromChild = desc.relationshipsByName[name];
        NSRelationshipDescription* inverseFromParent = relationFromChild.inverseRelationship;
        
        if (relationFromChild && inverseFromParent && ![relationFromChild manyToManyTableName]) {
            // This (many) Childs to -> (one) Parent
            NSEntityDescription* destinationEntity = relationFromChild.destinationEntity;
            NSString* relationMappedName = [relationFromChild mappingName];
            NSNumber* idObjectFormJson = json[relationMappedName];
            if (idObjectFormJson && [idObjectFormJson isKindOfClass:[NSNumber class]]) {
                // Relationship found
                NSManagedObject* toObject = [self findObjectInEntity:destinationEntity withId:idObjectFormJson enableCreating:NO];
                if (toObject)
                {
                    NSString* objectName = [NSString stringWithFormat:@"%@%@",[[inverseFromParent.name substringToIndex:1] uppercaseString],[inverseFromParent.name substringFromIndex:1] ];
                    NSString* selectorName = [NSString stringWithFormat:@"add%@Object:", objectName];
                    [toObject performSelectorIfResponseFromString:selectorName withObject:obj];
                }
            }
        } else {
            [self addRelationshipIfNeed:[relationFromChild manyToManyTableName] andRelationship:relationFromChild];
        }
        
    }
}

+ (void) mapAllRowsInEntity:(NSEntityDescription*)desc andWithJsonArray:(NSArray*)jsonArray
{
    [CMExtensions validateValue:desc withClass:[NSEntityDescription class]];
    [CMExtensions validateValue:jsonArray withClass:[NSArray class]];
    
    [jsonArray enumerateObjectsUsingBlock:^(NSDictionary* singleDict, NSUInteger idx, BOOL *stop)
     {
         NSManagedObject* obj = [self mapSingleRowInEntity:desc andJsonDict:singleDict];
         [obj performSelectorIfResponseFromString:CMCustomParse withObject:singleDict];
         
         currentActionsCount--;
         [self progressNotificationWithStatus:CMParsing progress:1-(float)currentActionsCount/totalActionsCount andEntity:desc];
     }];
}

+ (void) removeRowsInEntity:(NSEntityDescription*)desc withNumberArray:(NSArray*)removeArray
{
    [CMExtensions validateValue:desc withClass:[NSEntityDescription class]];
    [CMExtensions validateValue:removeArray withClass:[NSArray class]];
    
    [removeArray enumerateObjectsUsingBlock:^(NSNumber* removeId, NSUInteger idx, BOOL *stop) {
        NSFetchRequest* req = [[NSFetchRequest alloc]initWithEntityName:desc.name];
        NSPredicate* myPred = [NSPredicate predicateWithFormat:@"%K == %@", [desc mappingIdKey], removeId];
        [req setPredicate:myPred];
        NSArray* arr = [[CMCoreData managedObjectContext] executeFetchRequest:req error:nil];
        if (arr.count > 0) {
            [[CMCoreData managedObjectContext] deleteObject:arr[0]];
        }
        
        currentActionsCount--;
        [self progressNotificationWithStatus:CMParsing progress:1-(float)currentActionsCount/totalActionsCount andEntity:desc];
    }];
}

#pragma mark - Parse methods

+ (NSMutableArray*) entitiesForParsing
{
    // Remove not parsing entities
    NSMutableArray* entities = [[CMCoreData managedObjectModel] entities].mutableCopy;
    [entities.copy enumerateObjectsUsingBlock:^(NSEntityDescription* obj, NSUInteger idx, BOOL *stop) {
        if ([obj isNoParse]) {
            [entities removeObject:obj];
        }
    }];
    
    [entities sortUsingComparator:^NSComparisonResult(NSEntityDescription* entity1, NSEntityDescription* entity2)
     {
         NSString* ord1 = entity1.userInfo[CMParseOrd];
         NSString* ord2 = entity2.userInfo[CMParseOrd];
         
         if (!ord1 && !ord2) return NSOrderedSame;
         if (!ord1 && ord2) return NSOrderedDescending;
         if (ord1 && !ord2) return NSOrderedAscending;
         
         NSInteger ord1Int = [ord1 integerValue];
         NSInteger ord2Int = [ord2 integerValue];
         
         if (ord1Int > ord2Int) return NSOrderedDescending;
         if (ord1Int < ord2Int) return NSOrderedAscending;
         
         return NSOrderedSame;
     }];
    
    return entities;
}

+ (void) parseAddBlockForEntity:(NSEntityDescription*)entity withJson:(NSDictionary*)json
{
    NSDictionary* jsonTable = json[entity.mappingEntityName];
    if ([jsonTable.allKeys containsObject:CMJsonAddName])
    {
        NSDate* startDate = [NSDate date];
        hasNewData = YES;
        NSArray* addArray = [CMExtensions validateValue:json[entity.mappingEntityName][CMJsonAddName] withClass:[NSArray class]];
        printf ("%s", [[NSString stringWithFormat:@"[+] Adding %lu '%@' from Json -> %@ -> %@ ... ", (unsigned long)addArray.count, entity.mappingEntityName, entity.mappingEntityName,CMJsonAddName] UTF8String]);
        if (addArray) [self mapAllRowsInEntity:entity andWithJsonArray:addArray];
        printf("%s\n", [[NSString stringWithFormat:@"(%.1f sec)", [[NSDate date] timeIntervalSinceDate:startDate]] UTF8String]);
    } else {
        printf ("%s\n", [[NSString stringWithFormat:@"[i] No 'add' section in Json -> %@ -> %@", entity.mappingEntityName, CMJsonAddName] UTF8String]);
    }
}

+ (void) parseRemoveBlockForEntity:(NSEntityDescription*)entity withJson:(NSDictionary*)json
{
    NSDictionary* jsonTable = json[entity.mappingEntityName];
    if ([jsonTable.allKeys containsObject:CMJsonRemoveName])
    {
        NSDate* startDate = [NSDate date];
        hasNewData = YES;
        NSArray* removeArray = [CMExtensions validateValue:json[entity.mappingEntityName][CMJsonRemoveName] withClass:[NSArray class]];
        printf ("%s", [[NSString stringWithFormat:@"[-] Removing %lu '%@' from Json -> %@ -> %@ ... ", (unsigned long)removeArray.count, entity.mappingEntityName, entity.mappingEntityName, CMJsonRemoveName] UTF8String]);
        if (removeArray) [self removeRowsInEntity:entity withNumberArray:(NSArray*)removeArray];
        printf("%s\n", [[NSString stringWithFormat:@"(%.1f sec)", [[NSDate date] timeIntervalSinceDate:startDate]] UTF8String]);
    } else {
        printf ("%s\n", [[NSString stringWithFormat:@"[i] No 'remove' section in Json -> %@ -> %@", entity.mappingEntityName, CMJsonRemoveName] UTF8String]);
    }
}

+ (void) parseRelationshipsWithJson: (NSDictionary*) json
{
    // Parsing relationship tables
    for (NSString* tableName in [relationshipDictionary.copy allKeys])
    {
        if (!json[tableName]) {
            [relationshipDictionary removeObjectForKey:tableName];
        }
    }
    
    int relations = 0;
    
    for (NSString* key in relationshipDictionary.allKeys)
    {
        if (![json.allKeys containsObject:key]) continue;
        NSDictionary* relationDict = [json objectForKey:key];
        
        relationDict = [CMExtensions validateValue:relationDict withClass:[NSDictionary class]];
        
        if (![relationDict.allKeys containsObject:CMJsonAddName]) continue;
        NSArray* addArray = [relationDict objectForKey:CMJsonAddName];
        
        for (NSDictionary* tmpJson in addArray)
        {
            if (![CMExtensions validateValue:tmpJson withClass:[NSDictionary class]]) {
                continue;
            }
            
            relations++;
            
            NSRelationshipDescription* relationFromChild = [relationshipDictionary objectForKey:key];
            NSRelationshipDescription* inverseFromParent = relationFromChild.inverseRelationship;
            
            NSEntityDescription* childEntity = relationFromChild.entity;
            NSEntityDescription* destinationEntity = relationFromChild.destinationEntity;
            
            NSString* key1 = [childEntity mappingIdKey];
            NSString* key2 = [destinationEntity mappingIdKey];
            
            NSNumber* value1 = @([tmpJson[key1] integerValue]);
            NSNumber* value2 = @([tmpJson[key2] integerValue]);
            
            if (value1 && value2)
            {
                // Relationship found
                NSManagedObject* firstObject = [self findObjectInEntity:childEntity withId:value1 enableCreating:NO];
                NSManagedObject* secondObject = [self findObjectInEntity:destinationEntity withId:value2 enableCreating:NO];
                
                if (firstObject && secondObject)
                {
                    NSString* selectorName = [NSString stringWithFormat:@"add%@Object:", inverseFromParent.name.capitalizedString];
                    [secondObject performSelectorIfResponseFromString:selectorName withObject:firstObject];
                }
            }
        }
        
        if (![relationDict.allKeys containsObject:CMJsonRemoveName]) continue;
        NSArray* removeArray = [relationDict objectForKey:CMJsonRemoveName];
        
        for (NSDictionary* tmpJson in removeArray)
        {
            if (![CMExtensions validateValue:tmpJson withClass:[NSDictionary class]]) {
                continue;
            }
            
            relations++;
            
            NSRelationshipDescription* relationFromChild = [relationshipDictionary objectForKey:key];
            NSRelationshipDescription* inverseFromParent = relationFromChild.inverseRelationship;
            
            NSEntityDescription* childEntity = relationFromChild.entity;
            NSEntityDescription* destinationEntity = relationFromChild.destinationEntity;
            
            NSString* key1 = [childEntity mappingIdKey];
            NSString* key2 = [destinationEntity mappingIdKey];
            
            NSNumber* value1 = @([tmpJson[key1] integerValue]);
            NSNumber* value2 = @([tmpJson[key2] integerValue]);
            
            if (value1 && value2)
            {
                // Relationship found
                NSManagedObject* firstObject = [self findObjectInEntity:childEntity withId:value1 enableCreating:NO];
                NSManagedObject* secondObject = [self findObjectInEntity:destinationEntity withId:value2 enableCreating:NO];
                
                if (firstObject && secondObject)
                {
                    NSString* selectorName = [NSString stringWithFormat:@"remove%@Object:", inverseFromParent.name.capitalizedString];
                    [secondObject performSelectorIfResponseFromString:selectorName withObject:firstObject];
                }
            }
        }
        
    }
    
    if (relations>0) {
        hasNewData = YES;
        printf ("%s\n", [[NSString stringWithFormat:@"[+] Add %d relationship from tables: Json -> %@", relations, [relationshipDictionary.allKeys componentsJoinedByString:@", "]] UTF8String]);
    } else {
        printf ("%s\n", [[NSString stringWithFormat:@"[i] No relationship tables found"] UTF8String]);
    }
    
}

#pragma mark - Helper method

+ (NSDictionary*) jsonWithFileName:(NSString*)name error:(NSError**)error
{
    [CMExtensions validateValue:name withClass:[NSString class]];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:name ofType:@"json"];
    
    [CMExtensions validateValue:filePath withClass:[NSString class]];
    
    NSDictionary* json;
    NSData *myJSON = [NSData dataWithContentsOfFile:filePath];
    if (myJSON)
    {
        json = [NSJSONSerialization JSONObjectWithData:myJSON options:kNilOptions error:error];
    }
    else
    {
        printf ("%s\n", [[NSString stringWithFormat:@"[!] File with name '%@' not found in mainBundle", name] UTF8String]);
    }
    
    return json;
}

+ (void) progressNotificationWithStatus:(CMStatusType)status progress:(float)progress andEntity:(NSEntityDescription*)entity
{
    NSString* text;
    switch (status)
    {
        case CMConnecting: text = @"Соединение ..."; break;
        case CMDownloading: text = [NSString stringWithFormat:@"Загрузка ..."]; break;
        case CMParsing: text = [NSString stringWithFormat:@"Обработка данных ..."]; break;
        case CMComplete: text = @"Готово"; break;
        default: text = @" "; break;
    }
    
    // loading indicator
    if (status != CMComplete)
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
    
    // Post on main thread
    NSDictionary* userInfo = @{CMText:text, CMStatus:@(status), CMProgress:@(progress), CMEntityName:(entity) ? entity.mappingEntityName : [NSNull null]};
    dispatch_async(dispatch_get_main_queue(),^{
        [[NSNotificationCenter defaultCenter] postNotificationName:CMProgressNotificationName object:nil userInfo:userInfo];
    });
}

#pragma mark - Counter methods

+ (void) countActionsForEntity:(NSEntityDescription*)entity withJson:(NSDictionary*)json
{
    NSDictionary* jsonTable = json[entity.mappingEntityName];
    if ([jsonTable.allKeys containsObject:CMJsonAddName])
    {
        hasNewData = YES;
        NSArray* addArray = [CMExtensions validateValue:json[entity.mappingEntityName][CMJsonAddName] withClass:[NSArray class]];
        totalActionsCount += addArray.count;
    }
    
    if ([jsonTable.allKeys containsObject:CMJsonRemoveName])
    {
        hasNewData = YES;
        NSArray* removeArray = [CMExtensions validateValue:json[entity.mappingEntityName][CMJsonRemoveName] withClass:[NSArray class]];
        totalActionsCount += removeArray.count;
    }
}

#pragma mark - Sync methods

+ (void) syncWithJson:(NSDictionary*)json;
{
    NSDate* parseTime = [NSDate date];
    hasNewData = NO;
    [CMExtensions validateValue:json withClass:[NSDictionary class]];
    
    printf ("\n%s", [[NSString stringWithFormat:@"Parsing status: "] UTF8String]);
    
    [self progressNotificationWithStatus:CMParsing progress:0.0f andEntity:nil];
    
    NSMutableArray* entities = [self entitiesForParsing];
    
    /* counters */
    totalActionsCount = 0;
    [entities enumerateObjectsUsingBlock:^(NSEntityDescription* entity, NSUInteger idx, BOOL *stop)
     {
         if ([CMExtensions validateValue:json[entity.mappingEntityName] withClass:[NSDictionary class]])
         {
             [self countActionsForEntity:entity withJson:json];
         }
     }];
    currentActionsCount = totalActionsCount;
    printf ("%s\n", [[NSString stringWithFormat:@"(total %lu actions)", (unsigned long)totalActionsCount] UTF8String]);
    /* */
    
    [entities enumerateObjectsUsingBlock:^(NSEntityDescription* entity, NSUInteger idx, BOOL *stop)
     {
         if ([CMExtensions validateValue:json[entity.mappingEntityName] withClass:[NSDictionary class]])
         {
             // add
             [self parseAddBlockForEntity:entity withJson:json];
             
             // remove
             [self parseRemoveBlockForEntity:entity withJson:json];
         }
         else
         {
             printf ("%s\n", [[NSString stringWithFormat:@"[!] Json -> '%@' not found or not array", entity.mappingEntityName] UTF8String]);
         }
     }];
    
    // relationships
    NSEntityDescription* relationEntity = [NSEntityDescription new];
    relationEntity.name = CMRelationships;
    [self progressNotificationWithStatus:CMParsing progress:1.0f andEntity:relationEntity];
    [self parseRelationshipsWithJson:json];
    
    [CMCoreData saveContext];
    printf("%s\n\n", [[NSString stringWithFormat:@"[√] Complete, total %.1f sec", [[NSDate date] timeIntervalSinceDate:parseTime]] UTF8String]);
    [CMCoreData shortStatus];
    
    [self progressNotificationWithStatus:CMComplete progress:1.0f andEntity:nil];
}


+ (void) syncWithJson:(NSDictionary*)json completion:(void(^)(NSDictionary* json))completion
{
    [CMExtensions validateValue:json withClass:[NSDictionary class]];
    
    [CMCoreData databaseOperationInBackground:^{
        [self syncWithJson:json];
    } completion:^{
        completion(json);
    }];
}

+ (void) syncWithJsonByName: (NSString*) name error: (NSError*) error;
{
    [CMExtensions validateValue:name withClass:[NSString class]];
    
    NSDictionary* json = [self jsonWithFileName:name error:&error];
    [self syncWithJson:json];
}

+ (void) syncWithJsonByName:(NSString*)name success:(void(^)(NSDictionary* json))success failure:(void(^)(NSError *error))failure;
{
    [CMExtensions validateValue:name withClass:[NSString class]];
    
    NSError* error;
    NSDictionary* json = [self jsonWithFileName:name error:&error];
    if (json) {
        [CMCoreData databaseOperationInBackground:^{
            [self syncWithJson:json];
        } completion:^{
            success(json);
        }];
    } else {
        failure(error);
    }
}

+ (void) syncWithJsonByUrl:(NSURL*)url withParameters:(NSDictionary*)parameters success:(void(^)(NSDictionary* json))success failure:(void(^)(NSError *error))failure
{
    [CMExtensions validateValue:url withClass:[NSURL class]];
    if (!url) {
        printf ("%s\n", [[NSString stringWithFormat:@"[!] Sync url is nil!"] UTF8String]);
        return;
    }
    
    AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html", @"application/json", nil];
    
    [CMExtensions validateValue:url withClass:[NSURL class]];
    if (parameters) {
        printf ("%s\n", [[NSString stringWithFormat:@"[i] Downloading Json ... \n └> url: %@\n └> parameters: %@", url.absoluteString, parameters] UTF8String]);
    } else {
        printf ("%s\n", [[NSString stringWithFormat:@"[i] Downloading Json ... \n └> url: %@", url.absoluteString] UTF8String]);
    }
    
    [self progressNotificationWithStatus:CMConnecting progress:0.0f andEntity:nil];
    __block NSDate* startDate = [NSDate date];
    
    AFHTTPRequestOperation *requestOperation = [manager GET:[url absoluteString] parameters:parameters success:^(AFHTTPRequestOperation *operation, NSDictionary* responseObject) {
        printf ("%s\n", [[NSString stringWithFormat:@"[i] Json downloaded! (%.1f sec)", [[NSDate date] timeIntervalSinceDate:startDate]] UTF8String]);
        [CMCoreData databaseOperationInBackground:^{
            [self syncWithJson:responseObject];
        } completion:^{
            success(responseObject);
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error)  {
        printf ("%s\n", [[NSString stringWithFormat:@"[!] Json not downloaded! \n └> url: %@\n └> error: %@", url.absoluteString, error.localizedDescription] UTF8String]);
        [self progressNotificationWithStatus:CMComplete progress:1.0f andEntity:nil];
        failure(error);
    }];
    
    __weak AFHTTPRequestOperation* operation = requestOperation;
    
    [requestOperation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        NSInteger totalContentSize = [operation.response.allHeaderFields[@"X-Uncompressed-Content-Length"] integerValue];
        float progress = (totalContentSize > 0) ? (float)totalBytesRead / totalContentSize : 0.0f;
        [self progressNotificationWithStatus:CMDownloading progress:progress andEntity:nil];
    }];
}

+ (void) performFetchByUrl:(NSURL*)url withParameters:(NSDictionary*)parameters completion:(void(^)(UIBackgroundFetchResult result))completion
{
    [self syncWithJsonByUrl:url withParameters:parameters success:^(NSDictionary *json) {
        if (hasNewData) {
            completion (UIBackgroundFetchResultNewData);
        } else {
            completion (UIBackgroundFetchResultNoData);
        }
    } failure:^(NSError *error) {
        completion (UIBackgroundFetchResultFailed);
    }];
}

@end
