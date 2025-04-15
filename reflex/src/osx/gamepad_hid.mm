// -*- objc -*-
#include "../gamepad.h"


#include <memory>
#include <vector>
#include <map>
#import <IOKit/hid/IOHIDManager.h>
#import <IOKit/hid/IOHIDDevice.h>
#import <GameController/GameController.h>
#include <xot/util.h>
#include "reflex/exception.h"
#include "reflex/debug.h"
#include "event.h"
#include "window.h"


namespace Reflex
{


	static int
	get_int_property (IOHIDDeviceRef device, CFStringRef key)
	{
		CFNumberRef ref = (CFNumberRef) IOHIDDeviceGetProperty(device, key);
		if (!ref) return 0;

		int value = 0;
		CFNumberGetValue(ref, kCFNumberIntType, &value);
		return value;
	}

	static String
	get_string_property (IOHIDDeviceRef device, CFStringRef key)
	{
		return Xot::to_s((CFStringRef) IOHIDDeviceGetProperty(device, key));
	}


	struct HIDGamepadData : Gamepad::Data
	{

		typedef Gamepad::Data Super;

		enum Mapping {RSTICK_UNKNOWN, RSTICK_RxRy, RSTICK_ZRz};

		IOHIDDeviceRef device;

		Mapping mapping = RSTICK_UNKNOWN;

		CFIndex prev_hatswitch = 8;// neutral

		mutable String name_cache;

		HIDGamepadData (IOHIDDeviceRef device)
		:	device(device)
		{
			if (!device)
				argument_error(__FILE__, __LINE__);

			CFRetain(device);
			prev.reset(new Gamepad());
		}

		~HIDGamepadData ()
		{
			CFRelease(device);
		}

		const char* name () const override
		{
			if (name_cache.empty())
			{
				String& name   = name_cache;
				name           = get_string_property(device, CFSTR(kIOHIDManufacturerKey));
				String product = get_string_property(device, CFSTR(kIOHIDProductKey));
				String serial  = get_string_property(device, CFSTR(kIOHIDSerialNumberKey));

				if (!product.empty())
				{
					if (!name.empty() && name[name.size() - 1] != ' ') name_cache += " ";
					name += product;
				}

				if (!serial.empty())
				{
					if (!name.empty() && name[name.size() - 1] != ' ')
					{
						name  += " ";
						serial = "[" + serial + "]";
					}
					name += serial;
				}

				if (name.empty()) name = "Unknown";
			}
			return name_cache;
		}

		bool is_valid () const override
		{
			return Super::is_valid() && device;
		}

		bool has_handle (void* handle) const override
		{
			return handle == device;
		}

	};// HIDGamepadData


	static Gamepad*
	Gamepad_create (IOHIDDeviceRef device)
	{
		Gamepad* g = Gamepad_create();
		g->self.reset(new HIDGamepadData(device));
		return g;
	}

	static HIDGamepadData*
	get_data (Gamepad* gamepad)
	{
		return (HIDGamepadData*) gamepad->self.get();
	}

	static std::map<IOHIDElementRef, IOHIDDeviceRef> element2device;

	static void
	each_element (IOHIDDeviceRef device, std::function<bool(IOHIDElementRef)> fun)
	{
		std::shared_ptr<const __CFArray> elements(
			IOHIDDeviceCopyMatchingElements(device, NULL, kIOHIDOptionsTypeNone),
			Xot::safe_cfrelease);
		if (!elements) return;

		CFIndex count = CFArrayGetCount(elements.get());
		for (CFIndex i = 0; i < count; ++i)
		{
			IOHIDElementRef element =
				(IOHIDElementRef) CFArrayGetValueAtIndex(elements.get(), i);
			if (!element) continue;

			if (!fun(element)) break;
		}
	}

	static void
	register_to_device_map (IOHIDDeviceRef device)
	{
		if (@available(macOS 11.0, *))
			return;

		each_element(device, [&](IOHIDElementRef element)
		{
			element2device[element] = device;
			return true;
		});
	}

	static void
	unregister_to_device_map (IOHIDDeviceRef device)
	{
		if (@available(macOS 11.0, *))
			return;

		std::erase_if(
			element2device,
			[&](const auto& e) {return e.second == device;});
	}

	static IOHIDDeviceRef
	get_device (IOHIDElementRef element)
	{
		if (@available(macOS 11.0, *))
			return IOHIDElementGetDevice(element);
		else
		{
			auto it = element2device.find(element);
			if (it == element2device.end())
				return NULL;

			return it->second;
		}
	}

