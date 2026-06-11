// -*- objc -*-
#pragma once
#ifndef __REFLEX_WEBVIEW_OSX_WK_CAPTURE_H__
#define __REFLEX_WEBVIEW_OSX_WK_CAPTURE_H__


#include <stdint.h>
#include <CoreGraphics/CoreGraphics.h>
#include <rays/bitmap.h>


namespace Reflex
{


	/*
		Off-screen window capture for the wk backend.

		macOS exposes no public way to read a WKWebView's pixels, so the
		web view is hosted in an invisible, off-desktop-but-ordered-in
		NSWindow and its composited image is grabbed each frame. Three
		paths exist, none guaranteed across OS versions, so the method is
		chosen by a runtime probe (see WKCapture_probe). Order of
		preference:

		  CGS      CGSHWCaptureWindowList -- private SkyLight, used by
		           WebKit itself. Best when it composites off-desktop
		           windows; behaviour varies by OS version.
		  CGWINDOW CGWindowListCreateImage -- obsoleted in the macOS 15
		           SDK, resolved at runtime via dlsym. Works for our
		           off-desktop ordered-in window today.
		  (snapshot fallback is async and lives in the backend.)
	*/
	enum WKCaptureMethod
	{

		WK_CAPTURE_NONE = 0,
		WK_CAPTURE_CGS,
		WK_CAPTURE_CGWINDOW,

	};// WKCaptureMethod


	// Resolves the private/obsoleted symbols once. Safe to call repeatedly.
	void WKCapture_init ();

	bool WKCapture_available (WKCaptureMethod method);

	// Captures the window's composited image. Returns a +1 CGImageRef the
	// caller must release, or NULL on failure.
	CGImageRef WKCapture_grab (WKCaptureMethod method, uint32_t window_number);

	// Picks the best sync method for this window/OS by grabbing once with
	// each candidate and rejecting NULL or uniform-colour (blank) results.
	// Returns WK_CAPTURE_NONE if none yields usable content.
	WKCaptureMethod WKCapture_probe (uint32_t window_number);

	// Draws a captured CGImage into an RGBA bitmap, normalising the pixel
	// format to a top-left row order. The bitmap must already be sized to
	// the image.
	void WKCapture_blit (CGImageRef image, Rays::Bitmap* bitmap);


}// Reflex


#endif//EOH
