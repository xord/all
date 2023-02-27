// -*- c++ -*-
#include "event.h"


#include <assert.h>
#include <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>


namespace Reflex
{


	static const char*
	get_chars (NSEvent* e)
	{
		NSString* chars = [e characters];//charactersIgnoringModifiers];
		return [chars UTF8String];
	}

	static KeyCode
	get_code (UInt16 code)
	{
		switch (code)
		{
			case kVK_ANSI_A:              return KEY_A;
			case kVK_ANSI_S:              return KEY_S;
			case kVK_ANSI_D:              return KEY_D;
			case kVK_ANSI_F:              return KEY_F;
			case kVK_ANSI_H:              return KEY_H;
			case kVK_ANSI_G:              return KEY_G;
			case kVK_ANSI_Z:              return KEY_Z;
			case kVK_ANSI_X:              return KEY_X;
			case kVK_ANSI_C:              return KEY_C;
			case kVK_ANSI_V:              return KEY_V;
			case kVK_ANSI_B:              return KEY_B;
			case kVK_ANSI_Q:              return KEY_Q;
			case kVK_ANSI_W:              return KEY_W;
			case kVK_ANSI_E:              return KEY_E;
			case kVK_ANSI_R:              return KEY_R;
			case kVK_ANSI_Y:              return KEY_Y;
			case kVK_ANSI_T:              return KEY_T;
			case kVK_ANSI_1:              return KEY_1;
			case kVK_ANSI_2:              return KEY_2;
			case kVK_ANSI_3:              return KEY_3;
			case kVK_ANSI_4:              return KEY_4;
			case kVK_ANSI_6:              return KEY_6;
			case kVK_ANSI_5:              return KEY_5;
			case kVK_ANSI_Equal:          return KEY_EQUAL;
			case kVK_ANSI_9:              return KEY_9;
			case kVK_ANSI_7:              return KEY_7;
			case kVK_ANSI_Minus:          return KEY_MINUS;
			case kVK_ANSI_8:              return KEY_8;
			case kVK_ANSI_0:              return KEY_0;
			case kVK_ANSI_RightBracket:   return KEY_RBRACKET;
			case kVK_ANSI_O:              return KEY_O;
			case kVK_ANSI_U:              return KEY_U;
			case kVK_ANSI_LeftBracket:    return KEY_LBRACKET;
			case kVK_ANSI_I:              return KEY_I;
			case kVK_ANSI_P:              return KEY_P;
			case kVK_ANSI_L:              return KEY_L;
			case kVK_ANSI_J:              return KEY_J;
			case kVK_ANSI_Quote:          return KEY_QUOTE;
			case kVK_ANSI_K:              return KEY_K;
			case kVK_ANSI_Semicolon:      return KEY_SEMICOLON;
			case kVK_ANSI_Backslash:      return KEY_BACKSLASH;
			case kVK_ANSI_Comma:          return KEY_COMMA;
			case kVK_ANSI_Slash:          return KEY_SLASH;
			case kVK_ANSI_N:              return KEY_N;
			case kVK_ANSI_M:              return KEY_M;
			case kVK_ANSI_Period:         return KEY_PERIOD;
			case kVK_ANSI_Grave:          return KEY_GRAVE;
			case kVK_ANSI_KeypadDecimal:  return KEY_NUM_DECIMAL;
			case kVK_ANSI_KeypadMultiply: return KEY_NUM_MULTIPLY;
			case kVK_ANSI_KeypadPlus:     return KEY_NUM_PLUS;
			case kVK_ANSI_KeypadClear:    return KEY_NUM_CLEAR;
			case kVK_ANSI_KeypadDivide:   return KEY_NUM_DIVIDE;
			case kVK_ANSI_KeypadEnter:    return KEY_ENTER;
			case kVK_ANSI_KeypadMinus:    return KEY_NUM_MINUS;
			case kVK_ANSI_KeypadEquals:   return KEY_NUM_EQUAL;
			case kVK_ANSI_Keypad0:        return KEY_NUM_0;
			case kVK_ANSI_Keypad1:        return KEY_NUM_1;
			case kVK_ANSI_Keypad2:        return KEY_NUM_2;
			case kVK_ANSI_Keypad3:        return KEY_NUM_3;
			case kVK_ANSI_Keypad4:        return KEY_NUM_4;
			case kVK_ANSI_Keypad5:        return KEY_NUM_5;
			case kVK_ANSI_Keypad6:        return KEY_NUM_6;
			case kVK_ANSI_Keypad7:        return KEY_NUM_7;
			case kVK_ANSI_Keypad8:        return KEY_NUM_8;
			case kVK_ANSI_Keypad9:        return KEY_NUM_9;

			case kVK_Return:        return KEY_RETURN;
			case kVK_Tab:           return KEY_TAB;
			case kVK_Space:         return KEY_SPACE;
			case kVK_Delete:        return KEY_BACKSPACE;
			case kVK_Escape:        return KEY_ESCAPE;
			case kVK_Command:       return KEY_LCOMMAND;
			case kVK_Shift:         return KEY_LSHIFT;
			case kVK_CapsLock:      return KEY_CAPSLOCK;
			case kVK_Option:        return KEY_LOPTION;
			case kVK_Control:       return KEY_LCONTROL;
			case kVK_RightCommand:  return KEY_RCOMMAND;
			case kVK_RightShift:    return KEY_RSHIFT;
			case kVK_RightOption:   return KEY_ROPTION;
			case kVK_RightControl:  return KEY_RCONTROL;
			case kVK_Function:      return KEY_FUNCTION;
			case kVK_F17:           return KEY_F17;
			case kVK_VolumeUp:      return KEY_VOLUME_UP;
			case kVK_VolumeDown:    return KEY_VOLUME_DOWN;
			case kVK_Mute:          return KEY_MUTE;
			case kVK_F18:           return KEY_F18;
			case kVK_F19:           return KEY_F19;
			case kVK_F20:           return KEY_F20;
			case kVK_F5:            return KEY_F5;
			case kVK_F6:            return KEY_F6;
			case kVK_F7:            return KEY_F7;
			case kVK_F3:            return KEY_F3;
			case kVK_F8:            return KEY_F8;
			case kVK_F9:            return KEY_F9;
			case kVK_F11:           return KEY_F11;
			case kVK_F13:           return KEY_F13;
			case kVK_F16:           return KEY_F16;
			case kVK_F14:           return KEY_F14;
			case kVK_F10:           return KEY_F10;
			case kVK_F12:           return KEY_F12;
			case kVK_F15:           return KEY_F15;
			case kVK_Help:          return KEY_HELP;
			case kVK_Home:          return KEY_HOME;
			case kVK_PageUp:        return KEY_PAGEUP;
			case kVK_ForwardDelete: return KEY_DELETE;
			case kVK_F4:            return KEY_F4;
			case kVK_End:           return KEY_END;
			case kVK_F2:            return KEY_F2;
			case kVK_PageDown:      return KEY_PAGEDOWN;
			case kVK_F1:            return KEY_F1;
			case kVK_LeftArrow:     return KEY_LEFT;
			case kVK_RightArrow:    return KEY_RIGHT;
			case kVK_DownArrow:     return KEY_DOWN;
			case kVK_UpArrow:       return KEY_UP;

			case kVK_ISO_Section: return KEY_SECTION;

			case kVK_JIS_Yen:         return KEY_YEN;
			case kVK_JIS_Underscore:  return KEY_UNDERSCORE;
			case kVK_JIS_KeypadComma: return KEY_NUM_COMMA;
			case kVK_JIS_Eisu:        return KEY_IME_EISU;
			case kVK_JIS_Kana:        return KEY_IME_KANA;
		}

		return KEY_NONE;
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

	static uint
	get_modifiers (const NSEvent* e)
	{
		NSUInteger flags = [e modifierFlags];
		return
			(flags & NSAlphaShiftKeyMask) ? MOD_CAPS     : 0 |
			(flags & NSShiftKeyMask)      ? MOD_SHIFT    : 0 |
			(flags & NSControlKeyMask)    ? MOD_CONTROL  : 0 |
			(flags & NSAlternateKeyMask)  ? MOD_ALT      : 0 |
			(flags & NSCommandKeyMask)    ? MOD_COMMAND  : 0 |
			(flags & NSNumericPadKeyMask) ? MOD_NUMPAD   : 0 |
			(flags & NSHelpKeyMask)       ? MOD_HELP     : 0 |
			(flags & NSFunctionKeyMask)   ? MOD_FUNCTION : 0;
	}

	static NSPoint
	correct_point (NSView* view, const NSPoint& point)
	{
		assert(view);
		NSPoint p = [view convertPoint: point fromView: nil];
		p.y = [view bounds].size.height - p.y;
		return p;
	}

	static Point
	get_pointer_position (NSEvent* e, NSView* view)
	{
		NSPoint p = correct_point(view, [e locationInWindow]);
		return Point(p.x, p.y);
	}


	NativeKeyEvent::NativeKeyEvent (NSEvent* e, Action action)
	:	KeyEvent(
			action, get_chars(e), get_code([e keyCode]),
			get_modifiers(e), [e isARepeat] ? 1 : 0)
	{
	}


	NativeFlagKeyEvent::NativeFlagKeyEvent (NSEvent* e)
	:	KeyEvent(
			get_flag_key_event_action(e), "", get_code([e keyCode]),
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

	NativePointerEvent::NativePointerEvent (
		NSEvent* event, NSView* view, Pointer::ID id, Pointer::Action action)
	{
		bool dragging = is_pointer_dragging(event);
		PointerEvent_add_pointer(this, Pointer(
			id,
			get_pointer_type(event),
			action,
			get_pointer_position(event, view),
			get_modifiers(event),
			action == Pointer::MOVE && !dragging ? 0 : (uint) [event clickCount],
			dragging,
			time()));
	}


	NativeWheelEvent::NativeWheelEvent (NSEvent* e, NSView* view)
	:	WheelEvent(0, 0, 0, [e deltaX], [e deltaY], [e deltaZ], get_modifiers(e))
	{
		WheelEvent_set_position(this, get_pointer_position(e, view));
	}


};// Reflex
