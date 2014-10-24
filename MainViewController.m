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
    
    [super viewDidLoad];
    
    [CoreMapping clearDatabase];
    NSDictionary* json = [CMHelper jsonWithFileName:@"test_add"];

    [CoreMapping syncWithJson: json completion:^{
        [CoreMapping shortStatus];
    }];
    
}

@end
