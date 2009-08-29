//
//  HeadlineViewController.h
//  gohuskies
//
//  Created by Jeff Dlouhy on 7/2/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

@protocol FeedViewDelegate <NSFetchedResultsControllerDelegate>
- (void)insertNewEntry:(NSDictionary*)aNewObject;
- (BOOL)insertNewEntries:(NSArray*)newEntries;
@end

@interface HeadlineViewController : UITableViewController <NSFetchedResultsControllerDelegate, FeedViewDelegate> {
	NSFetchedResultsController* fetchedResultsController;
	NSManagedObjectContext* managedObjectContext;

  NSMutableArray* mEntryArray;
}

@property (nonatomic, retain) NSFetchedResultsController* fetchedResultsController;
@property (nonatomic, retain) NSManagedObjectContext* managedObjectContext;

@property (nonatomic, retain) NSMutableArray* entryArray;
@end
