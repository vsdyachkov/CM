//
//  CMFRC.m
//  CoreMapping
//
//  Created by Dyachkov Victor on 20.03.15.
//  Copyright (c) 2015 Dyachkov Victor. All rights reserved.
//

#import "CMFRC.h"

@implementation CMFRC

static UITableView* CMTable;
static NSFetchRequest* CMRequest;
static NSString* cm_sectionNameKeyPath;
static NSFetchedResultsController* cm_fetchedResultsController;

+ (id)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = self;
    });
    return instance;
}

+ (void)initInTableView:(UITableView*)table withRequest:(NSFetchRequest*)request sectionNameKeyPath:(NSString*)path
{
    CMTable = table;
    CMRequest = request;
    cm_sectionNameKeyPath = path;
    
    CMTable.delegate = [self sharedManager];
   
    [NSFetchedResultsController deleteCacheWithName:nil];
    
    cm_fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:CMRequest
                                                                      managedObjectContext:[CMCoreData managedObjectContext]
                                                                        sectionNameKeyPath:cm_sectionNameKeyPath cacheName:nil];
    cm_fetchedResultsController.delegate = [self sharedManager];
    NSError* fetchError = nil;
    [cm_fetchedResultsController performFetch:&fetchError];
    
    [request addObserver:[self sharedManager] forKeyPath:@"entity" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [request addObserver:[self sharedManager] forKeyPath:@"predicate" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [request addObserver:[self sharedManager] forKeyPath:@"sortDescriptors" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString: @"entity"] ||
        [keyPath isEqualToString: @"sortDescriptors"] ||
        [keyPath isEqualToString: @"predicate"])
    {
        [NSFetchedResultsController deleteCacheWithName:nil];
        
        cm_fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:CMRequest
                                                                          managedObjectContext:[CMCoreData managedObjectContext]
                                                                            sectionNameKeyPath:cm_sectionNameKeyPath cacheName:nil];
        cm_fetchedResultsController.delegate = self;
        [cm_fetchedResultsController performFetch:nil];
        
        [UIView transitionWithView:CMTable duration:0.3f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            [CMTable reloadData];
        } completion:^(BOOL finished) {}];
    }
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [CMTable beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [CMTable endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type)
    {
        case NSFetchedResultsChangeInsert:
        {
            [CMTable insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        break;
        
        case NSFetchedResultsChangeDelete:
        {
            [CMTable deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        break;
        
        case NSFetchedResultsChangeUpdate:
        {
            [CMTable reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        break;
        
        case NSFetchedResultsChangeMove:
        {
            [CMTable deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [CMTable insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch (type)
    {
        case NSFetchedResultsChangeInsert:
        {
            [CMTable insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
        }
        break;
        
        case NSFetchedResultsChangeDelete:
        {
            [CMTable deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
        }
        break;
        
        case NSFetchedResultsChangeMove:
        {
            [CMTable reloadData];
        }
        break;
        
        case NSFetchedResultsChangeUpdate:
        {
            [CMTable reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
        }
        break;
    }
}

#pragma mark - TableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return cm_fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [cm_fetchedResultsController.sections[section] numberOfObjects];
}

#pragma mark - TableView Delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [UITableViewCell new];
    //[self.delegate configureCell]
    //configureCell:(UITableViewCell *)myCell atIndexPath:(NSIndexPath *)indexPath
    return cell;
}

@end
