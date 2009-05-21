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

#import "FeedDataSource.h"

static NSUInteger const kDefaultNumOfItems = 10;

@interface FeedDataSource (Private)
-(NSArray*)parseNewsFeed:(NSData*)feedData;
@end

@implementation FeedDataSource

@synthesize itemsPerPage = mItemsPerPage;

- (id)init
{
  if (self = [super init]) {
    mFeedUrl = @"";
    mLoading = YES;
    mLoaded = NO;
    mItemsPerPage = kDefaultNumOfItems;
  }
  return self;
}

- (id)initWithFeed:(NSString*)feedUrl
{
  if (self = [self init]) {
    mFeedUrl = feedUrl;
  }

  return self;
}

- (void)dealloc
{
  [mFeedItems release];
  [super dealloc];
}

-(NSArray*)parseNewsFeed:(NSData*)feedData
{

  // Initialize the blogEntries MutableArray that we declared in the header
  NSMutableArray* blogEntries = [[NSMutableArray alloc] init];

  // Create a new rssParser object based on the TouchXML "CXMLDocument" class, this is the
  // object that actually grabs and processes the RSS data
  CXMLDocument *rssParser = [[[CXMLDocument alloc] initWithData:feedData options:0 error:nil] autorelease];

  // Create a new Array object to be used with the looping of the results from the rssParser
  NSArray *resultNodes = NULL;

  // Set the resultNodes Array to contain an object for every instance of an  node in our RSS feed
  resultNodes = [rssParser nodesForXPath:@"//item" error:nil];

  // Loop through the resultNodes to access each items actual data
  for (CXMLElement *resultElement in resultNodes) {

    // Create a temporary MutableDictionary to store the items fields in, which will eventually end up in blogEntries
    NSMutableDictionary *blogItem = [[NSMutableDictionary alloc] init];

    // Create a counter variable as type "int"
    int counter;

    // Loop through the children of the current  node
    for(counter = 0; counter < [resultElement childCount]; counter++) {

      // Add each field to the blogItem Dictionary with the node name as key and node value as the value
      NSString* currentKey = [[resultElement childAtIndex:counter] name];
      NSString* currentVal = [[resultElement childAtIndex:counter] stringValue];

      if (currentVal && currentKey)
        [blogItem setObject:currentVal forKey:currentKey];
    }

    // Add the blogItem to the global blogEntries Array so that the view can access it.
    [blogEntries addObject:blogItem];
  }

  return blogEntries;
}


#pragma mark TTTableViewDataSource

- (void)load:(TTURLRequestCachePolicy)cachePolicy nextPage:(BOOL)nextPage
{
  if(!mFeedItems) {
    TTURLRequest *request = [TTURLRequest requestWithURL:mFeedUrl delegate:self];
    request.cachePolicy = cachePolicy;
    request.response = [[[TTURLDataResponse alloc] init] autorelease];
    request.httpMethod = @"GET";

    BOOL cacheHit = [request send];
    NSLog((cacheHit ? @"Cache hit for %@" : @"Cache miss for %@"), mFeedUrl);
  }

}

-(void)loadNextItems:(NSUInteger)itemsToAdd
{
  if (mFeedItems) {
    NSUInteger feedCount = [mFeedItems count];
    NSUInteger addedSoFarCount = [[self items] count];
    NSArray* nextItems;

    // If we are trying to add more than we have
    if (itemsToAdd >= (addedSoFarCount + feedCount))
      nextItems = [mFeedItems objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange((addedSoFarCount - 1), (feedCount - 1))]];
    else if (addedSoFarCount == 0)
      nextItems = [mFeedItems objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, itemsToAdd)]];
    else
      nextItems = [mFeedItems objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange((addedSoFarCount - 1), (addedSoFarCount + itemsToAdd))]];

    for(NSDictionary* feedItem in nextItems) {
      NSLog(@"News");
      [[self items] addObject:[[[TTIconTableField alloc]
                                 initWithText:[feedItem objectForKey:@"title"]
                                          url:nil
                                        image:nil
                                 defaultImage:[UIImage imageNamed:@"seal.png"]] autorelease]];
    }

    if (addedSoFarCount < feedCount) {
      NSString* countString = [NSString stringWithFormat:@"Showing %d of %d", [[self items] count], feedCount];
      TTMoreButtonTableField* moreButton = [[[TTMoreButtonTableField alloc] initWithText:@"Load More Stories..."
                                                                                subtitle:countString] autorelease];
      [[self items] addObject:moreButton];
    }
  } else {
    [self loadNextItems:[self itemsPerPage]];
  }
}

#pragma mark TTLoadable

- (BOOL)isLoading
{
  return mLoading;
}

- (BOOL)isLoaded
{
  return mLoaded;
}

#pragma mark TTURLRequestDelegate

- (void)requestDidStartLoad:(TTURLRequest*)request
{
  mLoading = YES;
  mLoaded = NO;
  [self dataSourceDidStartLoad];
}

- (void)requestDidFinishLoad:(TTURLRequest*)request
{
  TTURLDataResponse *response = request.response;
  NSData* feedData = [response data];

  mFeedItems = [self parseNewsFeed:feedData];

  [self loadNextItems:[self itemsPerPage]];

  mLoading = NO;
  mLoaded = YES;
  [self dataSourceDidFinishLoad];
}

- (void)request:(TTURLRequest*)request didFailLoadWithError:(NSError*)error
{
  NSLog(@"didFailLoadWithError");
  mLoading = NO;
  mLoaded = YES;
  [self dataSourceDidFailLoadWithError:error];
}

- (void)requestDidCancelLoad:(TTURLRequest*)request
{
  NSLog(@"requestDidCancelLoad");
  mLoading = NO;
  mLoaded = YES;
  [self dataSourceDidCancelLoad];
}

@end
