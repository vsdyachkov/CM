//
//  MainViewController.m
//  CoreMapping
//
//  Created by Dyachkov Victor on 29.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "MainViewController.h"
#import "City.h"
#import "Phone.h"


@implementation MainViewController


- (void)viewDidLoad
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(progress:) name:CMprogressNotificationName object:nil];
    
    [super viewDidLoad];
    
    [CoreMapping clearDatabase];
    NSDictionary* json = [CMHelper jsonWithFileName:@"test_add"];

    [CoreMapping syncWithJson: json completion:^{
        [CoreMapping shortStatus];
    }];
    
}

- (void) progress: (NSNotification *) notification
{
    NSNumber* progress = [notification.userInfo objectForKey:CMprogressNotificationName];
    NSLog (@"progress: %@", progress);
}

@end
