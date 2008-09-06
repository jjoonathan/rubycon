/**
 *  @file RubyConUtilities.h
 *  @license MIT License (see LICENSE.txt)
 *  @date 8/7/08.
 *  @author Jonathan deWerd
 *  @copyright Copyright 2008 Jonathan deWerd. This file is distributed under the MIT license (see accompanying file for details).
 */

@interface RubyConUtilities : NSObject {}
- (NSArray*)arrayByCallingSelector:(SEL)sel onObject:(id)receiver; ///Helps resolve the conflict between FScript's Array class and Ruby's Array class by dealing with it in objc.
@end

@interface NSObject (RubyConAdditions)
- (uintptr_t)numericalPointer;
+ (id)objectFromNumericalPointer:(uintptr_t)ptr;
@end