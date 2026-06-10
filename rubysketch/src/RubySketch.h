// -*- mode: objc -*-
#import <Foundation/Foundation.h>
#import <TargetConditionals.h>
#import <CRBValue.h>


@interface RubySketch : NSObject

	typedef void (^RescueBlock) (CRBValue* exception);

	+ (void) setup;

	+ (BOOL) start;
	+ (BOOL) startWithRescue: (RescueBlock) rescue;

	+ (BOOL) start: (NSString*) path;
	+ (BOOL) start: (NSString*) path rescue: (RescueBlock) rescue;

#if TARGET_OS_IPHONE
	+ (void) setActiveReflexViewController: (id) reflexViewController;

	+ (void) resetActiveReflexViewController;
#endif

@end