	static float
	get_current_value (IOHIDDeviceRef device, uint32_t usage)
	{
		float value = 0;
		each_element(device, [&](IOHIDElementRef element)
		{
			if (IOHIDElementGetUsage(element) != usage)
				return true;

			IOHIDValueRef valref = NULL;
			IOReturn result      = IOHIDDeviceGetValue(device, element, &valref);
			if (result != kIOReturnSuccess || !valref)
				return true;

			CFIndex val = IOHIDValueGetIntegerValue(valref);
			CFIndex min = IOHIDElementGetLogicalMin(element);
			CFIndex max = IOHIDElementGetLogicalMax(element);

			value = (val - min) / (float) (max - min);
			return false;
		});

		return value;
	}

	static HIDGamepadData::Mapping
	get_mapping (IOHIDDeviceRef device)
	{
		float Z  = get_current_value(device, kHIDUsage_GD_Z);
		float Rx = get_current_value(device, kHIDUsage_GD_Rx);
		if (0.4 < Z  && Z  < 0.6) return HIDGamepadData::RSTICK_ZRz;
		if (0.4 < Rx && Rx < 0.6) return HIDGamepadData::RSTICK_RxRy;
		return                           HIDGamepadData::RSTICK_UNKNOWN;
	}

	static void
	add_gamepad (Application* app, IOHIDDeviceRef device)
	{
		Gamepad* gamepad           = Gamepad_create(device);
		get_data(gamepad)->mapping = get_mapping(device);
		Gamepad_add(app, gamepad);
	}

	static void
	remove_gamepad (Application* app, IOHIDDeviceRef device)
	{
		Gamepad* gamepad = Gamepad_find(device);
		if (!gamepad) return;

		Gamepad_remove(app, gamepad);
	}

	static bool
	can_handle (IOHIDDeviceRef device)
	{
		int page  = get_int_property(device, CFSTR(kIOHIDPrimaryUsagePageKey));
		int usage = get_int_property(device, CFSTR(kIOHIDPrimaryUsageKey));
		return
			page == kHIDPage_GenericDesktop &&
			(usage == kHIDUsage_GD_GamePad || usage == kHIDUsage_GD_Joystick);
	}

	static void
	handle_disconnect_event (void* context, IOReturn result, void* sender)
	{
		IOHIDDeviceRef device = (IOHIDDeviceRef) context;

		remove_gamepad(app(), device);
		unregister_to_device_map(device);
	}

	static void
	handle_connect_event (
		void* context, IOReturn result, void* sender, IOHIDDeviceRef device)
	{
		Application* app = (Application*) context;

		if (!can_handle(device))
			return;

		if (@available(macOS 11.0, *))
		{
			if ([GCController supportsHIDDevice: device])
				return;
		}

		IOHIDDeviceRegisterRemovalCallback(device, handle_disconnect_event, device);

		register_to_device_map(device);
		add_gamepad(app, device);
	}

	enum
	{
		DPAD_UP    = Xot::bit(0),
		DPAD_RIGHT = Xot::bit(1),
		DPAD_DOWN  = Xot::bit(2),
		DPAD_LEFT  = Xot::bit(3)
	};

	static uint
	to_dpad (CFIndex hatswitch)
	{
		switch (hatswitch)
		{
			case 0: return DPAD_UP;
			case 1: return DPAD_UP    | DPAD_RIGHT;
			case 2: return DPAD_RIGHT;
			case 3: return DPAD_RIGHT | DPAD_DOWN;
			case 4: return DPAD_DOWN;
			case 5: return DPAD_DOWN  | DPAD_LEFT;
			case 6: return DPAD_LEFT;
			case 7: return DPAD_LEFT  | DPAD_UP;
		}
		return 0;
	}

	static void
	call_gamepad_event (int key_code, bool pressed)
	{
		Window* win = Window_get_active();
		if (!win) return;

		auto action = pressed ? KeyEvent::DOWN : KeyEvent::UP;
		KeyEvent e(action, NULL, key_code, KeyEvent_get_modifiers(), 0);
		Window_call_key_event(win, &e);
	}

	static void
	call_button_event (
		Gamepad* gamepad, ulonglong button, int key_code, float value)
	{
		Gamepad::Data* self = gamepad->self.get();

		bool pressed = value > Gamepad_get_button_press_threshold();
		bool current = self->state.buttons & button;
		if (pressed == current) return;

		self->update_prev();
		if (pressed)
			self->state.buttons |=  button;
		else
			self->state.buttons &= ~button;

		call_gamepad_event(key_code, pressed);
	}

