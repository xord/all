// -*- objc -*-
#include "wk_capture.h"


#include <dlfcn.h>


namespace Reflex
{


	// --- private/obsoleted symbol bindings ----------------------------

	typedef int      CGSConnectionID;
	typedef uint32_t CGSWindowID;
	typedef uint32_t CGSWindowCaptureOptions;

	enum
	{
		kCGSNominalResolution = 1 << 9,
		kCGSIgnoreClipShape   = 1 << 11,
	};

	// CGWindowListCreateImage options (stable values, header obsoleted).
	enum
	{
		kListOptionIncludingWindow = 1 << 3,
		kImageBoundsIgnoreFraming  = 1 << 0,
		kImageNominalResolution    = 1 << 4,
	};

	typedef CGSConnectionID (*MainConnectionFun) (void);
	typedef CFArrayRef      (*HWCaptureFun) (
		CGSConnectionID, const CGSWindowID*, int, CGSWindowCaptureOptions);
	typedef CGImageRef      (*WindowImageFun) (
		CGRect, uint32_t, uint32_t, uint32_t);

	static MainConnectionFun main_connection = NULL;
	static HWCaptureFun       hw_capture      = NULL;
	static WindowImageFun     window_image    = NULL;
	static bool               initialized     = false;


	void
	WKCapture_init ()
	{
		if (initialized) return;
		initialized = true;

		dlopen(
			"/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight",
			RTLD_LAZY);

		main_connection =
			(MainConnectionFun) dlsym(RTLD_DEFAULT, "CGSMainConnectionID");
		hw_capture =
			(HWCaptureFun)      dlsym(RTLD_DEFAULT, "CGSHWCaptureWindowList");
		window_image =
			(WindowImageFun)    dlsym(RTLD_DEFAULT, "CGWindowListCreateImage");
	}

	bool
	WKCapture_available (WKCaptureMethod method)
	{
		WKCapture_init();
		switch (method)
		{
			case WK_CAPTURE_CGS:     return main_connection && hw_capture;
			case WK_CAPTURE_CGWINDOW: return window_image != NULL;
			default:                 return false;
		}
	}

	// --- capture ------------------------------------------------------

	static CGImageRef
	grab_cgs (uint32_t window_number)
	{
		if (!main_connection || !hw_capture) return NULL;

		CGSWindowID wid = window_number;
		CFArrayRef arr  = hw_capture(
			main_connection(), &wid, 1,
			kCGSNominalResolution | kCGSIgnoreClipShape);
		if (!arr) return NULL;

		CGImageRef image = NULL;
		if (CFArrayGetCount(arr) > 0)
		{
			CFTypeRef el = CFArrayGetValueAtIndex(arr, 0);
			// On macOS 15 this array holds CGImages. Older systems may
			// return IOSurfaces; those are not handled here (the probe
			// will reject this method and fall through to CGWINDOW).
			if (CFGetTypeID(el) == CGImageGetTypeID())
				image = (CGImageRef) CFRetain(el);
		}
		CFRelease(arr);
		return image;
	}

	static CGImageRef
	grab_cgwindow (uint32_t window_number)
	{
		if (!window_image) return NULL;
		return window_image(
			CGRectNull, kListOptionIncludingWindow, window_number,
			kImageBoundsIgnoreFraming | kImageNominalResolution);
	}

	CGImageRef
	WKCapture_grab (WKCaptureMethod method, uint32_t window_number)
	{
		WKCapture_init();
		switch (method)
		{
			case WK_CAPTURE_CGS:      return grab_cgs(window_number);
			case WK_CAPTURE_CGWINDOW: return grab_cgwindow(window_number);
			default:                  return NULL;
		}
	}

	// --- probe --------------------------------------------------------

	// Cheap sample of the image to reject NULL or single-colour (blank)
	// captures. Returns true if the image looks like real content.
	static bool
	looks_usable (CGImageRef image)
	{
		if (!image) return false;

		size_t w = CGImageGetWidth(image), h = CGImageGetHeight(image);
		if (w == 0 || h == 0) return false;

		// Render a tiny version and check the pixels are not all equal.
		const int N = 8;
		uint32_t buf[N * N];
		memset(buf, 0, sizeof(buf));

		CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
		CGContextRef ctx = CGBitmapContextCreate(
			buf, N, N, 8, N * 4, cs,
			kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
		CGColorSpaceRelease(cs);
		if (!ctx) return false;

		CGContextDrawImage(ctx, CGRectMake(0, 0, N, N), image);
		CGContextRelease(ctx);

		uint32_t first = buf[0];
		for (int i = 1; i < N * N; ++i)
			if (buf[i] != first) return true;
		return false;
	}

	WKCaptureMethod
	WKCapture_probe (uint32_t window_number)
	{
		WKCapture_init();

		const WKCaptureMethod order[] = {WK_CAPTURE_CGS, WK_CAPTURE_CGWINDOW};
		for (WKCaptureMethod method : order)
		{
			if (!WKCapture_available(method)) continue;

			CGImageRef image = WKCapture_grab(method, window_number);
			bool ok = looks_usable(image);
			if (image) CGImageRelease(image);
			if (ok) return method;
		}
		return WK_CAPTURE_NONE;
	}

	// --- blit ---------------------------------------------------------

	void
	WKCapture_blit (CGImageRef image, Rays::Bitmap* bitmap)
	{
		if (!image || !bitmap || !*bitmap) return;

		int w = bitmap->width(), h = bitmap->height();
		void* pixels = bitmap->pixels();
		if (!pixels || w <= 0 || h <= 0) return;

		// RGBA8888 (R,G,B,A byte order) == premultiplied-last + big-endian.
		// Rays uploads RGBA as GL_RGBA; BGRA is rejected as a GL internal
		// format, so we normalise to RGBA here.
		CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
		CGContextRef ctx = CGBitmapContextCreate(
			pixels, w, h, 8, bitmap->pitch(), cs,
			kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
		CGColorSpaceRelease(cs);
		if (!ctx) return;

		// Captured images are already top-left oriented and drawing them
		// into the bitmap context lands row 0 at the top, matching how
		// Rays::Bitmap reads its pixels (verified for the CGWINDOW path).
		CGContextSetBlendMode(ctx, kCGBlendModeCopy);
		CGContextDrawImage(ctx, CGRectMake(0, 0, w, h), image);
		CGContextRelease(ctx);
	}


}// Reflex
