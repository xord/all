// -*- objc -*-
#import "app_delegate.h"


#include <assert.h>
#import  <CoreMotion/CoreMotion.h>
#include "reflex/event.h"
#include "reflex/exception.h"
#include "application.h"


@implementation ReflexAppDelegate

	{
		Reflex::Application* application;
		bool started;
		UIWindow* window;
		CMMotionManager* motion_manager;
	}

	- (id) init
	{
		self = [super init];
		if (!self) return nil;

		application    = NULL;
		started        = false;
		window         = nil;
		motion_manager = nil;

		return self;
	}

	- (void) dealloc
	{
		assert(!application);

		[self stopUpdateDeviceMotion];

		[super dealloc];
	}

	- (void) bind: (Reflex::Application*) app
	{
		if (!app)
			Reflex::argument_error(__FILE__, __LINE__);

		Reflex::ApplicationData& data = Reflex::Application_get_data(app);
		if (data.delegate)
			Reflex::invalid_state_error(__FILE__, __LINE__);

		data.delegate = [self retain];
		app->retain();

		application = app;
	}

	- (void) unbind
	{
		if (!application) return;

		Reflex::ApplicationData& data = Reflex::Application_get_data(application);
		if (data.delegate)
		{
			[data.delegate release];
			data.delegate = nil;
		}

		application->release();
		application = NULL;
	}

	- (BOOL) callOnStart
	{
		if (!application || started)
			return YES;

		Reflex::Event e;
		Application_call_start(application, &e);
		started = true;

		return !e.is_blocked();
	}

	- (BOOL) application: (UIApplication*) application
		didFinishLaunchingWithOptions: (NSDictionary*) options
	{
		Reflex::Application* app = Reflex::app();
		if (!self->application && app)
			[self bind: app];

		[self startUpdateDeviceMotion];

		return [self callOnStart];
	}

	- (void) startUpdateDeviceMotion
	{
		CMMotionManager* man = [[[CMMotionManager alloc] init] autorelease];
		if (!man || !man.deviceMotionAvailable)
			return;

		man.deviceMotionUpdateInterval = 1 / 60.0;
		[man
			startDeviceMotionUpdatesToQueue: NSOperationQueue.currentQueue
			withHandler: ^(CMDeviceMotion* motion, NSError* error)
			{
				if (!application) return;

				Reflex::MotionEvent e(
					Reflex::Point(motion.gravity.x, -motion.gravity.y, motion.gravity.z));
				application->on_motion(&e);
			}
		];

		motion_manager = [man retain];
	}

	- (void) stopUpdateDeviceMotion
	{
		if (!motion_manager || !motion_manager.deviceMotionActive)
			return;

		[motion_manager stopDeviceMotionUpdates];
		[motion_manager release];
		motion_manager = nil;
	}

	- (void) applicationWillResignActive: (UIApplication*) application
	{
	}

	- (void) applicationDidEnterBackground: (UIApplication*) application
	{
	}

	- (void) applicationWillEnterForeground: (UIApplication*) application
	{
	}

	- (void) applicationDidBecomeActive: (UIApplication*) application
	{
	}

	- (void) applicationWillTerminate: (UIApplication*) application
	{
		if (self->application)
		{
			Reflex::Event e;
			Application_call_quit(self->application, &e);
			if (e.is_blocked())
			{
				Reflex::not_implemented_error(
					__FILE__, __LINE__, "blocking to quit is not supported.");
			}
		}

		[self unbind];
	}

@end// ReflexAppDelegate
