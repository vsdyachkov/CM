//
//  CoreMapping.m
//  CoreMapping
//
//  Created by Dyachkov Victor on 26.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "CoreMapping.h"

@implementation CoreMapping



#pragma mark - Core Data stack


+ (NSManagedObjectModel *)managedObjectModel
{
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:SQLFileName withExtension:@"momd"];
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return managedObjectModel;
}

+ (NSManagedObjectContext *)managedObjectContext
{
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return managedObjectContext;
}

+ (NSManagedObjectContext *)childManagedObjectContext
{
    if (childManagedObjectContext != nil) {
        return childManagedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        NSManagedObjectContext *childManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [childManagedObjectContext setParentContext:[self managedObjectContext]];
    }
    return managedObjectContext;
}

+ (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
    
    NSString* pathComponent = [NSString stringWithFormat:@"%@.sqlite", SQLFileName];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:pathComponent];
    
    NSError *error = nil;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return persistentStoreCoordinator;
}

/*
+ (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}
 1750
*/

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
    [childManagedObjectContext save:&error];
    if (error) NSLog(@"Can't save child context, error: %@", error.localizedDescription);
    return error;
}

+ (NSManagedObjectContext*) contextForCurrentThread
{
    if ([NSThread isMainThread]) {
        return [self managedObjectContext];
    } else {
        return [self childManagedObjectContext];
    }
}



#pragma mark - Application's Documents directory


+ (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}



#pragma mark - Core Mapping stack


+ (void) mapValue:(id) value withJsonKey: (NSString*) key andType: (NSAttributeType) type andManagedObject: (NSManagedObject*) obj
{
    id convertedValue;
    NSString* strValue = [NSString stringWithFormat:@"%@",value];
    switch (type) {
        case NSUndefinedAttributeType: convertedValue =  nil; break;
        case NSInteger16AttributeType: convertedValue =  [NSNumber numberWithInt:[strValue integerValue]]; break;
        case NSInteger32AttributeType: convertedValue =  [NSNumber numberWithInt:[strValue integerValue]]; break;
        case NSInteger64AttributeType: convertedValue =  [NSNumber numberWithInt:[strValue integerValue]]; break;
        case NSDecimalAttributeType: convertedValue =    [NSNumber numberWithInt:[strValue doubleValue]]; break;
        case NSDoubleAttributeType: convertedValue =     [NSNumber numberWithInt:[strValue doubleValue]]; break;
        case NSFloatAttributeType: convertedValue =      [NSNumber numberWithInt:[strValue floatValue]]; break;
        case NSStringAttributeType: convertedValue =     strValue; break;
        case NSBooleanAttributeType: convertedValue =    [NSNumber numberWithInt:[strValue boolValue]]; break;
        case NSDateAttributeType: convertedValue =       nil; break;
        case NSBinaryDataAttributeType: convertedValue = [strValue dataUsingEncoding:NSUTF8StringEncoding]; break;
        /*
        case 1800:   return @"NSTransformableAttributeType";
        case 2000:   return @"NSObjectIDAttributeType";
        */
        default: [NSException raise:@"Invalid attribute type" format:@"This type is not supported in database"]; break;
    }
    [obj setValue:convertedValue forKey:key];
}


+ (NSManagedObject*) findOrCreateObjectInEntity: (NSEntityDescription*) entity withId: (NSNumber*) idNumber
{
    NSFetchRequest* req = [[NSFetchRequest alloc]initWithEntityName:entity.name];
    NSString* idString = [entity idKeyString];
    NSPredicate* myPred = [NSPredicate predicateWithFormat:@"%K == %@", idString, idNumber];
    [req setPredicate:myPred];
    NSArray* arr = [self.managedObjectContext executeFetchRequest:req error:nil];
    if (arr.count > 0) {
        return arr[0];
    } else {
        return [NSEntityDescription insertNewObjectForEntityForName:entity.name inManagedObjectContext:self.managedObjectContext];
    }
}


+ (NSManagedObject*) mapAllValuesInEntity: (NSEntityDescription*) desc andJsonDict: (NSDictionary*) json
{
    NSNumber* idFromJson = @([json[@"id"] integerValue]);
    NSManagedObject* obj = [self findOrCreateObjectInEntity:desc withId:idFromJson];
    NSDictionary* attributes = [desc attributesByName];
    [[attributes allValues] enumerateObjectsUsingBlock:^(NSAttributeDescription* attr, NSUInteger idx, BOOL *stop) {
        NSString* mappingAttrName = [attr mappingName];
        id valueFromJson = json [mappingAttrName];
        [self mapValue:valueFromJson withJsonKey:attr.name andType:attr.attributeType andManagedObject:obj];
    }];
    return obj;
}


+ (void) mapAllEntityWithJson: (NSDictionary*) json
{
    NSArray* entities = [self.managedObjectModel entities];
    [entities enumerateObjectsUsingBlock:^(NSEntityDescription* desc, NSUInteger idx, BOOL *stop) {
        NSString* mappingEntityName = [desc mappingName];
        NSArray* arrayWithName = json[mappingEntityName];
        [arrayWithName enumerateObjectsUsingBlock:^(NSDictionary* singleDict, NSUInteger idx, BOOL *stop) {
            NSManagedObject* obj = [self mapAllValuesInEntity:desc andJsonDict:singleDict];
            if ([obj respondsToSelector:NSSelectorFromString(@"customizeWithJson:")]) {
                [obj performSelector:NSSelectorFromString(@"customizeWithJson:") withObject:singleDict afterDelay:0];
            }
        }];
    }];
    [self saveContext];
}


+ (void) saveInBackgroundWithBlock: (void(^)(NSManagedObjectContext *context))block completion:(void(^)(BOOL success, NSError *error)) completion
{
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


+ (void)clearDatabase
{
    NSArray *entities = [[self.managedObjectModel entities] valueForKey:@"name"];
    
    for (NSString* entityName in entities)
    {
        NSString *entityDescription = entityName;
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:entityDescription inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        NSError *error;
        NSArray *items = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        for (NSManagedObject *managedObject in items) {
            [self.managedObjectContext deleteObject:managedObject];
        }
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"Error: %@",error.localizedDescription);
        }
    }
}


@end
