// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_FIXTURE_H__
#define __REFLEX_SRC_FIXTURE_H__


#include <memory>
#include <vector>
#include <box2d/id.h>
#include <box2d/collision.h>
#include <xot/noncopyable.h>
#include "reflex/defs.h"


namespace Reflex
{


	class Body;


	class Fixture : public Xot::NonCopyable
	{

		public:

			static constexpr float DEFAULT_DENSITY     = 1;

			static constexpr float DEFAULT_FRICTION    = 0.6f;// Box2D 3.x defaults

			static constexpr float DEFAULT_RESTITUTION = 0;

			Fixture (Body* body, const b2Circle& circle, void* data = NULL);

			Fixture (Body* body, const b2Polygon& polygon, void* data = NULL);

			Fixture (Body* body, const b2Segment& segment, void* data = NULL);

			Fixture (
				Body* body, const b2Vec2* points, size_t size, bool loop,
				void* data = NULL);

			~Fixture ();

			void set_density (float density);

			float    density () const;

			void set_friction (float friction);

			float    friction () const;

			void set_restitution (float restitution);

			float    restitution () const;

			void set_sensor (bool state);

			bool  is_sensor () const;

			void       set_next (Fixture* fixture);

			      Fixture* next ();

			const Fixture* next () const;

		private:

			typedef std::vector<b2Vec2>    b2Vec2List;

			typedef std::vector<b2ShapeId> b2ShapeIdList;

			Body* body         = NULL;

			void* data         = NULL;

			float density_     = DEFAULT_DENSITY;

			float friction_    = DEFAULT_FRICTION;

			float restitution_ = DEFAULT_RESTITUTION;

			bool sensor_       = false;

			b2ShapeIdList b2shapes;

			b2ChainId b2chain      = b2_nullChainId;

			bool        chain_loop = false;

			b2Vec2List  chain_points;

			std::unique_ptr<Fixture> pnext;

			void create_chain (float friction, float restitution);

			void create_chain_sensors (float friction, float restitution);

			void apply_density (float density);

			void apply_sensor (bool state);

			void destroy_shapes ();

			b2ShapeId head_shape () const;

			friend bool Fixture_is_temporary (const Fixture& fixture);

	};// Fixture


	void Fixture_copy_attributes (Fixture* to, const Fixture& from);

	Fixture* Fixture_create_temporary ();

	bool Fixture_is_temporary (const Fixture& fixture);


}// Reflex


#endif//EOH
