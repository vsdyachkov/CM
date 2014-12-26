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
static NSMutableDictionary* relationshipDictionary;

#pragma mark - Mapping methods

+ (void) mapValue:(id) value withJsonKey: (NSString*) key andType: (NSAttributeType) type andManagedObject: (NSManagedObject*) obj
{
    [CMTests validateValue:key withClass:[NSString class]];
    [CMTests validateValue:obj withClass:[NSManagedObject class]];
    
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
    
    [CMTests validateValue:convertedValue withClass:[convertedValue class]];
    [CMTests validateValue:key withClass:[key class]];
    
    [obj setValue:convertedValue forKey:key];
}

+ (NSManagedObject*) findObjectInEntity: (NSEntityDescription*) entity withId: (NSNumber*) idNumber enableCreating: (BOOL) create
{
    [CMTests validateValue:entity withClass:[NSEntityDescription class]];
    [CMTests validateValue:idNumber withClass:[NSNumber class]];
    
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

+ (NSManagedObject*) mapSingleRowInEntity: (NSEntityDescription*) desc andJsonDict: (NSDictionary*) json
{
    [CMTests validateValue:desc withClass:[NSEntityDescription class]];
    [CMTests validateValue:json withClass:[NSDictionary class]];
    
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
    
    [CMTests validateValue:obj withClass:[NSManagedObject class]];
    
    return obj;
}

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

+ (void) mapRelationshipsWithObject: (NSManagedObject*) obj andJsonDict: (NSDictionary*) json
{
    [CMTests validateValue:obj withClass:[NSManagedObject class]];
    [CMTests validateValue:json withClass:[NSDictionary class]];
    
    // perform Relationships: ManyToOne & OneToOne & OneToMany
    NSEntityDescription* desc = obj.entity;
    for (NSString* name in desc.relationshipsByName) {
        NSRelationshipDescription* relationFromChild = desc.relationshipsByName[name];
        NSRelationshipDescription* inverseFromParent = relationFromChild.inverseRelationship;
        
        if ((relationFromChild && inverseFromParent) &&  ![[relationFromChild relationshipType] isEqual: @3]) {
            // This (many) Childs to -> (one) Parent
            NSEntityDescription* destinationEntity = relationFromChild.destinationEntity;
            NSString* relationMappedName = [relationFromChild mappingName];
            NSNumber* idObjectFormJson = json[relationMappedName];
            if (idObjectFormJson && [idObjectFormJson isKindOfClass:[NSNumber class]]) {
                // Relationship found
                NSManagedObject* toObject = [self findObjectInEntity:destinationEntity withId:idObjectFormJson enableCreating:NO];
                if (toObject)
                {
                    NSString* selectorName = [NSString stringWithFormat:@"add%@Object:", inverseFromParent.name.capitalizedString];
                    [toObject performSelectorIfResponseFromString:selectorName withObject:obj];
                }

            }
        } else {
            [self addRelationshipIfNeed:[relationFromChild manyToManyTableName] andRelationship:relationFromChild];
        }
        
    }
}

+ (void) mapAllRowsInEntity: (NSEntityDescription*) desc andWithJsonArray: (NSArray*) jsonArray
{
    [CMTests validateValue:desc withClass:[NSEntityDescription class]];
    [CMTests validateValue:jsonArray withClass:[NSArray class]];
    
    [jsonArray enumerateObjectsUsingBlock:^(NSDictionary* singleDict, NSUInteger idx, BOOL *stop) {
        NSManagedObject* obj = [self mapSingleRowInEntity:desc andJsonDict:singleDict];
        [obj performSelectorIfResponseFromString:@"customizeWithJson:" withObject:singleDict];
    }];
}

+ (void) removeRowsInEntity: (NSEntityDescription*) desc withNumberArray: (NSArray*) removeArray
{
    [CMTests validateValue:desc withClass:[NSEntityDescription class]];
    [CMTests validateValue:removeArray withClass:[NSArray class]];
    
    [removeArray enumerateObjectsUsingBlock:^(NSNumber* removeId, NSUInteger idx, BOOL *stop) {
        NSFetchRequest* req = [[NSFetchRequest alloc]initWithEntityName:desc.name];
        NSPredicate* myPred = [NSPredicate predicateWithFormat:@"%K == %@", [desc mappingIdKey], removeId];
        [req setPredicate:myPred];
        NSArray* arr = [[CMCoreData managedObjectContext] executeFetchRequest:req error:nil];
        if (arr.count > 0) {
            [[CMCoreData managedObjectContext] deleteObject:arr[0]];
        }
    }];
}

#pragma mark - Sync methods

+ (NSMutableArray*) entitiesForParsing
{
    // Remove not parsing entities
    NSMutableArray* entities = [[CMCoreData managedObjectModel] entities].mutableCopy;
    [entities.copy enumerateObjectsUsingBlock:^(NSEntityDescription* obj, NSUInteger idx, BOOL *stop) {
        if ([obj isNoParse]) {
            [entities removeObject:obj];
        }
    }];
    return entities;
}

+ (void) parseAddBlockForEntity: (NSEntityDescription*) entity withJson: (NSDictionary*) json
{
    NSDictionary* jsonTable = json[entity.mappingEntityName];
    if ([jsonTable.allKeys containsObject:CMJsonAddName])
    {
        NSArray* addArray = [CMTests validateValue:json[entity.mappingEntityName][CMJsonAddName] withClass:[NSArray class]];
        CFLog(@"[+] Added %lu '%@' from Json -> %@ -> %@\n", (unsigned long)addArray.count, entity.mappingEntityName, entity.mappingEntityName,CMJsonAddName);
        if (addArray) [self mapAllRowsInEntity:entity andWithJsonArray:addArray];
    } else {
        CFLog(@"[i] No 'add' section in Json -> %@ -> %@\n", entity.mappingEntityName, CMJsonAddName);
    }
}

+ (void) parseRemoveBlockForEntity: (NSEntityDescription*) entity withJson: (NSDictionary*) json
{
    NSDictionary* jsonTable = json[entity.mappingEntityName];
    if ([jsonTable.allKeys containsObject:CMJsonRemoveName])
    {
        NSArray* removeArray = [CMTests validateValue:json[entity.mappingEntityName][CMJsonRemoveName] withClass:[NSArray class]];
        CFLog(@"[-] Removed %lu '%@' from Json -> %@ -> %@\n", (unsigned long)removeArray.count, entity.mappingEntityName, entity.mappingEntityName, CMJsonRemoveName);
        if (removeArray) [self removeRowsInEntity:entity withNumberArray:(NSArray*)removeArray];
    } else {
        CFLog(@"[i] No 'remove' section in Json -> %@ -> %@\n", entity.mappingEntityName, CMJsonRemoveName);
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
        
        if (![relationDict.allKeys containsObject:CMJsonAddName]) continue;
        NSArray* addArray = [relationDict objectForKey:CMJsonAddName];
        
        for (NSDictionary* tmpJson in addArray)
        {
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
    }
    
    if (relations>0) {
        CFLog(@"[+] Add %d relationship from tables: Json -> %@", relations, relationshipDictionary.allKeys);
    } else {
        CFLog(@"[i] No relationship tables found");
    }
    
}

#pragma mark - Helper method

void CFLog(NSString *format, ...)
{
    if (!format) {
        return;
    }
    
    va_list args;
    va_start(args, format);
    
    CFShow((__bridge CFStringRef)[[NSString alloc] initWithFormat:format arguments:args]);
    
    va_end(args);
}

+ (NSDictionary*) jsonWithFileName: (NSString*) name error: (NSError**) error
{
    [CMTests validateValue:name withClass:[NSString class]];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:name ofType:@"json"];
    
    [CMTests validateValue:filePath withClass:[NSString class]];
    
    NSData *myJSON = [NSData dataWithContentsOfFile:filePath];
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:myJSON options:kNilOptions error:error];
    
    return json;
}

