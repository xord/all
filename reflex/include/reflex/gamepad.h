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

			typedef Xot::Ref<Gamepad> Ref;

			typedef std::vector<Ref>  List;

			enum Index
			{

				INDEX_LEFT = 0, INDEX_RIGHT, INDEX_MAX

			};// Index

			enum Button
			{

				LEFT         = Xot::bit<ulonglong>(0),

				RIGHT        = Xot::bit<ulonglong>(1),

				UP           = Xot::bit<ulonglong>(2),

				DOWN         = Xot::bit<ulonglong>(3),

				LSTICK_LEFT  = Xot::bit<ulonglong>(4),

				LSTICK_RIGHT = Xot::bit<ulonglong>(5),

				LSTICK_UP    = Xot::bit<ulonglong>(6),

				LSTICK_DOWN  = Xot::bit<ulonglong>(7),

				RSTICK_LEFT  = Xot::bit<ulonglong>(8),

				RSTICK_RIGHT = Xot::bit<ulonglong>(9),

				RSTICK_UP    = Xot::bit<ulonglong>(10),

				RSTICK_DOWN  = Xot::bit<ulonglong>(11),

				BUTTON_A     = Xot::bit<ulonglong>(12),

				BUTTON_B     = Xot::bit<ulonglong>(13),

				BUTTON_X     = Xot::bit<ulonglong>(14),

				BUTTON_Y     = Xot::bit<ulonglong>(15),

				LSHOULDER    = Xot::bit<ulonglong>(16),

				RSHOULDER    = Xot::bit<ulonglong>(17),

				LTRIGGER     = Xot::bit<ulonglong>(18),

				RTRIGGER     = Xot::bit<ulonglong>(19),

				LTHUMB       = Xot::bit<ulonglong>(20),

				RTHUMB       = Xot::bit<ulonglong>(21),

				LPADDLE_0    = Xot::bit<ulonglong>(22),

				LPADDLE_1    = Xot::bit<ulonglong>(23),

				RPADDLE_0    = Xot::bit<ulonglong>(24),

				RPADDLE_1    = Xot::bit<ulonglong>(25),

				HOME         = Xot::bit<ulonglong>(26),

				MENU         = Xot::bit<ulonglong>(27),

				OPTION       = Xot::bit<ulonglong>(28),

				SHARE        = Xot::bit<ulonglong>(29),

				START        = Xot::bit<ulonglong>(30),

				SELECT       = Xot::bit<ulonglong>(31),

				BUTTON_TOUCH = Xot::bit<ulonglong>(32),

				BUTTON_0     = Xot::bit<ulonglong>(33),

				BUTTON_1     = Xot::bit<ulonglong>(34),

				BUTTON_2     = Xot::bit<ulonglong>(35),

				BUTTON_3     = Xot::bit<ulonglong>(36),

				BUTTON_4     = Xot::bit<ulonglong>(37),

				BUTTON_5     = Xot::bit<ulonglong>(38),

				BUTTON_6     = Xot::bit<ulonglong>(39),

				BUTTON_7     = Xot::bit<ulonglong>(40),

				BUTTON_8     = Xot::bit<ulonglong>(41),

				BUTTON_9     = Xot::bit<ulonglong>(42),

				BUTTON_10    = Xot::bit<ulonglong>(43),

				BUTTON_11    = Xot::bit<ulonglong>(44),

				BUTTON_12    = Xot::bit<ulonglong>(45),

				BUTTON_13    = Xot::bit<ulonglong>(46),

				BUTTON_14    = Xot::bit<ulonglong>(47),

				BUTTON_15    = Xot::bit<ulonglong>(48),

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
