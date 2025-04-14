#include "reflex/timer.h"
#include "timer.h"


#include <assert.h>
#include "reflex/view.h"
#include "reflex/event.h"
#include "reflex/exception.h"
#include "selector.h"


namespace Reflex
{


	struct Timer::Data
	{

		View* owner;

		int id, count;

		float interval;

		double next_time;

		SelectorPtr pselector;

		Data ()
		:	owner(NULL), id(ID_INVALID), count(1), interval(-1), next_time(-1)
		{
		}

		Selector& selector ()
		{
			if (!pselector) pselector.reset(new Selector);
			return *pselector;
		}

	};// Data


	static Timer_CreateFun timer_create_fun = NULL;

	void
	Timer_set_create_fun (Timer_CreateFun fun)
	{
		timer_create_fun = fun;
	}

	static Timer*
	Timer_create ()
	{
		return timer_create_fun ? timer_create_fun() : new Timer();
	}


	Timer::Timer ()
	{
	}

	Timer::~Timer ()
	{
	}

	void
	Timer::fire ()
	{
		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		TimerEvent e(this);
		self->owner->on_timer(&e);
	}

	void
	Timer::stop ()
	{
		set_count(0);
	}

	View*
	Timer::owner () const
	{
		return self->owner;
	}

	int
	Timer::id () const
	{
		return self->id;
	}

	float
	Timer::interval () const
	{
		return self->interval;
	}

	void
	Timer::set_count (int count)
	{
		self->count = count;
	}

	int
	Timer::count () const
	{
		return self->count;
	}

	bool
	Timer::is_finished () const
	{
		return self->count == 0;
	}

	Timer::operator bool () const
	{
		const Data* p = self.get();
		return p->owner && p->id != ID_INVALID && p->interval >= 0;
	}

	bool
	Timer::operator ! () const
	{
		return !operator bool();
	}

	bool
	operator == (const Timer& lhs, const Timer& rhs)
	{
		return lhs.self.get() == rhs.self.get();
	}

	bool
	operator != (const Timer& lhs, const Timer& rhs)
	{
		return !operator==(lhs, rhs);
	}

	SelectorPtr*
	Timer::get_selector_ptr ()
	{
		return &self->pselector;
	}


	Timers::Timers ()
	:	next_id(Timer::ID_FIRST)
	{
	}

	void
	Timers::add (Timer* timer)
	{
		assert(timer && *timer);

		for (auto it = timers.begin(), end = timers.end(); it != end; ++it)
		{
			if (timer->self->next_time < (*it)->self->next_time)
			{
				timers.insert(it, timer);
				return;
			}
		}

		timers.push_back(timer);
	}

	static void
	update_next_time (Timer* timer)
	{
		assert(timer && *timer);

		timer->self->next_time = Xot::time() + timer->self->interval;
	}

	static void
	setup_timer (Timer* timer, View* owner, int id, float interval, int count)
	{
		assert(timer);

		Timer::Data* self = timer->self.get();

		self->owner    = owner;
		self->id       = id;
		self->interval = interval;
		self->count    = count;

		update_next_time(timer);
	}

	Timer*
	Timers::add (View* owner, float interval, int count)
	{
		if (!owner)
			argument_error(__FILE__, __LINE__);

		Timer* timer = Timer_create();
		if (!timer)
			reflex_error(__FILE__, __LINE__, "failed to create timer.");

		setup_timer(timer, owner, next_id++, interval, count);
		add(timer);
		return timer;
	}

	void
	Timers::remove (Timer* timer)
	{
		if (!timer)
			argument_error(__FILE__, __LINE__);

		for (auto it = timers.begin(), end = timers.end(); it != end; ++it)
		{
			if (timer->id() == (*it)->id())
				timers.erase(it);
		}
	}

	static bool
	is_time_to_fire (Timer* timer, double now)
	{
		assert(timer);

		return now >= timer->self->next_time;
	}

	static void
	fire_timer (Timer* timer)
	{
		assert(timer);

		if (timer->is_finished())
			return;

		if (timer->self->count > 0)
			--timer->self->count;

		timer->fire();

		if (!timer->is_finished())
			update_next_time(timer);
	}

	static bool
	compare_timer (const Timer::Ref& lhs, const Timer::Ref& rhs)
	{
		return lhs->is_finished() || lhs->self->next_time < rhs->self->next_time;
	}

	void
	Timers::fire (double now)
	{
		for (auto it = timers.begin(), end = timers.end(); it != end; ++it)
		{
			Timer* timer = it->get();
			if (!is_time_to_fire(timer, now))
				break;

			fire_timer(timer);
		}

		timers.sort(compare_timer);

		while (!timers.empty() && timers.front()->is_finished())
			timers.pop_front();
	}

	void
	Timers::find_timers (
		TimerList* result, const Selector& selector, bool recursive) const
	{
		if (!result)
			argument_error(__FILE__, __LINE__);

		not_implemented_error(__FILE__, __LINE__);
	}


}// Reflex
