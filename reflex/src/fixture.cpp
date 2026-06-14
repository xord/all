#include "fixture.h"


#include <assert.h>
#include <box2d/box2d.h>
#include "reflex/exception.h"
#include "reflex/debug.h"
#include "view.h"
#include "world.h"
#include "body.h"


namespace Reflex
{


	static b2ShapeDef
	make_shape_def (
		void* data,
		float density     = Fixture::DEFAULT_DENSITY,
		float friction    = Fixture::DEFAULT_FRICTION,
		float restitution = Fixture::DEFAULT_RESTITUTION,
		bool sensor       = false)
	{
		b2ShapeDef def           = b2DefaultShapeDef();
		def.userData             = data;
		def.density              = density;
		def.material.friction    = friction;
		def.material.restitution = restitution;
		def.isSensor             = sensor;
		def.enableSensorEvents   = true;
		def.enableContactEvents  = true;
		return def;
	}


	Fixture::Fixture (Body* body, const b2Circle& circle, void* data)
	:	body(body), data(data)
	{
		assert(body);

		b2ShapeDef def    = make_shape_def(data);
		b2ShapeId b2shape = b2CreateCircleShape(Body_get_id(body), &def, &circle);
		if (!b2Shape_IsValid(b2shape))
			physics_error(__FILE__, __LINE__);

		b2shapes.push_back(b2shape);
	}

	Fixture::Fixture (Body* body, const b2Polygon& polygon, void* data)
	:	body(body), data(data)
	{
		assert(body);

		b2ShapeDef def    = make_shape_def(data);
		b2ShapeId b2shape = b2CreatePolygonShape(Body_get_id(body), &def, &polygon);
		if (!b2Shape_IsValid(b2shape))
			physics_error(__FILE__, __LINE__);

		b2shapes.push_back(b2shape);
	}

	Fixture::Fixture (Body* body, const b2Segment& segment, void* data)
	:	body(body), data(data)
	{
		assert(body);

		b2ShapeDef def    = make_shape_def(data);
		b2ShapeId b2shape = b2CreateSegmentShape(Body_get_id(body), &def, &segment);
		if (!b2Shape_IsValid(b2shape))
			physics_error(__FILE__, __LINE__);

		b2shapes.push_back(b2shape);
	}

	Fixture::Fixture (
		Body* body, const b2Vec2* points, size_t size, bool loop, void* data)
	:	body(body), data(data), chain_loop(loop), chain_points(points, points + size)
	{
		assert(body);

		create_chain(DEFAULT_FRICTION, DEFAULT_RESTITUTION);
	}

	Fixture::~Fixture ()
	{
		destroy_shapes();
	}

	void
	Fixture::set_density (float density)
	{
		if (density == density_)
			return;

		for (Fixture* fix = this; fix; fix = fix->pnext.get())
		{
			fix->density_ = density;
			fix->apply_density(density);
		}

		b2BodyId b2body = Body_get_id(body);
		if (b2Body_IsValid(b2body))
			b2Body_ApplyMassFromShapes(b2body);
	}

	float
	Fixture::density () const
	{
		return density_;
	}

	void
	Fixture::set_friction (float friction)
	{
		if (friction == friction_)
			return;

		for (Fixture* fix = this; fix; fix = fix->pnext.get())
		{
			fix->friction_ = friction;

			if (b2Chain_IsValid(fix->b2chain))
				b2Chain_SetFriction(fix->b2chain, friction);
			else for (auto& b2shape : fix->b2shapes)
			{
				if (b2Shape_IsValid(b2shape))
					b2Shape_SetFriction(b2shape, friction);
			}
		}
	}

	float
	Fixture::friction () const
	{
		return friction_;
	}

	void
	Fixture::set_restitution (float restitution)
	{
		if (restitution == restitution_)
			return;

		for (Fixture* fix = this; fix; fix = fix->pnext.get())
		{
			fix->restitution_ = restitution;

			if (b2Chain_IsValid(fix->b2chain))
				b2Chain_SetRestitution(fix->b2chain, restitution);
			else for (auto& b2shape : fix->b2shapes)
			{
				if (b2Shape_IsValid(b2shape))
					b2Shape_SetRestitution(b2shape, restitution);
			}
		}
	}

	float
	Fixture::restitution () const
	{
		return restitution_;
	}

	void
	Fixture::set_sensor (bool sensor)
	{
		if (sensor == sensor_)
			return;

		for (Fixture* fix = this; fix; fix = fix->pnext.get())
		{
			fix->sensor_ = sensor;
			fix->apply_sensor(sensor);
		}
	}

	bool
	Fixture::is_sensor () const
	{
		return sensor_;
	}

	void
	Fixture::set_next (Fixture* fixture)
	{
		if (fixture)
			Fixture_copy_attributes(fixture, *this);

		pnext.reset(fixture);
	}

	Fixture*
	Fixture::next ()
	{
		return pnext.get();
	}

	const Fixture*
	Fixture::next () const
	{
		return const_cast<Fixture*>(this)->next();
	}

