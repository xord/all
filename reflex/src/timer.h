// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_TIMER_H__
#define __REFLEX_SRC_TIMER_H__


#include <vector>
#include <list>
#include <reflex/timer.h>


namespace Reflex
{


	class Timers
	{

		public:

			typedef std::vector<Timer::Ref> TimerList;

			Timers ();

			Timer* add (View* owner, float interval, int count = 1);

			void remove (Timer* timer);

			void fire (double now);

			void find_timers (
				TimerList* result, const Selector& selector, bool recuesive = false) const;

		private:

			typedef std::list<Timer::Ref> List;

			List timers;

			int next_id;

			void add (Timer* timer);

	};// Timers


	typedef Timer* (*Timer_CreateFun) ();

	void Timer_set_create_fun (Timer_CreateFun fun);


}// Reflex


#endif//EOH
