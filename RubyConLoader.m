/**
 *  @file RubyConLoader.m
 *  @license MIT License (see LICENSE.txt)
 *  @date 7/7/08.
 *  @author Jonathan deWerd
 *  @copyright Copyright 2008 Jonathan deWerd. This file is distributed under the MIT license (see accompanying file for details).
 */
#define USE_MACRUBY
#import "RubyConLoader.h"
#ifdef USE_MACRUBY
#import <MacRuby/MacRuby.h>
#else
#import <RubyCocoa/RubyCocoa.h>
#endif

@implementation RubyConLoader

+ (void)doNothing:(id)inp {
}

+ (void)load {
	NSString* rubyconStartPath = [[NSBundle bundleForClass:self] pathForResource:@"rubycon" ofType:@"rb"];
#ifndef USE_MACRUBY
	const char* entry_file = [rubyconStartPath UTF8String];
	//Don't load rubycocoa into rubycocoa apps. Two rubies load, and its a big mess.
	if (!system([[NSString stringWithFormat:@"nm \"%@\" | grep RBApplicationMain", [[NSBundle mainBundle] executablePath]] UTF8String])) return;
		
	//But otherwise go ahead
	RBBundleInit(entry_file, self, nil);
#else
	[[MacRuby sharedRuntime] evaluateFileAtPath:rubyconStartPath];
#endif
}

@end
