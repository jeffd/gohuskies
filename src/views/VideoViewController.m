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

#import "VideoViewController.h"
#import "Constants.h"
#import "NewsDetailViewController.h"
#import "VideoParser.h"

static NSUInteger const kVideoThumbnailWidth = 90;

@interface VideoViewController (Private)
- (void)populateEntryArray;
- (void)insertNewVideo:(NSDictionary*)aNewVideoDict withParentEntry:(NSManagedObject*)aParentEntry;
@end

@implementation VideoViewController

@synthesize fetchedResultsController, managedObjectContext;
@synthesize entryArray = mEntryArray;

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = @"Headlines";
	self.tableView.rowHeight = 90;

  self.managedObjectContext = [[[UIApplication sharedApplication] delegate] managedObjectContext];

  NSString* nutvFeed = @"http://pipes.yahoo.com/pipes/pipe.run?_id=og03IQ593hGRZbmmA9V6qA&_render=rss"; //@"http://feeds.feedburner.com/nutv"
  VideoParser* parsy = [[VideoParser alloc] initWithURL:[NSURL URLWithString:nutvFeed]];
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

  [fetchRequest setEntity:[NSEntityDescription entityForName:kVideoEntryMOName inManagedObjectContext:context]];

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

- (void)insertNewVideo:(NSDictionary*)aNewVideoDict withParentEntry:(NSManagedObject*)aParentEntry
{
  NSManagedObjectContext* context = [fetchedResultsController managedObjectContext];
  NSEntityDescription* videoEntity = [NSEntityDescription entityForName:kVideoMOName inManagedObjectContext:managedObjectContext];
  NSManagedObject* newVideoContent = [NSEntityDescription insertNewObjectForEntityForName:[videoEntity name] inManagedObjectContext:context];

  for (id key in aNewVideoDict) {
    id objForKey = [aNewVideoDict objectForKey:key];
    if (objForKey) {
      NSLog(@"key: %@, value: %@", key, objForKey);

      // If appropriate, configure the new managed object.
      [newVideoContent setValue:objForKey forKey:key];
    }
  }

  [newVideoContent setValue:aParentEntry forKey:kVideoParentRelationshipName];

  // Save the context.
  NSError *error;
  if (![context save:&error]) {
    // Update to handle the error appropriately.
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    exit(-1);  // Fail
  }
}

- (void)insertNewEntry:(NSDictionary*)aNewObjDict
{
  // Create a new instance of the entity managed by the fetched results controller.
  NSManagedObjectContext* context = [fetchedResultsController managedObjectContext];
  NSEntityDescription* entity = [[fetchedResultsController fetchRequest] entity];
  NSManagedObject* newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];

  for (id key in aNewObjDict) {
    id objForKey = [aNewObjDict objectForKey:key];

    if (objForKey) {
      NSLog(@"key: %@, value: %@", key, objForKey);

      // When we hit video content, we need to make a video for them
      if ([key isEqualToString:kVideoGroupPropertyName]) {
        NSArray* videos = objForKey;

        // Add the video and pass it the relationship
        for (NSDictionary* vidDict in videos) {
          [self insertNewVideo:vidDict withParentEntry:newManagedObject];
        }
      }
      else {
        [newManagedObject setValue:objForKey forKey:key];
      }
    }
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

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  static NSString* kVideoCellID = @"VideoTableCellIdentifier";
  UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:kVideoCellID];

  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kVideoCellID];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:12];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
  }

	// Configure the cell.
	NSManagedObject *managedObject = [fetchedResultsController objectAtIndexPath:indexPath];

  cell.textLabel.text = [[managedObject valueForKey:kTitleElementName] description];
  cell.detailTextLabel.text = [[managedObject valueForKey:kDescKey] description];
  cell.imageView.image = [UIImage imageNamed:@"seal.png"];

  return cell;
}

// // Customize the appearance of table view cells.
// - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//   // Each subview in the cell will be identified by a unique tag.
//   static NSUInteger const kTitleLabelTag = 2;
//   static NSUInteger const kDescriptionLabelTag = 3;
//   static NSUInteger const kEntryImageTag = 5;
//   static NSString *kEntryCellID = @"EntryCellID";

//   // Declare references to the subviews which will display the earthquake data.
//   UILabel* titleLabel = nil;
//   UILabel* descriptionLabel = nil;
//   UIImageView* videoThumbnail = nil;

