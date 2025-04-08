#include "gamepad.h"


#include "reflex/exception.h"
#include "application.h"


namespace Reflex
{


	Gamepad::Data::~Data ()
	{
	}

	void
	Gamepad::Data::update_prev ()
	{
		if (prev) prev->self->state = state;
	}

	const char*
	Gamepad::Data::name () const
	{
		return "Unknown";
	}

	bool
	Gamepad::Data::is_valid () const
	{
		return true;
	}

	bool
	Gamepad::Data::has_handle (void* handle) const
	{
		return false;
	}


	static Gamepad_CreateFun gamepad_create_fun = NULL;

	void
	Gamepad_set_create_fun (Gamepad_CreateFun fun)
	{
		gamepad_create_fun = fun;
	}

	Gamepad*
	Gamepad_create ()
	{
		return gamepad_create_fun ? gamepad_create_fun() : new Gamepad();
	}

	static Gamepad::List gamepads;

	void
	Gamepad_add (Application* app, Gamepad* gamepad)
	{
		if (!gamepad)
			argument_error(__FILE__, __LINE__);

		gamepads.emplace_back(gamepad);

		Application_call_device_connect(app, gamepad);
	}

	void
	Gamepad_remove (Application* app, Gamepad* gamepad)
	{
		if (!gamepad) return;

		auto it = std::find(gamepads.begin(), gamepads.end(), gamepad);
		if (it == gamepads.end()) return;

		Application_call_device_disconnect(app, gamepad);

		gamepads.erase(it);
	}

	void
	Gamepad_remove_all (Application* app)
	{
		for (auto& gamepad : gamepads)
			Gamepad_remove(app, gamepad);
	}

	Gamepad*
	Gamepad_find (void* handle)
	{
		if (!handle)
			return NULL;

		auto it = std::find_if(
			gamepads.begin(), gamepads.end(),
			[&](auto& gamepad) {return gamepad->self->has_handle(handle);});
		if (it == gamepads.end())
			return NULL;

		return it->get();
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
		return self->state.buttons;
	}

	const Point&
	Gamepad::stick (size_t index) const
	{
		if (index >= INDEX_MAX)
			index_error(__FILE__, __LINE__);

		return self->state.sticks[index];
	}

	float
	Gamepad::trigger (size_t index) const
	{
		if (index >= INDEX_MAX)
			index_error(__FILE__, __LINE__);

		return self->state.triggers[index];
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


}// Reflex
