// -*- objc -*-
#include "../web_view.h"


#include <string.h>
#include <map>
#include <string>
#include <vector>
#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#include <reflex/web_view.h>
#include <reflex/pointer.h>
#include "wk_capture.h"


namespace
{

	// Page-load notifications queued by the navigation delegate and
	// drained on the next update() so Ruby handlers run inside the
	// normal event cycle.
	struct LoadItem
	{

		enum Type {START, FINISH, FAIL};

		Type type;

		std::string url, description;

		long code;

		LoadItem (
			Type type, const char* url,
			long code = 0, const char* description = NULL)
		:	type(type), url(url ? url : ""),
			description(description ? description : ""), code(code)
		{
		}

	};// LoadItem

}// namespace


namespace
{

	NSUInteger
	to_ns_modifiers (unsigned mods)
	{
		using namespace Reflex;
		NSUInteger f = 0;
		if (mods & MOD_SHIFT)    f |= NSEventModifierFlagShift;
		if (mods & MOD_CONTROL)  f |= NSEventModifierFlagControl;
		if (mods & MOD_OPTION)   f |= NSEventModifierFlagOption;
		if (mods & MOD_COMMAND)  f |= NSEventModifierFlagCommand;
		if (mods & MOD_CAPS)     f |= NSEventModifierFlagCapsLock;
		if (mods & MOD_FUNCTION) f |= NSEventModifierFlagFunction;
		return f;
	}

	// Left/right modifier keys, caps lock, and fn. AppKit reports these
	// via flagsChanged:, never keyDown:/keyUp:. Forwarding them as
	// keyDown would make WebKit re-dispatch the (characterless) event to
	// the menu's key-equivalent matching, where it hits the first item
	// with an empty key equivalent -- the About panel.
	bool
	is_modifier_key (unsigned short code)
	{
		switch (code)
		{
			case 54: case 55: case 56: case 57: case 58:
			case 59: case 60: case 61: case 62: case 63:
				return true;
			default:
				return false;
		}
	}

	void
	dispatch_mouse (WKWebView* wv, NSEvent* e)
	{
		switch (e.type)
		{
			case NSEventTypeLeftMouseDown:     [wv mouseDown:        e]; break;
			case NSEventTypeLeftMouseUp:       [wv mouseUp:          e]; break;
			case NSEventTypeLeftMouseDragged:  [wv mouseDragged:     e]; break;
			case NSEventTypeRightMouseDown:    [wv rightMouseDown:   e]; break;
			case NSEventTypeRightMouseUp:      [wv rightMouseUp:     e]; break;
			case NSEventTypeRightMouseDragged: [wv rightMouseDragged:e]; break;
			case NSEventTypeOtherMouseDown:    [wv otherMouseDown:   e]; break;
			case NSEventTypeOtherMouseUp:      [wv otherMouseUp:     e]; break;
			case NSEventTypeOtherMouseDragged: [wv otherMouseDragged:e]; break;
			case NSEventTypeMouseMoved:        [wv mouseMoved:       e]; break;
			default: break;
		}
	}

}// namespace


// SPI: keep the page rendering (visibilityState == "visible") even though
// the host window is positioned off the desktop.
@interface WKWebView (ReflexSPI)
- (void) _setWindowOcclusionDetectionEnabled: (BOOL) enabled;
@end


// WebKit only draws the caret and active selection while its window is
// key, but the off-desktop host window must never actually take key
// status away from the user-facing Reflex window. Instead, report key
// status as a flag the backend toggles on Reflex focus changes; posting
// the matching NSWindow key notifications makes WebKit re-evaluate its
// activity state.
@interface ReflexWKHostWindow : NSWindow
{
	@public
	BOOL fakeKey;
}
@end

@implementation ReflexWKHostWindow

	// Note: canBecomeKeyWindow stays NO (the borderless default). If this
	// window could really take key status -- e.g. while the intercepted
	// context menu runs -- every key event including Cmd+Q would route to
	// the WKWebView and get swallowed there.

	- (BOOL) isKeyWindow
	{
		return fakeKey ? YES : [super isKeyWindow];
	}

@end


@class ReflexWKHost;

// WKUserContentController retains its script message handlers, which
// would create a retain cycle if the host registered itself. This proxy
// holds the host unretained and is detached when the backend goes away.
@interface ReflexWKMessageProxy : NSObject <WKScriptMessageHandler>
{
	@public
	ReflexWKHost* host;  // assigned
}
@end


