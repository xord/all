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


	// Box2D 2.x fixture defaults
	static constexpr float DEFAULT_FRICTION    = 0.2f;
	static constexpr float DEFAULT_RESTITUTION = 0;


	static b2ShapeDef
	make_shape_def (
		void* userdata,
		float density, float friction, float restitution, bool sensor)
	{
		b2ShapeDef def           = b2DefaultShapeDef();
		def.userData             = userdata;
		def.density              = density;
		def.material.friction    = friction;
		def.material.restitution = restitution;
		def.isSensor             = sensor;
		def.enableSensorEvents   = true;
		def.enableContactEvents  = true;
		return def;
	}

	static World*
	get_world (Body* body)
	{
		b2BodyId b2body = Body_get_b2id(body);
		if (!b2Body_IsValid(b2body)) return NULL;

		return (World*) b2World_GetUserData(b2Body_GetWorld(b2body));
	}


	Fixture::Fixture (Body* body, const b2Circle& circle, void* userdata)
	:	body(body), userdata(userdata), b2chain(b2_nullChainId)
	{
		assert(body);

		b2ShapeDef def = make_shape_def(
			userdata, 0, DEFAULT_FRICTION, DEFAULT_RESTITUTION, false);

		b2ShapeId id = b2CreateCircleShape(Body_get_b2id(body), &def, &circle);
		if (!b2Shape_IsValid(id))
			system_error(__FILE__, __LINE__);

		b2shapes.push_back(id);
	}

	Fixture::Fixture (Body* body, const b2Polygon& polygon, void* userdata)
	:	body(body), userdata(userdata), b2chain(b2_nullChainId)
	{
		assert(body);

		b2ShapeDef def = make_shape_def(
			userdata, 0, DEFAULT_FRICTION, DEFAULT_RESTITUTION, false);

		b2ShapeId id = b2CreatePolygonShape(Body_get_b2id(body), &def, &polygon);
		if (!b2Shape_IsValid(id))
			system_error(__FILE__, __LINE__);

		b2shapes.push_back(id);
	}

	Fixture::Fixture (Body* body, const b2Segment& segment, void* userdata)
	:	body(body), userdata(userdata), b2chain(b2_nullChainId)
	{
		assert(body);

		b2ShapeDef def = make_shape_def(
			userdata, 0, DEFAULT_FRICTION, DEFAULT_RESTITUTION, false);

		b2ShapeId id = b2CreateSegmentShape(Body_get_b2id(body), &def, &segment);
		if (!b2Shape_IsValid(id))
			system_error(__FILE__, __LINE__);

		b2shapes.push_back(id);
	}

	Fixture::Fixture (
		Body* body, const b2Vec2* points, size_t size, bool loop,
		void* userdata)
	:	body(body), userdata(userdata), b2chain(b2_nullChainId),
		chain_points(points, points + size), chain_loop(loop)
	{
		assert(body);

		create_chain(DEFAULT_FRICTION, DEFAULT_RESTITUTION);
	}

	Fixture::~Fixture ()
	{
		destroy_shapes();
	}

	void
	Fixture::create_chain (float friction, float restitution)
	{
		size_t size = chain_points.size();
		if (size < 2) return;

		const b2Vec2* p = chain_points.data();
		std::vector<b2Vec2> points;
		bool loop = chain_loop;

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
		def.userData           = userdata;
		def.points             = points.data();
		def.count              = (int) points.size();
		def.materials          = &mat;
		def.materialCount      = 1;
		def.isLoop             = loop;
		def.enableSensorEvents = true;

		b2chain = b2CreateChain(Body_get_b2id(body), &def);
		if (!b2Chain_IsValid(b2chain))
			system_error(__FILE__, __LINE__);

		int count = b2Chain_GetSegmentCount(b2chain);
		b2shapes.resize(count);
		b2Chain_GetSegments(b2chain, b2shapes.data(), count);

		// chain segments are created with contact events disabled
		for (auto& id : b2shapes)
			b2Shape_EnableContactEvents(id, true);
	}

	void
	Fixture::create_chain_sensors (float friction, float restitution)
	{
		size_t size = chain_points.size();
		if (size < 2) return;

		b2ShapeDef def = make_shape_def(
			userdata, density_, friction, restitution, true);

		b2BodyId b2body = Body_get_b2id(body);

		size_t nedges = chain_loop ? size : size - 1;
		for (size_t i = 0; i < nedges; ++i)
		{
			b2Segment seg = {chain_points[i], chain_points[(i + 1) % size]};
			b2ShapeId id  = b2CreateSegmentShape(b2body, &def, &seg);
			if (b2Shape_IsValid(id)) b2shapes.push_back(id);
		}
	}

	void
	Fixture::destroy_shapes ()
	{
		World* world = get_world(body);

		for (auto& id : b2shapes)
		{
			if (!b2Shape_IsValid(id)) continue;

			if (world) World_end_contacts_for(world, id);
			b2Shape_SetUserData(id, NULL);
		}

		if (b2Chain_IsValid(b2chain))
			b2DestroyChain(b2chain);
		else
		{
			for (auto& id : b2shapes)
				if (b2Shape_IsValid(id)) b2DestroyShape(id, false);
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
	Fixture::set_density (float density)
	{
		if (density == this->density())
			return;

		for (Fixture* p = this; p; p = p->pnext.get())
			p->apply_density(density);

		b2BodyId b2body = Body_get_b2id(body);
		if (b2Body_IsValid(b2body))
			b2Body_ApplyMassFromShapes(b2body);
	}

	void
	Fixture::apply_density (float density)
	{
		density_ = density;

		if (b2Chain_IsValid(b2chain))
			return;// chains have no mass

		for (auto& id : b2shapes)
			if (b2Shape_IsValid(id)) b2Shape_SetDensity(id, density, false);
	}

	float
	Fixture::density () const
	{
		b2ShapeId id = head_shape();
		if (b2Chain_IsValid(b2chain) || !b2Shape_IsValid(id))
			return density_;

		return b2Shape_GetDensity(id);
	}

	void
	Fixture::set_friction (float friction)
	{
		if (friction == this->friction())
			return;

		for (Fixture* p = this; p; p = p->pnext.get())
		{
			if (b2Chain_IsValid(p->b2chain))
				b2Chain_SetFriction(p->b2chain, friction);
			else
			{
				for (auto& id : p->b2shapes)
					if (b2Shape_IsValid(id)) b2Shape_SetFriction(id, friction);
			}
		}
	}

	float
	Fixture::friction () const
	{
		b2ShapeId id = head_shape();
		return b2Shape_IsValid(id)
			?	b2Shape_GetFriction(id)
			:	DEFAULT_FRICTION;
	}

	void
	Fixture::set_restitution (float restitution)
	{
		if (restitution == this->restitution())
			return;

		for (Fixture* p = this; p; p = p->pnext.get())
		{
			if (b2Chain_IsValid(p->b2chain))
				b2Chain_SetRestitution(p->b2chain, restitution);
			else
			{
				for (auto& id : p->b2shapes)
					if (b2Shape_IsValid(id)) b2Shape_SetRestitution(id, restitution);
			}
		}
	}

	float
	Fixture::restitution () const
	{
		b2ShapeId id = head_shape();
		return b2Shape_IsValid(id)
			?	b2Shape_GetRestitution(id)
			:	DEFAULT_RESTITUTION;
	}

	void
	Fixture::set_sensor (bool state)
	{
		if (state == is_sensor())
			return;

		// Box2D 3.x can not change the sensor flag after creation,
		// so recreate shapes with the new flag
		for (Fixture* p = this; p; p = p->pnext.get())
			p->apply_sensor(state);
	}

	void
	Fixture::apply_sensor (bool state)
	{
		float fri = friction();
		float res = restitution();

		if (!chain_points.empty())
		{
			// chains can not be sensors, so recreate the chain
			// as a list of segment sensors
			destroy_shapes();
			if (state)
				create_chain_sensors(fri, res);
			else
				create_chain(fri, res);
			return;
		}

		World*   world  = get_world(body);
		b2BodyId b2body = Body_get_b2id(body);

		for (auto& id : b2shapes)
		{
			if (!b2Shape_IsValid(id)) continue;

			b2ShapeDef def = make_shape_def(
				userdata,
				b2Shape_GetDensity(id), b2Shape_GetFriction(id),
				b2Shape_GetRestitution(id), state);

			b2ShapeType type = b2Shape_GetType(id);
			b2Circle  circle;
			b2Polygon polygon;
			b2Segment segment;
			switch (type)
			{
				case b2_circleShape:  circle  = b2Shape_GetCircle(id);  break;
				case b2_polygonShape: polygon = b2Shape_GetPolygon(id); break;
				case b2_segmentShape: segment = b2Shape_GetSegment(id); break;
				default: continue;
			}

			if (world) World_end_contacts_for(world, id);
			b2Shape_SetUserData(id, NULL);
			b2DestroyShape(id, false);

			switch (type)
			{
				case b2_circleShape:
					id = b2CreateCircleShape(b2body, &def, &circle);
					break;

				case b2_polygonShape:
					id = b2CreatePolygonShape(b2body, &def, &polygon);
					break;

				case b2_segmentShape:
					id = b2CreateSegmentShape(b2body, &def, &segment);
					break;

				default: break;
			}
		}
	}

	bool
	Fixture::is_sensor () const
	{
		b2ShapeId id = head_shape();
		return b2Shape_IsValid(id) ? b2Shape_IsSensor(id) : false;
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
	Fixture_copy_attributes (Fixture* to, const Fixture& from)
	{
		if (!to)
			return;

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
		b2ShapeId id = fixture.head_shape();
		if (!b2Shape_IsValid(id)) return false;

		b2BodyId b2body   = b2Shape_GetBody(id);
		b2BodyId tmp_body = Body_get_b2id(get_temporary_body());
		return B2_ID_EQUALS(b2body, tmp_body);
	}


}// Reflex
