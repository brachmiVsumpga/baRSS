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

@import Cocoa;

@interface UserPrefs : NSObject
// User Preferences Plist
+ (BOOL)defaultYES:(NSString*)key;
+ (BOOL)defaultNO:(NSString*)key;
+ (NSUInteger)defaultUInt:(NSUInteger)defaultInt forKey:(NSString*)key;

+ (NSString*)getHttpApplication;
+ (void)setHttpApplication:(NSString*)bundleID;
+ (BOOL)openURLsWithPreferredBrowser:(NSArray<NSURL*>*)urls;

// Hidden Plist Properties
+ (NSUInteger)openFewLinksLimit; // Change with: 'defaults write de.relikd.baRSS openFewLinksLimit -int 10'
+ (NSUInteger)shortArticleNamesLimit; // Change with: 'defaults write de.relikd.baRSS shortArticleNamesLimit -int 50'
+ (NSUInteger)articlesInMenuLimit; // Change with: 'defaults write de.relikd.baRSS articlesInMenuLimit -int 40'

// Application Info Plist
+ (NSString*)appName;
+ (NSString*)appVersion;
+ (NSString*)appVersionWithBuildNo;

// Core Data Properties
+ (BOOL)dbIsUnusedInitalState;
+ (BOOL)dbIsCurrentFileVersion;
+ (BOOL)dbIsCurrentAppVersion;
+ (void)dbUpdateFileVersion;
+ (void)dbUpdateAppVersion;
@end
