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


	typedef SnapConstraint*  (*SnapConstraint_CreateFun) ();

	typedef LinkConstraint*  (*LinkConstraint_CreateFun) ();

	typedef WheelConstraint* (*WheelConstraint_CreateFun) ();

	typedef ChaseConstraint* (*ChaseConstraint_CreateFun) ();

	void SnapConstraint_set_create_fun  (SnapConstraint_CreateFun fun);

	void LinkConstraint_set_create_fun  (LinkConstraint_CreateFun fun);

	void WheelConstraint_set_create_fun (WheelConstraint_CreateFun fun);

	void ChaseConstraint_set_create_fun (ChaseConstraint_CreateFun fun);

	SnapConstraint*  SnapConstraint_create ();

	LinkConstraint*  LinkConstraint_create ();

	WheelConstraint* WheelConstraint_create ();

	ChaseConstraint* ChaseConstraint_create ();


}// Reflex


#endif//EOH
