/* ***** BEGIN LICENSE BLOCK *****
 * Version: MIT
 *
 * Copyright (c) 2009 Jeff Dlouhy
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 *
 * Contributor(s):
 *  Jeff Dlouhy <jeff.dlouhy@gmail.com>
 *
 * ***** END LICENSE BLOCK ***** */

#import "HeadlineViewController.h"
#import "Constants.h"
#import "NewsDetailViewController.h"
#import "FeedParser.h"

@interface HeadlineViewController (Private)
- (void)populateEntryArray;
@end

@implementation HeadlineViewController

@synthesize fetchedResultsController, managedObjectContext;
@synthesize entryArray = mEntryArray;

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = @"Headlines";
	self.tableView.rowHeight = 80;

  self.managedObjectContext = [[[UIApplication sharedApplication] delegate] managedObjectContext];

  FeedParser* parsy = [[FeedParser alloc] initWithURL:[NSURL URLWithString:@"http://feeds.feedburner.com/gonu-headlines"]];
  [parsy setDelegate:self];

//  [self populateEntryArray];

	NSError *error = nil;
	if (![[self fetchedResultsController] performFetch:&error]) {
		// Update to handle the error appropriately.
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		exit(-1);  // Fail
	}
}

// - (void)populateEntryArray
// {
// 	NSFetchRequest *request = [[NSFetchRequest alloc] init];
// 	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Entry" inManagedObjectContext:managedObjectContext];
// 	[request setEntity:entity];

// 	// Order the events by creation date, most recent first.
// 	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"pubDate" ascending:NO];
// 	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
// 	[request setSortDescriptors:sortDescriptors];
// 	[sortDescriptor release];
// 	[sortDescriptors release];

// 	// Execute the fetch -- create a mutable copy of the result.
// 	NSError *error = nil;
// 	NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
// 	if (mutableFetchResults == nil) {
// 		// Handle the error.
// 	}

// 	// Set self's events array to the mutable array, then clean up.
// 	[self setEntryArray:mutableFetchResults];
// 	[mutableFetchResults release];
// 	[request release];
// }

/*
  - (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  }
*/
/*
  - (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  }
*/
/*
  - (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
  }
*/
/*
  - (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
  }
*/

- (void)viewDidUnload {
	// Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
	// For example: self.myOutlet = nil;
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
// Return YES for supported orientations.
return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

#pragma mark -
#pragma mark Add a new object

//
// Takes an array of dictionaries and checks to see if any are *not* in the database.
// If they are new, it will add them.
//
// If no new entries ==> return NO
// If it *contains* a new entry ==> return YES
//
- (BOOL)insertNewEntries:(NSArray*)newEntries
{
  // create the fetch request to get all Employees matching the IDs
  NSFetchRequest* fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
  NSManagedObjectContext* context = [fetchedResultsController managedObjectContext];
  NSMutableArray* entryTitles = [NSMutableArray arrayWithCapacity:[newEntries count]];

  for (NSDictionary* entry in newEntries) {
    NSString* title = [entry objectForKey:kTitleElementName];

    if(title)
      [entryTitles addObject:title];
  }

  [fetchRequest setEntity:[NSEntityDescription entityForName:kNewsEntryMOName inManagedObjectContext:context]];

  // This String building is quite the hack and is done because predicateWithFormat freaks when you give it
  // the string as the first argment and the array as the second.
  NSString* predPrefix = [NSString stringWithFormat:@"(%@ ", kTitleElementName];
  [fetchRequest setPredicate:[NSPredicate predicateWithFormat:[predPrefix stringByAppendingString:@" IN %@)"] , entryTitles]];

  // make sure the results are sorted as well
  [fetchRequest setSortDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey: kTitleElementName
                                                                                         ascending:YES] autorelease]]];
  // Execute the fetch
  NSError* error;
  NSArray* entriesMatchingTitles = [context executeFetchRequest:fetchRequest error:&error];

  // If there are no new items, say NO
  if ([entriesMatchingTitles count] == [newEntries count])
    return NO;

  // Otherwise, add the ones that are new
  for (NSDictionary* item in newEntries) {
    if (![entriesMatchingTitles containsObject:item])
      [self insertNewEntry:item];
  }

  return YES;
}

- (void)insertNewEntry:(NSDictionary*)aNewObjDict
{
  // Create a new instance of the entity managed by the fetched results controller.
  NSManagedObjectContext* context = [fetchedResultsController managedObjectContext];
  NSEntityDescription* entity = [[fetchedResultsController fetchRequest] entity];
  NSManagedObject* newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];

  for (id key in aNewObjDict) {
//    NSLog(@"key: %@, value: %@", key, [aNewObjDict objectForKey:key]);

    // If appropriate, configure the new managed object.
    [newManagedObject setValue:[aNewObjDict objectForKey:key] forKey:key];
  }

  // Save the context.
  NSError *error;
  if (![context save:&error]) {
    // Update to handle the error appropriately.
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    exit(-1);  // Fail
  }
}

