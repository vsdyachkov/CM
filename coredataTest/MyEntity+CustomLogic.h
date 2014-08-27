//
//  MyEntity+CustomLogic.h
//  CoreMapping
//
//  Created by Dyachkov Victor on 26.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "MyEntity.h"

@interface MyEntity (CustomLogic)

- (void) customizeWithJson: (NSDictionary*) json;

@end
