// -*- c++ -*-
#pragma once
#ifndef __REFLEX_CONSTRAINT_H__
#define __REFLEX_CONSTRAINT_H__


#include <xot/ref.h>
#include <xot/pimpl.h>
#include <rays/point.h>
#include <reflex/defs.h>


namespace Reflex
{


	class View;
	class Pin;


	class Constraint : public Xot::RefCountable<>
	{

		typedef Constraint This;

		public:

			typedef Xot::Ref<This> Ref;

			virtual ~Constraint ();

			virtual void remove ();

			virtual const Pin& pin (size_t index) const;

			virtual       View* view (size_t index);

			virtual const View* view (size_t index) const;

			virtual void set_spring (float hertz);

			virtual float    spring () const;

			virtual void set_damping (float ratio);

			virtual float    damping () const;

			virtual void set_collide (bool state);

			virtual bool can_collide () const;

			virtual bool is_removed () const;

			virtual operator bool () const;

			virtual bool operator ! () const;

			struct Data;

			Xot::PImpl<Data> self;

		protected:

			Constraint (Data* data);

	};// Constraint


	class SnapConstraint : public Constraint
	{

		typedef Constraint Super;

		public:

			virtual ~SnapConstraint ();

			virtual void   set_angle (float min_degree, float max_degree);

			virtual void clear_angle ();

			virtual float      angle_min () const;

			virtual float      angle_max () const;

			virtual bool   has_angle () const;

			virtual void   set_motor (float degree_per_second);

			virtual void clear_motor ();

			virtual float      motor () const;

			virtual bool   has_motor () const;

		protected:

			SnapConstraint ();

			friend class Pin;

	};// SnapConstraint


	class LinkConstraint : public Constraint
	{

		typedef Constraint Super;

		public:

			virtual ~LinkConstraint ();

			virtual void      set_distance (coord distance);

			virtual void    clear_distance ();

			virtual coord         distance () const;

			virtual bool      has_distance () const;

			virtual coord current_distance () const;

			virtual void   set_range (coord min, coord max);

			virtual void clear_range ();

			virtual coord      range_min () const;

			virtual coord      range_max () const;

			virtual bool   has_range () const;

			virtual void   set_motor (coord pixel_per_second);

			virtual void clear_motor ();

			virtual coord      motor () const;

			virtual bool   has_motor () const;

		protected:

			LinkConstraint ();

			friend class Pin;

	};// LinkConstraint


	class RailConstraint : public Constraint
	{

		typedef Constraint Super;

		public:

			virtual ~RailConstraint ();

			virtual void     set_axis (coord x, coord y);

			virtual void     set_axis (const Point& direction);

			virtual const Point& axis () const;

			virtual void set_rotate (bool state);

			virtual bool can_rotate () const;

			virtual void   set_range (coord min, coord max);

			virtual void clear_range ();

			virtual coord      range_min () const;

			virtual coord      range_max () const;

			virtual bool   has_range () const;

			virtual void   set_motor (float speed);

			virtual void clear_motor ();

			virtual float      motor () const;

			virtual bool   has_motor () const;

		protected:

			RailConstraint ();

			friend class Pin;

	};// RailConstraint


	class ChaseConstraint : public Constraint
	{

		typedef Constraint Super;

		public:

			virtual ~ChaseConstraint ();

			virtual void   set_target (const Pin& target);

			virtual const Pin& target () const;

			virtual void   set_force (float max_force);

			virtual void clear_force ();

			virtual float      force () const;

			virtual bool   has_force () const;

		protected:

			ChaseConstraint ();

			friend class Pin;

	};// ChaseConstraint


}// Reflex


#endif//EOH
