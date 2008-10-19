/**
 *  @file RubyConLoader.m
 *  @license MIT License (see LICENSE.txt)
 *  @date 7/7/08.
 *  @author Jonathan deWerd
 *  @copyright Copyright 2008 Jonathan deWerd. This file is distributed under the MIT license (see accompanying file for details).
 */
#import "RubyConLoader.h"
#import <RubyCocoa/RubyCocoa.h>

@implementation RubyConLoader

+ (void)doNothing:(id)inp {
}

+ (void)load {
	//Don't load into rubycocoa apps. Two rubies load, and its a big mess.
	if (!system([[NSString stringWithFormat:@"nm \"%@\" | grep RBApplicationMain", [[NSBundle mainBundle] executablePath]] UTF8String])) return;
		
	//But otherwise go ahead
	RBBundleInit([[[NSBundle bundleForClass:self] pathForResource:@"rubycon" ofType:@"rb"] UTF8String], self, nil);
}

@end
