/**
 *  @file RubyConUtilities.m
 *  @license MIT License (see LICENSE.txt)
 *  @date 8/7/08.
 *  @author Jonathan deWerd
 *  @copyright Copyright 2008 Jonathan deWerd. This file is distributed under the MIT license (see accompanying file for details).
 */
#import "RubyConUtilities.h"


@implementation RubyConUtilities
- (NSArray*)arrayByCallingSelector:(SEL)sel onObject:(id)receiver {
	NSArray* arr = [receiver performSelector:sel];
	return [NSArray arrayWithArray:arr];
}
@end


@implementation NSObject (RubyConAdditions)
- (uintptr_t)numericalPointer {
	return (uintptr_t)self;
}

+ (id)objectFromNumericalPointer:(uintptr_t)ptr {
	return (id)ptr;
}

@end
