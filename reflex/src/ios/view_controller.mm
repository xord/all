// -*- objc -*-
#import "view_controller.h"


#include <rays/opengl.h>
#include "reflex/exception.h"
#include "../view.h"
#include "../pointer.h"
#include "event.h"
#include "window.h"


//#define TRANSPARENT_BACKGROUND


static ReflexViewController*
create_reflex_view_controller ()
{
	return [[[ReflexViewController alloc] init] autorelease];
}

static UIViewController*
get_next_view_controller (UIViewController* vc)
{
	assert(vc);

	if ([vc isKindOfClass: UINavigationController.class])
		return ((UINavigationController*) vc).topViewController;

	if ([vc isKindOfClass: UITabBarController.class])
		return ((UITabBarController*) vc).selectedViewController;

	if ([vc isKindOfClass: UISplitViewController.class])
	{
		UISplitViewController* split = (UISplitViewController*) vc;
		return split.viewControllers[split.viewControllers.count - 1];
	}

	return vc.presentedViewController;
}

static UIViewController*
get_top_view_controller (UIViewController* vc)
{
	assert(vc);

	UIViewController* next;
	while (next = get_next_view_controller(vc))
		vc = next;

	return vc;
}

static void
show_reflex_view_controller (
	UIViewController* root_vc, ReflexViewController* reflex_vc)
{
	UIViewController* top = get_top_view_controller(root_vc);
	if (!top) return;

	if (top.navigationController)
		[top.navigationController pushViewController: reflex_vc animated: YES];
	else
		[top presentViewController: reflex_vc animated: YES completion: nil];
}


namespace global
{

	static ReflexViewController_CreateFun create_fun = NULL;

	static ReflexViewController_ShowFun   show_fun   = NULL;

}// global


void
ReflexViewController_set_create_fun (ReflexViewController_CreateFun fun)
{
	global::create_fun = fun;
}

void
ReflexViewController_set_show_fun (ReflexViewController_ShowFun fun)
{
	global::show_fun = fun;
}

ReflexViewController_CreateFun
ReflexViewController_get_create_fun ()
{
	return global::create_fun ? global::create_fun : create_reflex_view_controller;
}

ReflexViewController_ShowFun
ReflexViewController_get_show_fun ()
{
	return global::show_fun ? global::show_fun : show_reflex_view_controller;
}


@interface ReflexView ()

	@property(nonatomic, unsafe_unretained) ReflexViewController* reflexViewController;

@end


@implementation ReflexView

	- (void) layoutSubviews
	{
		[super layoutSubviews];

		if (self.reflexViewController)
			[self.reflexViewController viewDidResize];
	}

@end


@interface ReflexViewController () <GLKViewDelegate>

	@property(nonatomic, strong) ReflexView* reflexView;

	@property(nonatomic, strong) CADisplayLink* displayLink;

@end


