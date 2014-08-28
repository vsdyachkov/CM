//
//  AppDelegate.m
//  CoreMapping
//
//  Created by Dyachkov Victor on 26.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "AppDelegate.h"
#import "MyEntity.h"

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = [UIViewController new];
    [self.window makeKeyAndVisible];
    
    [CoreMapping clearDatabase];
    
    NSDictionary* json = [self jsonWithFileName:@"test_add"];
    
    //[CoreMapping mapAllEntityWithJson:json];
    
    [CoreMapping saveInBackgroundWithBlock:^(NSManagedObjectContext *context) {
        [CoreMapping syncWithJson:json];
    } completion:^(BOOL success, NSError *error) {
        //[CoreMapping shortStatus];
    }];
    
    return YES;
    
}

- (NSDictionary*) jsonWithFileName: (NSString*) name
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:name ofType:@"json"];
    NSData *myJSON = [NSData dataWithContentsOfFile:filePath];
    return [NSJSONSerialization JSONObjectWithData:myJSON options:kNilOptions error:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [CoreMapping saveContext];
}


@end
