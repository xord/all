// -*- c++ -*-
#include "event.h"


#include <assert.h>
#include <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>
#include "reflex/exception.h"
#include "reflex/debug.h"


namespace Reflex
{


	static uint
	get_modifiers (const NSEvent* event)
	{
		NSUInteger flags = event ? event.modifierFlags : NSEvent.modifierFlags;
		return
			(flags & NSAlphaShiftKeyMask) ? MOD_CAPS     : 0 |
			(flags & NSShiftKeyMask)      ? MOD_SHIFT    : 0 |
			(flags & NSControlKeyMask)    ? MOD_CONTROL  : 0 |
			(flags & NSAlternateKeyMask)  ? MOD_OPTION   : 0 |
			(flags & NSCommandKeyMask)    ? MOD_COMMAND  : 0 |
			(flags & NSNumericPadKeyMask) ? MOD_NUMPAD   : 0 |
			(flags & NSHelpKeyMask)       ? MOD_HELP     : 0 |
			(flags & NSFunctionKeyMask)   ? MOD_FUNCTION : 0;
	}

	uint
	get_key_modifiers ()
	{
		return get_modifiers(nil);
	}

	static Point
	get_pointer_position (NSEvent* e, NSView* view)
	{
		assert(view);

		NSPoint p = [view convertPoint: e.locationInWindow fromView: nil];
		p.y = view.bounds.size.height - p.y;
		return Point(p.x, p.y);
	}


	static const char*
	get_chars (NSEvent* e)
	{
		NSString* chars = [e characters];//charactersIgnoringModifiers];
		return [chars UTF8String];
	}

	NativeKeyEvent::NativeKeyEvent (NSEvent* e, Action action)
	:	KeyEvent(
			action, get_chars(e), [e keyCode],
			get_modifiers(e), [e isARepeat] ? 1 : 0)
	{
	}


	static uint
	get_modifier_flag_mask (const NSEvent* e)
	{
		switch ([e keyCode])
		{
			case kVK_Shift:
			case kVK_RightShift:   return NSShiftKeyMask;
			case kVK_Control:
			case kVK_RightControl: return NSControlKeyMask;
			case kVK_Option:
			case kVK_RightOption:  return NSAlternateKeyMask;
			case kVK_Command:
			case kVK_RightCommand: return NSCommandKeyMask;
			case kVK_CapsLock:     return NSAlphaShiftKeyMask;
			case kVK_Function:     return NSFunctionKeyMask;
		}
		return 0;
	}

	static KeyEvent::Action
	get_flag_key_event_action (const NSEvent* e)
	{
		uint mask = get_modifier_flag_mask(e);
		if (mask == 0) return Reflex::KeyEvent::ACTION_NONE;

		return [e modifierFlags] & mask
			?	Reflex::KeyEvent::DOWN
			:	Reflex::KeyEvent::UP;
	}

	NativeFlagKeyEvent::NativeFlagKeyEvent (NSEvent* e)
	:	KeyEvent(
			get_flag_key_event_action(e), "", [e keyCode],
			get_modifiers(e), 0)
	{
	}


	static bool
	is_pointer_dragging (NSEvent* e)
	{
		return
			[e type] == NSLeftMouseDragged  ||
			[e type] == NSRightMouseDragged ||
			[e type] == NSOtherMouseDragged;
	}

	static uint
	get_current_pointer_type ()
	{
		NSUInteger buttons = [NSEvent pressedMouseButtons];
		uint ret = 0;
		if (buttons &  Xot::bit(0)) ret |= Reflex::Pointer::MOUSE_LEFT;
		if (buttons &  Xot::bit(1)) ret |= Reflex::Pointer::MOUSE_RIGHT;
		if (buttons >= Xot::bit(2)) ret |= Reflex::Pointer::MOUSE_MIDDLE;
		return ret;
	}

	static uint
	get_pointer_type (NSEvent* e)
	{
		switch ([e type])
		{
			case NSLeftMouseDown:
			case NSLeftMouseUp:
			case NSLeftMouseDragged:
				return Reflex::Pointer::MOUSE | Reflex::Pointer::MOUSE_LEFT;

			case NSRightMouseDown:
			case NSRightMouseUp:
			case NSRightMouseDragged:
				return Reflex::Pointer::MOUSE | Reflex::Pointer::MOUSE_RIGHT;

			case NSOtherMouseDown:
			case NSOtherMouseUp:
			case NSOtherMouseDragged:
				return Reflex::Pointer::MOUSE | Reflex::Pointer::MOUSE_MIDDLE;

			case NSMouseMoved:
				return Reflex::Pointer::MOUSE | get_current_pointer_type();

			default:
				return Reflex::Pointer::TYPE_NONE;
		}
	}

	NativePointerEvent::NativePointerEvent (
		NSEvent* event, NSView* view, Pointer::Action action)
	{
		bool dragging = is_pointer_dragging(event);
		PointerEvent_add_pointer(this, Pointer(
			0,
			get_pointer_type(event),
			action,
			get_pointer_position(event, view),
			get_modifiers(event),
			action == Pointer::MOVE && !dragging ? 0 : (uint) event.clickCount,
			dragging,
			time()));
	}


	NativeWheelEvent::NativeWheelEvent (NSEvent* e, NSView* view)
	:	WheelEvent(0, 0, 0, [e deltaX], [e deltaY], [e deltaZ], get_modifiers(e))
	{
		WheelEvent_set_position(this, get_pointer_position(e, view));
	}


};// Reflex
