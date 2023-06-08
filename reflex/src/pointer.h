// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_POINTER_H__
#define __REFLEX_SRC_POINTER_H__


#include <functional>
#include "reflex/pointer.h"


namespace Reflex
{


	void Pointer_update_positions (
		Pointer* pthis, std::function<void(Point*)> fun);

	void Pointer_set_id (Pointer* pthis, Pointer::ID id);

	void Pointer_set_view_index (Pointer* pthis, uint view_index);

	void Pointer_set_prev (Pointer* pthis, const Pointer* prev);

	void Pointer_set_down (Pointer* pthis, const Pointer* down);


}// Reflex


#endif//EOH
