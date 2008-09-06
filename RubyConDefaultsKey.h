/**
 *  @file RubyConDefaultsKey.h
 *  @license MIT License (see LICENSE.txt)
 *  @date 9/2/08.
 *  @author Jonathan deWerd
 *  @copyright Copyright 2008 Jonathan deWerd. This file is distributed under the MIT license (see accompanying file for details).
 */
@class RubyConDefaultsDomain;

@interface RubyConDefaultsKey : NSObject {
	RubyConDefaultsDomain* mDomain;
	NSString* mName;
}
- (id)initWithName:(NSString*)name domain:(RubyConDefaultsDomain*)d;
- (NSString*)name;
- (void)setName:(NSString*)newName;
- (NSString*)domainName;
- (void)setDomainName:(NSString*)dn;
- (id)value;
- (NSString*)stringValue;
@end
