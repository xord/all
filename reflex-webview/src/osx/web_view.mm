// -*- objc -*-
#include "../web_view.h"


#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#include <reflex/web_view.h>
#include "wk_capture.h"


// SPI: keep the page rendering (visibilityState == "visible") even though
// the host window is positioned off the desktop.
@interface WKWebView (ReflexSPI)
- (void) _setWindowOcclusionDetectionEnabled: (BOOL) enabled;
@end


// Hosts the WKWebView in an invisible, off-desktop-but-ordered-in window
// and owns the bits that must outlive an async snapshot completion. All
// access is on the main thread.
@interface ReflexWKHost : NSObject <WKNavigationDelegate>
{
	@public
	NSWindow*  window;
	WKWebView* webView;
	BOOL       loadFinished;
	BOOL       snapshotPending;
	CGImageRef pendingSnapshot;
}
- (instancetype) initWithWidth: (int) w height: (int) h;
- (void) setSizeWidth: (int) w height: (int) h;
- (BOOL) consumeLoadFinished;
- (void) requestSnapshot;
- (CGImageRef) takePendingSnapshot;  // returns +1, caller releases
@end


@implementation ReflexWKHost

	- (instancetype) initWithWidth: (int) w height: (int) h
	{
		self = [super init];
		if (!self) return nil;

		NSRect rect = NSMakeRect(0, 0, w, h);
		window = [[NSWindow alloc]
			initWithContentRect: rect
			          styleMask: NSWindowStyleMaskBorderless
			            backing: NSBackingStoreBuffered
			              defer: NO];
		[window setReleasedWhenClosed: NO];

		// Keep the host window out of the user-facing window lists. It must
		// stay shareable (the default sharing type) so the capture APIs can
		// still read it, so it remains visible to screen-share pickers --
		// but it is excluded from the Window menu, window cycling, and
		// Mission Control, and is off the desktop anyway.
		[window setExcludedFromWindowsMenu: YES];
		[window setCollectionBehavior:
			NSWindowCollectionBehaviorTransient |
			NSWindowCollectionBehaviorIgnoresCycle |
			NSWindowCollectionBehaviorStationary];

		WKWebViewConfiguration* conf = [[[WKWebViewConfiguration alloc] init] autorelease];
		webView = [[WKWebView alloc] initWithFrame: rect configuration: conf];
		[webView setNavigationDelegate: self];
		[[window contentView] addSubview: webView];

		if ([webView respondsToSelector: @selector(_setWindowOcclusionDetectionEnabled:)])
			[webView _setWindowOcclusionDetectionEnabled: NO];

		// off the desktop, but ordered-in so the page keeps animating.
		[window setFrameOrigin: NSMakePoint(-10000, -10000)];
		[window orderBack: nil];

		return self;
	}

	- (void) dealloc
	{
		if (pendingSnapshot) CGImageRelease(pendingSnapshot);
		[webView setNavigationDelegate: nil];
		[webView release];
		[window release];
		[super dealloc];
	}

	- (void) setSizeWidth: (int) w height: (int) h
	{
		[window setContentSize: NSMakeSize(w, h)];
		[window setFrameOrigin: NSMakePoint(-10000, -10000)];
		[webView setFrame: NSMakeRect(0, 0, w, h)];
	}

	- (void) webView: (WKWebView*) wv
		didFinishNavigation: (WKNavigation*) nav
	{
		loadFinished = YES;
	}

	- (BOOL) consumeLoadFinished
	{
		BOOL f = loadFinished;
		loadFinished = NO;
		return f;
	}

	- (void) requestSnapshot
	{
		if (snapshotPending) return;
		snapshotPending = YES;

		[webView takeSnapshotWithConfiguration: nil
			completionHandler: ^(NSImage* image, NSError* error)
		{
			snapshotPending = NO;
			if (error || !image) return;

			CGImageRef cg = [image CGImageForProposedRect: NULL context: nil hints: nil];
			if (!cg) return;

			if (pendingSnapshot) CGImageRelease(pendingSnapshot);
			pendingSnapshot = (CGImageRef) CGImageRetain(cg);
		}];
	}

	- (CGImageRef) takePendingSnapshot
	{
		CGImageRef cg = pendingSnapshot;
		pendingSnapshot = NULL;
		return cg;
	}

