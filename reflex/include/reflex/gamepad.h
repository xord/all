// -*- c++ -*-
#pragma once
#ifndef __REFLEX_GAMEPAD_H__
#define __REFLEX_GAMEPAD_H__


#include <xot/ref.h>
#include <xot/pimpl.h>
#include <xot/util.h>
#include <reflex/device.h>
#include <reflex/event.h>


namespace Reflex
{


	class Gamepad : public Device
	{

		public:

			typedef Xot::Ref<Gamepad>         Ref;

			typedef std::vector<Gamepad::Ref> List;

			enum {INDEX_LEFT = 0, INDEX_RIGHT, INDEX_MAX};

			enum Button
			{

				LEFT         = Xot::bit(0),

				RIGHT        = Xot::bit(1),

				UP           = Xot::bit(2),

				DOWN         = Xot::bit(3),

				LSTICK_LEFT  = Xot::bit(4),

				LSTICK_RIGHT = Xot::bit(5),

				LSTICK_UP    = Xot::bit(6),

				LSTICK_DOWN  = Xot::bit(7),

				RSTICK_LEFT  = Xot::bit(8),

				RSTICK_RIGHT = Xot::bit(9),

				RSTICK_UP    = Xot::bit(10),

				RSTICK_DOWN  = Xot::bit(11),

				BUTTON_A     = Xot::bit(12),

				BUTTON_B     = Xot::bit(13),

				BUTTON_X     = Xot::bit(14),

				BUTTON_Y     = Xot::bit(15),

				BUTTON_TOUCH = Xot::bit(16),

				LSHOULDER    = Xot::bit(17),

				RSHOULDER    = Xot::bit(18),

				LTRIGGER     = Xot::bit(19),

				RTRIGGER     = Xot::bit(20),

				LTHUMB       = Xot::bit(21),

				RTHUMB       = Xot::bit(22),

				LPADDLE_1    = Xot::bit(23),

				LPADDLE_2    = Xot::bit(24),

				RPADDLE_1    = Xot::bit(25),

				RPADDLE_2    = Xot::bit(26),

				HOME         = Xot::bit(27),

				MENU         = Xot::bit(28),

				OPTION       = Xot::bit(29),

				SHARE        = Xot::bit(30),

				START        = Xot::bit(31),

				SELECT       = Xot::bit(32),

				BUTTON_0     = Xot::bit(33),

				BUTTON_1     = Xot::bit(34),

				BUTTON_2     = Xot::bit(35),

				BUTTON_3     = Xot::bit(36),

				BUTTON_4     = Xot::bit(37),

				BUTTON_5     = Xot::bit(38),

				BUTTON_6     = Xot::bit(39),

				BUTTON_7     = Xot::bit(40),

				BUTTON_8     = Xot::bit(41),

				BUTTON_9     = Xot::bit(42),

				BUTTON_10    = Xot::bit(43),

				BUTTON_11    = Xot::bit(44),

				BUTTON_12    = Xot::bit(45),

				BUTTON_13    = Xot::bit(46),

				BUTTON_14    = Xot::bit(47),

				BUTTON_15    = Xot::bit(48),

			};// Button

			Gamepad ();

			virtual ~Gamepad ();

			virtual const char* name () const;

			virtual ulonglong buttons () const;

			virtual const Point& stick (size_t index = INDEX_LEFT) const;

			virtual float trigger      (size_t index = INDEX_LEFT) const;

			const Gamepad* prev () const;

			virtual void on_key      (KeyEvent* e);

			virtual void on_key_down (KeyEvent* e);

			virtual void on_key_up   (KeyEvent* e);

			//virtual void on_stick (StickEvent* e);

			//virtual void on_trigger (TriggerEvent* e);

			virtual operator bool () const;

			static const List& all ();

			struct Data;

			Xot::PImpl<Data> self;

	};// Gamepad


}// Reflex


#endif//EOH
