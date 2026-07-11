// -*- c++ -*-
#pragma once
#ifndef __REFLEX_RUBY_CONSTRAINT_H__
#define __REFLEX_RUBY_CONSTRAINT_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <reflex/constraint.h>


RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::Constraint)

RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::SnapConstraint)

RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::LinkConstraint)

RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::RailConstraint)

RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::ChaseConstraint)


namespace Reflex
{


	template <typename T>
	class RubyConstraint : public Rucy::ClassWrapper<T> {};


	REFLEX_EXPORT Rucy::Class constraint_class ();
	// class Reflex::Constraint

	REFLEX_EXPORT Rucy::Class snap_constraint_class ();
	// class Reflex::SnapConstraint

	REFLEX_EXPORT Rucy::Class link_constraint_class ();
	// class Reflex::LinkConstraint

	REFLEX_EXPORT Rucy::Class rail_constraint_class ();
	// class Reflex::RailConstraint

	REFLEX_EXPORT Rucy::Class chase_constraint_class ();
	// class Reflex::ChaseConstraint


}// Reflex


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Reflex::Constraint> ()
	{
		return Reflex::constraint_class();
	}

	template <> inline Class
	get_ruby_class<Reflex::SnapConstraint> ()
	{
		return Reflex::snap_constraint_class();
	}

	template <> inline Class
	get_ruby_class<Reflex::LinkConstraint> ()
	{
		return Reflex::link_constraint_class();
	}

	template <> inline Class
	get_ruby_class<Reflex::RailConstraint> ()
	{
		return Reflex::rail_constraint_class();
	}

	template <> inline Class
	get_ruby_class<Reflex::ChaseConstraint> ()
	{
		return Reflex::chase_constraint_class();
	}

	inline Value
	value (Reflex::Constraint::Ref& ref, Value klass = Reflex::constraint_class())
	{
		return value(ref.get(), klass);
	}


}// Rucy


#endif//EOH