// Hosts the WKWebView in an invisible, off-desktop-but-ordered-in window
// and owns the bits that must outlive an async snapshot completion. All
// access is on the main thread.
@interface ReflexWKHost : NSObject <WKNavigationDelegate, WKUIDelegate>
{
	@public
	ReflexWKHostWindow* window;
	WKWebView* webView;
	BOOL       snapshotPending;
	CGImageRef pendingSnapshot;
	std::vector<LoadItem> loadQueue;
	std::vector<std::string> openQueue;
	std::vector<std::string> messageQueue;
	std::vector<std::pair<long, std::string>> evalResults;
	ReflexWKMessageProxy* messageProxy;
	Reflex::WebView* owner;  // assigned; cleared by ~WKBackend
}
- (void) didReceiveMessage: (NSString*) json;
- (instancetype) initWithWidth: (int) w height: (int) h;
- (void) setSizeWidth: (int) w height: (int) h;
- (void) requestSnapshot;
- (CGImageRef) takePendingSnapshot;  // returns +1, caller releases
@end


@implementation ReflexWKMessageProxy

	- (void) userContentController: (WKUserContentController*) controller
		didReceiveScriptMessage: (WKScriptMessage*) message
	{
		if (!host) return;
		if (![message.body isKindOfClass: [NSString class]]) return;
		[host didReceiveMessage: (NSString*) message.body];
	}

@end


// Injected into every page at document start. postMessage() funnels
// into the script message handler as a JSON string; onmessage is the
// page-side hook for messages from the app.
static NSString* const REFLEX_BRIDGE_SCRIPT =
	@"window.__REFLEX__ = {"
	@"  postMessage: function (data) {"
	@"    window.webkit.messageHandlers.reflex.postMessage("
	@"      JSON.stringify(data === undefined ? null : data));"
	@"  },"
	@"  onmessage: null"
	@"};";