@implementation ReflexViewController

	{
		Reflex::Window *pwindow, *ptr_for_rebind;
		int update_count;
		int touching_count;
		Reflex::Pointer::ID pointer_id;
		Reflex::PrevPointerList prev_pointers;
	}

	- (id) init
	{
		self = [super init];
		if (!self) return nil;

		pwindow        =
		ptr_for_rebind = NULL;
		update_count   = 0;
		touching_count = 0;
		pointer_id     = 0;

		return self;
	}

	- (void) dealloc
	{
		Reflex::Window* win = self.window;
		if (win) win->close(true);

		[self cleanup];
		[super dealloc];
	}

	- (void) cleanup
	{
		[self cleanupReflexView];
		[self unbind];
	}

	- (void) bind: (Reflex::Window*) window
	{
		if (!window)
			Reflex::argument_error(__FILE__, __LINE__);

		Reflex::WindowData& data = Window_get_data(window);
		if (data.view_controller)
			Reflex::invalid_state_error(__FILE__, __LINE__);

		// ruby value references view controller weakly.
		data.view_controller = self;

		// Reflex::Window is not constructed completely,
		// so can not call ClassWrapper::retain().
		window->Xot::template RefCountable<>::retain();

		// defer calling ClassWrapper::retain() to rebind.
		ptr_for_rebind = window;
	}

	- (void) rebind
	{
		if (!pwindow && ptr_for_rebind)
		{
			pwindow = ptr_for_rebind;
			pwindow->retain();

			ptr_for_rebind->Xot::template RefCountable<>::release();
			ptr_for_rebind = NULL;
		}
	}

	- (void) unbind
	{
		[self rebind];
		if (!pwindow) return;

		Window_get_data(pwindow).view_controller = nil;

		pwindow->release();
		pwindow = NULL;
	}

	- (Reflex::Window*) window
	{
		[self rebind];
		return pwindow;
	}

	- (void) didReceiveMemoryWarning
	{
		[super didReceiveMemoryWarning];

		if ([self isViewLoaded] && !self.view.window)
			[self cleanup];
	}

	- (void) viewDidLoad
	{
		[super viewDidLoad];

		[self setupReflexView];
	}

	- (ReflexView*) createReflexView
	{
		return [[[ReflexView alloc] initWithFrame: self.view.bounds] autorelease];
	}

	- (void) setupReflexView
	{
		ReflexView* view = [self createReflexView];
		if (!view)
		{
			Reflex::reflex_error(
				__FILE__, __LINE__, "failed to setup OpenGL view.");
		}

		EAGLContext* context = (EAGLContext*) Rays::get_offscreen_context();
		if (!context)
		{
			Reflex::reflex_error(
				__FILE__, __LINE__, "failed to setup OpenGL context.");
		}

		view.reflexViewController  = self;
		view.delegate              = self;
		view.context               = context;
		view.enableSetNeedsDisplay = YES;
		view.multipleTouchEnabled  = YES;
		view.drawableDepthFormat   = GLKViewDrawableDepthFormat24;
		//view.drawableMultisample   = GLKViewDrawableMultisample4X;

		[self.view addSubview: view];

		self.reflexView = view;
	}

	- (void) cleanupReflexView
	{
		ReflexView* view = self.reflexView;
		if (!view) return;

		EAGLContext* context = view.context;
		if (context && context == [EAGLContext currentContext])
			[EAGLContext setCurrentContext: (EAGLContext*) Rays::get_offscreen_context()];

		view.reflexViewController = nil;
		[view removeFromSuperview];

		self.reflexView = nil;
	}

	- (void) viewDidAppear: (BOOL) animated
	{
		[super viewDidAppear: animated];
		[self startTimer];

		Window_call_activate_event(self.window);

		[NSNotificationCenter.defaultCenter
			addObserver: self
			selector: @selector(didBecomeActive)
			name: UIApplicationDidBecomeActiveNotification
			object: nil];
		[NSNotificationCenter.defaultCenter
			addObserver: self
			selector: @selector(willResignActive)
			name: UIApplicationWillResignActiveNotification
			object: nil];
	}

	- (void) viewDidDisappear: (BOOL) animated
	{
		[NSNotificationCenter.defaultCenter
			removeObserver: self
			name: UIApplicationDidBecomeActiveNotification
			object: nil];
		[NSNotificationCenter.defaultCenter
			removeObserver: self
			name: UIApplicationWillResignActiveNotification
			object: nil];

		Window_ca__deactivate_event(self.window);

		[self stopTimer];
		[super viewDidDisappear: animated];
	}

	- (void) didBecomeActive
	{
		Window_call_activate_event(self.window);
	}

	- (void) willResignActive
	{
		Window_call_deactivate_event(self.window);
	}

	- (void)viewDidLayoutSubviews
	{
		[super viewDidLayoutSubviews];
		self.reflexView.frame = self.view.bounds;
	}

	- (void) startTimer
	{
		[self startTimer: 60];
	}

	- (void) startTimer: (int) fps
	{
		[self stopTimer];

		CADisplayLink* dl = [CADisplayLink
			displayLinkWithTarget: self
			selector:              @selector(update)];
		dl.preferredFramesPerSecond = fps;// TODO: min ver to iOS10

		[dl addToRunLoop: NSRunLoop.currentRunLoop forMode: NSRunLoopCommonModes];
		self.displayLink = dl;
	}

	- (void) stopTimer
	{
		if (!self.displayLink) return;

		[self.displayLink
			removeFromRunLoop: NSRunLoop.currentRunLoop
			forMode:           NSRunLoopCommonModes];
		self.displayLink = nil;
	}

	- (void) update
	{
		Reflex::Window* win = self.window;
		if (!win) return;

		++update_count;

		double now = Xot::time();
		Reflex::UpdateEvent e(now, now - win->self->prev_time_update);
		win->self->prev_time_update = now;

		win->on_update(&e);
		if (!e.is_blocked())
			Reflex::View_update_tree(win->root(), e);

		if (win->self->redraw)
		{
			[self.reflexView setNeedsDisplay];
			win->self->redraw = false;
		}
	}

	- (void) glkView: (GLKView*) view drawInRect: (CGRect) rect
	{
		Reflex::Window* win = self.window;
		if (!win) return;

		if (update_count == 0)
			[self update];

		EAGLContext* context = self.reflexView.context;
		if (!context) return;

		[EAGLContext setCurrentContext: context];

		double now = Xot::time();
		double dt  = now - win->self->prev_time_draw;
		double fps = 1. / dt;

		fps = win->self->prev_fps * 0.9 + fps * 0.1;// LPF

		win->self->prev_time_draw = now;
		win->self->prev_fps       = fps;

		Reflex::DrawEvent e(dt, fps);
		Window_call_draw_event(win, &e);
	}

	- (void) viewDidResize
	{
		Reflex::Window* win = self.window;
		if (!win) return;

		Rays::Bounds b           = win->frame();
		Rays::Point dpos         = b.position() - win->self->prev_position;
		Rays::Point dsize        = b.size()     - win->self->prev_size;
		win->self->prev_position = b.position();
		win->self->prev_size     = b.size();

		if (dpos != 0 || dsize != 0)
		{
			Reflex::FrameEvent e(b, dpos.x, dpos.y, dsize.x, dsize.y, 0, 0);
			if (dpos  != 0) win->on_move(&e);
			if (dsize != 0)
			{
				Rays::Bounds b = win->frame();
				b.move_to(0, 0);

				if (win->painter())
					win->painter()->canvas(b, win->painter()->pixel_density());

				if (win->root())
					View_set_frame(win->root(), b);

				win->on_resize(&e);
			}
		}
	}

	- (void) titleDidChange
	{
	}

	- (void) touchesBegan: (NSSet*) touches withEvent: (UIEvent*) event
	{
		Reflex::Window* win = self.window;
		if (!win) return;

		Reflex::NativePointerEvent e(touches, event, self.reflexView, &pointer_id);
		[self addToPrevPointers: e];

		touching_count += e.size();

		Window_call_pointer_event(win, &e);
	}

	- (void) touchesEnded: (NSSet*) touches withEvent: (UIEvent*) event
	{
		Reflex::Window* win = self.window;
		if (!win) return;

		Reflex::NativePointerEvent e(touches, event, self.reflexView, &prev_pointers);

		touching_count -= e.size();
		if (touching_count == 0)
			prev_pointers.clear();
		else if (touching_count < 0)
			Reflex::invalid_state_error(__FILE__, __LINE__);

		Window_call_pointer_event(win, &e);
	}

	- (void) touchesCancelled: (NSSet*) touches withEvent: (UIEvent*) event
	{
		[self touchesEnded: touches withEvent: event];
	}

	- (void) touchesMoved: (NSSet*) touches withEvent: (UIEvent*) event
	{
		Reflex::Window* win = self.window;
		if (!win) return;

		Reflex::NativePointerEvent e(touches, event, self.reflexView, &prev_pointers);
		[self addToPrevPointers: e];

		Window_call_pointer_event(win, &e);
	}

	- (void) addToPrevPointers: (const Reflex::PointerEvent&) event
	{
		size_t size = event.size();
		for (size_t i = 0; i < size; ++i)
		{
			prev_pointers.emplace_back(event[i]);
			Reflex::Pointer_set_prev(&prev_pointers.back(), NULL);
		}
	}

@end// ReflexViewController
