/**
 *  @file RubyConDefaultsDomain.m
 *  @license MIT License (see LICENSE.txt)
 *  @date 9/2/08.
 *  @author Jonathan deWerd
 *  @copyright Copyright 2008 Jonathan deWerd. This file is distributed under the MIT license (see accompanying file for details).
 */
@class RubyConDefaultsDomain;

@interface RubyConDefaultsController : NSObject {
	BOOL mSetuped;
	IBOutlet NSWindow* oWindow;
	IBOutlet NSArrayController* oDefaultDomains;
	NSMutableArray* mDomains;
}
- (void)show;
- (NSArray*)defaultDomains;
- (NSArray*)domains;
+ (RubyConDefaultsDomain*)appDomain;
+ (RubyConDefaultsDomain*)globalDomain;
@end
