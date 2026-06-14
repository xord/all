#include "body.h"


#include <assert.h>
#include <box2d/box2d.h>
#include <xot/util.h>
#include "reflex/exception.h"
#include "world.h"


namespace Reflex
{


	struct Body::Data
	{

		b2BodyId b2body = b2_nullBodyId;

		float ppm       = 0;

		~Data ()
		{
			if (b2Body_IsValid(b2body))
				b2DestroyBody(b2body);
		}

		bool is_valid () const
		{
			return B2_IS_NON_NULL(b2body) && ppm > 0;
		}

	};// Body::Data


	static inline void
	validate (const Body* body, bool check_stepping = false)
	{
		if (!body->self->is_valid())
			invalid_state_error(__FILE__, __LINE__);

		if (check_stepping && World_is_stepping(Body_get_world(body)))
			physics_error(__FILE__, __LINE__);
	}


	Body::Body (World* world, const Point& position, float angle)
	{
		assert(world);

		if (World_is_stepping(world))
			physics_error(__FILE__, __LINE__);

		float ppm = world->meter2pixel();
		assert(ppm > 0);

		b2BodyDef def = b2DefaultBodyDef();
		def.position  = to_b2vec2(position, ppm);
		def.rotation  = b2MakeRot(Xot::deg2rad(angle));

		b2BodyId b2body = b2CreateBody(World_get_id(world), &def);
		if (!b2Body_IsValid(b2body))
			physics_error(__FILE__, __LINE__);

		self->b2body = b2body;
		self->ppm    = ppm;
	}

	Body::~Body ()
	{
		assert(!World_is_stepping(Body_get_world(this)));
	}

	void
	Body::apply_force (coord x, coord y)
	{
		apply_force(Point(x, y));
	}

	void
	Body::apply_force (const Point& force)
	{
		validate(this);

		b2Body_ApplyForceToCenter(self->b2body, to_b2vec2(force, self->ppm), true);
	}

	void
	Body::apply_torque (float torque)
	{
		validate(this);

		b2Body_ApplyTorque(self->b2body, torque, true);
	}

	void
	Body::apply_linear_impulse (coord x, coord y)
	{
		apply_linear_impulse(Point(x, y));
	}

	void
	Body::apply_linear_impulse (const Point& impulse)
	{
		validate(this);

		b2Body_ApplyLinearImpulseToCenter(
			self->b2body, to_b2vec2(impulse, self->ppm), true);
	}

	void
	Body::apply_angular_impulse (float impulse)
	{
		validate(this);

		b2Body_ApplyAngularImpulse(self->b2body, impulse, true);
	}

	void
	Body::awake ()
	{
		validate(this);

		b2Body_SetAwake(self->b2body, true);
	}

	float
	Body::meter2pixel (float meter) const
	{
		return meter * self->ppm;
	}

	void
	Body::set_transform (coord x, coord y, float degree)
	{
		validate(this, true);

		b2Body_SetTransform(
			self->b2body, to_b2vec2(x, y, self->ppm), b2MakeRot(Xot::deg2rad(degree)));
	}

	void
	Body::set_transform (const Point& position, float degree)
	{
		set_transform(position.x, position.y, degree);
	}

	Point
	Body::position () const
	{
		validate(this);

		return to_point(b2Body_GetPosition(self->b2body), self->ppm);
	}

	float
	Body::angle () const
	{
		validate(this);

		return Xot::rad2deg(b2Rot_GetAngle(b2Body_GetRotation(self->b2body)));
	}

	static bool
	is_body_dynamic (const Body* body)
	{
		assert(body);

		return b2Body_GetType(body->self->b2body) == b2_dynamicBody;
	}

	void
	Body::set_dynamic (bool dynamic)
	{
		if (dynamic == is_body_dynamic(this))
			return;

		validate(this, true);

		b2Body_SetType(self->b2body, dynamic ? b2_dynamicBody : b2_staticBody);
	}

	bool
	Body::is_dynamic () const
	{
		validate(this);

		return is_body_dynamic(this);
	}

	static void
	make_body_kinematic (Body* body)
	{
		if (b2Body_GetType(body->self->b2body) == b2_staticBody)
			b2Body_SetType(body->self->b2body, b2_kinematicBody);
	}