	static void
	handle_hatswitch_event (
		Gamepad* gamepad, IOHIDElementRef element, CFIndex hatswitch)
	{
		HIDGamepadData* data = get_data(gamepad);

		CFIndex prev         = data->prev_hatswitch;
		data->prev_hatswitch = hatswitch;

		uint prev_dpad = to_dpad(prev);
		uint      dpad = to_dpad(hatswitch);
		uint diff      = prev_dpad ^ dpad;

		#define HANDLE_BUTTON(button, value) \
			call_button_event( \
				gamepad, \
				Gamepad::button, KEY_GAMEPAD_##button, \
				(value) ? 1 : 0)

		if (diff & DPAD_UP)    HANDLE_BUTTON(UP,    dpad & DPAD_UP);
		if (diff & DPAD_RIGHT) HANDLE_BUTTON(RIGHT, dpad & DPAD_RIGHT);
		if (diff & DPAD_DOWN)  HANDLE_BUTTON(DOWN,  dpad & DPAD_DOWN);
		if (diff & DPAD_LEFT)  HANDLE_BUTTON(LEFT,  dpad & DPAD_LEFT);

		#undef HANDLE_BUTTON
	}

	static void
	handle_stick_dpad_event (
		Gamepad* gamepad, auto* state, float value,
		ulonglong button_negative, int key_code_negative,
		ulonglong button_positive, int key_code_positive)
	{
		*state = value;

		if (value < 0)
			call_button_event(gamepad, button_negative, key_code_negative, -value);
		else
			call_button_event(gamepad, button_positive, key_code_positive,  value);
	}

	static void
	handle_trigger_event (Gamepad* gamepad, auto* state, float value)
	{
		*state = value;
	}

