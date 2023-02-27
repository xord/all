// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_STYLE_H__
#define __REFLEX_SRC_STYLE_H__


#include <reflex/style.h>


namespace Reflex
{


	class View;


	bool StyleLength_get_pixel_length (
		coord* pixel_length, const StyleLength& style_length, coord parent_size);


	bool Style_set_owner (Style* style, View* owner);

	bool Style_has_variable_lengths (const Style& style);

	void Style_clear_inherited_values (Style* style);

	void Style_override (Style* overridden, const Style& overrides);

	void Style_apply_to (const Style& style, View* view);

	bool Style_has_width  (const Style& style);

	bool Style_has_height (const Style& style);


}// Reflex


#endif//EOH