	void
	Body::set_linear_velocity (coord x, coord y)
	{
		set_linear_velocity(Point(x, y));
	}

	void
	Body::set_linear_velocity (const Point& velocity)
	{
		validate(this);

		make_body_kinematic(this);

		b2Body_SetLinearVelocity(self->b2body, to_b2vec2(velocity, self->ppm));
	}

	Point
	Body::linear_velocity () const
	{
		validate(this);

		return to_point(b2Body_GetLinearVelocity(self->b2body), self->ppm);
	}

	void
	Body::set_angular_velocity (float velocity)
	{
		validate(this);

		make_body_kinematic(this);

		b2Body_SetAngularVelocity(self->b2body, Xot::deg2rad(velocity));
	}

	float
	Body::angular_velocity () const
	{
		validate(this);

		return Xot::rad2deg(b2Body_GetAngularVelocity(self->b2body));
	}

	void
	Body::fix_rotation (bool state)
	{
		validate(this);

		b2Body_SetFixedRotation(self->b2body, state);
	}

	bool
	Body::is_rotation_fixed () const
	{
		return b2Body_IsFixedRotation(self->b2body);
	}

	void
	Body::set_gravity_scale (float scale)
	{
		validate(this);

		if (scale == b2Body_GetGravityScale(self->b2body))
			return;

		b2Body_SetGravityScale(self->b2body, scale);
	}

	float
	Body::gravity_scale () const
	{
		validate(this);

		return b2Body_GetGravityScale(self->b2body);
	}


	b2BodyId
	Body_get_id (const Body* body)
	{
		return body ? body->self->b2body : b2_nullBodyId;
	}

	World*
	Body_get_world (Body* body)
	{
		b2BodyId b2body = Body_get_id(body);
		if (B2_IS_NULL(b2body)) return NULL;

		return (World*) b2World_GetUserData(b2Body_GetWorld(b2body));
	}

	const World*
	Body_get_world (const Body* body)
	{
		return Body_get_world(const_cast<Body*>(body));
	}

	void
	Body_copy_attributes (Body* to, const Body& from)
	{
		if (!to) return;

		b2BodyId b2to   = Body_get_id(to);
		b2BodyId b2from = Body_get_id(&from);
		assert(b2Body_IsValid(b2to) && b2Body_IsValid(b2from));

		b2Body_SetType(           b2to, b2Body_GetType(b2from));
		b2Body_SetAngularVelocity(b2to, b2Body_GetAngularVelocity(b2from));
		b2Body_SetAngularDamping( b2to, b2Body_GetAngularDamping(b2from));
		b2Body_SetGravityScale(   b2to, b2Body_GetGravityScale(b2from));
		b2Body_SetBullet(         b2to, b2Body_IsBullet(b2from));

		float ppm_to   = to->self->ppm;
		float ppm_from = from.self->ppm;
		if (ppm_to == ppm_from)
		{
			b2Body_SetTransform(     b2to, b2Body_GetPosition(      b2from),
			                               b2Body_GetRotation(      b2from));
			b2Body_SetLinearVelocity(b2to, b2Body_GetLinearVelocity(b2from));
			b2Body_SetLinearDamping( b2to, b2Body_GetLinearDamping( b2from));
		}
		else
		{
			float scale = ppm_from / ppm_to;
			auto pos    = b2Body_GetPosition(      b2from);
			auto vel    = b2Body_GetLinearVelocity(b2from);
			auto damp   = b2Body_GetLinearDamping( b2from);
			pos.x *= scale;
			pos.y *= scale;
			vel.x *= scale;
			vel.y *= scale;
			damp  *= scale;
			b2Body_SetTransform(     b2to, pos, b2Body_GetRotation(b2from));
			b2Body_SetLinearVelocity(b2to, vel);
			b2Body_SetLinearDamping( b2to, damp);
		}
	}

	Body*
	Body_create_temporary ()
	{
		return new Body(World_get_temporary());
	}

	bool
	Body_is_temporary (const Body& body)
	{
		b2BodyId b2body = Body_get_id(&body);
		if (B2_IS_NULL(b2body)) return false;

		b2WorldId world = b2Body_GetWorld(b2body);
		b2WorldId tmp   = World_get_id(World_get_temporary());
		return b2StoreWorldId(world) == b2StoreWorldId(tmp);
	}


}// Reflex
