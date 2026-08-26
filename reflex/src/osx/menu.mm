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

	static NSString*
	get_keyequivalent_string (int key)
	{
		using namespace Reflex;
		switch (key)
		{
			#define KEY_STR(key) [NSString stringWithFormat: @"%C", (unichar) (key)]

			case KEY_A: return @"a";
			case KEY_B: return @"b";
			case KEY_C: return @"c";
			case KEY_D: return @"d";
			case KEY_E: return @"e";
			case KEY_F: return @"f";
			case KEY_G: return @"g";
			case KEY_H: return @"h";
			case KEY_I: return @"i";
			case KEY_J: return @"j";
			case KEY_K: return @"k";
			case KEY_L: return @"l";
			case KEY_M: return @"m";
			case KEY_N: return @"n";
			case KEY_O: return @"o";
			case KEY_P: return @"p";
			case KEY_Q: return @"q";
			case KEY_R: return @"r";
			case KEY_S: return @"s";
			case KEY_T: return @"t";
			case KEY_U: return @"u";
			case KEY_V: return @"v";
			case KEY_W: return @"w";
			case KEY_X: return @"x";
			case KEY_Y: return @"y";
			case KEY_Z: return @"z";

			case KEY_0: return @"0";
			case KEY_1: return @"1";
			case KEY_2: return @"2";
			case KEY_3: return @"3";
			case KEY_4: return @"4";
			case KEY_5: return @"5";
			case KEY_6: return @"6";
			case KEY_7: return @"7";
			case KEY_8: return @"8";
			case KEY_9: return @"9";

			case KEY_MINUS:     return @"-";
			case KEY_EQUAL:     return @"=";
			case KEY_COMMA:     return @",";
			case KEY_PERIOD:    return @".";
			case KEY_SEMICOLON: return @";";
			case KEY_QUOTE:     return @"'";
			case KEY_SLASH:     return @"/";
			case KEY_BACKSLASH: return @"\\";
			case KEY_GRAVE:     return @"`";
			case KEY_LBRACKET:  return @"[";
			case KEY_RBRACKET:  return @"]";

			case KEY_ENTER:     return @"\r";
			case KEY_SPACE:     return @" ";
			case KEY_TAB:       return @"\t";
			case KEY_ESCAPE:    return @"\033";
			case KEY_BACKSPACE: return @"\b";
			case KEY_DELETE:    return KEY_STR(NSDeleteFunctionKey);
			case KEY_INSERT:    return KEY_STR(NSInsertFunctionKey);

			case KEY_LEFT:     return KEY_STR(NSLeftArrowFunctionKey);
			case KEY_RIGHT:    return KEY_STR(NSRightArrowFunctionKey);
			case KEY_UP:       return KEY_STR(NSUpArrowFunctionKey);
			case KEY_DOWN:     return KEY_STR(NSDownArrowFunctionKey);
			case KEY_HOME:     return KEY_STR(NSHomeFunctionKey);
			case KEY_END:      return KEY_STR(NSEndFunctionKey);
			case KEY_PAGEUP:   return KEY_STR(NSPageUpFunctionKey);
			case KEY_PAGEDOWN: return KEY_STR(NSPageDownFunctionKey);

			case KEY_F1:  return KEY_STR(NSF1FunctionKey);
			case KEY_F2:  return KEY_STR(NSF2FunctionKey);
			case KEY_F3:  return KEY_STR(NSF3FunctionKey);
			case KEY_F4:  return KEY_STR(NSF4FunctionKey);
			case KEY_F5:  return KEY_STR(NSF5FunctionKey);
			case KEY_F6:  return KEY_STR(NSF6FunctionKey);
			case KEY_F7:  return KEY_STR(NSF7FunctionKey);
			case KEY_F8:  return KEY_STR(NSF8FunctionKey);
			case KEY_F9:  return KEY_STR(NSF9FunctionKey);
			case KEY_F10: return KEY_STR(NSF10FunctionKey);
			case KEY_F11: return KEY_STR(NSF11FunctionKey);
			case KEY_F12: return KEY_STR(NSF12FunctionKey);
			case KEY_F13: return KEY_STR(NSF13FunctionKey);
			case KEY_F14: return KEY_STR(NSF14FunctionKey);
			case KEY_F15: return KEY_STR(NSF15FunctionKey);
			case KEY_F16: return KEY_STR(NSF16FunctionKey);
			case KEY_F17: return KEY_STR(NSF17FunctionKey);
			case KEY_F18: return KEY_STR(NSF18FunctionKey);
			case KEY_F19: return KEY_STR(NSF19FunctionKey);
			case KEY_F20: return KEY_STR(NSF20FunctionKey);
			case KEY_F21: return KEY_STR(NSF21FunctionKey);
			case KEY_F22: return KEY_STR(NSF22FunctionKey);
			case KEY_F23: return KEY_STR(NSF23FunctionKey);
			case KEY_F24: return KEY_STR(NSF24FunctionKey);

			#undef KEY_STR
		}
		return @"";
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
		[self.nsitem setKeyEquivalent: get_keyequivalent_string(menu->shortcut_key())];
		[self.nsitem setKeyEquivalentModifierMask: modifiers2mask(menu->shortcut_modifiers())];
		[self.nsitem setImage: menu->image() ? Rays::Bitmap_get_nsimage(menu->image().bitmap()) : nil];
		[self.nsitem setSubmenu: menu->empty() ? nil : self.nssubmenu];
	}

	void
	Menu_popup (Menu* menu, View* view, coord x, coord y)
	{
		Menu_cancel_active_pointers_for_popup(view);

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


static NSMenuItem*
find_key_equivalent_item (NSMenu* nsmenu, NSEvent* event)
{
	static const NSEventModifierFlags KEY_EQUIVALENT_MODIFIER_MASK =
		NSEventModifierFlagCommand |
		NSEventModifierFlagShift   |
		NSEventModifierFlagOption  |
		NSEventModifierFlagControl;

	if (event.type != NSEventTypeKeyDown)
		return nil;

	NSEventModifierFlags mods = event.modifierFlags & KEY_EQUIVALENT_MODIFIER_MASK;
	NSString* chars           = event.charactersIgnoringModifiers;

	for (NSMenuItem* nsitem in nsmenu.itemArray)
	{
		if (!nsitem.enabled) continue;

		if (nsitem.hasSubmenu)
		{
			NSMenuItem* found = find_key_equivalent_item(nsitem.submenu, event);
			if (found) return found;
		}
		else if (
			nsitem.keyEquivalent.length > 0          &&
			nsitem.keyEquivalentModifierMask == mods &&
			[nsitem.keyEquivalent isEqualToString: chars])
		{
			return nsitem;
		}
	}
	return nil;
}


@implementation ReflexMenuTarget

	- (void) handleMenuItem: (id) sender
	{
		NSMenuItem* nsitem = nil;
		if ([sender isKindOfClass: NSMenuItem.class])
			nsitem = (NSMenuItem*) sender;
		else if ([sender isKindOfClass: NSMenu.class])
			nsitem = find_key_equivalent_item((NSMenu*) sender, NSApp.currentEvent);

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
		menu->on_open_submenu(&e);

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
		menu->on_close_submenu(&e);
	}

	- (BOOL) menuHasKeyEquivalent: (NSMenu*) nsmenu
		forEvent: (NSEvent*) event
		target: (id*) target
		action: (SEL*) action
	{
		// answer key equivalent matching ourselves: AppKit's own scanning of
		// delegate-backed menus caches stale results across setMainMenu calls,
		// leaving every shortcut dead until the menu bar is clicked once

		NSMenuItem* nsitem = find_key_equivalent_item(nsmenu, event);
		if (!nsitem) return NO;

		*target = nsitem.target;
		*action = nsitem.action;
		return YES;
	}

@end// ReflexMenuTarget
