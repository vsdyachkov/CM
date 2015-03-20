//
//  CMFRC.h
//  CoreMapping
//
//  Created by Dyachkov Victor on 20.03.15.
//  Copyright (c) 2015 Dyachkov Victor. All rights reserved.
//

#import "CoreMapping.h"

@interface CMFRC : NSObject <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

+ (void)initInTableView:(UITableView*)table withRequest:(NSFetchRequest*)request sectionNameKeyPath:(NSString*)path;

@end
