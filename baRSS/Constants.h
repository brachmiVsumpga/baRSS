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

#ifndef Constants_h
#define Constants_h

// TODO: Add support for media player? image feed?
// <enclosure url="https://url.mp3" length="63274022" type="audio/mpeg" />
// TODO: Disable 'update all' menu item during update?
// TODO: List of hidden preferences for readme
// TODO: Do we need to search for favicon in places other than '../favicon.ico'?

static NSString *kNotificationFeedUpdated = @"baRSS-notification-feed-updated";
static NSString *kNotificationNetworkStatusChanged = @"baRSS-notification-network-status-changed";
static NSString *kNotificationTotalUnreadCountChanged = @"baRSS-notification-total-unread-count-changed";
static NSString *kNotificationTotalUnreadCountReset = @"baRSS-notification-total-unread-count-reset";

extern uint64_t dispatch_benchmark(size_t count, void (^block)(void));
//void benchmark(char *desc, dispatch_block_t b){printf("%s: %llu ns\n", desc, dispatch_benchmark(1, b));}
#define benchmark(desc,block) printf(desc": %llu ns\n", dispatch_benchmark(1, block));

#endif /* Constants_h */
