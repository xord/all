// -*- objc -*-
#include "../gamepad.h"


#include <memory>
#include <vector>
#include <map>
#import <IOKit/hid/IOHIDManager.h>
#import <IOKit/hid/IOHIDDevice.h>
#import <GameController/GameController.h>
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

		IOHIDDeviceRef device;

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

	static std::map<IOHIDElementRef, IOHIDDeviceRef> element2device;

	static void
	register_to_device_map (IOHIDDeviceRef device)
	{
		if (@available(macOS 11.0, *))
			return;

		std::shared_ptr<const __CFArray> elements(
			IOHIDDeviceCopyMatchingElements(device, NULL, kIOHIDOptionsTypeNone),
			Xot::safe_cfrelease);
		if (!elements) return;

		CFIndex count = CFArrayGetCount(elements.get());
		for (CFIndex i = 0; i < count; ++i)
		{
			IOHIDElementRef element =
				(IOHIDElementRef) CFArrayGetValueAtIndex(elements.get(), i);
			element2device[element] = device;
		}
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

	static void
	add_gamepad (Application* app, IOHIDDeviceRef device)
	{
		Gamepad_add(app, Gamepad_create(device));
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
	call_gamepad_event (int code, bool pressed)
	{
		Window* win = Window_get_active();
		if (!win) return;

		auto action = pressed ? KeyEvent::DOWN : KeyEvent::UP;
		KeyEvent e(action, NULL, code, get_key_modifiers(), 0);
		Window_call_key_event(win, &e);
	}

	static void
	handle_hatswitch_events (
		Gamepad* gamepad, IOHIDElementRef element, CFIndex hatswitch)
	{
		static std::map<void*, CFIndex> prev_hatswitches;

		CFIndex prev_hatswitch = 8;// neutral
		auto it = prev_hatswitches.find(gamepad);
		if (it != prev_hatswitches.end()) prev_hatswitch = it->second;

		uint prev_dpad = to_dpad(prev_hatswitch);
		uint      dpad = to_dpad(     hatswitch);
		uint diff      = prev_dpad ^ dpad;
		if (diff & DPAD_UP)    call_gamepad_event(KEY_GAMEPAD_UP,    dpad & DPAD_UP);
		if (diff & DPAD_RIGHT) call_gamepad_event(KEY_GAMEPAD_RIGHT, dpad & DPAD_RIGHT);
		if (diff & DPAD_DOWN)  call_gamepad_event(KEY_GAMEPAD_DOWN,  dpad & DPAD_DOWN);
		if (diff & DPAD_LEFT)  call_gamepad_event(KEY_GAMEPAD_LEFT,  dpad & DPAD_LEFT);

		prev_hatswitches[gamepad] = hatswitch;
	}

	static void
	handle_gamepad_events (
		void* context, IOReturn result, void* sender, IOHIDValueRef value)
	{
		IOHIDElementRef element = IOHIDValueGetElement(value);
		if (!element) return;

		Gamepad* gamepad = Gamepad_find(get_device(element));
		if (!gamepad) return;

		uint32_t page  = IOHIDElementGetUsagePage(element);
		uint32_t usage = IOHIDElementGetUsage(element);
		CFIndex intval = IOHIDValueGetIntegerValue(value);

		switch (page)
		{
			case kHIDPage_GenericDesktop:
				switch (usage)
				{
					case kHIDUsage_GD_Hatswitch:
						handle_hatswitch_events(gamepad, element, intval);
						break;

					case kHIDUsage_GD_X:  break;
					case kHIDUsage_GD_Y:  break;
					case kHIDUsage_GD_Rx: break;
					case kHIDUsage_GD_Ry: break;
				}
				break;

			case kHIDPage_Button:
			{
				int button = (int) usage - 1;
				if (0 <= button && button <= (KEY_GAMEPAD_BUTTON_MAX - KEY_GAMEPAD_BUTTON_0))
					call_gamepad_event(KEY_GAMEPAD_BUTTON_0 + button, intval != 0);
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
