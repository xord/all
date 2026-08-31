// -*- objc -*-
#include "../file_dialog.h"


#import <AppKit/AppKit.h>
#include "reflex/exception.h"
#include "window.h"


@interface ReflexOpenSavePanelDelegate : NSObject <NSOpenSavePanelDelegate>
@end


@implementation ReflexOpenSavePanelDelegate

	{
		NSArray<NSString*>* suffixes;
	}

	- (id) initWithExtensions: (const Reflex::StringList&) extensions
	{
		self = [super init];
		if (!self) return nil;

		NSMutableArray* array = [NSMutableArray arrayWithCapacity: extensions.size()];
		for (const auto& extension : extensions)
		{
			NSString* str = [NSString stringWithUTF8String: ("." + extension).c_str()];
			if (!str)
				Reflex::argument_error(__FILE__, __LINE__);

			[array addObject: str];
		}
		suffixes = [array retain];

		return self;
	}

	- (void) dealloc
	{
		[suffixes release];

		[super dealloc];
	}

	- (BOOL) panel: (id) sender shouldEnableURL: (NSURL*) url
	{
		NSNumber* directory = nil;
		if (![url getResourceValue: &directory forKey: NSURLIsDirectoryKey error: NULL])
			return YES;// what cannot be classified is better shown than hidden

		if (directory.boolValue)
			return YES;

		NSString* name = url.lastPathComponent.lowercaseString;
		for (NSString* suffix in suffixes)
		{
			if ([name hasSuffix: suffix.lowercaseString])
				return YES;
		}
		return NO;
	}

@end


namespace Reflex
{


	static NSOpenPanel*
	create_open_panel (FileDialog* dialog, FileDialog::Data::Mode mode)
	{
		NSOpenPanel* panel            = [NSOpenPanel openPanel];
		panel.canChooseFiles          = mode != FileDialog::Data::OPEN_DIRECTORY;
		panel.canChooseDirectories    = mode == FileDialog::Data::OPEN_DIRECTORY;
		panel.allowsMultipleSelection = mode == FileDialog::Data::OPEN_FILES;

		const StringList& extensions = dialog->extensions();
		if (mode != FileDialog::Data::OPEN_DIRECTORY && !extensions.empty())
		{
			panel.delegate = [[[ReflexOpenSavePanelDelegate alloc]
				initWithExtensions: extensions]
				autorelease];
		}

		return panel;
	}

	static NSSavePanel*
	create_save_panel (const char* name)
	{
		NSSavePanel* panel = [NSSavePanel savePanel];

		if (name && *name)
			panel.nameFieldStringValue = [NSString stringWithUTF8String: name];

		return panel;
	}

	void
	FileDialog_show (
		FileDialog* dialog, FileDialog::Data::Mode mode,
		const char* dir, const char* name)
	{
		if (!dialog)
			argument_error(__FILE__, __LINE__);

		bool save          = mode == FileDialog::Data::SAVE_FILE;
		NSSavePanel* panel = save
			?	create_save_panel(name)
			:	create_open_panel(dialog, mode);

		const char* title = dialog->title();
		if (*title)
			panel.message = [NSString stringWithUTF8String: title];

		if (dir && *dir)
		{
			NSString* nsdir    = [NSString stringWithUTF8String: dir];
			panel.directoryURL = [NSURL fileURLWithPath: nsdir isDirectory: YES];
		}

		FileDialog::Ref dialog_ref          = dialog;
		id delegate                         = panel.delegate;
		void (^completion)(NSModalResponse) = ^(NSModalResponse result)
		{
			(void) delegate;// panel.delegate is weak ref, so capture it here

			FileDialog* pdialog = const_cast<FileDialog*>(dialog_ref.get());

			if (result == NSModalResponseOK)
			{
				StringList paths;
				if (save)
				{
					const char* path = panel.URL.path.UTF8String;
					if (path) paths.emplace_back(path);
				}
				else
				{
					for (NSURL* url in ((NSOpenPanel*) panel).URLs)
					{
						const char* path = url.path.UTF8String;
						if (path) paths.emplace_back(path);
					}
				}

				FileEvent e(save ? FileEvent::SAVE : FileEvent::OPEN, paths);
				FileDialog_call_file_event(pdialog, &e);
			}
			else
			{
				Event e;
				FileDialog_call_cancel_event(pdialog, &e);
			}
		};

		Window* owner      = dialog->owner();
		NSWindow* nswindow = owner ? (NSWindow*) Window_get_data(owner).native : nil;
		if (nswindow)
			[panel beginSheetModalForWindow: nswindow completionHandler: completion];
		else
			[panel beginWithCompletionHandler: completion];
	}


}// Reflex
