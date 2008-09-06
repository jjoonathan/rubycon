/**
 *  @file NSWindow+WindowList.m
 *  @license MIT License (see LICENSE.txt)
 *  @date 8/8/08.
 *  @author Jonathan deWerd
 *  @copyright Copyright 2008 Jonathan deWerd. This file is distributed under the MIT license (see accompanying file for details).
 */
#import "NSWindow+WindowList.h"


@implementation NSWindow (WindowList)
+ (NSArray*)listOfAllAppWindows {
	NSInteger num_windows; NSCountWindows(&num_windows);
    NSInteger* windows = malloc(num_windows*sizeof(NSInteger));
    NSWindowList(num_windows, windows);
	NSMutableArray* ret = [NSMutableArray array];
	NSInteger i; for (i=0; i<num_windows; i++) {
		NSWindow* win = [NSApp windowWithWindowNumber:windows[i]];
		if (win) [ret addObject:win]; //For some reason there are lots of "false positives" that turn out to be nil?!
	}
	free(windows);
	return ret;
}
@end
