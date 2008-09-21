/**
 *  @file RubyConDefaultsKey.m
 *  @license MIT License (see LICENSE.txt)
 *  @date 9/2/08.
 *  @author Jonathan deWerd
 *  @copyright Copyright 2008 Jonathan deWerd. This file is distributed under the MIT license (see accompanying file for details).
 */
#import "RubyConDefaultsKey.h"
#import "RubyConDefaultsDomain.h"
#import "RubyConDefaultsController.h"

@implementation RubyConDefaultsKey
- (id)initWithName:(NSString*)name domain:(RubyConDefaultsDomain*)d {
	if (!(self = [super init])) return nil;
	mName = [name copy];
	mDomain = d;
	return self;
}

- (id)copyWithZone:(NSZone*)z {
	return [self retain];
}

- (NSString*)name {
	return mName;
}

- (id)value {
	return [mDomain valueForKeyNamed:mName];
}

- (NSString*)stringValue {
	return [[self value] description];
}

- (BOOL)setName:(NSString*)newName {
	if (![[self domainName] isEqualToString:[[RubyConDefaultsController appDomain] name]]) return NO;
	if ([mName isEqualToString:newName]) return NO;
	id val = [self value];
	NSUserDefaults* sd = [NSUserDefaults standardUserDefaults];
	[sd removeObjectForKey:mName];
	if ([[sd objectForKey:mName] isEqualTo:val]) return NO;
	[sd setObject:val forKey:newName];
	[mName release];
	mName = [newName copy];
	return YES;
}

- (id)color {
	return nil;
}

- (NSString*)domainName {
	return [mDomain name];
}

- (void)setDomainName:(NSString*)dn {
	[self doesNotRecognizeSelector:_cmd];
}

@end
