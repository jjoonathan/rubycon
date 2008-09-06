/**
 *  @file RubyConDefaultsDomain.m
 *  @license MIT License (see LICENSE.txt)
 *  @date 9/2/08.
 *  @author Jonathan deWerd
 *  @copyright Copyright 2008 Jonathan deWerd. This file is distributed under the MIT license (see accompanying file for details).
 */
#import "RubyConDefaultsDomain.h"
#import "RubyConDefaultsKey.h"
#import "RubyConDefaultsController.h"

@interface RubyConDefaultsKey (Private)
- (NSArray*)keysForKeynames:(NSArray*)ents inDomain:(RubyConDefaultsDomain*)d;
- (BOOL)isReal;
@end



@implementation RubyConDefaultsDomain

- (id)initWithName:(NSString*)nm volatility:(BOOL)vol controller:(RubyConDefaultsController*)dc {
	if (!(self=[super init])) return nil;
	mName=[nm copy];
	mVolatile=vol;
	mController = dc;
	[self updateDomainCache:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDomainCache:) name:NSUserDefaultsDidChangeNotification object:nil];
	return self;
}

- (void)updateDomainCache:(id)dummy {
	[self willChangeValueForKey:@"keys"];
	[mKVPairs release];
	if ([mName isEqualToString:@"All"]) {
		mKVPairs = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] retain];
	} else if (mVolatile) {
		mKVPairs = [[[NSUserDefaults standardUserDefaults] volatileDomainForName:mName] retain];
	} else if (!mVolatile) {
		mKVPairs = [[[NSUserDefaults standardUserDefaults] persistentDomainForName:mName] retain];
	}
	[self didChangeValueForKey:@"keys"];
}

- (void)dealloc {
	[mKVPairs release];
	[mName release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


- (NSString*)name {return mName;}
- (BOOL)isVolatile {return mVolatile;}
- (BOOL)isReal {if ([mName isEqualToString:@"All"]) return NO; return YES;}
- (NSColor*)nameColor {return ([self isVolatile])? [NSColor redColor] : [NSColor blackColor];}

- (NSArray*)keysForKeynames:(NSArray*)ents inDomain:(RubyConDefaultsDomain*)d {
	NSMutableArray* ret = [[[NSMutableArray alloc] init] autorelease];
	NSEnumerator* mKVPairsEnumerator = [mKVPairs keyEnumerator];
	NSString* o; while ((o = [mKVPairsEnumerator nextObject])) {
		[ret addObject:[[[RubyConDefaultsKey alloc] initWithName:o domain:d] autorelease]];
	}
	return ret;	
}

- (NSArray*)keys {
	if ([mName isEqualToString:@"All"]) {
		NSMutableArray* keys = [[[NSMutableArray alloc] init] autorelease];
		NSArray* dmns = [mController domains];
		NSEnumerator* dmnsEnumerator = [dmns objectEnumerator];
		RubyConDefaultsDomain* o; while ((o = [dmnsEnumerator nextObject])) {
			if (![o isReal]) continue;
			[keys addObjectsFromArray:[o keys]];
		}
		return keys;
	} else {
		return [self keysForKeynames:[mKVPairs allKeys] inDomain:self];
	}
}
		
- (id)valueForKeyNamed:(NSString*)k {
	return [mKVPairs objectForKey:k];
}


@end
