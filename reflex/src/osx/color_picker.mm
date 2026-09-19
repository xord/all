// -*- objc -*-
#include "../color_picker.h"


#import <AppKit/AppKit.h>
#include "reflex/exception.h"


@interface ReflexColorPanelTarget : NSObject

	- (void) setCurrentPicker: (Reflex::ColorPicker*) picker;

@end


@implementation ReflexColorPanelTarget

	{
		// not a static, that would be released at exit after the ruby vm is gone
		Reflex::ColorPicker::Ref current;
	}

	- (void) setCurrentPicker: (Reflex::ColorPicker*) picker
	{
		if (current && current != picker)
			[self closeCurrent];

		current = picker;
	}

	- (void) closeCurrent
	{
		if (!current) return;

		Reflex::ColorPicker::Ref picker = current;
		current                         = NULL;

		Reflex::Event e;
		Reflex::ColorPicker_call_close_event(picker, &e);
	}

	- (void) colorChanged: (NSColorPanel*) panel
	{
		if (!current) return;

		NSColor* color = [panel.color colorUsingColorSpace: NSColorSpace.sRGBColorSpace];
		if (!color) return;

		Reflex::ColorEvent e(Reflex::Color(
			color.redComponent,
			color.greenComponent,
			color.blueComponent,
			color.alphaComponent));
		Reflex::ColorPicker_call_color_event(current, &e);
	}

	- (void) panelWillClose: (NSNotification*) notification
	{
		[self closeCurrent];
	}

@end


namespace Reflex
{


	static ReflexColorPanelTarget*
	get_target (NSColorPanel* panel)
	{
		static ReflexColorPanelTarget* target = nil;
		if (!target)
		{
			target = [[ReflexColorPanelTarget alloc] init];
			[NSNotificationCenter.defaultCenter
				addObserver: target
				selector: @selector(panelWillClose:)
				name: NSWindowWillCloseNotification
				object: panel];
		}
		return target;
	}

	void
	ColorPicker_show (ColorPicker* picker, const Color* initial)
	{
		if (!picker)
			argument_error(__FILE__, __LINE__);

		NSColorPanel* panel            = NSColorPanel.sharedColorPanel;
		ReflexColorPanelTarget* target = get_target(panel);
		[target setCurrentPicker: picker];

		panel.showsAlpha = picker->alpha();
		panel.continuous = YES;
		panel.target     = target;
		panel.action     = @selector(colorChanged:);
		if (initial)
		{
			panel.color = [NSColor
				colorWithSRGBRed: initial->red
				green:            initial->green
				blue:             initial->blue
				alpha:            initial->alpha];
		}

		[panel makeKeyAndOrderFront: nil];
	}


}// Reflex
