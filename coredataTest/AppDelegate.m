//
//  AppDelegate.m
//  CoreMapping
//
//  Created by Dyachkov Victor on 26.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "AppDelegate.h"
#import "City.h"
#import "Phone.h"

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = [UIViewController new];
    [self.window makeKeyAndVisible];
    
    [CoreMapping clearDatabase];
    
    NSDictionary* json = [self jsonWithFileName:@"test_add"];
    
    [CoreMapping saveInBackgroundWithBlock:^(NSManagedObjectContext *context) {
        [CoreMapping syncWithJson:json];
    } completion:^(BOOL success, NSError *error) {
        [CoreMapping shortStatus];
        [[City findAllRows] enumerateObjectsUsingBlock:^(City* obj, NSUInteger idx, BOOL *stop) {
            NSLog(@"name: '%@', phones: '%d'", obj.name, obj.phones.count);
        }];
    }];
    
    return YES;
    
}

- (NSDictionary*) jsonWithFileName: (NSString*) name
{
    NSAssert(name, @"%@ name: %@", errParameter, name);
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:name ofType:@"json"];
    NSData *myJSON = [NSData dataWithContentsOfFile:filePath];
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:myJSON options:kNilOptions error:nil];
    return json;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [CoreMapping saveContext];
}


@end
