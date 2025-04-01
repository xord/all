#include "reflex/device.h"



namespace Reflex
{


	Device::~Device ()
	{
	}


	Gamepad::Data::~Data ()
	{
	}

	void
	Gamepad::Data::update_prev ()
	{
		if (!prev)
			invalid_state_error(__FILE__, __LINE__);

		prev->self->state = state;
	}

	bool
	Gamepad::Data::is_valid () const
	{
		return true;
	}


	static Gamepad_CreateFun gamepad_create_fun = NULL;

	Gamepad*
	Gamepad_create ()
	{
		return gamepad_create_fun ? gamepad_create_fun() : new Gamepad();
	}

	void
	Gamepad_set_create_fun (Gamepad_CreateFun fun)
	{
		gamepad_create_fun = fun;
	}


	Gamepad::Gamepad ()
	{
	}

	Gamepad::~Gamepad ()
	{
	}

	const char*
	Gamepad::name () const
	{
		return self->name();
	}

	ulonglong
	Gamepad::buttons () const
	{
		return self->buttons;
	}

	const Point&
	Gamepad::stick (size_t index) const
	{
		if (index >= 2)
			index_error(__FILE__, __LINE__);

		return self->sticks[index];
	}

	float
	Gamepad::trigger (size_t index) const
	{
		if (index >= 2)
			index_error(__FILE__, __LINE__);

		return self->triggers[index];
	}

	const Gamepad*
	Gamepad::prev () const
	{
		return self->prev.get();
	}

	void
	Gamepad::on_key (KeyEvent* e)
	{
	}

	void
	Gamepad::on_key_down (KeyEvent* e)
	{
	}

	void
	Gamepad::on_key_up (KeyEvent* e)
	{
	}

	Gamepad::operator bool () const
	{
		return self->is_valid();
	}

	bool
	Gamepad::operator ! () const
	{
		return !operator bool();
	}


}// Reflex
