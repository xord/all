// -*- objc -*-
#include "reflex/clipboard.h"


#import <AppKit/NSPasteboard.h>
#include "reflex/exception.h"


namespace Reflex
{


	void
	set_clipboard (const Clipboard& clipboard)
	{
		const char* text = clipboard.text();
		NSString* nstext = nil;
		if (text)
		{
			nstext = [NSString stringWithUTF8String: text];
			if (!nstext)
				argument_error(__FILE__, __LINE__);
		}

		NSPasteboard* pasteboard = NSPasteboard.generalPasteboard;
		[pasteboard clearContents];

		if (nstext)
			[pasteboard setString: nstext forType: NSPasteboardTypeString];
	}

	Clipboard
	get_clipboard ()
	{
		Clipboard clipboard;

		NSString* nstext = [NSPasteboard.generalPasteboard stringForType: NSPasteboardTypeString];
		const char* text = nstext ? nstext.UTF8String : NULL;
		if (text) clipboard.set_text(text);

		return clipboard;
	}


}// Reflex