+ (void) progressNotificationWithStatus: (CMStatusType) status progress: (float) progress andEntity: (NSEntityDescription*) entity
{
    NSDictionary* userInfo;
    if (entity) {
        userInfo = @{CMStatus:@(status), CMProgress:@(progress), CMEntityName:entity.mappingEntityName};
    } else {
        userInfo = @{CMStatus:@(status), CMProgress:@(progress)};
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:CMProgressNotificationName object:nil userInfo:userInfo];
}

#pragma mark - Sync methods

+ (void) syncWithJson: (NSDictionary*) json;
{
    [CMTests validateValue:json withClass:[NSDictionary class]];
    
    CFLog(@"\nParsing status:\n");
    [self progressNotificationWithStatus:CMParsing progress:0.0f andEntity:nil];
    
    NSMutableArray* entities = [self entitiesForParsing];
    [entities enumerateObjectsUsingBlock:^(NSEntityDescription* entity, NSUInteger idx, BOOL *stop)
    {
        if ([CMTests validateValue:json[entity.mappingEntityName] withClass:[NSDictionary class]])
        {
            [self parseAddBlockForEntity:entity withJson:json];
            [self progressNotificationWithStatus:CMParsing progress:(float)(idx+0.5f)/(entities.count+1) andEntity:entity];
        
            [self parseRemoveBlockForEntity:entity withJson:json];
            [self progressNotificationWithStatus:CMParsing progress:(float)(idx+1.0f)/(entities.count+1) andEntity:entity];
        }
        else
        {
            CFLog(@"[!] Json -> '%@' not found or not array\n", entity.mappingEntityName);
        }
    }];
    
    [self parseRelationshipsWithJson:json];
    [self progressNotificationWithStatus:CMParsing progress:1.0f andEntity:nil];
    
    [CMCoreData saveContext];
    [CMCoreData shortStatus];

    [self progressNotificationWithStatus:CMComplete progress:1.0f andEntity:nil];
}


