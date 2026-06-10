// -*- mode: objc -*-
#import <CRuby.h>
#import "RubySketch.h"
#ifdef IOS
#include "../reflex/src/ios/view_controller.h"
#endif


extern "C"
{
	void Init_beeps_ext ();
	void Init_rays_ext ();
	void Init_reflex_ext ();
}


#ifdef IOS
static ReflexViewController* active_reflex_view_controller = nil;

static ReflexViewController*
ReflexViewController_create()
{
	return active_reflex_view_controller;
}

static void
ReflexViewController_show (UIViewController*, ReflexViewController*)
{
}
#endif


@implementation RubySketch

	+ (void) setup
	{
		static BOOL done = NO;
		if (done) return;
		done = YES;

		[CRuby addExtension:@"beeps_ext"  init:^{Init_beeps_ext();}];
		[CRuby addExtension:@"rays_ext"   init:^{Init_rays_ext();}];
		[CRuby addExtension:@"reflex_ext" init:^{Init_reflex_ext();}];

		for (NSString *ext in @[
			@"Xot",
			@"Rucy",
			@"Beeps",
			@"Rays",
			@"Reflex",
			@"Processing",
			@"RubySketch"
		]) [CRuby addLibrary:ext bundle:[NSBundle bundleForClass:RubySketch.class]];

#ifdef IOS
		ReflexViewController_set_create_fun(ReflexViewController_create);
		ReflexViewController_set_show_fun(ReflexViewController_show);
#endif
	}

	+ (BOOL) start
	{
		return [self start:@"main.rb" rescue:nil];
	}

	+ (BOOL) startWithRescue: (RescueBlock) rescue
	{
		return [self start:@"main.rb" rescue:rescue];
	}

	+ (BOOL) start: (NSString*) path
	{
		return [self start:path rescue:nil];
	}

	+ (BOOL) start: (NSString*) path rescue: (RescueBlock) rescue
	{
#ifdef OSX
		// add the script directory to the load path so that sketches
		// split into multiple files can require each other
		[CRuby evaluate:[NSString stringWithFormat:
			@"$LOAD_PATH.unshift '%@'", [path stringByDeletingLastPathComponent]]];

		// CRuby finalizes the interpreter after loading the script, which
		// fires the at_exit hook in lib/rubysketch.rb that starts the
		// application event loop just like 'ruby main.rb' does
		return rescue ? [CRuby start:path rescue:rescue] : [CRuby start:path];
#else
		// the host UIApplication is already running the event loop,
		// so showing the window is enough
		NSString* script = [NSString stringWithFormat:@
			"raise 'already started' unless require 'rubysketch'\n"
			"load '%@'\n"
			"RubySketch::WINDOW__.__send__ :end_draw\n"
			"RubySketch::WINDOW__.show",
			path];
		CRBValue* ret = rescue
			? [CRuby evaluate:script rescue:rescue]
			: [CRuby evaluate:script];
		return ret && ret.toBOOL;
#endif
	}

#ifdef IOS
	+ (void) setActiveReflexViewController: (id) reflexViewController
	{
		active_reflex_view_controller = reflexViewController;
	}

	+ (void) resetActiveReflexViewController
	{
		active_reflex_view_controller = nil;
	}
#endif

@end
