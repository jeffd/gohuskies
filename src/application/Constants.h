/*
 *  Constants.h
 *  gohuskies
 *
 *  Created by Jeff Dlouhy on 7/13/09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

// CoreData Model
static NSString* const kFeedItemModelFilename = @"FeedItem.sqlite";

// Managed Objects
static NSString* const kNewsEntryMOName = @"NewsEntry";
static NSString* const kVideoEntryMOName = @"VideoEntry";
static NSString* const kCategoryMOName = @"Category";
static NSString* const kVideoMOName = @"VideoContent";

// News/Video Entry
static NSString* const kChannelElementName = @"channel";
static NSString* const kEntryElementName = @"item";
static NSString* const kLinkElementName = @"link";
static NSString* const kGUIDElementName = @"guid";
static NSString* const kTitleElementName = @"title";
static NSString* const kPubDateElementName = @"pubDate";
// Does not like it when description is used for a key
static NSString* const kDescElementName = @"description";
static NSString* const kDescKey = @"summary";

// Video Entry
static NSString* const kMRSSThumbnailElementName = @"media:thumbnail";
static NSString* const kMRSSGroupElementName = @"media:group";
static NSString* const kMRSSContentElementName = @"media:content";
static NSString* const kMRSSDurationElementName = @"duration";
static NSString* const kMRSSMediumElementName = @"medium";
static NSString* const kMRSSFilesizeElementName = @"fileSize";
static NSString* const kMRSSURLElementName = @"url";
static NSString* const kMRSSTypeElementName = @"type";

static NSUInteger const kMRSSNumberDefaultContentElements = 5;

static NSString* const kVideoThumbnailURLPropertyName = @"thumbnailURL";
static NSString* const kVideoGroupPropertyName = @"videos";

// Category
static NSString* const kCategoryElementName = @"category";

// Video
static NSString* const kVideoParentRelationshipName = @"videoEntry";

// Parsing Settings
static NSUInteger const kMaximumNumberOfItemsToParse = 50;
static NSUInteger const kSizeOfFeedBatch = 10;
static NSUInteger const kDefaultEntryElements = 6;