	void
	Fixture::create_chain (float friction, float restitution)
	{
		size_t size = chain_points.size();
		if (size < 2) return;

		const b2Vec2* p = chain_points.data();
		bool loop       = chain_loop;
		std::vector<b2Vec2> points;

		if (loop && size >= 4)
			points.assign(p, p + size);
		else if (loop && size == 3)
		{
			// Box2D 3.x chains need 4+ points, so emulate small loops
			// with an open chain wrapped around by ghost points
			points = {p[2], p[0], p[1], p[2], p[0], p[1]};
			loop   = false;
		}
		else
		{
			// open chains treat the first and last points as ghosts,
			// so duplicate both end points like Box2D 2.x did
			points.reserve(size + 2);
			points.emplace_back(p[0]);
			points.insert(points.end(), p, p + size);
			points.emplace_back(p[size - 1]);
			loop = false;
		}

		b2SurfaceMaterial mat = b2DefaultSurfaceMaterial();
		mat.friction          = friction;
		mat.restitution       = restitution;

		b2ChainDef def         = b2DefaultChainDef();
		def.userData           = data;
		def.points             = points.data();
		def.count              = (int) points.size();
		def.materials          = &mat;
		def.materialCount      = 1;
		def.isLoop             = loop;
		def.enableSensorEvents = true;

		b2chain = b2CreateChain(Body_get_id(body), &def);
		if (!b2Chain_IsValid(b2chain))
			physics_error(__FILE__, __LINE__);

		int count = b2Chain_GetSegmentCount(b2chain);
		b2shapes.resize(count);
		b2Chain_GetSegments(b2chain, b2shapes.data(), count);

		// chain segments are created with contact events disabled
		for (auto& b2shape : b2shapes)
			b2Shape_EnableContactEvents(b2shape, true);
	}

	void
	Fixture::create_chain_sensors (float friction, float restitution)
	{
		size_t size = chain_points.size();
		if (size < 2) return;

		b2ShapeDef def  = make_shape_def(data, density_, friction_, restitution_, true);
		b2BodyId b2body = Body_get_id(body);

		size_t nedges = chain_loop ? size : size - 1;
		for (size_t i = 0; i < nedges; ++i)
		{
			b2Segment seg     = {chain_points[i], chain_points[(i + 1) % size]};
			b2ShapeId b2shape = b2CreateSegmentShape(b2body, &def, &seg);
			if (b2Shape_IsValid(b2shape)) b2shapes.push_back(b2shape);
		}
	}

	void
	Fixture::apply_density (float density)
	{
		if (b2Chain_IsValid(b2chain))
			return;// chains have no mass

		for (auto& b2shape : b2shapes)
		{
			if (b2Shape_IsValid(b2shape))
				b2Shape_SetDensity(b2shape, density, false);
		}
	}

	static void
	cleanup_b2shape (b2ShapeId b2shape, World* world)
	{
		if (world)
			World_end_contacts_for(world, b2shape);

		b2Shape_SetUserData(b2shape, NULL);
	}

	void
	Fixture::apply_sensor (bool sensor)
	{
		if (!chain_points.empty())
		{
			// chains can not be sensors, so recreate the chain
			// as a list of segment sensors
			destroy_shapes();
			if (sensor)
				create_chain_sensors(friction_, restitution_);
			else
				create_chain(friction_, restitution_);
			return;
		}

		b2BodyId b2body = Body_get_id(body);
		World* world    = Body_get_world(body);
		b2ShapeDef def  = make_shape_def(data, density_, friction_, restitution_, sensor);

		for (auto& b2shape : b2shapes)
		{
			if (!b2Shape_IsValid(b2shape)) continue;

			switch (b2Shape_GetType(b2shape))
			{
				case b2_circleShape:
				{
					b2Circle circle = b2Shape_GetCircle(b2shape);
					cleanup_b2shape(b2shape, world);
					b2DestroyShape(b2shape, false);
					b2shape = b2CreateCircleShape(b2body, &def, &circle);
				}
				break;

				case b2_polygonShape:
				{
					b2Polygon polygon = b2Shape_GetPolygon(b2shape);
					cleanup_b2shape(b2shape, world);
					b2DestroyShape(b2shape, false);
					b2shape = b2CreatePolygonShape(b2body, &def, &polygon);
				}
				break;

				case b2_segmentShape:
				{
					b2Segment segment = b2Shape_GetSegment(b2shape);
					cleanup_b2shape(b2shape, world);
					b2DestroyShape(b2shape, false);
					b2shape = b2CreateSegmentShape(b2body, &def, &segment);
				}
				break;

				default: break;
			}
		}
	}

	void
	Fixture::destroy_shapes ()
	{
		World* world = Body_get_world(body);

		for (auto& b2shape : b2shapes)
		{
			if (b2Shape_IsValid(b2shape))
				cleanup_b2shape(b2shape, world);
		}

		if (b2Chain_IsValid(b2chain))
			b2DestroyChain(b2chain);

		for (auto& b2shape : b2shapes)
		{
			if (b2Shape_IsValid(b2shape))
				b2DestroyShape(b2shape, false);
		}

		b2chain = b2_nullChainId;
		b2shapes.clear();
	}

	b2ShapeId
	Fixture::head_shape () const
	{
		return b2shapes.empty() ? b2_nullShapeId : b2shapes[0];
	}


	void
	Fixture_copy_attributes (Fixture* to, const Fixture& from)
	{
		if (!to) return;

		to->set_density(    from.density());
		to->set_friction(   from.friction());
		to->set_restitution(from.restitution());
		to->set_sensor(     from.is_sensor());
	}

	static Body*
	get_temporary_body ()
	{
		static Body* body = NULL;
		if (!body) body = Body_create_temporary();
		return body;
	}

	Fixture*
	Fixture_create_temporary ()
	{
		Body* body = get_temporary_body();
		if (!body)
			invalid_state_error(__FILE__, __LINE__);

		b2Circle b2shape = {{0, 0}, 1};
		return new Fixture(body, b2shape);
	}

	bool
	Fixture_is_temporary (const Fixture& fixture)
	{
		b2ShapeId b2shape = fixture.head_shape();
		if (B2_IS_NULL(b2shape)) return false;

		b2BodyId b2body = b2Shape_GetBody(b2shape);
		b2BodyId tmp    = Body_get_id(get_temporary_body());
		return B2_ID_EQUALS(b2body, tmp);
	}


}// Reflex
