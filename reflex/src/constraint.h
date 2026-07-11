// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_CONSTRAINT_H__
#define __REFLEX_SRC_CONSTRAINT_H__


#include "reflex/constraint.h"


namespace Reflex
{


	class View;
	class World;


	void Constraint_set_pins (
		Constraint* constraint,
		View* view0, const Point* position0,
		View* view1, const Point* position1);

	bool Constraint_activate   (Constraint* constraint);

	void Constraint_deactivate (Constraint* constraint);

	void Constraint_sever (Constraint* constraint);

	void Constraint_on_world_destroyed (Constraint* constraint);

	void Constraint_on_world_update    (Constraint* constraint);

	bool Constraint_has_world_mismatch (const Constraint* constraint);


}// Reflex


#endif//EOH
