// -*- objc -*-
#include "menu.h"


#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>
#import <objc/runtime.h>
#include "reflex/exception.h"
#include "reflex/event.h"
#include "reflex/view.h"
#include "window.h"
#include "screen.h"
#import "native_window.h"


namespace Rays
{
	NSImage* Bitmap_get_nsimage (const Bitmap& bmp);
}


@interface ReflexMenuTarget : NSObject <NSMenuDelegate>
	- (void) handleMenuItem: (NSMenuItem*) sender;
@end


static NSValue*
menu2value (Reflex::Menu* menu)
{
	return [NSValue valueWithPointer: menu];
}

static Reflex::Menu*
value2menu (NSValue* value)
{
	return value ? (Reflex::Menu*) value.pointerValue : NULL;
}

static void
set_owner (NSMenuItem* nsitem, Reflex::Menu* owner)
{
	[nsitem setRepresentedObject: menu2value(owner)];
}

static Reflex::Menu*
get_owner (NSMenuItem* nsitem)
{
	return value2menu(nsitem.representedObject);
}

static void*
associated_object_key ()
{
	static char key;
	return &key;
}

static void
set_owner (NSMenu* nsmenu, Reflex::Menu* owner)
{
	objc_setAssociatedObject(
		nsmenu, associated_object_key(), menu2value(owner),
		OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static Reflex::Menu*
get_owner (NSMenu* nsmenu)
{
	return value2menu(objc_getAssociatedObject(nsmenu, associated_object_key()));
}

static ReflexMenuTarget*
menu_target ()
{
	static ReflexMenuTarget* target = [[ReflexMenuTarget alloc] init];
	return target;
}


namespace Reflex
{


	struct MenuData : public Menu::Data
	{

		NSMenuItem* nsitem = nil;

		NSMenu* nssubmenu  = nil;

		SEL native_action  = NULL;

		MenuData ()
		{
			nsitem = [[NSMenuItem alloc]
				initWithTitle: @"" action: @selector(handleMenuItem:) keyEquivalent: @""];
		}

		virtual ~MenuData ()
		{
			[nsitem release];
			[nssubmenu release];
		}

		NSMenu* get_nssubmenu (Menu* menu)
		{
			if (!nssubmenu)
			{
				nssubmenu = [[NSMenu alloc] initWithTitle: @""];
				set_owner(nssubmenu, menu);
				[nssubmenu setAutoenablesItems: NO];
				[nssubmenu setDelegate: menu_target()];
				[nsitem setSubmenu: nssubmenu];
			}
			return nssubmenu;
		}

	};// MenuData


	static MenuData&
	get_data (Menu* menu)
	{
		if (!menu)
			argument_error(__FILE__, __LINE__);

		return (MenuData&) *menu->self;
	}

	static void
	Menu_validate_items (NSMenu* nsmenu)
	{
		for (NSMenuItem* nsitem in nsmenu.itemArray)
		{
			Menu* menu = get_owner(nsitem);
			if (!menu) continue;

			MenuData& self = get_data(menu);
			if (!self.native_action) continue;

			[nsitem setEnabled:
				menu->is_enabled() && [NSApp targetForAction: self.native_action] != nil];
		}
	}

	Menu::Data*
	Menu_create_data ()
	{
		return new MenuData();
	}

	static NSEventModifierFlags
	modifiers2mask (uint mods)
	{
		NSEventModifierFlags mask = 0;
		if (mods &  MOD_SHIFT)             mask |= NSEventModifierFlagShift;
		if (mods &  MOD_CONTROL)           mask |= NSEventModifierFlagControl;
		if (mods &  MOD_COMMAND)           mask |= NSEventModifierFlagCommand;
		if (mods & (MOD_OPTION | MOD_ALT)) mask |= NSEventModifierFlagOption;
		return mask;
	}

	void
	Menu_update (Menu* menu)
	{
		auto& self   = get_data(menu);
		bool old_sep = self.nsitem && self.nsitem.isSeparatorItem;
		bool  is_sep = menu->is_separator();

		if (!self.nsitem || is_sep != old_sep)
		{
			NSMenu* parent  = self.nsitem.menu;
			NSInteger index = parent ? [parent indexOfItem: self.nsitem] : -1;

			NSMenuItem* nsitem = is_sep
				?	[[NSMenuItem separatorItem] retain]
				:	[[NSMenuItem alloc]
						initWithTitle: @""
						action:        @selector(handleMenuItem:)
						keyEquivalent: @""];

			if (parent)
			{
				[parent removeItem: self.nsitem];
				[parent insertItem: nsitem atIndex: index];
			}

			[self.nsitem release];
			self.nsitem = nsitem;
		}

		if (is_sep) return;

		set_owner(self.nsitem, menu);
		[self.nsitem setTarget: self.native_action ? nil : menu_target()];
		[self.nsitem setAction: self.native_action ? self.native_action : @selector(handleMenuItem:)];
		[self.nsitem setTitle: [NSString stringWithUTF8String: menu->label()]];
		[self.nsitem setEnabled: menu->is_enabled() ? YES : NO];
		[self.nsitem setState: menu->is_checked() ? NSControlStateValueOn : NSControlStateValueOff];
		[self.nsitem setKeyEquivalent: [NSString stringWithUTF8String: menu->shortcut_key()]];
		[self.nsitem setKeyEquivalentModifierMask: modifiers2mask(menu->shortcut_modifiers())];
		[self.nsitem setImage: menu->image() ? Rays::Bitmap_get_nsimage(menu->image().bitmap()) : nil];
		[self.nsitem setSubmenu: menu->empty() ? nil : self.nssubmenu];
	}

	void
	Menu_popup (Menu* menu, View* view, coord x, coord y)
	{
		MenuData& self = get_data(menu);

		if (!self.nssubmenu)
			invalid_state_error(__FILE__, __LINE__);

		if (view)
		{
			Window* win     = view->window();
			if (!win)
				invalid_state_error(__FILE__, __LINE__);

			NSWindow* nswin = Window_get_data(win).native;
			if (!nswin)
				invalid_state_error(__FILE__, __LINE__);

			NSView* nsview  = nswin.contentView;
			if (!nsview)
				invalid_state_error(__FILE__, __LINE__);

			Point win_pos   = view->to_window(Point(x, y));
			CGFloat win_h   = nsview.frame.size.height;
			[self.nssubmenu popUpMenuPositioningItem: nil
				atLocation: NSMakePoint(win_pos.x, win_h - win_pos.y)
				inView: nsview];
		}
		else
		{
			[self.nssubmenu popUpMenuPositioningItem: nil
				atLocation: NSMakePoint(x, primary_screen_height() - y)
				inView: nil];
		}
	}

	void
	Menu_child_added (Menu* parent, Menu* child, int index)
	{
		auto& p = get_data(parent);
		auto& c = get_data(child);

		[p.get_nssubmenu(parent) insertItem: c.nsitem atIndex: index];
		Menu_update(child);
	}

	void
	Menu_child_removed (Menu* parent, Menu* child)
	{
		auto& p = get_data(parent);
		auto& c = get_data(child);

		if (p.nssubmenu && c.nsitem.menu == p.nssubmenu)
			[p.nssubmenu removeItem: c.nsitem];
	}

	NSMenu*
	Menu_get_nssubmenu (Menu* menu)
	{
		return get_data(menu).get_nssubmenu(menu);
	}

	void
	Menu_set_native_action (Menu* menu, SEL action)
	{
		MenuData& self = get_data(menu);

		self.native_action = action;
		Menu_update(menu);
	}

	void
	Menu_apply_to_main_menu (Menu* menu)
	{
		if (!menu && app())
			menu = app()->menu();

		if (!menu) return;

		[NSApp setMainMenu: get_data(menu).get_nssubmenu(menu)];
	}


}// Reflex


@implementation ReflexMenuTarget

	- (void) handleMenuItem: (NSMenuItem*) nsitem
	{
		Reflex::Menu* menu = get_owner(nsitem);
		if (!menu) return;

		Reflex::Event e;
		menu->on_click(&e);
	}

	- (void) menuWillOpen: (NSMenu*) nsmenu
	{
		Reflex::Menu_validate_items(nsmenu);

		Reflex::Menu* menu = get_owner(nsmenu);
		if (!menu) return;

		Reflex::Event e;
		menu->on_open_child(&e);

		for (NSMenuItem* nsitem in nsmenu.itemArray)
		{
			Reflex::Menu* child = get_owner(nsitem);
			if (!child) continue;

			Reflex::Event ce;
			child->on_show(&ce);
		}
	}

	- (void) menuDidClose: (NSMenu*) nsmenu
	{
		Reflex::Menu* menu = get_owner(nsmenu);
		if (!menu) return;

		for (NSMenuItem* nsitem in nsmenu.itemArray)
		{
			Reflex::Menu* child = get_owner(nsitem);
			if (!child) continue;

			Reflex::Event ce;
			child->on_hide(&ce);
		}

		Reflex::Event e;
		menu->on_close_child(&e);
	}

	- (BOOL) menuHasKeyEquivalent: (NSMenu*) nsmenu
		forEvent: (NSEvent*) event
		target: (id*) target
		action: (SEL*) action
	{
		// answer key equivalent matching ourselves: AppKit's own scanning of
		// delegate-backed menus caches stale results across setMainMenu calls,
		// leaving every shortcut dead until the menu bar is clicked once
		static const NSEventModifierFlags MODIFIER_MASK =
			NSEventModifierFlagCommand |
			NSEventModifierFlagShift   |
			NSEventModifierFlagOption  |
			NSEventModifierFlagControl;

		NSEventModifierFlags mods = event.modifierFlags & MODIFIER_MASK;
		NSString* chars           = event.charactersIgnoringModifiers;

		for (NSMenuItem* nsitem in nsmenu.itemArray)
		{
			if (nsitem.hasSubmenu || !nsitem.enabled)           continue;
			if (nsitem.keyEquivalent.length == 0)               continue;
			if (nsitem.keyEquivalentModifierMask != mods)       continue;
			if (![nsitem.keyEquivalent isEqualToString: chars]) continue;

			*target = nsitem.target;
			*action = nsitem.action;
			return YES;
		}
		return NO;
	}

@end// ReflexMenuTarget
