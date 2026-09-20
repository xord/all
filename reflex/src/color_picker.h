// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_COLOR_PICKER_H__
#define __REFLEX_SRC_COLOR_PICKER_H__


#include <rays/color.h>
#include "reflex/color_picker.h"
#include "reflex/window.h"


namespace Reflex
{


	struct ColorPicker::Data
	{

		Xot::WeakRef<Window> owner;

		bool alpha = false;

	};// ColorPicker::Data


	void ColorPicker_show (ColorPicker* picker, const Color* initial);

	void ColorPicker_call_color_event (ColorPicker* picker, ColorEvent* event);

	void ColorPicker_call_close_event (ColorPicker* picker, Event* event);


}// Reflex


#endif//EOH
