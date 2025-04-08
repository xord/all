// -*- objc -*-
#include "../gamepad.h"


#include "reflex/exception.h"
#include "../gamepad.h"
#include "application.h"


namespace Reflex
{


	void init_gc_gamepads  (Application* app);

	void  fin_gc_gamepads  (Application* app);

	void init_hid_gamepads (Application* app);

	void  fin_hid_gamepads (Application* app);


	void
	Gamepad_init (Application* app)
	{
		init_gc_gamepads(app);
		init_hid_gamepads(app);
	}

	void
	Gamepad_fin (Application* app)
	{
		fin_gc_gamepads(app);
		fin_hid_gamepads(app);

		Gamepad_remove_all(app);
	}


}// Reflex