@end


namespace Reflex
{


	class WKBackend : public WebViewBackend
	{

		public:

			WKBackend (WebView* owner)
			:	owner(owner), host(nil),
				method(WK_CAPTURE_NONE), probed(false), dirty(false)
			{
				int w, h;
				owner_size(&w, &h);
				host = [[ReflexWKHost alloc] initWithWidth: w height: h];
			}

			~WKBackend ()
			{
				[host release];
			}

			void load (const char* url) override
			{
				NSString* s = url ? [NSString stringWithUTF8String: url] : @"";
				NSURL* u = [NSURL URLWithString: s];
				if (u) [host->webView loadRequest: [NSURLRequest requestWithURL: u]];
			}

			void load_html (const char* html) override
			{
				NSString* s = html ? [NSString stringWithUTF8String: html] : @"";
				[host->webView loadHTMLString: s baseURL: nil];
			}

			void eval (const char* script) override
			{
				NSString* s = script ? [NSString stringWithUTF8String: script] : @"";
				[host->webView evaluateJavaScript: s completionHandler: nil];
			}

			void reload () override
			{
				[host->webView reload];
			}

			Xot::String url () const override
			{
				NSURL* u = [host->webView URL];
				return u ? Xot::String([[u absoluteString] UTF8String]) : Xot::String("");
			}

			void set_size (int w, int h, float pixel_density) override
			{
				if (w <= 0 || h <= 0) return;
				[host setSizeWidth: w height: h];
			}

			bool update () override
			{
				if (!host) return false;

				if ([host consumeLoadFinished] && owner)
				{
					Event e;
					owner->on_load(&e);
				}

				uint32_t win = (uint32_t) [host->window windowNumber];

				if (!probed)
				{
					method = WKCapture_probe(win);
					probed = true;
				}

				CGImageRef image = NULL;
				if (method != WK_CAPTURE_NONE)
					image = WKCapture_grab(method, win);

				if (!image)
				{
					// no usable sync method (or it failed this frame):
					// fall back to the public async snapshot.
					[host requestSnapshot];
					image = [host takePendingSnapshot];
				}

				if (image)
				{
					blit_to_image(image);
					CGImageRelease(image);
					dirty = true;
				}

				bool d = dirty;
				dirty = false;
				return d;
			}

			const Rays::Image* image () const override
			{
				return image_ ? &image_ : NULL;
			}

			void pointer (PointerEvent* e) override {}

			void wheel (WheelEvent* e) override {}

			void key (KeyEvent* e) override {}

			void focus (bool in) override {}

		private:

			WebView*        owner;
			ReflexWKHost*   host;
			Rays::Image     image_;
			WKCaptureMethod method;
			bool            probed;
			bool            dirty;

			void owner_size (int* w, int* h)
			{
				const Bounds& f = owner->frame();
				*w = (int) f.w > 0 ? (int) f.w : 1;
				*h = (int) f.h > 0 ? (int) f.h : 1;
			}

			void blit_to_image (CGImageRef src)
			{
				int w = (int) CGImageGetWidth(src);
				int h = (int) CGImageGetHeight(src);
				if (w <= 0 || h <= 0) return;

				if (!image_ || image_.width() != w || image_.height() != h)
					image_ = Rays::Image(w, h, Rays::RGBA);

				WKCapture_blit(src, &image_.bitmap(true));
			}

	};// WKBackend


	WebViewBackend*
	WebViewBackend_create (WebView* owner)
	{
		return new WKBackend(owner);
	}


}// Reflex
