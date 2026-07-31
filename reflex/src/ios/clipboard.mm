// -*- objc -*-
#include "reflex/clipboard.h"


#import <UIKit/UIKit.h>
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

		UIPasteboard* pasteboard = UIPasteboard.generalPasteboard;
		pasteboard.items         = @[];

		if (nstext) pasteboard.string = nstext;
	}

	Clipboard
	get_clipboard ()
	{
		Clipboard clipboard;

		NSString* nstext = UIPasteboard.generalPasteboard.string;
		const char* text = nstext ? nstext.UTF8String : NULL;
		if (text) clipboard.set_text(text);

		return clipboard;
	}


}// Reflex