	static void
	handle_analog_event (
		Gamepad* gamepad, uint32_t usage, IOHIDElementRef element, CFIndex intval)
	{
		int value   = (int) intval;
		int min     = (int) IOHIDElementGetLogicalMin(element);
		int max     = (int) IOHIDElementGetLogicalMax(element);
		float range = min == max ? max : max - min;
		if (range == 0) range = 1;

		float linear   = (value - min) / range;
		float centered = linear * 2 - 1;

		#define HANDLE_DPAD(stick, neg, pos, var, value) \
			handle_stick_dpad_event( \
				gamepad, \
				&gamepad->self->state.var, \
				value, \
				Gamepad::stick##_##neg, KEY_GAMEPAD_##stick##_##neg, \
				Gamepad::stick##_##pos, KEY_GAMEPAD_##stick##_##pos)

		#define HANDLE_TRIGGER(trigger, var, value) \
			handle_trigger_event( \
				gamepad, \
				&gamepad->self->state.var, \
				value)

		switch (get_data(gamepad)->mapping)
		{
			case HIDGamepadData::RSTICK_RxRy:
				switch (usage)
				{
					case kHIDUsage_GD_X:  HANDLE_DPAD(LSTICK, LEFT, RIGHT, sticks[0].x,  centered); break;
					case kHIDUsage_GD_Y:  HANDLE_DPAD(LSTICK, UP,   DOWN,  sticks[0].y, -centered); break;
					case kHIDUsage_GD_Rx: HANDLE_DPAD(RSTICK, LEFT, RIGHT, sticks[1].x,  centered); break;
					case kHIDUsage_GD_Ry: HANDLE_DPAD(RSTICK, UP,   DOWN,  sticks[1].y, -centered); break;
					case kHIDUsage_GD_Z:  HANDLE_TRIGGER(LTRIGGER,         triggers[0],  linear);   break;
					case kHIDUsage_GD_Rz: HANDLE_TRIGGER(RTRIGGER,         triggers[1],  linear);   break;
				}
				break;

			case HIDGamepadData::RSTICK_ZRz:
				switch (usage)
				{
					case kHIDUsage_GD_X:  HANDLE_DPAD(LSTICK, LEFT, RIGHT, sticks[0].x,  centered); break;
					case kHIDUsage_GD_Y:  HANDLE_DPAD(LSTICK, UP,   DOWN,  sticks[0].y, -centered); break;
					case kHIDUsage_GD_Z:  HANDLE_DPAD(RSTICK, LEFT, RIGHT, sticks[1].x,  centered); break;
					case kHIDUsage_GD_Rz: HANDLE_DPAD(RSTICK, UP,   DOWN,  sticks[1].y, -centered); break;
					case kHIDUsage_GD_Rx: HANDLE_TRIGGER(LTRIGGER,         triggers[0],  linear);   break;
					case kHIDUsage_GD_Ry: HANDLE_TRIGGER(RTRIGGER,         triggers[1],  linear);   break;
				}
				break;

			default:
				switch (usage)
				{
					case kHIDUsage_GD_X:  HANDLE_DPAD(LSTICK, LEFT, RIGHT, sticks[0].x,  centered); break;
					case kHIDUsage_GD_Y:  HANDLE_DPAD(LSTICK, UP,   DOWN,  sticks[0].y, -centered); break;
				}
				break;
		}

		#undef HANDLE_DPAD
		#undef HANDLE_TRIGGER
	}

	static void
	handle_gamepad_events (
		void* context, IOReturn result, void* sender, IOHIDValueRef valref)
	{
		IOHIDElementRef element = IOHIDValueGetElement(valref);
		if (!element) return;

		Gamepad* gamepad = Gamepad_find(get_device(element));
		if (!gamepad) return;

		uint32_t page  = IOHIDElementGetUsagePage(element);
		uint32_t usage = IOHIDElementGetUsage(element);
		CFIndex value  = IOHIDValueGetIntegerValue(valref);

		switch (page)
		{
			case kHIDPage_GenericDesktop:
				switch (usage)
				{
					case kHIDUsage_GD_Hatswitch:
						handle_hatswitch_event(gamepad, element, value);
						break;

					case kHIDUsage_GD_X:
					case kHIDUsage_GD_Y:
					case kHIDUsage_GD_Z:
					case kHIDUsage_GD_Rx:
					case kHIDUsage_GD_Ry:
					case kHIDUsage_GD_Rz:
						handle_analog_event(gamepad, usage, element, value);
						break;
				}
				break;

			case kHIDPage_Button:
			{
				int nth = (int) usage - 1;
				if (0 <= nth && nth < (KEY_GAMEPAD_BUTTON_MAX - KEY_GAMEPAD_BUTTON_0))
				{
					ulonglong button = Xot::bit<ulonglong>(nth, Gamepad::BUTTON_0);
					int key_code     = KEY_GAMEPAD_BUTTON_0 + nth;
					call_button_event(gamepad, button, key_code, value > 0 ? 1 : 0);
				}
				break;
			}
		}
	}

	static IOHIDManagerRef manager = NULL;

	static void
	add_connected_gamepads (Application* app)
	{
		std::shared_ptr<const __CFSet> set(
			IOHIDManagerCopyDevices(manager),
			Xot::safe_cfrelease);
		if (!set) return;

		CFIndex count = CFSetGetCount(set.get());
		std::vector<IOHIDDeviceRef> devices(count, NULL);
		CFSetGetValues(set.get(), (const void**) &devices[0]);

		for (CFIndex i = 0; i < count; ++i)
			handle_connect_event(app, kIOReturnSuccess, manager, devices[i]);
	}

	void
	init_hid_gamepads (Application* app)
	{
		if (manager)
			invalid_state_error(__FILE__, __LINE__);

		manager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
		if (!manager)
			system_error(__FILE__, __LINE__);

		add_connected_gamepads(app);

		NSDictionary* gamepad =
		@{
			@kIOHIDDeviceUsagePageKey: @(kHIDPage_GenericDesktop),
			@kIOHIDDeviceUsageKey:     @(kHIDUsage_GD_GamePad)
		};
		NSDictionary* joystick =
		@{
			@kIOHIDDeviceUsagePageKey: @(kHIDPage_GenericDesktop),
			@kIOHIDDeviceUsageKey:     @(kHIDUsage_GD_Joystick)
		};
		NSArray* matchings = @[gamepad, joystick];
		IOHIDManagerSetDeviceMatchingMultiple(
			manager, (__bridge CFArrayRef) matchings);

		IOHIDManagerRegisterDeviceMatchingCallback(
			manager, handle_connect_event, app);
		IOHIDManagerRegisterInputValueCallback(
			manager, handle_gamepad_events, app);

		IOHIDManagerScheduleWithRunLoop(
			manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);

		IOReturn ret = IOHIDManagerOpen(manager, kIOHIDOptionsTypeNone);
		if (ret != kIOReturnSuccess)
			system_error(__FILE__, __LINE__);
	}

	void
	fin_hid_gamepads (Application* app)
	{
		if (!manager)
			invalid_state_error(__FILE__, __LINE__);

		IOHIDManagerUnscheduleFromRunLoop(
			manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
		IOHIDManagerClose(manager, kIOHIDOptionsTypeNone);

		CFRelease(manager);
		manager = NULL;
	}


}// Reflex
