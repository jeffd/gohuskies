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

#import "FeedParser.h"
#import "Constants.h"
// This framework was imported so we could use the kCFURLErrorNotConnectedToInternet error code.
#import <CFNetwork/CFNetwork.h>

@interface FeedParser (Private)
- (void)showNetworkSpinner:(BOOL)showSpinner;
- (void)handleError:(NSError*)error;
@end

@implementation FeedParser

@synthesize feedList = mParsedItemsList;
@synthesize currentFeedConnection = mCurrentFeedConnection;
@synthesize feedData = mFeedData;
@synthesize currentFeedDictionary = mCurrentFeedItem;
@synthesize currentParsedCharacterData = mCurrentParsedCharacterData;
@synthesize currentParseBatch = mCurrentParseBatch;
@synthesize delegate = mDelegate;

 - (id)init
 {
   if ((self = [super init])) {
     mDidAbortParsing = NO;
     mShouldStopParse = NO;
     mSimpleElementNames = [[NSSet alloc] initWithObjects:kTitleElementName, kPubDateElementName, kDescElementName, kLinkElementName, kGUIDElementName, nil];
   }

   return self;
 }

- (id)initWithURL:(NSURL*)feedURL
{
  if ((self = [self init])) {
    NSURLRequest *feedURLRequest = [NSURLRequest requestWithURL:feedURL];
    mCurrentFeedConnection = [[[NSURLConnection alloc] initWithRequest:feedURLRequest delegate:self] autorelease];
    NSAssert(mCurrentFeedConnection != nil, @"Failure to create URL connection.");
    [self showNetworkSpinner:YES];
  }

  return self;
}

- (void)dealloc
{
  [mCurrentFeedConnection release];
  [mFeedData release];
  [super dealloc];
}

// Start the status bar network activity indicator.
// We'll turn it off when the connection finishes or experiences an error.
- (void)showNetworkSpinner:(BOOL)showSpinner
{
  [UIApplication sharedApplication].networkActivityIndicatorVisible = showSpinner;
}

#pragma mark NSURLConnection delegate methods

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response
{
  mFeedData = [[NSMutableData data] retain];
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
  [mFeedData appendData:data];
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
  [self showNetworkSpinner:NO];
  if ([error code] == kCFURLErrorNotConnectedToInternet) {
    // if we can identify the error, we can present a more precise message to the user.
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"No Connection Error",
                                                                                  @"Error message displayed when not connected to the Internet.")
                                                         forKey:NSLocalizedDescriptionKey];
    NSError *noConnectionError = [NSError errorWithDomain:NSCocoaErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:userInfo];
    [self handleError:noConnectionError];
  } else {
    // otherwise handle the error generically
    [self handleError:error];
  }
  mCurrentFeedConnection = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
  mCurrentFeedConnection = nil;
  [self showNetworkSpinner:NO];
  [NSThread detachNewThreadSelector:@selector(parseFeedData:) toTarget:self withObject:mFeedData];
  // mFeedData will be retained by the thread until parseFeedData: has finished executing, so we no longer need
  // a reference to it in the main thread.
  mFeedData = nil;
}

- (void)parseFeedData:(NSData*)data
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  mCurrentParseBatch = [NSMutableArray array];
  mCurrentParsedCharacterData = [NSMutableString string];
  //
  // It's also possible to have NSXMLParser download the data, by passing it a URL, but this is not desirable
  // because it gives less control over the network, particularly in responding to connection errors.
  //
  NSXMLParser* parser = [[NSXMLParser alloc] initWithData:data];
  [parser setDelegate:self];
  [parser parse];

  // depending on the total number of items parsed, the last batch might not have been a "full" batch, and thus
  // not been part of the regular batch transfer. So, we check the count of the array and, if necessary, send it to the main thread.
  if ([mCurrentParseBatch count] > 0) {
    [self performSelectorOnMainThread:@selector(addFeedItemsToList:) withObject:mCurrentParseBatch waitUntilDone:NO];
  }
  mCurrentParseBatch = nil;
  mCurrentFeedItem= nil;
  mCurrentParsedCharacterData = nil;
  [parser release];
  [pool release];
}

