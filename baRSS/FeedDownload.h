//
//  The MIT License (MIT)
//  Copyright (c) 2018 Oleg Geier
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

#import <Cocoa/Cocoa.h>
#import <RSXML/RSXML.h>

@class Feed;

@interface FeedDownload : NSObject
// Register for network change notifications
+ (void)registerNetworkChangeNotification;
+ (void)unregisterNetworkChangeNotification;
// Scheduling
+ (void)scheduleUpdateForUpcomingFeeds;
+ (void)forceUpdateAllFeeds;
// Downloading
+ (void)newFeed:(NSString *)urlStr block:(void(^)(RSParsedFeed *feed, NSError *error, NSHTTPURLResponse *response))block;
+ (void)autoDownloadAndParseURL:(NSString*)urlStr;
+ (void)batchDownloadRSSAndFavicons:(NSArray<Feed*> *)list showErrorAlert:(BOOL)flag rssFinished:(void(^)(NSArray<Feed*> *successful, BOOL *cancelFavicons))blockXml finally:(void(^)(BOOL successful))blockFavicon;
+ (void)downloadFavicon:(NSString*)urlStr finished:(void(^)(NSImage * _Nullable img))block ;
// User interaction
+ (BOOL)allowNetworkConnection;
+ (BOOL)isPaused;
+ (void)setPaused:(BOOL)flag;
@end


/*
 Developer Tip, error logs see:
 
 Task <..> HTTP load failed (error code: -1003 [12:8])
 Task <..> finished with error - code: -1003
 ==> NSURLErrorCannotFindHost in #import <Foundation/NSURLError.h>
 
 TIC TCP Conn Failed [21:0x1d417fb00]: 1:65 Err(65)
 ==> EHOSTUNREACH in #import <sys/errno.h>
 */
