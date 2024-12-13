// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_POINTER_H__
#define __REFLEX_SRC_POINTER_H__


#include <functional>
#include "reflex/pointer.h"


namespace Reflex
{


	void Pointer_update_positions (Pointer* it, std::function<void(Point*)> fun);

	void Pointer_set_id (Pointer* it, Pointer::ID id);

	void Pointer_add_flag (Pointer* it, uint flag);

	void Pointer_remove_flag (Pointer* it, uint flag);

	uint Pointer_mask_flag (const Pointer& it, uint mask);

	void Pointer_set_prev (Pointer* it, const Pointer* prev);

	void Pointer_set_down (Pointer* it, const Pointer* down);

	void               Pointer_set_system_id (Pointer* it, Pointer::ID id);

	const Pointer::ID* Pointer_get_system_id (const Pointer& it);

	void         Pointer_set_prev_position (Pointer* it, const Point& position);

	const Point* Pointer_get_prev_position (const Pointer& it);


}// Reflex


#endif//EOH
