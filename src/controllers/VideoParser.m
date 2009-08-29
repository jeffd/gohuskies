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

#import "VideoParser.h"
#import "Constants.h"
// This framework was imported so we could use the kCFURLErrorNotConnectedToInternet error code.
#import <CFNetwork/CFNetwork.h>

static NSUInteger const kDefaultNumberGroupItems = 2;

@implementation VideoParser

@synthesize currentGroupVideos = mCurrentGroupItems;

- (id)init
{
  if ((self = [super init])) {
    mSimpleElementNames = [[NSSet alloc] initWithObjects:kTitleElementName, kPubDateElementName, kDescElementName, kLinkElementName, nil];
    mIntegerElementNames = [[NSSet alloc] initWithObjects: kMRSSFilesizeElementName, kMRSSDurationElementName, nil];
  }

   return self;
}

- (void)dealloc
{
  [mCurrentGroupItems release];
  [mIntegerElementNames release];
  [super dealloc];
}

#pragma mark NSXMLParser delegate methods

- (void)parser:(NSXMLParser*)parser didStartElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qName attributes:(NSDictionary*)attributeDict
{
  // If the number of parsed items is greater than kMaximumNumberOfItemsToParse, abort the parse.
  if (mParsedFeedCounter >= kMaximumNumberOfItemsToParse) {
    // Use the flag didAbortParsing to distinguish between this deliberate stop and other parser errors.
    mDidAbortParsing = YES;
    [parser abortParsing];
  }

  // Create a new element item
  if ([elementName isEqualToString:kEntryElementName]) {
    NSMutableDictionary* feedItem = [NSMutableDictionary dictionaryWithCapacity:kDefaultEntryElements];
    mCurrentFeedItem = feedItem;
  }

  // Create a new group array
  else if ([elementName isEqualToString:kMRSSGroupElementName]) {
    NSMutableArray* groupItems = [NSMutableArray arrayWithCapacity:kDefaultNumberGroupItems];
    mCurrentGroupItems = groupItems;
  }

  // Fill in the values for the group items
  else if ([elementName isEqualToString:kMRSSContentElementName]) {
    NSMutableDictionary* contentItem = [NSMutableDictionary dictionaryWithCapacity:kMRSSNumberDefaultContentElements];
    NSSet* attrKeys = [[[NSSet alloc] initWithObjects: kMRSSMediumElementName, kMRSSURLElementName, kMRSSTypeElementName, nil] autorelease];

    for (NSString* atKey in attrKeys) {
      id attribute = [attributeDict valueForKey:atKey];

      if (attribute)
        [contentItem setObject:attribute forKey:atKey];
    }

    [self.currentGroupVideos addObject:contentItem];
    [mCurrentFeedItem setObject:[self currentGroupVideos] forKey:kVideoGroupPropertyName];
  }

  else if ([elementName isEqualToString:kMRSSThumbnailElementName]) {
    NSString *imageURL = [attributeDict valueForKey:kMRSSURLElementName];
    if (imageURL) {
      [mCurrentFeedItem setObject:imageURL
                           forKey:kVideoThumbnailURLPropertyName];
    }
  }
  else if ([mSimpleElementNames containsObject:elementName]) {
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

  // For elements that need to be converted to integers
  else if ([mIntegerElementNames containsObject:elementName]) {
    NSString* elemString = [[mCurrentParsedCharacterData copy] autorelease];
    NSInteger* intVal = [elemString integerValue];

    [mCurrentFeedItem setObject:intVal
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

@end
