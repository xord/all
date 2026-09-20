#include "color_picker.h"


#include "reflex/exception.h"
#include "application.h"


namespace Reflex
{


	void
	ColorPicker_call_color_event (ColorPicker* picker, ColorEvent* event)
	{
		if (!picker)
			argument_error(__FILE__, __LINE__);
		if (!event)
			argument_error(__FILE__, __LINE__);

		Application_guard([&]()
		{
			picker->on_color(event);
		});
	}

	void
	ColorPicker_call_close_event (ColorPicker* picker, Event* event)
	{
		if (!picker)
			argument_error(__FILE__, __LINE__);
		if (!event)
			argument_error(__FILE__, __LINE__);

		Application_guard([&]()
		{
			picker->on_close(event);
		});
	}


	ColorPicker::ColorPicker ()
	{
	}

	ColorPicker::~ColorPicker ()
	{
	}

	void
	ColorPicker::pick_color ()
	{
		ColorPicker_show(this, NULL);
	}

	void
	ColorPicker::pick_color (const Color& initial)
	{
		ColorPicker_show(this, &initial);
	}

	void
	ColorPicker::set_owner (Window* window)
	{
		self->owner = window;
	}

	Window*
	ColorPicker::owner ()
	{
		return self->owner;
	}

	const Window*
	ColorPicker::owner () const
	{
		return const_cast<ColorPicker*>(this)->owner();
	}

	void
	ColorPicker::set_alpha (bool state)
	{
		self->alpha = state;
	}

	bool
	ColorPicker::alpha () const
	{
		return self->alpha;
	}

	void
	ColorPicker::on_color (ColorEvent* e)
	{
	}

	void
	ColorPicker::on_close (Event* e)
	{
	}

	ColorPicker::operator bool () const
	{
		return true;
	}

	bool
	ColorPicker::operator ! () const
	{
		return !operator bool();
	}


}// Reflex
