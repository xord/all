// -*- c++ -*-
#pragma once
#ifndef __REFLEX_RUBY_SHAPE_H__
#define __REFLEX_RUBY_SHAPE_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <reflex/shape.h>
#include <reflex/ruby/event.h>


namespace Reflex
{


	Rucy::Class shape_class ();
	// class Reflex::Shape

	Rucy::Class polygon_shape_class ();
	// class Reflex::PolygonShape

	Rucy::Class line_shape_class ();
	// class Reflex::LineShape

	Rucy::Class rect_shape_class ();
	// class Reflex::RectShape

	Rucy::Class ellipse_shape_class ();
	// class Reflex::EllipseShape


	template <typename T>
	class RubyShape : public Rucy::ClassWrapper<T>
	{

		typedef Rucy::ClassWrapper<T> Super;

		public:

			virtual void on_draw (DrawEvent* e)
			{
				RUCY_SYM(on_draw);
				if (this->is_overridable())
					this->value.call(on_draw, Rucy::value(e));
				else
					Super::on_draw(e);
			}

			virtual void on_contact (ContactEvent* e)
			{
				RUCY_SYM_B(on_contact);
				if (this->is_overridable())
					this->value.call(on_contact, Rucy::value(e));
				else
					Super::on_contact(e);
			}

			virtual void on_contact_begin (ContactEvent* e)
			{
				RUCY_SYM_B(on_contact_begin);
				if (this->is_overridable())
					this->value.call(on_contact_begin, Rucy::value(e));
				else
					Super::on_contact_begin(e);
			}

			virtual void on_contact_end (ContactEvent* e)
			{
				RUCY_SYM_B(on_contact_end);
				if (this->is_overridable())
					this->value.call(on_contact_end, Rucy::value(e));
				else
					Super::on_contact_end(e);
			}

	};// RubyShape


}// Reflex


RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(Reflex::Shape)

RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(Reflex::PolygonShape)

RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(Reflex::LineShape)

RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(Reflex::RectShape)

RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(Reflex::EllipseShape)


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Reflex::Shape> ()
	{
		return Reflex::shape_class();
	}

	template <> inline Class
	get_ruby_class<Reflex::PolygonShape> ()
	{
		return Reflex::polygon_shape_class();
	}

	template <> inline Class
	get_ruby_class<Reflex::LineShape> ()
	{
		return Reflex::line_shape_class();
	}

	template <> inline Class
	get_ruby_class<Reflex::RectShape> ()
	{
		return Reflex::rect_shape_class();
	}

	template <> inline Class
	get_ruby_class<Reflex::EllipseShape> ()
	{
		return Reflex::ellipse_shape_class();
	}


	inline Value
	value (Reflex::Shape::Ref& ref, Value klass = Reflex::shape_class())
	{
		return value(ref.get(), klass);
	}


}// Rucy


#endif//EOH
