/**
 *  @file RubyConFocusView.h
 *  @license MIT License (see LICENSE.txt)
 *  @date 8/15/08.
 *  @author Jonathan deWerd
 *  @copyright Copyright 2008 Jonathan deWerd. This file is distributed under the MIT license (see accompanying file for details).
 */

@interface RubyConFocusView : NSView {
	NSView* mTV;
}
- (NSView*)targetView;
- (void)setTargetView:(NSView*)tv;
- (void)drawBoxForView:(NSView*)v path:(NSString*)p;
@end