+ (void) syncWithJson: (NSDictionary*) json completion:(void(^)(NSDictionary* json)) completion
{
    [CMTests validateValue:json withClass:[NSDictionary class]];
    
    [CMCoreData databaseOperationInBackground:^{
        [self syncWithJson:json];
    } completion:^{
        completion(json);
    }];
}

+ (void) syncWithJsonByName: (NSString*) name error: (NSError*) error;
{
    [CMTests validateValue:name withClass:[NSString class]];
    
    NSDictionary* json = [self jsonWithFileName:name error:&error];
    [self syncWithJson:json];
}

+ (void) syncWithJsonByName: (NSString*) name success:(void(^)(NSDictionary* json)) success failure: (void(^)(NSError *error)) failure;
{
    [CMTests validateValue:name withClass:[NSString class]];
    
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

+ (void) syncWithJsonByUrl: (NSURL*) url success:(void(^)(NSDictionary* json)) success failure: (void(^)(NSError *error)) failure
{
    [CMTests validateValue:url withClass:[NSURL class]];

    [self progressNotificationWithStatus:CMConnecting progress:0.0f andEntity:nil];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    //[request setTimeoutInterval:10.0];
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    op.responseSerializer = [AFJSONResponseSerializer serializer];
    NSMutableSet* responseTypes = [NSMutableSet setWithSet:op.responseSerializer.acceptableContentTypes];
    [responseTypes addObject:@"text/html"];
    op.responseSerializer.acceptableContentTypes = responseTypes;
    
    CFLog(@"\n[i] Downloading Json from url:\n%@", url);
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, NSDictionary* responseObject) {
        CFLog(@"\n[i] Json downloaded from url:\n%@\n", url);
        [CMCoreData databaseOperationInBackground:^{
            [self syncWithJson:responseObject];
        } completion:^{
            success(responseObject);
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        CFLog(@"\n[!] Json not downloaded from url:\n%@error: %@\n", url, error.localizedDescription);
        [self progressNotificationWithStatus:CMComplete progress:1.0f andEntity:nil];
        failure(error);
    }];
    
    __weak AFHTTPRequestOperation* operation = op;
    
    [op setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead)
    {
        NSInteger totalContentSize = [operation.response.allHeaderFields[@"X-Uncompressed-Content-Length"] integerValue];
        float progress = (totalContentSize > 0) ? (float)totalBytesRead / totalContentSize : 0.0f;
        [self progressNotificationWithStatus:CMDownloading progress:progress andEntity:nil];
    }];
    
    [[NSOperationQueue mainQueue] cancelAllOperations];
    [[NSOperationQueue mainQueue] addOperation:op];
}

@end
