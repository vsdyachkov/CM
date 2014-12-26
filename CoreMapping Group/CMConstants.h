//
//  CMConstants.h
//  CoreMapping
//
//  Created by Dyachkov Victor on 25.10.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

typedef enum {
    CMConnecting,
    CMDownloading,
    CMParsing,
    CMComplete
} CMStatusType;

typedef enum {
    CMOneToOne,
    CMOneToMany,
    CMManyToOne,
    CMManyToMany,
} CMRelationshipType;


#define CMThreadError @"[!] This function should be called from main thread !"
#define CMPathError @"[!] Value for key path not found"
#define CMModelError @"[!] File '.xcdatamodeld' not found or database does not contain entities"
#define CMMigrationError @"[!] Unable to migrate database, an attempt to solve the problem"
#define CMPersistentStoreError @"[!] Could not resolve the problem: can't create SQLite persistent store"
#define CMMigrationSuccess @"[i] The problem was solved: the database has been overwritten"
#define CMSavingMainContextError @"[!] There was an error when saving 'main' context"
#define CMSavingChildContextError @"[!] There was an error when saving 'child' context"
#define CMUnsupportedAttrException @"[!] Invalid attribute type"
#define CMUnsupportedAttrFormat @"[!] This type is not supported in database"

static NSString* CMDefaultDateFormat = @"yyyy-LL-dd kk:mm:ss";

static NSString* CMSqlFileName = @"CoreMapping.sqlite";
static NSString* CMPrefix = @"CM";
static NSString* CMIdPrefix = @"CM_ID";
static NSString* CMNoParse = @"CM_NP";
static NSString* CMManyToManyName = @"CM_MM";

static NSString* CMJsonAddName = @"add";
static NSString* CMJsonRemoveName = @"remove";

static NSString* CMProgressNotificationName = @"CMProgressNotification";
static NSString* CMStatus = @"CMStatus";
static NSString* CMProgress = @"CMProgress";
static NSString* CMRelationships = @"CMRelationships";
static NSString* CMEntityName = @"CMEntityName";



