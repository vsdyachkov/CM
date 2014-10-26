//
//  CMConstants.h
//  CoreMapping
//
//  Created by Dyachkov Victor on 25.10.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#define errInvalidClassParam @"\n### Error: Invalid parameter class,"
#define errInvalidThread @"This function should be called from main thread !"
#define errNilParam @"\n### Error: One or more parameters is nil,"

static NSString* CMDefaultDateFormat = @"yyyy-LL-dd kk:mm:ss";

static NSString* CMSqlFileName = @"CoreMapping.sqlite";
static NSString* CMPrefix = @"CM";
static NSString* CMIdPrefix = @"CM_ID";
static NSString* CMNoParse = @"CM_NP";
static NSString* CMManyToManyName = @"CM_MM";

static NSString* CMJsonAddName = @"add";
static NSString* CMJsonRemoveName = @"remove";

static NSString* CMProgressNotificationName = @"CMProgressNotification";
static NSString* CMProgressEntityName = @"CMEntityName";
static NSString* CMProgress = @"CMProgress";
