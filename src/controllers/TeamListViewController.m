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

#import "TeamListViewController.h"

@implementation TeamListViewController

- (void)loadView {

  [super loadView];

  TTNavigationCenter* nav = [TTNavigationCenter defaultCenter];
  nav.mainViewController = self.navigationController;
  nav.delegate = self;
  self.navigationBarTintColor = [UIColor colorWithRed:0.8 green:0.0 blue:0.0 alpha:0.0];

  self.tableView = [[[UITableView alloc] initWithFrame:self.view.bounds
                                                 style:UITableViewStyleGrouped] autorelease];
	self.tableView.autoresizingMask =
  UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [self.view addSubview:self.tableView];
}

- (void)viewDidLoad {
  TTNavigationCenter* nav = [TTNavigationCenter defaultCenter];
  nav.mainViewController = self.navigationController;
  nav.delegate = self;
  nav.urlSchemes = [NSArray arrayWithObject:@"tt"];
  nav.supportsShakeToReload = YES;
}

- (id<TTTableViewDataSource>)createDataSource {
  return [TTSectionedDataSource dataSourceWithObjects:
          @"Fall",
              [[[TTIconTableField alloc] initWithText:@"Cross Country" url:@"tt://tableFieldTest"
                                                image:@"bundle://Olympic_pictogram_Athletics.png" ] autorelease],
              [[[TTIconTableField alloc] initWithText:@"Field Hockey" url:@"tt://tableFieldTest"
                                                image:@"bundle://Field_hockey_pictogram.png" ] autorelease],
              [[[TTIconTableField alloc] initWithText:@"Football" url:@"tt://tableFieldTest"
                                                image:@"bundle://Football_pictogram.png" ] autorelease],
              [[[TTIconTableField alloc] initWithText:@"Soccer" url:@"tt://tableFieldTest"
                                                image:@"bundle://Futsal_pictogram.png" ] autorelease],
              [[[TTIconTableField alloc] initWithText:@"Rowing" url:@"tt://tableFieldTest"
                                                image:@"bundle://Rowing_pictogram.png" ] autorelease],

                                @"Winter",
              [[[TTIconTableField alloc] initWithText:@"Basketball" url:@"tt://tableFieldTest"
                                                image:@"bundle://Basketball_pictogram.png" ] autorelease],
              [[[TTIconTableField alloc] initWithText:@"Hockey" url:@"tt://tableFieldTest"
                                                image:@"bundle://Olympic_pictogram_Ice_hockey.png" ] autorelease],
              [[[TTIconTableField alloc] initWithText:@"Swimming" url:@"tt://tableFieldTest"
                                                image:@"bundle://Swimming_pictogram.png" ] autorelease],
              [[[TTIconTableField alloc] initWithText:@"Volleyball" url:@"tt://tableFieldTest"
                                                image:@"bundle://Volleyball_(indoor)_pictogram.png" ] autorelease],
                                @"Spring",
              [[[TTIconTableField alloc] initWithText:@"Baseball" url:@"tt://tableFieldTest"
                                                image:@"bundle://Baseball_pictogram.png" ] autorelease],
              [[[TTIconTableField alloc] initWithText:@"Track" url:@"tt://tableFieldTest"
                                                image:@"bundle://Olympic_pictogram_Athletics.png" ] autorelease],

          nil];
}

- (void)dealloc {
  [super dealloc];
}

@end