@implementation ReflexWKHost

	- (instancetype) initWithWidth: (int) w height: (int) h
	{
		self = [super init];
		if (!self) return nil;

		NSRect rect = NSMakeRect(0, 0, w, h);
		window = [[ReflexWKHostWindow alloc]
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

		messageProxy = [[ReflexWKMessageProxy alloc] init];
		messageProxy->host = self;
		WKUserScript* bridge = [[[WKUserScript alloc]
			initWithSource: REFLEX_BRIDGE_SCRIPT
			 injectionTime: WKUserScriptInjectionTimeAtDocumentStart
			forMainFrameOnly: YES] autorelease];
		[[conf userContentController] addUserScript: bridge];
		[[conf userContentController]
			addScriptMessageHandler: messageProxy name: @"reflex"];

		webView = [[WKWebView alloc] initWithFrame: rect configuration: conf];
		[webView setNavigationDelegate: self];
		[webView setUIDelegate: self];
		[[window contentView] addSubview: webView];

		if ([webView respondsToSelector: @selector(_setWindowOcclusionDetectionEnabled:)])
			[webView _setWindowOcclusionDetectionEnabled: NO];

		// off the desktop, but ordered-in so the page keeps animating.
		[window setFrameOrigin: NSMakePoint(-10000, -10000)];
		[window orderBack: nil];

		// An ordered-in window keeps the app alive after the user closes
		// the last real window; watch for that and bow out.
		[[NSNotificationCenter defaultCenter]
			addObserver: self
			   selector: @selector(otherWindowWillClose:)
			       name: NSWindowWillCloseNotification
			     object: nil];

		return self;
	}

	- (void) otherWindowWillClose: (NSNotification*) notification
	{
		NSWindow* closing = (NSWindow*) [notification object];
		if (closing == window) return;

		for (NSWindow* w in [NSApp windows])
		{
			if (w == closing || w == window) continue;
			if ([w isVisible] && ![w isKindOfClass: [ReflexWKHostWindow class]])
				return;// a user-facing window remains
		}
		[window orderOut: nil];
	}

	- (void) dealloc
	{
		[[NSNotificationCenter defaultCenter] removeObserver: self];
		if (pendingSnapshot) CGImageRelease(pendingSnapshot);
		messageProxy->host = nil;
		[[[webView configuration] userContentController]
			removeScriptMessageHandlerForName: @"reflex"];
		[messageProxy release];
		[webView setNavigationDelegate: nil];
		[webView setUIDelegate: nil];
		[webView release];
		[window release];
		[super dealloc];
	}

	- (void) didReceiveMessage: (NSString*) json
	{
		messageQueue.emplace_back([json UTF8String]);
	}

	- (void) setSizeWidth: (int) w height: (int) h
	{
		[window setContentSize: NSMakeSize(w, h)];
		[window setFrameOrigin: NSMakePoint(-10000, -10000)];
		[webView setFrame: NSMakeRect(0, 0, w, h)];
	}

	- (const char*) currentURL
	{
		NSString* u = [[webView URL] absoluteString];
		return u ? [u UTF8String] : "";
	}

	- (void) webView: (WKWebView*) wv
		didStartProvisionalNavigation: (WKNavigation*) nav
	{
		loadQueue.emplace_back(LoadItem::START, [self currentURL]);
	}

	- (void) webView: (WKWebView*) wv
		didFinishNavigation: (WKNavigation*) nav
	{
		loadQueue.emplace_back(LoadItem::FINISH, [self currentURL]);
	}

	- (void) queueLoadFail: (NSError*) error
	{
		// stop() and superseding navigations cancel the current load;
		// browsers do not surface that as a page error.
		if (error.code == NSURLErrorCancelled) return;

		loadQueue.emplace_back(
			LoadItem::FAIL, [self currentURL],
			(long) error.code,
			error.localizedDescription.UTF8String);
	}

	- (void) webView: (WKWebView*) wv
		didFailProvisionalNavigation: (WKNavigation*) nav
		withError: (NSError*) error
	{
		[self queueLoadFail: error];
	}

	- (void) webView: (WKWebView*) wv
		didFailNavigation: (WKNavigation*) nav
		withError: (NSError*) error
	{
		[self queueLoadFail: error];
	}

	// Synchronous by design: the policy decision needs the handler's
	// verdict. Only main-frame navigations are offered to the app;
	// subframes always load.
	- (void) webView: (WKWebView*) wv
		decidePolicyForNavigationAction: (WKNavigationAction*) action
		decisionHandler: (void (^)(WKNavigationActionPolicy)) decisionHandler
	{
		BOOL allow = YES;
		if (owner && action.targetFrame && action.targetFrame.isMainFrame)
		{
			NSString* u = [[[action request] URL] absoluteString];
			Reflex::WebView::NavigateEvent e(u ? [u UTF8String] : "");
			owner->on_navigate(&e);
			allow = !e.is_blocked();
		}
		decisionHandler(
			allow ? WKNavigationActionPolicyAllow : WKNavigationActionPolicyCancel);
	}

	// JavaScript dialogs would otherwise try to present inside the
	// off-desktop host window where nobody can see (or dismiss) them,
	// silently breaking alert/confirm/prompt. Present app-modal
	// NSAlerts instead, titled by the requesting page's host like a
	// browser would.

	- (NSAlert*) dialogWithMessage: (NSString*) message
		frame: (WKFrameInfo*) frame
	{
		NSString* host = frame.request.URL.host;
		NSAlert* alert = [[[NSAlert alloc] init] autorelease];
		alert.messageText     = host && host.length > 0 ? host : @"JavaScript";
		alert.informativeText = message ? message : @"";
		return alert;
	}

	- (void) webView: (WKWebView*) wv
		runJavaScriptAlertPanelWithMessage: (NSString*) message
		initiatedByFrame: (WKFrameInfo*) frame
		completionHandler: (void (^)(void)) completionHandler
	{
		NSAlert* alert = [self dialogWithMessage: message frame: frame];
		[alert addButtonWithTitle: @"OK"];
		[alert runModal];
		completionHandler();
	}

	- (void) webView: (WKWebView*) wv
		runJavaScriptConfirmPanelWithMessage: (NSString*) message
		initiatedByFrame: (WKFrameInfo*) frame
		completionHandler: (void (^)(BOOL)) completionHandler
	{
		NSAlert* alert = [self dialogWithMessage: message frame: frame];
		[alert addButtonWithTitle: @"OK"];
		[alert addButtonWithTitle: @"Cancel"];
		completionHandler([alert runModal] == NSAlertFirstButtonReturn);
	}

	- (void) webView: (WKWebView*) wv
		runJavaScriptTextInputPanelWithPrompt: (NSString*) prompt
		defaultText: (NSString*) defaultText
		initiatedByFrame: (WKFrameInfo*) frame
		completionHandler: (void (^)(NSString*)) completionHandler
	{
		NSAlert* alert = [self dialogWithMessage: prompt frame: frame];
		[alert addButtonWithTitle: @"OK"];
		[alert addButtonWithTitle: @"Cancel"];

		NSTextField* input = [[[NSTextField alloc]
			initWithFrame: NSMakeRect(0, 0, 260, 24)] autorelease];
		[input setStringValue: defaultText ? defaultText : @""];
		[alert setAccessoryView: input];
		[[alert window] setInitialFirstResponder: input];

		if ([alert runModal] == NSAlertFirstButtonReturn)
			completionHandler([input stringValue]);
		else
			completionHandler(nil);
	}

	// window.open / target=_blank. Never creates a real web view;
	// queues the request for WebView::on_open, whose default opens the
	// URL in the same view.
	- (WKWebView*) webView: (WKWebView*) wv
		createWebViewWithConfiguration: (WKWebViewConfiguration*) conf
		forNavigationAction: (WKNavigationAction*) action
		windowFeatures: (WKWindowFeatures*) features
	{
		NSString* u = [[[action request] URL] absoluteString];
		if (u) openQueue.emplace_back([u UTF8String]);
		return nil;
	}

	// SPI (WKUIDelegatePrivate): intercept the context menu WebKit is
	// about to open. Its own popup would appear inside the off-desktop
	// host window where nobody can see it, so suppress that and pop the
	// proposed menu (whose items still target WebKit's internals) at the
	// real cursor position instead.
	- (void) _webView: (WKWebView*) wv
		getContextMenuFromProposedMenu: (NSMenu*) menu
		forElement: (id) element
		userInfo: (id) userInfo
		completionHandler: (void (^)(NSMenu*)) completionHandler
	{
		completionHandler(nil);
		if (!menu || menu.numberOfItems == 0) return;

		dispatch_async(dispatch_get_main_queue(), ^{
			[menu popUpMenuPositioningItem: nil
				atLocation: [NSEvent mouseLocation]
				inView: nil];
		});
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
				host->owner = owner;
			}

			~WKBackend ()
			{
				host->owner = NULL;
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

			void eval (
				const char* script, WebView::EvalCallback callback) override
			{
				if (!callback) return eval(script);

				long eid = ++last_eval_id_;
				eval_callbacks_[eid] = callback;

				// the result lands in the host queue and the callback runs
				// on the next update(), inside the normal event cycle. an
				// empty string marks failure (script error or a value JSON
				// cannot express).
				ReflexWKHost* h = host;
				NSString* s = script ? [NSString stringWithUTF8String: script] : @"";
				[host->webView evaluateJavaScript: s
					completionHandler: ^(id result, NSError* error)
				{
					std::string json;
					if (!error)
					{
						// NSJSONSerialization rejects top-level scalars;
						// wrap the value in an array.
						NSArray* wrapped = @[result ? result : [NSNull null]];
						if ([NSJSONSerialization isValidJSONObject: wrapped])
						{
							NSData* data = [NSJSONSerialization
								dataWithJSONObject: wrapped options: 0 error: NULL];
							if (data)
								json.assign((const char*) data.bytes, data.length);
						}
					}
					h->evalResults.emplace_back(eid, json);
				}];
			}

			void reload () override
			{
				[host->webView reload];
			}

			void reload (bool ignore_cache) override
			{
				if (ignore_cache) [host->webView reloadFromOrigin];
				else              [host->webView reload];
			}

			void go_back () override
			{
				[host->webView goBack];
			}

			void go_forward () override
			{
				[host->webView goForward];
			}

			void stop () override
			{
				[host->webView stopLoading];
			}

			bool can_go_back () const override
			{
				return [host->webView canGoBack];
			}

			bool can_go_forward () const override
			{
				return [host->webView canGoForward];
			}

			bool loading () const override
			{
				return [host->webView isLoading];
			}

			float progress () const override
			{
				return (float) [host->webView estimatedProgress];
			}

			Xot::String url () const override
			{
				NSURL* u = [host->webView URL];
				return u ? Xot::String([[u absoluteString] UTF8String]) : Xot::String("");
			}

			Xot::String title () const override
			{
				NSString* t = [host->webView title];
				return t ? Xot::String([t UTF8String]) : Xot::String("");
			}

			void set_user_agent (const char* user_agent) override
			{
				host->webView.customUserAgent = user_agent ?
					[NSString stringWithUTF8String: user_agent] : nil;
			}

			Xot::String user_agent () const override
			{
				NSString* ua = host->webView.customUserAgent;
				return ua ? Xot::String([ua UTF8String]) : Xot::String("");
			}

			void set_zoom (float zoom) override
			{
				host->webView.pageZoom = zoom;
			}

			float zoom () const override
			{
				return (float) host->webView.pageZoom;
			}

			void set_inspectable (bool inspectable) override
			{
				if ([host->webView respondsToSelector: @selector(setInspectable:)])
					host->webView.inspectable = inspectable;
			}

			bool inspectable () const override
			{
				if ([host->webView respondsToSelector: @selector(isInspectable)])
					return host->webView.inspectable;
				return false;
			}

			void set_size (int w, int h, float pixel_density) override
			{
				if (w <= 0 || h <= 0) return;
				[host setSizeWidth: w height: h];
			}

			bool update () override
			{
				if (!host) return false;

				pump_events();

				uint32_t win = (uint32_t) [host->window windowNumber];

				if (!probed)
				{
					// REFLEX_WEBVIEW_CAPTURE=cgs|cgwindow|snapshot skips the
					// probe; "snapshot" forces the async fallback path.
					const char* force = getenv("REFLEX_WEBVIEW_CAPTURE");
					if      (force && strcmp(force, "cgs")      == 0)
						method = WK_CAPTURE_CGS;
					else if (force && strcmp(force, "cgwindow") == 0)
						method = WK_CAPTURE_CGWINDOW;
					else if (force && strcmp(force, "snapshot") == 0)
						method = WK_CAPTURE_NONE;
					else
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
					if (blit_to_image(image)) dirty = true;
					CGImageRelease(image);
				}

				bool d = dirty;
				dirty = false;
				return d;
			}

			const Rays::Image* image () const override
			{
				return image_ ? &image_ : NULL;
			}

			void pointer (PointerEvent* e) override
			{
				if (!host || !e) return;

				WKWebView* wv = host->webView;
				CGFloat    vh = wv.frame.size.height;
				NSInteger  wn = [host->window windowNumber];

				for (size_t i = 0; i < e->size(); ++i)
				{
					const Pointer& p   = (*e)[i];
					const Point&   pos = p.position();
					// Reflex is top-left; AppKit window coords are bottom-left.
					NSPoint loc  = NSMakePoint(pos.x, vh - pos.y);
					NSUInteger m = to_ns_modifiers(p.modifiers());

					Pointer::Action a = p.action();
					bool down = a == Pointer::DOWN;
					bool up   = a == Pointer::UP;
					bool drag = a == Pointer::MOVE && p.is_drag();

					uint t = p.types();
					NSEventType type;
					if (t & Pointer::MOUSE_RIGHT)
					{
						type = down ? NSEventTypeRightMouseDown :
						       up   ? NSEventTypeRightMouseUp   :
						              NSEventTypeRightMouseDragged;
					}
					else if (t & Pointer::MOUSE_MIDDLE)
					{
						type = down ? NSEventTypeOtherMouseDown :
						       up   ? NSEventTypeOtherMouseUp   :
						              NSEventTypeOtherMouseDragged;
					}
					else
					{
						type = down ? NSEventTypeLeftMouseDown :
						       up   ? NSEventTypeLeftMouseUp   :
						              NSEventTypeLeftMouseDragged;
					}
					if (a == Pointer::MOVE && !drag)
						type = NSEventTypeMouseMoved;

					NSInteger clicks = (down || up) ?
						(NSInteger) (p.click_count() > 0 ? p.click_count() : 1) : 0;
					CGFloat pressure = (down || drag) ? 1.0 : 0.0;

					NSEvent* ev = [NSEvent
						mouseEventWithType: type
						          location: loc
						     modifierFlags: m
						         timestamp: NSProcessInfo.processInfo.systemUptime
						      windowNumber: wn
						           context: nil
						       eventNumber: 0
						        clickCount: clicks
						          pressure: pressure];
					if (ev) dispatch_mouse(wv, ev);
				}
			}

			void wheel (WheelEvent* e) override
			{
				if (!host || !e) return;

				CGEventRef cg = CGEventCreateScrollWheelEvent(
					NULL, kCGScrollEventUnitLine, 2, 0, 0);
				if (!cg) return;

				// NativeWheelEvent stores dy as -deltaY; mirror that back.
				// Use the fixed-point fields: trackpads emit fractional
				// line deltas that would truncate to zero as integers.
				const Point& d = e->dposition();
				CGEventSetDoubleValueField(
					cg, kCGScrollWheelEventFixedPtDeltaAxis1, -d.y);
				CGEventSetDoubleValueField(
					cg, kCGScrollWheelEventFixedPtDeltaAxis2, d.x);

				// The event has no window, so -locationInWindow yields the
				// CG location flipped against the primary screen -- and
				// WebKit feeds that straight to convertPoint:fromView:nil
				// as window coordinates. Pre-bake the window-local point so
				// it comes out right after that flip.
				WKWebView*   wv  = host->webView;
				const Point& pos = e->position();
				NSPoint local = NSMakePoint(pos.x, wv.frame.size.height - pos.y);
				CGFloat sh = NSScreen.screens.firstObject.frame.size.height;
				CGEventSetLocation(cg, CGPointMake(local.x, sh - local.y));

				NSEvent* ev = [NSEvent eventWithCGEvent: cg];
				CFRelease(cg);
				if (ev) [wv scrollWheel: ev];
			}

			void key (KeyEvent* e) override
			{
				if (!host || !e) return;

				NSEventType type;
				switch (e->action())
				{
					case KeyEvent::DOWN: type = NSEventTypeKeyDown; break;
					case KeyEvent::UP:   type = NSEventTypeKeyUp;   break;
					default: return;
				}

				unsigned short code = (unsigned short) e->code();

				// When the page has no editable focus, WebKit re-dispatches
				// unhandled keyDowns through [NSApp sendEvent:]; they land
				// back in the (key) Reflex window and would loop through
				// this forwarding forever. A non-repeat keyDown for a code
				// already down can only be such a re-dispatch -- drop it.
				if (code < 128)
				{
					if (e->action() == KeyEvent::DOWN)
					{
						if (key_down_sent_[code] && e->repeat() == 0) return;
						key_down_sent_[code] = true;
					}
					else
						key_down_sent_[code] = false;
				}

				if (is_modifier_key(code))
				{
					NSEvent* ev = [NSEvent
						keyEventWithType: NSEventTypeFlagsChanged
						        location: NSZeroPoint
						   modifierFlags: to_ns_modifiers(e->modifiers())
						       timestamp: NSProcessInfo.processInfo.systemUptime
						    windowNumber: [host->window windowNumber]
						         context: nil
						      characters: @""
						charactersIgnoringModifiers: @""
						       isARepeat: NO
						         keyCode: code];
					if (ev) [host->webView flagsChanged: ev];
					return;
				}

				NSString* chars = e->chars() ?
					[NSString stringWithUTF8String: e->chars()] : @"";

				NSEvent* ev = [NSEvent
					keyEventWithType: type
					        location: NSZeroPoint
					   modifierFlags: to_ns_modifiers(e->modifiers())
					       timestamp: NSProcessInfo.processInfo.systemUptime
					    windowNumber: [host->window windowNumber]
					         context: nil
					      characters: chars
					charactersIgnoringModifiers: chars
					       isARepeat: (e->repeat() > 0)
					         keyCode: code];
				if (!ev) return;

				if (type == NSEventTypeKeyDown) [host->webView keyDown: ev];
				else                            [host->webView keyUp:   ev];
			}

			void focus (bool in) override
			{
				if (!host) return;

				ReflexWKHostWindow* w = host->window;
				NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
				if (in)
				{
					[w makeFirstResponder: host->webView];
					w->fakeKey = YES;
					[nc postNotificationName: NSWindowDidBecomeKeyNotification
					                  object: w];
				}
				else
				{
					w->fakeKey = NO;
					[nc postNotificationName: NSWindowDidResignKeyNotification
					                  object: w];
					[w makeFirstResponder: nil];
				}
			}

		private:

			WebView*        owner;
			ReflexWKHost*   host;
			Rays::Image     image_;
			Rays::Bitmap    scratch_;
			WKCaptureMethod method;
			bool            probed;
			bool            dirty;
			bool            key_down_sent_[128] = {false};
			Xot::String     last_title_, last_url_;
			long            last_eval_id_ = 0;
			std::map<long, WebView::EvalCallback> eval_callbacks_;

			// Drains queued page-load notifications and polls title/URL
			// for changes; handlers run here, inside the update cycle.
			void pump_events ()
			{
				if (!owner) return;

				if (!host->loadQueue.empty())
				{
					std::vector<LoadItem> queue;
					queue.swap(host->loadQueue);
					for (const auto& item : queue)
					{
						WebView::LoadEvent e(
							item.url.c_str(), (int) item.code,
							item.description.c_str());
						switch (item.type)
						{
							case LoadItem::START:  owner->on_load_start(&e); break;
							case LoadItem::FINISH: owner->on_load(&e);       break;
							case LoadItem::FAIL:   owner->on_load_fail(&e);  break;
						}
					}
				}

				if (!host->evalResults.empty())
				{
					std::vector<std::pair<long, std::string>> results;
					results.swap(host->evalResults);
					for (const auto& [eid, json] : results)
					{
						auto it = eval_callbacks_.find(eid);
						if (it == eval_callbacks_.end()) continue;

						WebView::EvalCallback callback = it->second;
						eval_callbacks_.erase(it);
						callback(json.empty() ? NULL : json.c_str());
					}
				}

				if (!host->messageQueue.empty())
				{
					std::vector<std::string> queue;
					queue.swap(host->messageQueue);
					for (const auto& json : queue)
					{
						WebView::MessageEvent e(json.c_str());
						owner->on_message(&e);
					}
				}

				if (!host->openQueue.empty())
				{
					std::vector<std::string> queue;
					queue.swap(host->openQueue);
					for (const auto& url : queue)
					{
						WebView::NavigateEvent e(url.c_str());
						owner->on_open(&e);
					}
				}

				Xot::String t = title();
				if (t != last_title_)
				{
					last_title_ = t;
					Event e;
					owner->on_title_change(&e);
				}

				Xot::String u = url();
				if (u != last_url_)
				{
					last_url_ = u;
					Event e;
					owner->on_url_change(&e);
				}
			}

			void owner_size (int* w, int* h)
			{
				const Bounds& f = owner->frame();
				*w = (int) f.w > 0 ? (int) f.w : 1;
				*h = (int) f.h > 0 ? (int) f.h : 1;
			}

			// Returns whether the page pixels actually changed. Grabbing
			// runs every frame (cheap); decoding into the scratch bitmap
			// and comparing here keeps the texture upload and redraw --
			// the expensive part -- for frames that really differ.
			bool blit_to_image (CGImageRef src)
			{
				int w = (int) CGImageGetWidth(src);
				int h = (int) CGImageGetHeight(src);
				if (w <= 0 || h <= 0) return false;

				if (!scratch_ || scratch_.width() != w || scratch_.height() != h)
					scratch_ = Rays::Bitmap(w, h, Rays::RGBA);

				WKCapture_blit(src, &scratch_);

				bool same_size =
					image_ && image_.width() == w && image_.height() == h;
				if (same_size)
				{
					const Rays::Bitmap& bmp = image_.bitmap();
					if (
						bmp.pitch() == scratch_.pitch() &&
						memcmp(
							bmp.pixels(), scratch_.pixels(),
							(size_t) scratch_.pitch() * h) == 0)
					{
						return false;
					}
				}
				else
					image_ = Rays::Image(w, h, Rays::RGBA);

				Rays::Bitmap& dst = image_.bitmap(true);
				int rowbytes      = dst.pitch() < scratch_.pitch() ?
					dst.pitch() : scratch_.pitch();
				for (int y = 0; y < h; ++y)
				{
					memcpy(
						dst.at<void>(0, y), scratch_.at<void>(0, y),
						(size_t) rowbytes);
				}
				return true;
			}

	};// WKBackend


	WebViewBackend*
	WebViewBackend_create (WebView* owner)
	{
		return new WKBackend(owner);
	}


}// Reflex