//   UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:kEntryCellID];

// 	if (cell == nil) {
//     static NSUInteger const kThumbnailWidth = 90;
//     static NSUInteger const kRowHeight = tableView.rowHeight;

//     // No reusable cell was available, so we create a new cell and configure its subviews.
// 		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kEntryCellID] autorelease];
//     cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;

// //     videoThumbnail = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kRowHeight, kThumbnailWidth)] autorelease];
// //     videoThumbnail.tag = kEntryImageTag;
// //     videoThumbnail.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
// //     [cell.contentView addSubview:videoThumbnail];

// //     titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake((kThumbnailWidth + 10), 0, 250, 40)] autorelease];
// //     titleLabel.tag = kTitleLabelTag;
// //     titleLabel.font = [UIFont boldSystemFontOfSize:14];
// //     titleLabel.numberOfLines = 2;
// //     titleLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
// //     [cell.contentView addSubview:titleLabel];

// //     descriptionLabel = [[[UILabel alloc] initWithFrame:CGRectMake((kThumbnailWidth + 10), 35, 250, 40)] autorelease];
// //     descriptionLabel.tag = kDescriptionLabelTag;
// //     descriptionLabel.font = [UIFont systemFontOfSize:10];
// //     descriptionLabel.textColor = [UIColor darkGrayColor];
// //     descriptionLabel.numberOfLines = 2;
// //     descriptionLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
// //     [cell.contentView addSubview:descriptionLabel];

//   } else {
//     // A reusable cell was available, so we just need to get a reference to the subviews using their tags.
//     titleLabel = (UILabel*)[cell.contentView viewWithTag:kTitleLabelTag];
//     descriptionLabel = (UILabel*)[cell.contentView viewWithTag:kDescriptionLabelTag];
//     videoThumbnail = (UIImageView*)[cell.contentView viewWithTag:kEntryImageTag];
//   }

// 	// Configure the cell.
// 	NSManagedObject *managedObject = [fetchedResultsController objectAtIndexPath:indexPath];
//   titleLabel.text = [[managedObject valueForKey:kTitleElementName] description];
//   descriptionLabel.text = [[managedObject valueForKey:kDescKey] description];

//   NSString* thumbURL = [[[managedObject valueForKey:kVideoThumbnailURLPropertyName] description] stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
//   NSData* imageData = [[NSData alloc]initWithContentsOfURL:[NSURL URLWithString:thumbURL]];

//   videoThumbnail.image = [UIImage imageWithData:imageData];
//   videoThumbnail.frame = CGRectMake(280, 20, 50, 50);

//   return cell;
// }

//
// Download and display the thumbnail if available
//
- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
	NSManagedObject *managedObject = [fetchedResultsController objectAtIndexPath:indexPath];

  NSString* thumbURL = [[[managedObject valueForKey:kVideoThumbnailURLPropertyName] description] stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
  NSData* imageData = [[NSData alloc]initWithContentsOfURL:[NSURL URLWithString:thumbURL]];

  cell.imageView.image = [UIImage imageWithData:imageData];

  CGRect imFrame = cell.imageView.frame;
  imFrame.size.width = kVideoThumbnailWidth;
  imFrame.size.height = 90;
  cell.imageView.frame = imFrame;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  // Navigation logic may go here -- for example, create and push another view controller.
    NSManagedObject *selectedObject = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    // ...
    // Pass the selected object to the new view controller.
    //[self playMovie:[[selectedObject valueForKey:@"link"] description]];
}

-(void)playMovie:(NSString*)urlString
{
	// has the user entered a movie URL?
	if ([urlString length] > 0)
	{
		NSURL *movieURL = [NSURL URLWithString:urlString];
		if (movieURL)
		{
			if ([movieURL scheme])	// sanity check on the URL
			{
        MPMoviePlayerController *mp = [[MPMoviePlayerController alloc] initWithContentURL:movieURL];
        if (mp)
        {
          // Play the movie!
          [mp play];
        }
			}
		}
	}
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
	NSEntityDescription *feedEntry = [NSEntityDescription entityForName:kVideoEntryMOName inManagedObjectContext:managedObjectContext];
	[fetchRequest setEntity:feedEntry];

	// Set the batch size to a suitable number.
	[fetchRequest setFetchBatchSize:20];

	// Edit the sort key as appropriate.
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:kPubDateElementName ascending:NO];
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

