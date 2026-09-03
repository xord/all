// -*- objc -*-
#import <AppKit/NSApplication.h>
#include "application.h"


@interface ReflexAppDelegate : NSObject <NSApplicationDelegate>

	- (void) bind: (Reflex::Application*) application;

	- (BOOL) callOnStart;

	- (BOOL) isLaunched;

	- (void) updateStatusItem;

@end// ReflexAppDelegate
