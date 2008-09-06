#import "RubyConDefaultsController.h"
#import "RubyConDefaultsDomain.h"

@implementation RubyConDefaultsController

static void setupP(RubyConDefaultsController* self) {
	if (!self->mSetuped) {
		self->mSetuped = YES;
	}
}

- (void)show {
	setupP(self);
	[oWindow makeKeyAndOrderFront:self];
}


+ (RubyConDefaultsDomain*)appDomain {
	static RubyConDefaultsDomain* ad = nil;
	if (!ad) ad = [[RubyConDefaultsDomain alloc] initWithName:[[NSBundle mainBundle] bundleIdentifier] volatility:NO controller:nil];
	return ad;
}

+ (RubyConDefaultsDomain*)globalDomain {
	static RubyConDefaultsDomain* gd = nil;
	if (!gd) gd = [[RubyConDefaultsDomain alloc] initWithName:NSGlobalDomain volatility:NO controller:nil];
	return gd;
}

- (void)dealloc {
	[mDomains release];
	[super dealloc];
}


- (NSArray*)defaultDomains {
	NSMutableArray* ret = [NSMutableArray array];
	[ret addObject:[[[RubyConDefaultsDomain alloc] initWithName:@"All" volatility:NO controller:self] autorelease]];
	[ret addObject:[RubyConDefaultsController appDomain]]; //I think these are the only two persistent domains that are searched... correct it if I am wrong :)
	[ret addObject:[RubyConDefaultsController globalDomain]];
	
	NSArray* vds = [[NSUserDefaults standardUserDefaults] volatileDomainNames];
	NSUInteger i, count = [vds count];
	for (i = 0; i < count; i++) {
		id toadd = [[[RubyConDefaultsDomain alloc] initWithName:[vds objectAtIndex:i] volatility:YES controller:self] autorelease];
		[ret addObject:toadd];
	}
	return ret; //-domains relies on this being an NSMutableArray
}

- (NSArray*)domains {
	if (mDomains) return mDomains;
	mDomains = (NSMutableArray*)[[self defaultDomains] retain];
	return mDomains;
}

@end
