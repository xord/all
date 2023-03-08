// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_WORLD_H__
#define __REFLEX_SRC_WORLD_H__


#include <Box2D/Common/b2Math.h>
#include <Box2D/Dynamics/b2WorldCallbacks.h>
#include <xot/noncopyable.h>
#include <xot/pimpl.h>
#include <rays/point.h>
#include <rays/painter.h>
#include <reflex/defs.h>


class b2World;


namespace Reflex
{


	class View;
	class Body;


	class World : public Xot::NonCopyable, private b2ContactFilter, b2ContactListener
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

			virtual void on_update (float dt);

			virtual void on_draw (Painter* painter);

			struct Data;

			Xot::PImpl<Data> self;

		protected:

			virtual bool ShouldCollide (b2Fixture* f1, b2Fixture* f2) override;

			virtual void BeginContact (b2Contact* contact) override;

			virtual void   EndContact (b2Contact* contact) override;

	};// World


	template <typename T>
	inline float32
	to_b2coord (T t, float scale)
	{
		return t / scale;
	}

	template <typename T>
	inline b2Vec2
	to_b2vec2 (T x, T y, float scale)
	{
		return b2Vec2(
			to_b2coord(x, scale),
			to_b2coord(y, scale));
	}

	template <typename VEC>
	inline b2Vec2
	to_b2vec2 (const VEC& v, float scale)
	{
		return b2Vec2(
			to_b2coord(v.x, scale),
			to_b2coord(v.y, scale));
	}

	inline coord
	to_coord (float32 t, float scale)
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


	World* World_get_temporary ();

	      b2World* World_get_b2ptr (      World* world);

	const b2World* World_get_b2ptr (const World* world);


}// Reflex


#endif//EOH
