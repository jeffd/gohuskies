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

#import "RootFeedViewController.h"

@implementation RootFeedViewController

- (void)loadView {
  [super loadView];
}

- (void)viewDidLoad {
  TTNavigationCenter* nav = [TTNavigationCenter defaultCenter];
  nav.mainViewController = self.navigationController;
  nav.delegate = self;
  nav.urlSchemes = [NSArray arrayWithObject:@"go"];
  nav.supportsShakeToReload = YES;
}

-(NSMutableArray*)parsedRSSFeed:(NSString*)blogAddress {

  // Initialize the blogEntries MutableArray that we declared in the header
  NSMutableArray* blogEntries = [[NSMutableArray alloc] init];

  // Convert the supplied URL string into a usable URL object
  NSURL *url = [NSURL URLWithString: blogAddress];

  // Create a new rssParser object based on the TouchXML "CXMLDocument" class, this is the
  // object that actually grabs and processes the RSS data
  CXMLDocument *rssParser = [[[CXMLDocument alloc] initWithContentsOfURL:url options:0 error:nil] autorelease];

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
      [blogItem setObject:[[resultElement childAtIndex:counter] stringValue] forKey:[[resultElement childAtIndex:counter] name]];
    }

    // Add the blogItem to the global blogEntries Array so that the view can access it.
    [blogEntries addObject:blogItem];
  }

  return blogEntries;
}

- (void)dealloc {
  [super dealloc];
}


@end

