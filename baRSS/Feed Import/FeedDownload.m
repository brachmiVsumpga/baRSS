//
//  The MIT License (MIT)
//  Copyright (c) 2019 Oleg Geier
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
//  of the Software, and to permit persons to whom the Software is furnished to do
//  so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

@import RSXML;
#import "FeedDownload.h"
#import "FaviconDownload.h"
#import "Feed+Ext.h"
#import "FeedMeta+Ext.h"
#import "NSURLRequest+Ext.h"

@interface FeedDownload()
@property (nonatomic, assign) BOOL respondToSelectFeed, respondToRedirect, respondToEnd;
@property (nonatomic, weak) id<FeedDownloadDelegate> delegate;
@property (nonatomic, strong) FeedDownloadBlock block;
@property (nonatomic, weak) NSURLSessionTask *currentDownload;
@property (nonatomic, assign) BOOL canceled;

@property (nonatomic, assign) BOOL assertIsFeedURL; // prohibit processing of HTML data
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) NSHTTPURLResponse* response;
@property (nonatomic, strong) RSParsedFeed *xmlfeed;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NSString *faviconURL;
@end

@implementation FeedDownload

//  ---------------------------------------------------------------
// |  MARK: - Class methods
//  ---------------------------------------------------------------

/// @return New instance with plain @c url request.
+ (instancetype)withURL:(NSString*)url {
	FeedDownload *this = [FeedDownload new];
	this.request = [NSURLRequest withURL:url];
	return this;
}

/// @return New instance using existing @c feed as template. Will reuse @c Etag and @c Last-modified headers.
+ (instancetype)withFeed:(Feed*)feed forced:(BOOL)flag {
	FeedMeta *m = feed.meta;
	NSMutableURLRequest *req = [NSMutableURLRequest withURL:m.url];
	if (!flag) // any request that is not forced, is a background update
		req.networkServiceType = NSURLNetworkServiceTypeBackground;
	if (feed.articles.count > 0) { // dont use cache if feed is broken
		// Both fields should be send (if server provides both) RFC: https://tools.ietf.org/html/rfc7232#section-2.4
		if (m.etag.length > 0)
			[req setValue:[m.etag stringByReplacingOccurrencesOfString:@"-gzip" withString:@""] forHTTPHeaderField:@"If-None-Match"]; // ETag
		if (m.modified.length > 0)
			[req setValue:m.modified forHTTPHeaderField:@"If-Modified-Since"];
	}
	FeedDownload *this = [FeedDownload new];
	this.assertIsFeedURL = YES;
	this.request = req;
	return this;
}

//  ---------------------------------------------------------------
// |  MARK: - Getter & Setter
//  ---------------------------------------------------------------

/// Set delegate and check what methods are implemented.
- (void)setDelegate:(id<FeedDownloadDelegate>)observer {
	_delegate = observer;
	_respondToSelectFeed = [observer respondsToSelector:@selector(feedDownload:selectFeedFromList:)];
	_respondToRedirect = [observer respondsToSelector:@selector(feedDownload:urlRedirected:)];
	_respondToEnd = [observer respondsToSelector:@selector(feedDownloadDidFinish:)];
}

/// @return Initialize @c FaviconDownload instance. Will reuse favicon url from HTML parsing.
- (FaviconDownload*)faviconDownload {
	if (self.faviconURL.length > 0) // favicon url already found, nice job
		return [FaviconDownload withURL:self.faviconURL isImageURL:YES];
	
	NSString *url = self.xmlfeed.link; // does only work for status != 304
	if (!url) url = self.response.URL.absoluteString;
	return [FaviconDownload withURL:url isImageURL:NO];
}

//  ---------------------------------------------------------------
// |  MARK: - Actions
//  ---------------------------------------------------------------

/// Start download request and use @c delegate as callback notifier.
- (instancetype)startWithDelegate:(id<FeedDownloadDelegate>)delegate {
	self.delegate = delegate;
	[self downloadSource:self.request];
	return self;
}

/// Start download request and use @c block as callback notifier.
- (instancetype)startWithBlock:(nonnull FeedDownloadBlock)block {
	self.block = block;
	[self downloadSource:self.request];
	return self;
}

/// Cancel running download task without notice. Will notify neither @c delegate nor @c block
- (void)cancel {
	self.canceled = YES;
	self.delegate = nil;
	self.block = nil;
	[self.currentDownload cancel];
}

