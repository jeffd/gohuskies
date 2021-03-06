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

#import <UIKit/UIKit.h>

#import "HeadlineViewController.h"

@interface FeedParser : NSObject {
  NSURLConnection* mCurrentFeedConnection;
  NSMutableArray* mParsedItemsList;
  NSMutableData* mFeedData;
  NSSet* mSimpleElementNames;

  // Needed during parsing
  NSMutableDictionary* mCurrentFeedItem;
  NSMutableArray* mCurrentParseBatch;
  NSUInteger mParsedFeedCounter;
  NSMutableString* mCurrentParsedCharacterData;
  BOOL mAccumulatingParsedCharacterData;
  BOOL mDidAbortParsing;
  BOOL mShouldStopParse;

  id<FeedViewDelegate> mDelegate;
}

@property (nonatomic, retain) NSMutableArray *feedList;

@property (nonatomic, retain) NSURLConnection *currentFeedConnection;
@property (nonatomic, retain) NSMutableData *feedData;

@property (nonatomic, retain) NSMutableDictionary *currentFeedDictionary;
@property (nonatomic, retain) NSMutableString *currentParsedCharacterData;
@property (nonatomic, retain) NSMutableArray *currentParseBatch;

@property(nonatomic,assign) id<FeedViewDelegate> delegate;

- (id)initWithURL:(NSURL*)feedURL;

@end
