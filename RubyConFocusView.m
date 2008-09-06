/**
 *  @file RubyConFocusView.m
 *  @license MIT License (see LICENSE.txt)
 *  @date 8/15/08.
 *  @author Jonathan deWerd
 *  @copyright Copyright 2008 Jonathan deWerd. This file is distributed under the MIT license (see accompanying file for details).
 */
#import "RubyConFocusView.h"


@implementation RubyConFocusView

- (NSView*)targetView {return mTV;}
- (void)setTargetView:(NSView*)tv {
	if (tv==mTV) return;
	id old = mTV;
	mTV = [tv retain];
	[old release];
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)r {
	[self drawBoxForView:mTV path:nil];
}

- (void)drawBoxForView:(NSView*)v path:(NSString*)p {
	static NSColor* strokeColor = nil;
	if (!strokeColor) strokeColor = [[NSColor colorWithCalibratedRed:1 green:0 blue:0 alpha:.5] retain];
	static NSColor* fillColor = nil;
	if (!fillColor) fillColor = [[NSColor colorWithCalibratedWhite:0 alpha:.3] retain];
	static NSColor* whiteColor = nil;
	if (!whiteColor) whiteColor = [[NSColor whiteColor] retain];
	static NSDictionary* pathAttribs = nil;
	if (!pathAttribs) pathAttribs = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont systemFontOfSize:8], NSFontAttributeName, whiteColor, NSForegroundColorAttributeName, nil];
		
	if (!v) return;
	if (p && [v superview]) {
		NSRect vw_r = [[v superview] convertRect:[v frame] toView:nil];
		NSPoint s_o = [[v window] convertBaseToScreen:vw_r.origin];
		NSPoint sw_o = [[self window] convertScreenToBase:s_o];
		double newx = floor(sw_o.x)+.5; double dx = newx - sw_o.x;
		double newy = floor(sw_o.y)+.5; double dy = newy - sw_o.y;
		NSRect r = NSMakeRect(newx,
							  newy,
							  floor(vw_r.size.width-dx),
							  floor(vw_r.size.height-dy));
		[fillColor set];
		[NSBezierPath fillRect:r];
		[strokeColor set];
		[NSBezierPath strokeRect:r];
		[p drawAtPoint:NSMakePoint(r.origin.x+2, r.origin.y+1) withAttributes:pathAttribs];
	}
	NSArray* svs = [v subviews];
	NSUInteger i,ct = [svs count];
	for (i=0; i<ct; i++) {
		NSString* newpath = [p?:@"" stringByAppendingFormat:@"%s%i",p?".":"",i];
		[self drawBoxForView:[svs objectAtIndex:i] path:newpath];
	}
}

- (void)dealloc {
	[mTV release];
	[super dealloc];
}

@end
