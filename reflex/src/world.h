// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_WORLD_H__
#define __REFLEX_SRC_WORLD_H__


#include <box2d/id.h>
#include <box2d/math_functions.h>
#include <xot/noncopyable.h>
#include <xot/pimpl.h>
#include <rays/point.h>
#include <rays/painter.h>
#include "reflex/defs.h"


namespace Reflex
{


	class View;
	class Body;
	class Constraint;


	class World : public Xot::NonCopyable
	{

		public:

			enum
			{
				DEFAULT_PIXELS_PER_METER = 100
			};

			World (float pixels_per_meter = DEFAULT_PIXELS_PER_METER);

			virtual ~World ();

			void update (float duration = 0);

			float meter2pixel (float meter = 1) const;

			void set_gravity (const Point& gravity);

			Point    gravity () const;

			void set_time_scale (float scale);

			float    time_scale () const;

			void set_debug (bool state = true);

			bool     debug () const;

			virtual void on_update ();

			virtual void on_draw (Painter* painter);

			struct Data;

			Xot::PImpl<Data> self;

	};// World


	template <typename T>
	inline float
	to_b2coord (T t, float scale)
	{
		return t / scale;
	}

	template <typename T>
	inline b2Vec2
	to_b2vec2 (T x, T y, float scale)
	{
		return b2Vec2{
			to_b2coord(x, scale),
			to_b2coord(y, scale)};
	}

	template <typename VEC>
	inline b2Vec2
	to_b2vec2 (const VEC& v, float scale)
	{
		return b2Vec2{
			to_b2coord(v.x, scale),
			to_b2coord(v.y, scale)};
	}

	inline coord
	to_coord (float t, float scale)
	{
		return t * scale;
	}

	inline Point
	to_point (const b2Vec2& v, float scale)
	{
		return Point(
			to_coord(v.x, scale),
			to_coord(v.y, scale));
	}


	b2WorldId World_get_id (const World* world);

	void World_add_constraint    (World* world, Constraint* constraint);

	void World_remove_constraint (World* world, Constraint* constraint);

	void World_end_contacts_for (World* world, b2ShapeId b2shape);

	bool World_is_stepping (const World* world);

	const Body* World_get_ground (World* world);

	World* World_get_temporary ();


}// Reflex


#endif//EOH