#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return [[fetchedResultsController sections] count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedResultsController sections] objectAtIndex:section];
  return [sectionInfo numberOfObjects];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  // Each subview in the cell will be identified by a unique tag.
  static NSUInteger const kTitleLabelTag = 2;
  static NSUInteger const kDescriptionLabelTag = 3;
  static NSUInteger const kEntryImageTag = 5;

  // Declare references to the subviews which will display the earthquake data.
  UILabel *titleLabel = nil;
  UILabel *descriptionLabel = nil;
  UIImageView *entryImage = nil;

	static NSString *kEntryCellID = @"EntryCellID";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kEntryCellID];
	if (cell == nil) {
    // No reusable cell was available, so we create a new cell and configure its subviews.
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kEntryCellID] autorelease];

    titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 0, 250, 40)] autorelease];
    titleLabel.tag = kTitleLabelTag;
    titleLabel.font = [UIFont boldSystemFontOfSize:14];
    titleLabel.numberOfLines = 2;
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
    [cell.contentView addSubview:titleLabel];

    descriptionLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 35, 250, 40)] autorelease];
    descriptionLabel.tag = kDescriptionLabelTag;
    descriptionLabel.font = [UIFont systemFontOfSize:10];
    descriptionLabel.numberOfLines = 2;
    descriptionLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
    [cell.contentView addSubview:descriptionLabel];

    entryImage = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"seal.png"]] autorelease];
    CGRect imageFrame = entryImage.frame;
    imageFrame.origin = CGPointMake(280, 20);
    entryImage.frame = imageFrame;
    entryImage.tag = kEntryImageTag;
    entryImage.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [cell.contentView addSubview:entryImage];
  } else {
    // A reusable cell was available, so we just need to get a reference to the subviews using their tags.
    titleLabel = (UILabel*)[cell.contentView viewWithTag:kTitleLabelTag];
    descriptionLabel = (UILabel*)[cell.contentView viewWithTag:kDescriptionLabelTag];
    entryImage = (UIImageView*)[cell.contentView viewWithTag:kEntryImageTag];
  }

	// Configure the cell.
	NSManagedObject *managedObject = [fetchedResultsController objectAtIndexPath:indexPath];
  titleLabel.text = [[managedObject valueForKey:@"title"] description];
  descriptionLabel.text = [[managedObject valueForKey:@"summary"] description];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//  magnitudeImage.image = [self imageForMagnitude:earthquake.magnitude];

  return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  // Navigation logic may go here -- for example, create and push another view controller.
  NewsDetailViewController *detailViewController = [[NewsDetailViewController alloc] initWithNibName:@"NewsItemDetailView" bundle:nil];
  NSManagedObject *selectedObject = [[self fetchedResultsController] objectAtIndexPath:indexPath];
  // ...
  // Pass the selected object to the new view controller.
  detailViewController.newsEntry = selectedObject;
  self.hidesBottomBarWhenPushed = YES;
  [self.navigationController pushViewController:detailViewController animated:YES];
  [detailViewController release];
  self.hidesBottomBarWhenPushed = NO;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
// Return NO if you do not want the specified item to be editable.
return YES;
}
*/


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

  if (editingStyle == UITableViewCellEditingStyleDelete) {
    // Delete the managed object for the given index path
		NSManagedObjectContext *context = [fetchedResultsController managedObjectContext];
		[context deleteObject:[fetchedResultsController objectAtIndexPath:indexPath]];

		// Save the context.
		NSError *error;
		if (![context save:&error]) {
			// Update to handle the error appropriately.
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			exit(-1);  // Fail
		}
	}
}


- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
  // The table view should not be re-orderable.
  return NO;
}


#pragma mark -
#pragma mark Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController {

  if (fetchedResultsController != nil) {
    return fetchedResultsController;
  }

  /*
    Set up the fetched results controller.
	*/
	// Create the fetch request for the entity.
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	// Edit the entity name as appropriate.
	NSEntityDescription *feedEntry = [NSEntityDescription entityForName:kNewsEntryMOName inManagedObjectContext:managedObjectContext];
	[fetchRequest setEntity:feedEntry];

	// Set the batch size to a suitable number.
	[fetchRequest setFetchBatchSize:20];

	// Edit the sort key as appropriate.
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"pubDate" ascending:NO];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];

	[fetchRequest setSortDescriptors:sortDescriptors];

	// Edit the section name key path and cache name if appropriate.
  // nil for section name key path means "no sections".
	NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:managedObjectContext sectionNameKeyPath:nil cacheName:@"Root"];
  aFetchedResultsController.delegate = self;
	self.fetchedResultsController = aFetchedResultsController;

	[aFetchedResultsController release];
	[fetchRequest release];
	[sortDescriptor release];
	[sortDescriptors release];

	return fetchedResultsController;
}


// NSFetchedResultsControllerDelegate method to notify the delegate that all section and object changes have been processed.
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	// In the simplest, most efficient, case, reload the table view.
	[self.tableView reloadData];
}

/*
  Instead of using controllerDidChangeContent: to respond to all changes, you can implement all the delegate methods to update the table view in response to individual changes.  This may have performance implications if a large number of changes are made simultaneously.

// Notifies the delegate that section and object changes are about to be processed and notifications will be sent.
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
[self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
// Update the table view appropriately.
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
// Update the table view appropriately.
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
[self.tableView endUpdates];
}
*/



#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
	// Relinquish ownership of any cached data, images, etc that aren't in use.
}


- (void)dealloc {
	[fetchedResultsController release];
	[managedObjectContext release];
  [super dealloc];
}


@end