- (void)handleError:(NSError*)error
{
  NSString* errorMessage = [error localizedDescription];
  UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Title", @"Title for alert displayed when download or parse error occurs.") message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
  [alertView show];
  [alertView release];
}

- (void)addFeedItemsToList:(NSArray*)feedItems
{
  if (self.delegate) {
    // If there are no new entries, we should cancel the parse
    if (![self.delegate insertNewEntries:feedItems]) {
      mShouldStopParse = YES;
    }
  }

 // for (NSDictionary* item in feedItems) {
//    if (self.delegate)
//      [self.delegate insertNewEntry:item];
//  }

}

#pragma mark NSXMLParser delegate methods

- (void)parser:(NSXMLParser*)parser didStartElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qName attributes:(NSDictionary*)attributeDict
{
  // If the number of parsed items is greater than kMaximumNumberOfItemsToParse, abort the parse.
  if (mParsedFeedCounter >= kMaximumNumberOfItemsToParse || mShouldStopParse) {
    // Use the flag didAbortParsing to distinguish between this deliberate stop and other parser errors.
    mDidAbortParsing = YES;
    [parser abortParsing];
  }

  if ([elementName isEqualToString:kEntryElementName]) {
    NSMutableDictionary* feedItem = [NSMutableDictionary dictionaryWithCapacity:kDefaultEntryElements];
    mCurrentFeedItem = feedItem;
  } else if ([mSimpleElementNames containsObject:elementName]) {
    // For the 'title', 'updated', or 'georss:point' element, begin accumulating parsed character data.
    // The contents are collected in parser:foundCharacters:.
    mAccumulatingParsedCharacterData = YES;
    // The mutable string needs to be reset to empty.
    [mCurrentParsedCharacterData setString:@""];
  }
}

- (void)parser:(NSXMLParser*)parser didEndElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qName
{
  if ([elementName isEqualToString:kEntryElementName]) {
    [mCurrentParseBatch addObject:mCurrentFeedItem];
    mParsedFeedCounter++;

    if (mParsedFeedCounter % kSizeOfFeedBatch == 0) {
      [self performSelectorOnMainThread:@selector(addFeedItemsToList:) withObject:mCurrentParseBatch waitUntilDone:NO];
      mCurrentParseBatch = [NSMutableArray array];
    }
  }
  else if ([elementName isEqualToString:kPubDateElementName]) {
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    // Wed, 01 Jul 2009 11:37:23 EST
    [dateFormatter setDateFormat:@"EEE',' dd MMM yyyy HH:mm:ss zzz"];
    NSDate* pubDate = [dateFormatter dateFromString:mCurrentParsedCharacterData];
    [mCurrentFeedItem setObject:pubDate
                         forKey:elementName];

  }
  else if ([elementName isEqualToString:kDescElementName]) {
    [mCurrentFeedItem setObject:[[mCurrentParsedCharacterData copy] autorelease]
                         forKey:kDescKey];
  }
  else if ([mSimpleElementNames containsObject:elementName]) {
    [mCurrentFeedItem setObject:[[mCurrentParsedCharacterData copy] autorelease]
                         forKey:elementName];
  }
  // Stop accumulating parsed character data. We won't start again until specific elements begin.
  mAccumulatingParsedCharacterData = NO;
}

- (void)parser:(NSXMLParser*)parser foundCharacters:(NSString*)string
{
  if (mAccumulatingParsedCharacterData) {
    // If the current element is one whose content we care about, append 'string'
    // to the property that holds the content of the current element.
    [mCurrentParsedCharacterData appendString:string];
  }
}

- (void)parser:(NSXMLParser*)parser parseErrorOccurred:(NSError*)parseError
{
  // If the number of earthquake records received is greater than kMaximumNumberOfEarthquakesToParse, we abort parsing.
  // The parser will report this as an error, but we don't want to treat it as an error. The flag didAbortParsing is
  // how we distinguish real errors encountered by the parser.
  if (mDidAbortParsing == NO) {
    // Pass the error to the main thread for handling.
    [self performSelectorOnMainThread:@selector(handleError:) withObject:parseError waitUntilDone:NO];
  }
}

@end
