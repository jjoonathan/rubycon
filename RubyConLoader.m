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
	RBBundleInit([[[NSBundle bundleForClass:self] pathForResource:@"console" ofType:@"rb"] UTF8String], self, nil);
}

@end
