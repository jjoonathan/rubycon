/**
 *  @file RubyConDefaultsDomain.h
 *  @license MIT License (see LICENSE.txt)
 *  @date 9/2/08.
 *  @author Jonathan deWerd
 *  @copyright Copyright 2008 Jonathan deWerd. This file is distributed under the MIT license (see accompanying file for details).
 */
@class RubyConDefaultsController;

@interface RubyConDefaultsDomain : NSObject {
	NSString* mName;
	BOOL mVolatile;
	NSDictionary* mKVPairs;
	RubyConDefaultsController* mController;
}
- (id)initWithName:(NSString*)nm volatility:(BOOL)vol controller:(RubyConDefaultsController*)dc;
- (NSString*)name;
- (BOOL)isVolatile;
- (NSColor*)nameColor;
- (NSArray*)keys;
- (id)valueForKeyNamed:(NSString*)k;
- (void)updateDomainCache:(id)dummy;
@end