/// Take the @c urlStr and run a download @c dataTask: on it. Auto-detect if data is HTML or feed.
- (void)downloadSource:(NSURLRequest*)request {
	self.currentDownload = [request dataTask:^(NSData * _Nullable data, NSError * _Nullable error, NSHTTPURLResponse *response) {
		self.error = error;
		self.response = response;
		if (!data) { // data = nil if (error || 304)
			[self performSelectorOnMainThread:@selector(finishAndNotify) withObject:nil waitUntilDone:NO];
			return;
		}
		RSXMLData *xml = [[RSXMLData alloc] initWithData:data url:response.URL];
		if (!self.assertIsFeedURL && [xml.parserClass isHTMLParser])
			[self processXMLDataHTML:xml];
		else
			[self processXMLDataFeed:xml];
	}];
}

/// The downloaded source seems to be HTML data, lets parse it with @c RSXML @c RSHTMLMetadataParser
- (void)processXMLDataHTML:(RSXMLData*)xml {
	RSHTMLMetadataParser *parser = [RSHTMLMetadataParser parserWithXMLData:xml];
	[parser parseAsync:^(RSHTMLMetadata * _Nullable meta, NSError * _Nullable error) {
		if (error) {
			self.error = error;
		} else if (!meta || meta.feedLinks.count == 0) {
			self.error = RSXMLMakeErrorWrongParser(RSXMLErrorExpectingFeed, RSXMLErrorExpectingHTML, xml.url);
		} else {
			self.faviconURL = [FaviconDownload urlForMetadata:meta]; // we can re-use favicon url if we find one
			NSString *chosenURL = meta.feedLinks.firstObject.link;
			if (self.respondToSelectFeed && meta.feedLinks.count > 1)
				chosenURL = [self.delegate feedDownload:self selectFeedFromList:meta.feedLinks];
			
			if (chosenURL.length > 0) {
				self.assertIsFeedURL = YES;
				// Feeds like https://news.ycombinator.com/ return 503 if URLs are requested too rapidly
				//CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0, false); // Non-blocking sleep (1s)
				[self downloadSource:[NSURLRequest withURL:chosenURL]];
				return;
			} else { // User canceled operation, show appropriate error message
				NSDictionary *info = @{ NSLocalizedDescriptionKey: NSLocalizedString(@"Operation canceled.", nil) };
				self.error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:info];
			}
		}
		[self finishAndNotify];
	}];
}

/// The downloaded source seems to be proper feed data, lets parse it with @c RSXML @c RSFeedParser
- (void)processXMLDataFeed:(RSXMLData*)xml {
	RSFeedParser *parser = [RSFeedParser parserWithXMLData:xml];
	parser.dontStopOnLowerAsciiBytes = YES;
	[parser parseAsync:^(RSParsedFeed * _Nullable parsedDocument, NSError * _Nullable error) {
		self.error = error;
		self.xmlfeed = parsedDocument;
		[self finishAndNotify];
	}];
}

/// Check if @c responseURL @c != @c requestURL
- (void)checkRedirectAndNotify {
	NSString *responseURL = self.response.URL.absoluteString;
	if (responseURL.length > 0 && ![responseURL isEqualToString:self.request.URL.absoluteString]) {
		if (self.respondToRedirect) [self.delegate feedDownload:self urlRedirected:responseURL];
	}
}

/// Called when feed download finished or failed, but not if canceled. Will notify @c delegate .
- (void)finishAndNotify {
	if (self.canceled)
		return;
	[self checkRedirectAndNotify];
	// notify observer
	if (self.respondToEnd) [self.delegate feedDownloadDidFinish:self];
	if (self.block) { self.block(self); self.block = nil; }
}

/**
 Persist in memory object by copying all attributes to permanent core data storage.

 @param flag If @c YES then @c FeedGroup won't increase the error count for the feed.
             Feed will be scheduled as soon as the user reconnects to the internet.
 @return @c YES if downloaded feed contains at least one article. ( @c 304 returns @c NO )
 */
- (BOOL)copyValuesTo:(nonnull Feed*)feed ignoreError:(BOOL)flag {
	if (!flag && self.error) // Increase error count and schedule next update.
		[feed.meta setErrorAndPostponeSchedule];
	else if (self.response) // Update Etag & Last modified and schedule next update.
		[feed.meta setSucessfulWithResponse:self.response];
	else // Update URL but keep schedule (e.g., error while adding feed should auto-try once reconnected)
		[feed.meta setUrlIfChanged:self.request.URL.absoluteString];
	
	// If feed is broken indicate that feed will not be updated
	if (!self.xmlfeed || self.xmlfeed.articles.count == 0)
		return NO;
	// Else: Update stored articles and indicate that feed was updated
	[feed updateWithRSS:self.xmlfeed postUnreadCountChange:YES];
	return YES;
}

@end
