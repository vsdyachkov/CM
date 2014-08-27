//
//  MyEntity+CustomLogic.m
//  CoreMapping
//
//  Created by Dyachkov Victor on 26.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "MyEntity+CustomLogic.h"

@implementation MyEntity (CustomLogic)

- (void) customizeWithJson: (NSDictionary*) json
{
    self.myBool = @YES;
    //NSLog(@"self.myBool = %@", self.myBool);
}

@end
