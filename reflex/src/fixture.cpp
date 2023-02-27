#include "fixture.h"


#include <assert.h>
#include <Box2D/Dynamics/b2Fixture.h>
#include <Box2D/Collision/Shapes/b2CircleShape.h>
#include "reflex/exception.h"
#include "reflex/debug.h"
#include "view.h"
#include "world.h"
#include "body.h"


namespace Reflex
{


	Fixture::Fixture (Body* body, const b2Shape* b2shape, void* userdata)
	:	b2fixture(NULL)
	{
		assert(body);

		b2Body* b2body = Body_get_b2ptr(body);
		assert(b2body);

		b2fixture = b2body->CreateFixture(b2shape, 0);
		if (!b2fixture)
			system_error(__FILE__, __LINE__);

		b2fixture->SetUserData(userdata);
	}

	Fixture::~Fixture ()
	{
		b2fixture->SetUserData(NULL);
		b2fixture->GetBody()->DestroyFixture(b2fixture);
	}

	void
	Fixture::set_density (float density)
	{
		if (density == this->density())
			return;

		for (Fixture* p = this; p; p = p->pnext.get())
			p->b2fixture->SetDensity(density);

		b2fixture->GetBody()->ResetMassData();
	}

	float
	Fixture::density () const
	{
		return b2fixture->GetDensity();
	}

	void
	Fixture::set_friction (float friction)
	{
		if (friction == this->friction())
			return;

		for (Fixture* p = this; p; p = p->pnext.get())
			p->b2fixture->SetFriction(friction);
	}

	float
	Fixture::friction () const
	{
		return b2fixture->GetFriction();
	}

	void
	Fixture::set_restitution (float restitution)
	{
		if (restitution == this->restitution())
			return;

		for (Fixture* p = this; p; p = p->pnext.get())
			p->b2fixture->SetRestitution(restitution);
	}

	float
	Fixture::restitution () const
	{
		return b2fixture->GetRestitution();
	}

	void
	Fixture::set_sensor (bool state)
	{
		if (state == is_sensor())
			return;

		for (Fixture* p = this; p; p = p->pnext.get())
			p->b2fixture->SetSensor(state);
	}

	bool
	Fixture::is_sensor () const
	{
		return b2fixture->IsSensor();
	}

	void
	Fixture::set_category_bits (uint bits)
	{
		if (bits > USHRT_MAX)
		{
			argument_error(
				__FILE__, __LINE__, "category_bits must be less then USHRT_MAX.");
		}

		if (bits == category_bits())
			return;

		for (Fixture* p = this; p; p = p->pnext.get())
		{
			b2Filter f = p->b2fixture->GetFilterData();
			f.categoryBits = bits;
			p->b2fixture->SetFilterData(f);
		}
	}

	uint
	Fixture::category_bits () const
	{
		return b2fixture->GetFilterData().categoryBits;
	}

	void
	Fixture::set_collision_mask (uint mask)
	{
		if (mask > USHRT_MAX)
		{
			argument_error(
				__FILE__, __LINE__, "collision_mask must be less then USHRT_MAX.");
		}

		if (mask == collision_mask())
			return;

		for (Fixture* p = this; p; p = p->pnext.get())
		{
			b2Filter f = b2fixture->GetFilterData();
			f.maskBits = mask;
			b2fixture->SetFilterData(f);
		}
	}

	uint
	Fixture::collision_mask () const
	{
		return b2fixture->GetFilterData().maskBits;
	}

	b2Fixture*
	Fixture::b2ptr ()
	{
		return b2fixture;
	}

	const b2Fixture*
	Fixture::b2ptr () const
	{
		return const_cast<Fixture*>(this)->b2ptr();
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

		to->set_density(       from.density());
		to->set_friction(      from.friction());
		to->set_restitution(   from.restitution());
		to->set_sensor(        from.is_sensor());
		to->set_category_bits( from.category_bits());
		to->set_collision_mask(from.collision_mask());
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

		b2CircleShape b2shape;
		b2shape.m_radius = 1;

		return new Fixture(body, &b2shape);
	}

	bool
	Fixture_is_temporary (const Fixture& fixture)
	{
		return fixture.b2ptr()->GetBody() == Body_get_b2ptr(get_temporary_body());
	}


}// Reflex
