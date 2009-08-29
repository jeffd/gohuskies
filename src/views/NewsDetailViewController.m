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

#import "NewsDetailViewController.h"
#import "XPathQuery.h"
#import "Constants.h"
#import <CFNetwork/CFNetwork.h>

@implementation NewsDetailViewController

@synthesize newsEntry;
@synthesize webView = mWebView;

- (void)viewDidLoad
{
  [super viewDidLoad];

	// A date formatter for the creation date.
  static NSDateFormatter *dateFormatter = nil;
	if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	}

	static NSNumberFormatter *numberFormatter;
	if (numberFormatter == nil) {
		numberFormatter = [[NSNumberFormatter alloc] init];
		[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[numberFormatter setMaximumFractionDigits:3];
	}
  
  NSString* filePath = [[NSBundle mainBundle] pathForResource:@"NewsDetail" ofType:@"html"];  
  NSString* detailHTML =  [NSString stringWithContentsOfFile:filePath encoding:NSStringEncodingConversionAllowLossy error:nil];
 
  [self.webView loadHTMLString:detailHTML baseURL:nil];

	mResponseData = [[NSMutableData data] retain];

  NSString* articleLink = [[newsEntry valueForKey:kLinkElementName] description];
	mBaseURL = [[NSURL URLWithString:articleLink] retain];

  NSURLRequest* request = [NSURLRequest requestWithURL:mBaseURL];
  [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (NSURLRequest*)connection:(NSURLConnection *)connection
             willSendRequest:(NSURLRequest *)request
            redirectResponse:(NSURLResponse *)redirectResponse
{
  [mBaseURL autorelease];
  mBaseURL = [[request URL] retain];
  return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
  [mResponseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
  [mResponseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{

}

- (void)scrapeArticleWithQuery:(NSString*)xPathQ
{
	NSArray* xPathNodes = PerformHTMLXPathQuery(mResponseData, xPathQ);

  NSString* articleSum = [[newsEntry valueForKey:kDescKey] description];
  NSInteger* artSubLength = ([articleSum length] / 4);
  NSString* subSum = [articleSum substringWithRange:NSMakeRange(0, artSubLength)];
  NSString* fullArticle = [self articleContentForXPathNodes:xPathNodes withPrefix:subSum];

  if (fullArticle)
    [self setArticleContent:fullArticle];
}

-(void)setArticleTitle:(NSString*)aTitle
{
  [self setValue:aTitle forKey:@"innerHTML" onDOMElement:@"contentTitle"];
}

-(void)setArticleAuthor:(NSString*)aName
{
  [self setValue:aName forKey:@"innerHTML" onDOMElement:@"contentAuthorName"];
}

-(void)setArticleImage:(NSString*)aURL
{
  NSString* imgHTML = [NSString stringWithFormat:@"<img src='%@'/>", aURL];
  [self setValue:imgHTML forKey:@"innerHTML" onDOMElement:@"contentImage"];
}

-(void)setArticleContent:(NSString*)someContent
{
  [self setValue:someContent forKey:@"innerHTML" onDOMElement:@"mainContent"];
}

-(NSString*)setValue:(NSString*)aValue forKey:(NSString*)elementKey onDOMElement:(NSString*)elementName
{
  NSString* script = [NSString stringWithFormat:@"document.getElementById('%@').%@ = '%@'", elementName, elementKey, aValue];
  return [self.webView stringByEvaluatingJavaScriptFromString:script];
}

- (NSString*)articleContentForXPathNodes:(NSArray*)xPathNodes withPrefix:(NSString*)articleSummary
{
  NSLog(@"Nodes: %@", xPathNodes);
  for (NSDictionary* dictNode in xPathNodes) {
    NSString* nodeContentString = [dictNode objectForKey:@"nodeContent"];

    BOOL longerThanSummary = [nodeContentString length] > [articleSummary length];
    if ([nodeContentString hasPrefix:articleSummary] || longerThanSummary) {
      return nodeContentString;
    }
  }

  return articleSummary;
}

- (void)scrapeImageWithQuery:(NSString*)xPathQ
{
	NSArray* xPathNodes = PerformHTMLXPathQuery(mResponseData, xPathQ);
  NSLog(@"Nodes: %@", xPathNodes);

  for (NSDictionary* dictNode in xPathNodes) {
    NSString* nodeAttrs = [dictNode objectForKey:@"nodeAttributeArray"];

    for (NSDictionary* dictNodeAttr in nodeAttrs) {
      NSString* nodeContentString = [dictNodeAttr objectForKey:@"nodeContent"];

      if ([nodeContentString hasPrefix:@"http"]) {
        NSLog(@"SET IMAGE");
        NSString* imgURL = [nodeContentString stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
        [self setArticleImage:imgURL];
        //NSData* imageData = [[NSData alloc]initWithContentsOfURL:[NSURL URLWithString:imgURL]];

       // photoImageView.image = [UIImage imageWithData:imageData];
      }
    }
  }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
  // Once this method is invoked, "mResponseData" contains the complete result
	NSString* xPathQueryString = @"//div[@class='padmaster']/p";
  [self scrapeArticleWithQuery:xPathQueryString];

	NSString* xPathImageQuery = @"//img[@alt='NU Photo']";
  [self scrapeImageWithQuery:xPathImageQuery];
}

- (IBAction)shareItem:(id)sender
{
  UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"External App Sheet Title", @"Title for sheet displayed with options for displaying Earthquake data in other applications") delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Share Story", @"Share Story"), NSLocalizedString(@"Open In Safari", @"Open In Safari"), nil];
  [sheet showInView:self.view];
  [sheet release];
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	// starting the load, show the activity indicator in the status bar
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	// finished loading, hide the activity indicator in the status bar
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

  [self setArticleTitle:[[newsEntry valueForKey:kTitleElementName] description]];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	// load error, hide the activity indicator in the status bar
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  
	// report the error inside the webview
	NSString* errorString = [NSString stringWithFormat:
                           @"<html><center><font size=+5 color='red'>An error occurred:<br>%@</font></center></html>",
                           error.localizedDescription];
	[self.webView loadHTMLString:errorString baseURL:nil];
}

- (void)dealloc
{
	[newsEntry release];
	[mWebView release];
	[mResponseData release];
	[mBaseURL release];

  [super dealloc];
}

@end
