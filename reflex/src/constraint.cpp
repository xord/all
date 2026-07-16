#include "constraint.h"


#include <box2d/box2d.h>
#include "reflex/pin.h"
#include "reflex/exception.h"
#include "view.h"
#include "selector.h"
#include "body.h"
#include "world.h"


namespace Reflex
{


	static constexpr float DEFAULT_DAMPING      = 0.7f;

	static constexpr float DEFAULT_CHASE_SPRING = 5;

	static constexpr float FORCE_PER_MASS       = 1000;


	static float
	default_max_force (b2BodyId body)
	{
		float mass = b2Body_GetMass(body);
		return FORCE_PER_MASS * (mass > 0 ? mass : 1);
	}

	static Point
	view_center (const View* view)
	{
		return view ? view->frame().size() / 2 : Point(0);
	}

	static float
	relative_angle (b2BodyId body0, b2BodyId body1)
	{
		return
			b2Rot_GetAngle(b2Body_GetRotation(body0)) -
			b2Rot_GetAngle(b2Body_GetRotation(body1));
	}


	struct Constraint::Data
	{

		Pin pins[2];

		b2JointId b2joint  = b2_nullJointId;

		World* world       = NULL;

		float spring       = 0;

		float damping      = DEFAULT_DAMPING;

		bool collide       = false;

		bool removed       = false;

		bool resolved      = false;

		float resolved_ppm = 0;

		b2Vec2 anchor0     = {0, 0};

		b2Vec2 anchor1     = {0, 0};

		float ref_angle    = 0;

		SelectorPtr pselector;

		virtual ~Data ()
		{
		}

		virtual b2JointId create_joint (
			b2WorldId world, b2BodyId body0, b2BodyId body1, float ppm) = 0;

		virtual void apply_params (float ppm) = 0;

		virtual void on_world_update (float ppm)
		{
		}

		bool is_valid () const
		{
			return b2Joint_IsValid(b2joint);
		}

		float ppm () const
		{
			assert(world);
			return world->meter2pixel();
		}

		void resolve_anchors (b2BodyId body0, b2BodyId body1, float ppm)
		{
			if (resolved)
				return rescale_resolved_anchors(ppm);

			const Point* pos0 = pins[0].position();
			const Point* pos1 = pins[1].position();

			if (pos0 && pos1)
			{
				anchor0 = to_b2vec2(*pos0, ppm);
				anchor1 = to_b2vec2(*pos1, ppm);
			}
			else if (pos1)
			{
				anchor1 = to_b2vec2(*pos1, ppm);
				anchor0 = b2Body_GetLocalPoint(body0, b2Body_GetWorldPoint(body1, anchor1));
			}
			else
			{
				anchor0 = to_b2vec2(pos0 ? *pos0 : view_center(pins[0].view()), ppm);
				anchor1 = b2Body_GetLocalPoint(body1, b2Body_GetWorldPoint(body0, anchor0));
			}

			ref_angle    = relative_angle(body0, body1);
			resolved     = true;
			resolved_ppm = ppm;
			write_back_resolved_pins();
		}

		void rescale_resolved_anchors (float ppm)
		{
			// the anchors cache the pinned positions in meters, so moving to
			// a world with another pixels-per-meter only needs unit rescaling,
			// never a re-derivation

			if (resolved_ppm == ppm) return;

			anchor0      = to_b2vec2(*pins[0].position(), ppm);
			anchor1      = to_b2vec2(*pins[1].position(), ppm);
			resolved_ppm = ppm;
		}

		void write_back_resolved_pins ()
		{
			if (!pins[0].position())
				pins[0] = Pin(pins[0].view(), to_point(anchor0, resolved_ppm));
			if (!pins[1].position())
				pins[1] = Pin(pins[1].view(), to_point(anchor1, resolved_ppm));
		}

		void update_params ()
		{
			if (!is_valid() || !world) return;

			b2Joint_SetCollideConnected(b2joint, collide);
			apply_params(ppm());
			b2Joint_WakeBodies(b2joint);
		}

	};// Constraint::Data


	static void
	reactivate_constraint (Constraint* constraint)
	{
		assert(constraint);

		if (!constraint->self->is_valid()) return;

		Constraint_deactivate(constraint);
		Constraint_activate(constraint);
	}

	void
	Constraint_set_pins (
		Constraint* constraint,
		View* view0, const Point* position0,
		View* view1, const Point* position1)
	{
		if (!constraint || !view0)
			argument_error(__FILE__, __LINE__);

		if (view0 == view1)
			argument_error(__FILE__, __LINE__, "can not constrain a view to itself");

		Constraint::Data* self = constraint->self.get();

		if (self->pins[0].view())
			invalid_state_error(__FILE__, __LINE__, "constraint already has pins");

		self->pins[0] = position0 ? Pin(view0, *position0) : Pin(view0);
		self->pins[1] = position1 ? Pin(view1, *position1) : Pin(view1);
	}

	static bool
	get_view_body_and_world (b2BodyId* pid, World** ppworld, View* view)
	{
		if (!view)
			return false;

		Body* body = View_get_body(view);
		if (!body || Body_is_temporary(*body))
			return false;

		World* world = Body_get_world(body);
		if (!world)
			return false;

		*ppworld = world;
		*pid     = Body_get_id(body);
		return true;
	}

	bool
	Constraint_activate (Constraint* constraint)
	{
		if (!constraint)
			argument_error(__FILE__, __LINE__);

		Constraint::Data* self = constraint->self.get();

		if (self->removed || self->is_valid())
			return false;

		b2BodyId id0 = b2_nullBodyId;
		b2BodyId id1 = b2_nullBodyId;

		World* world0 = NULL;
		if (!get_view_body_and_world(&id0, &world0, self->pins[0].view()))
			return false;

		View* view1 = self->pins[1].view();
		if (view1)
		{
			World* world1 = NULL;
			if (!get_view_body_and_world(&id1, &world1, view1))
				return false;

			if (world1 != world0)
				return false;
		}
		else
			id1 = Body_get_id(World_get_ground(world0));

		if (World_is_stepping(world0))
			physics_error(__FILE__, __LINE__, "world is stepping now");

		b2JointId joint =
			self->create_joint(World_get_id(world0), id0, id1, world0->meter2pixel());
		if (!b2Joint_IsValid(joint))
			physics_error(__FILE__, __LINE__);

		self->b2joint = joint;
		self->world   = world0;
		World_add_constraint(world0, constraint);
		return true;
	}

	void
	Constraint_deactivate (Constraint* constraint)
	{
		if (!constraint)
			argument_error(__FILE__, __LINE__);

		Constraint::Data* self = constraint->self.get();

		if (self->world)
		{
			if (self->is_valid())
			{
				if (World_is_stepping(self->world))
					physics_error(__FILE__, __LINE__, "world is stepping now");

				b2DestroyJoint(self->b2joint);
			}
			World_remove_constraint(self->world, constraint);
		}

		self->b2joint = b2_nullJointId;
		self->world   = NULL;
	}

	void
	Constraint_sever (Constraint* constraint)
	{
		if (!constraint)
			argument_error(__FILE__, __LINE__);

		Constraint::Data* self = constraint->self.get();

		if (self->removed) return;

		Constraint::Ref guard(constraint);

		Constraint_deactivate(constraint);
		self->removed = true;

		View* view0 = self->pins[0].view();
		View* view1 = self->pins[1].view();
		if (view0) View_remove_constraint(view0, constraint);
		if (view1) View_remove_constraint(view1, constraint);
	}

	void
	Constraint_on_world_destroyed (Constraint* constraint)
	{
		if (!constraint)
			argument_error(__FILE__, __LINE__);

		Constraint::Data* self = constraint->self.get();

		self->b2joint = b2_nullJointId;
		self->world   = NULL;
	}

	void
	Constraint_on_world_update (Constraint* constraint)
	{
		if (!constraint)
			argument_error(__FILE__, __LINE__);

		Constraint::Data* self = constraint->self.get();
		if (!self->world) return;

		self->on_world_update(self->ppm());
	}

	bool
	Constraint_has_world_mismatch (const Constraint* constraint)
	{
		if (!constraint)
			argument_error(__FILE__, __LINE__);

		const Constraint::Data* self = constraint->self.get();

		const View* view0 = self->pins[0].view();
		const View* view1 = self->pins[1].view();
		if (!view0 || !view1) return false;

		const Body* body0 = View_get_body(view0);
		const Body* body1 = View_get_body(view1);
		if (!body0 || Body_is_temporary(*body0)) return false;
		if (!body1 || Body_is_temporary(*body1)) return false;

		return Body_get_world(body0) != Body_get_world(body1);
	}


	Constraint::Constraint (Data* data)
	:	self(data)
	{
	}

	Constraint::~Constraint ()
	{
		Constraint_deactivate(this);
	}

	void
	Constraint::remove ()
	{
		Constraint_sever(this);
	}

	const Pin&
	Constraint::pin (size_t index) const
	{
		if (index > 1)
			argument_error(__FILE__, __LINE__);

		return self->pins[index];
	}

	View*
	Constraint::view (size_t index)
	{
		if (index > 1)
			argument_error(__FILE__, __LINE__);

		return self->pins[index].view();
	}

	const View*
	Constraint::view (size_t index) const
	{
		return const_cast<Constraint*>(this)->view(index);
	}

	void
	Constraint::set_spring (float hertz)
	{
		if (hertz < 0)
			argument_error(__FILE__, __LINE__);

		self->spring = hertz;
		self->update_params();
	}

	float
	Constraint::spring () const
	{
		return self->spring;
	}

	void
	Constraint::set_damping (float ratio)
	{
		if (ratio < 0)
			argument_error(__FILE__, __LINE__);

		self->damping = ratio;
		self->update_params();
	}

	float
	Constraint::damping () const
	{
		return self->damping;
	}

	void
	Constraint::set_collide (bool state)
	{
		self->collide = state;
		self->update_params();
	}

	bool
	Constraint::can_collide () const
	{
		return self->collide;
	}

	bool
	Constraint::is_removed () const
	{
		return self->removed;
	}

	Constraint::operator bool () const
	{
		return self->is_valid();
	}

	bool
	Constraint::operator ! () const
	{
		return !operator bool();
	}

	SelectorPtr*
	Constraint::get_selector_ptr ()
	{
		return &self->pselector;
	}


	struct SnapConstraintData : public Constraint::Data
	{

		bool  has_angle   = false;

		float angle_min   = 0;

		float angle_max   = 0;

		bool  has_motor   = false;

		float motor_speed = 0;

		bool  has_force   = false;

		float force       = 0;

		bool use_weld () const
		{
			return has_angle && angle_min == angle_max;
		}

		b2JointId create_joint (
			b2WorldId world, b2BodyId body0, b2BodyId body1, float ppm) override
		{
			resolve_anchors(body0, body1, ppm);

			// the declaring side goes to bodyB because the mouse joint
			// assumes bodyA is static
			if (use_weld())
			{
				b2WeldJointDef def      = b2DefaultWeldJointDef();
				def.bodyIdA             = body1;
				def.bodyIdB             = body0;
				def.localAnchorA        = anchor1;
				def.localAnchorB        = anchor0;
				def.referenceAngle      = ref_angle + Xot::deg2rad(angle_min);
				def.linearHertz         = spring;
				def.angularHertz        = spring;
				def.linearDampingRatio  = damping;
				def.angularDampingRatio = damping;
				def.collideConnected    = collide;
				return b2CreateWeldJoint(world, &def);
			}
			else
			{
				b2RevoluteJointDef def = b2DefaultRevoluteJointDef();
				def.bodyIdA            = body1;
				def.bodyIdB            = body0;
				def.localAnchorA       = anchor1;
				def.localAnchorB       = anchor0;
				def.referenceAngle     = ref_angle;
				def.enableSpring       = spring > 0;
				def.hertz              = spring;
				def.dampingRatio       = damping;
				def.enableLimit        = has_angle;
				def.lowerAngle         = Xot::deg2rad(angle_min);
				def.upperAngle         = Xot::deg2rad(angle_max);
				def.enableMotor        = has_motor;
				def.motorSpeed         = Xot::deg2rad(motor_speed);
				def.maxMotorTorque     = has_force ? force : default_max_force(body0);
				def.collideConnected   = collide;
				return b2CreateRevoluteJoint(world, &def);
			}
		}

		void apply_params (float ppm) override
		{
			if (b2Joint_GetType(b2joint) == b2_weldJoint)
			{
				float min = Xot::deg2rad(angle_min);
				b2Joint_SetReferenceAngle(         b2joint, ref_angle + min);
				b2WeldJoint_SetLinearHertz(        b2joint, spring);
				b2WeldJoint_SetAngularHertz(       b2joint, spring);
				b2WeldJoint_SetLinearDampingRatio( b2joint, damping);
				b2WeldJoint_SetAngularDampingRatio(b2joint, damping);
			}
			else
			{
				b2RevoluteJoint_EnableSpring(         b2joint, spring > 0);
				b2RevoluteJoint_SetSpringHertz(       b2joint, spring);
				b2RevoluteJoint_SetSpringDampingRatio(b2joint, damping);
				b2RevoluteJoint_EnableLimit(          b2joint, has_angle);
				if (has_angle)
				{
					float min = Xot::deg2rad(angle_min), max = Xot::deg2rad(angle_max);
					b2RevoluteJoint_SetLimits(          b2joint, min, max);
				}
				b2RevoluteJoint_EnableMotor(          b2joint, has_motor);
				b2RevoluteJoint_SetMotorSpeed(        b2joint, Xot::deg2rad(motor_speed));
				if (has_force)
					b2RevoluteJoint_SetMaxMotorTorque(  b2joint, force);
			}
		}

	};// SnapConstraintData


	static SnapConstraintData&
	get_data (SnapConstraint& constraint)
	{
		return (SnapConstraintData&) *constraint.self;
	}

	static const SnapConstraintData&
	get_data (const SnapConstraint& constraint)
	{
		return get_data(const_cast<SnapConstraint&>(constraint));
	}


	static SnapConstraint_CreateFun snap_constraint_create_fun = NULL;

	void
	SnapConstraint_set_create_fun (SnapConstraint_CreateFun fun)
	{
		snap_constraint_create_fun = fun;
	}

	SnapConstraint*
	SnapConstraint_create ()
	{
		return snap_constraint_create_fun
			?	snap_constraint_create_fun()
			:	new SnapConstraint();
	}


	SnapConstraint::SnapConstraint ()
	:	Super(new SnapConstraintData)
	{
	}

	SnapConstraint::~SnapConstraint ()
	{
	}

	static void
	update_angle (SnapConstraint* c, bool has_angle, float min, float max)
	{
		if (min > max)
			argument_error(__FILE__, __LINE__);

		SnapConstraintData& self = get_data(*c);

		bool weld      = self.use_weld();
		self.has_angle = has_angle;
		self.angle_min = min;
		self.angle_max = max;

		if (self.is_valid() && weld != self.use_weld())
			reactivate_constraint(c);
		else
			self.update_params();
	}

	void
	SnapConstraint::set_angle (float min_degree, float max_degree)
	{
		update_angle(this, true, min_degree, max_degree);
	}

	void
	SnapConstraint::clear_angle ()
	{
		update_angle(this, false, 0, 0);
	}

	float
	SnapConstraint::angle_min () const
	{
		return get_data(*this).angle_min;
	}

	float
	SnapConstraint::angle_max () const
	{
		return get_data(*this).angle_max;
	}

	bool
	SnapConstraint::has_angle () const
	{
		return get_data(*this).has_angle;
	}

	static void
	update_motor (SnapConstraint* c, bool has_motor, float speed)
	{
		SnapConstraintData& self = get_data(*c);

		self.has_motor   = has_motor;
		self.motor_speed = speed;
		self.update_params();
	}

	void
	SnapConstraint::set_motor (float degrees_per_second)
	{
		update_motor(this, true, degrees_per_second);
	}

	void
	SnapConstraint::clear_motor ()
	{
		update_motor(this, false, 0);
	}

	float
	SnapConstraint::motor () const
	{
		return get_data(*this).motor_speed;
	}

	bool
	SnapConstraint::has_motor () const
	{
		return get_data(*this).has_motor;
	}

	void
	SnapConstraint::set_force (float max_torque)
	{
		if (max_torque < 0)
			argument_error(__FILE__, __LINE__);

		SnapConstraintData& self = get_data(*this);

		self.has_force = true;
		self.force     = max_torque;
		self.update_params();
	}

	void
	SnapConstraint::clear_force ()
	{
		SnapConstraintData& self = get_data(*this);

		self.has_force = false;
		self.force     = 0;

		if (
			self.is_valid() && self.world &&
			b2Joint_GetType(self.b2joint) == b2_revoluteJoint)
		{
			View* view = self.pins[0].view();
			Body* body = view ? View_get_body(view, false) : NULL;
			if (body)
			{
				b2RevoluteJoint_SetMaxMotorTorque(
					self.b2joint, default_max_force(Body_get_id(body)));
			}
		}
	}

	float
	SnapConstraint::force () const
	{
		const SnapConstraintData& self = get_data(*this);

		if (self.has_force)
			return self.force;

		if (
			self.is_valid() && self.world &&
			b2Joint_GetType(self.b2joint) == b2_revoluteJoint)
		{
			return b2RevoluteJoint_GetMaxMotorTorque(self.b2joint);
		}

		return 0;
	}

	bool
	SnapConstraint::has_force () const
	{
		return get_data(*this).has_force;
	}


	struct LinkConstraintData : public Constraint::Data
	{

		bool  has_axis     = false;

		Point axis         = Point(1, 0);

		bool  has_distance = false;

		coord distance     = 0;

		float b2distance   = 0;

		bool  has_range    = false;

		coord range_min    = 0;

		coord range_max    = 0;

		bool  has_motor    = false;

		coord motor_speed  = 0;

		bool  has_force    = false;

		float force        = 0;

		b2JointId create_joint (
			b2WorldId world, b2BodyId body0, b2BodyId body1, float ppm) override
		{
			// the declaring side goes to bodyB because the mouse joint
			// assumes bodyA is static
			if (has_axis)
			{
				// an axis turns the link into a rail: the anchors coincide and
				// the separation is measured along the axis, not radially
				resolve_anchors(body0, body1, ppm);

				b2PrismaticJointDef def = b2DefaultPrismaticJointDef();
				def.bodyIdA             = body1;
				def.bodyIdB             = body0;
				def.localAnchorA        = anchor1;
				def.localAnchorB        = anchor0;
				def.localAxisA          = b2axis();
				def.referenceAngle      = ref_angle;
				def.targetTranslation   = has_distance ? to_b2coord(distance, ppm) : 0;
				def.enableSpring        = spring > 0;
				def.hertz               = spring;
				def.dampingRatio        = damping;
				def.enableLimit         = has_range;
				def.lowerTranslation    = to_b2coord(range_min, ppm);
				def.upperTranslation    = to_b2coord(range_max, ppm);
				def.enableMotor         = has_motor;
				def.motorSpeed          = to_b2coord(motor_speed, ppm);
				def.maxMotorForce       = has_force ? force : default_max_force(body0);
				def.collideConnected    = collide;
				return b2CreatePrismaticJoint(world, &def);
			}
			else
			{
				resolve_link_anchors(body0, body1, ppm);

				b2DistanceJointDef def = b2DefaultDistanceJointDef();
				def.bodyIdA            = body1;
				def.bodyIdB            = body0;
				def.localAnchorA       = anchor1;
				def.localAnchorB       = anchor0;
				def.length             = b2distance;
				def.enableSpring       = spring > 0;
				def.hertz              = spring;
				def.dampingRatio       = damping;
				def.enableLimit        = has_range;
				def.minLength          = to_b2coord(range_min, ppm);
				def.maxLength          = to_b2coord(range_max, ppm);
				def.enableMotor        = has_motor;
				def.motorSpeed         = to_b2coord(motor_speed, ppm);
				def.maxMotorForce      = has_force ? force : default_max_force(body0);
				def.collideConnected   = collide;
				return b2CreateDistanceJoint(world, &def);
			}
		}

		void resolve_link_anchors (b2BodyId body0, b2BodyId body1, float ppm)
		{
			// unlike coincidence type constraints, unspecified link anchors
			// default to the view centers because the relation to be kept is
			// the distance, not the anchor placement

			if (resolved)
			{
				if (has_distance)
					b2distance = to_b2coord(distance, ppm);
				else if (resolved_ppm != ppm)
					b2distance = to_b2coord(to_coord(b2distance, resolved_ppm), ppm);

				return rescale_resolved_anchors(ppm);
			}

			const Point* pos0 = pins[0].position();
			const Point* pos1 = pins[1].position();

			anchor0 = to_b2vec2(pos0 ? *pos0 : view_center(pins[0].view()), ppm);
			if (pos1)
				anchor1 = to_b2vec2(*pos1, ppm);
			else if (pins[1].view())
				anchor1 = to_b2vec2(view_center(pins[1].view()), ppm);
			else
				anchor1 = b2Body_GetLocalPoint(body1, b2Body_GetWorldPoint(body0, anchor0));

			ref_angle    = relative_angle(body0, body1);
			resolved     = true;
			resolved_ppm = ppm;
			b2distance   = has_distance
				?	to_b2coord(distance, ppm)
				:	b2Distance(b2Body_GetWorldPoint(body0, anchor0), b2Body_GetWorldPoint(body1, anchor1));

			write_back_resolved_pins();
		}

		void apply_params (float ppm) override
		{
			if (b2Joint_GetType(b2joint) == b2_prismaticJoint)
			{
				b2Joint_SetLocalAxisA(b2joint, b2axis());
				if (has_distance)
					b2PrismaticJoint_SetTargetTranslation(b2joint, to_b2coord(distance, ppm));
				b2PrismaticJoint_EnableSpring(         b2joint, spring > 0);
				b2PrismaticJoint_SetSpringHertz(       b2joint, spring);
				b2PrismaticJoint_SetSpringDampingRatio(b2joint, damping);
				b2PrismaticJoint_EnableLimit(          b2joint, has_range);
				if (has_range)
				{
					float min = to_b2coord(range_min, ppm), max = to_b2coord(range_max, ppm);
					b2PrismaticJoint_SetLimits(          b2joint, min, max);
				}
				b2PrismaticJoint_EnableMotor(          b2joint, has_motor);
				b2PrismaticJoint_SetMotorSpeed(        b2joint, to_b2coord(motor_speed, ppm));
				if (has_force)
					b2PrismaticJoint_SetMaxMotorForce(   b2joint, force);
			}
			else
			{
				if (has_distance)
					b2DistanceJoint_SetLength(          b2joint, to_b2coord(distance, ppm));
				b2DistanceJoint_EnableSpring(         b2joint, spring > 0);
				b2DistanceJoint_SetSpringHertz(       b2joint, spring);
				b2DistanceJoint_SetSpringDampingRatio(b2joint, damping);
				b2DistanceJoint_EnableLimit(          b2joint, has_range);
				if (has_range)
				{
					float min = to_b2coord(range_min, ppm), max = to_b2coord(range_max, ppm);
					b2DistanceJoint_SetLengthRange(     b2joint, min, max);
				}
				b2DistanceJoint_EnableMotor(          b2joint, has_motor);
				b2DistanceJoint_SetMotorSpeed(        b2joint, to_b2coord(motor_speed, ppm));
				if (has_force)
					b2DistanceJoint_SetMaxMotorForce(   b2joint, force);
			}
		}

		b2Vec2 b2axis () const
		{
			return b2Normalize(b2Vec2(axis.x, axis.y));
		}

	};// LinkConstraintData


	static LinkConstraintData&
	get_data (LinkConstraint& constraint)
	{
		return (LinkConstraintData&) *constraint.self;
	}

	static const LinkConstraintData&
	get_data (const LinkConstraint& constraint)
	{
		return get_data(const_cast<LinkConstraint&>(constraint));
	}


	static LinkConstraint_CreateFun link_constraint_create_fun = NULL;

	void
	LinkConstraint_set_create_fun (LinkConstraint_CreateFun fun)
	{
		link_constraint_create_fun = fun;
	}

	LinkConstraint*
	LinkConstraint_create ()
	{
		return link_constraint_create_fun
			?	link_constraint_create_fun()
			:	new LinkConstraint();
	}


	LinkConstraint::LinkConstraint ()
	:	Super(new LinkConstraintData)
	{
	}

	LinkConstraint::~LinkConstraint ()
	{
	}

	static void
	update_axis (LinkConstraint* c, bool has_axis, const Point& axis)
	{
		LinkConstraintData& self = get_data(*c);

		bool was_axis = self.has_axis;
		self.has_axis = has_axis;
		if (has_axis) self.axis = axis;

		if (self.is_valid() && was_axis != has_axis)
			reactivate_constraint(c); // distance joint <-> prismatic joint
		else
			self.update_params();
	}

	void
	LinkConstraint::set_axis (coord x, coord y)
	{
		set_axis(Point(x, y));
	}

	void
	LinkConstraint::set_axis (const Point& direction)
	{
		if (direction.x == 0 && direction.y == 0)
			argument_error(__FILE__, __LINE__);

		update_axis(this, true, direction);
	}

	void
	LinkConstraint::clear_axis ()
	{
		update_axis(this, false, Point(0));
	}

	const Point&
	LinkConstraint::axis () const
	{
		return get_data(*this).axis;
	}

	bool
	LinkConstraint::has_axis () const
	{
		return get_data(*this).has_axis;
	}

	static void
	update_distance (LinkConstraint* c, bool has_distance, coord distance)
	{
		// distance is a radial length (>= 0) for a distance joint, or a signed
		// target translation along the axis for a rail, so it is not clamped

		LinkConstraintData& self = get_data(*c);

		self.has_distance = has_distance;
		self.distance     = distance;
		self.update_params();
	}

	void
	LinkConstraint::set_distance (coord distance)
	{
		update_distance(this, true, distance);
	}

	void
	LinkConstraint::clear_distance ()
	{
		update_distance(this, false, 0);
	}

	coord
	LinkConstraint::distance () const
	{
		const LinkConstraintData& self = get_data(*this);

		if (self.has_distance)
			return self.distance;

		if (self.is_valid() && self.world)
			return to_coord(
				self.has_axis
					?	b2PrismaticJoint_GetTargetTranslation(self.b2joint)
					:	b2DistanceJoint_GetLength(self.b2joint),
				self.ppm());

		return 0;
	}

	bool
	LinkConstraint::has_distance () const
	{
		return get_data(*this).has_distance;
	}

	coord
	LinkConstraint::current_distance () const
	{
		const LinkConstraintData& self = get_data(*this);

		if (!self.is_valid() || !self.world) return 0;

		return to_coord(
			self.has_axis
				?	b2PrismaticJoint_GetTranslation(self.b2joint)
				:	b2DistanceJoint_GetCurrentLength(self.b2joint),
			self.ppm());
	}

	static void
	update_range (LinkConstraint* c, bool has_range, coord min, coord max)
	{
		// range bounds are radial lengths (>= 0) for a distance joint, or signed
		// translations along the axis for a rail, so only the order is checked

		if (min > max)
			argument_error(__FILE__, __LINE__);

		LinkConstraintData& self = get_data(*c);

		self.has_range = has_range;
		self.range_min = min;
		self.range_max = max;
		self.update_params();
	}

	void
	LinkConstraint::set_range (coord min, coord max)
	{
		update_range(this, true, min, max);
	}

	void
	LinkConstraint::clear_range ()
	{
		update_range(this, false, 0, 0);
	}

	coord
	LinkConstraint::range_min () const
	{
		return get_data(*this).range_min;
	}

	coord
	LinkConstraint::range_max () const
	{
		return get_data(*this).range_max;
	}

	bool
	LinkConstraint::has_range () const
	{
		return get_data(*this).has_range;
	}

	static void
	update_motor (LinkConstraint* c, bool has_motor, coord speed)
	{
		LinkConstraintData& self = get_data(*c);

		self.has_motor   = has_motor;
		self.motor_speed = speed;
		self.update_params();
	}

	void
	LinkConstraint::set_motor (coord pixels_per_second)
	{
		update_motor(this, true, pixels_per_second);
	}

	void
	LinkConstraint::clear_motor ()
	{
		update_motor(this, false, 0);
	}

	coord
	LinkConstraint::motor () const
	{
		return get_data(*this).motor_speed;
	}

	bool
	LinkConstraint::has_motor () const
	{
		return get_data(*this).has_motor;
	}

	void
	LinkConstraint::set_force (float max_force)
	{
		if (max_force < 0)
			argument_error(__FILE__, __LINE__);

		LinkConstraintData& self = get_data(*this);

		self.has_force = true;
		self.force     = max_force;
		self.update_params();
	}

	void
	LinkConstraint::clear_force ()
	{
		LinkConstraintData& self = get_data(*this);

		self.has_force = false;
		self.force     = 0;

		if (self.is_valid() && self.world)
		{
			View* view = self.pins[0].view();
			Body* body = view ? View_get_body(view, false) : NULL;
			if (body)
			{
				float force = default_max_force(Body_get_id(body));
				if (self.has_axis)
					b2PrismaticJoint_SetMaxMotorForce(self.b2joint, force);
				else
					b2DistanceJoint_SetMaxMotorForce( self.b2joint, force);
			}
		}
	}

	float
	LinkConstraint::force () const
	{
		const LinkConstraintData& self = get_data(*this);

		if (self.has_force)
			return self.force;

		if (self.is_valid() && self.world)
			return self.has_axis
				?	b2PrismaticJoint_GetMaxMotorForce(self.b2joint)
				:	b2DistanceJoint_GetMaxMotorForce( self.b2joint);

		return 0;
	}

	bool
	LinkConstraint::has_force () const
	{
		return get_data(*this).has_force;
	}


	struct WheelConstraintData : public Constraint::Data
	{

		Point axis        = Point(0, 1);

		bool  has_range   = false;

		coord range_min   = 0;

		coord range_max   = 0;

		bool  has_motor   = false;

		float motor_speed = 0;// degree/sec

		bool  has_force   = false;

		float force       = 0;

		b2JointId create_joint (
			b2WorldId world, b2BodyId body0, b2BodyId body1, float ppm) override
		{
			resolve_anchors(body0, body1, ppm);

			// the declaring side goes to bodyB because the mouse joint
			// assumes bodyA is static
			b2WheelJointDef def  = b2DefaultWheelJointDef();
			def.bodyIdA          = body1;
			def.bodyIdB          = body0;
			def.localAnchorA     = anchor1;
			def.localAnchorB     = anchor0;
			def.localAxisA       = b2axis();
			def.enableSpring     = spring > 0;
			def.hertz            = spring;
			def.dampingRatio     = damping;
			def.enableLimit      = has_range;
			def.lowerTranslation = to_b2coord(range_min, ppm);
			def.upperTranslation = to_b2coord(range_max, ppm);
			def.enableMotor      = has_motor;
			def.motorSpeed       = Xot::deg2rad(motor_speed);
			def.maxMotorTorque   = has_force ? force : default_max_force(body0);
			def.collideConnected = collide;
			return b2CreateWheelJoint(world, &def);
		}

		void apply_params (float ppm) override
		{
			b2Joint_SetLocalAxisA(b2joint, b2axis());
			b2WheelJoint_EnableSpring(         b2joint, spring > 0);
			b2WheelJoint_SetSpringHertz(       b2joint, spring);
			b2WheelJoint_SetSpringDampingRatio(b2joint, damping);
			b2WheelJoint_EnableLimit(          b2joint, has_range);
			if (has_range)
			{
				float min = to_b2coord(range_min, ppm), max = to_b2coord(range_max, ppm);
				b2WheelJoint_SetLimits(          b2joint, min, max);
			}
			b2WheelJoint_EnableMotor(          b2joint, has_motor);
			b2WheelJoint_SetMotorSpeed(        b2joint, Xot::deg2rad(motor_speed));
			if (has_force)
				b2WheelJoint_SetMaxMotorTorque(  b2joint, force);
		}

		b2Vec2 b2axis () const
		{
			return b2Normalize(b2Vec2(axis.x, axis.y));
		}

	};// WheelConstraintData


	static WheelConstraintData&
	get_data (WheelConstraint& constraint)
	{
		return (WheelConstraintData&) *constraint.self;
	}

	static const WheelConstraintData&
	get_data (const WheelConstraint& constraint)
	{
		return get_data(const_cast<WheelConstraint&>(constraint));
	}


	static WheelConstraint_CreateFun wheel_constraint_create_fun = NULL;

	void
	WheelConstraint_set_create_fun (WheelConstraint_CreateFun fun)
	{
		wheel_constraint_create_fun = fun;
	}

	WheelConstraint*
	WheelConstraint_create ()
	{
		return wheel_constraint_create_fun
			?	wheel_constraint_create_fun()
			:	new WheelConstraint();
	}


	WheelConstraint::WheelConstraint ()
	:	Super(new WheelConstraintData)
	{
	}

	WheelConstraint::~WheelConstraint ()
	{
	}

	void
	WheelConstraint::set_axis (coord x, coord y)
	{
		set_axis(Point(x, y));
	}

	void
	WheelConstraint::set_axis (const Point& direction)
	{
		if (direction.x == 0 && direction.y == 0)
			argument_error(__FILE__, __LINE__);

		WheelConstraintData& self = get_data(*this);

		self.axis = direction;
		self.update_params();
	}

	const Point&
	WheelConstraint::axis () const
	{
		return get_data(*this).axis;
	}

	static void
	update_range (WheelConstraint* c, bool has_range, float min, float max)
	{
		if (min > max)
			argument_error(__FILE__, __LINE__);

		WheelConstraintData& self = get_data(*c);

		self.has_range = has_range;
		self.range_min = min;
		self.range_max = max;
		self.update_params();
	}

	void
	WheelConstraint::set_range (coord min, coord max)
	{
		update_range(this, true, min, max);
	}

	void
	WheelConstraint::clear_range ()
	{
		update_range(this, false, 0, 0);
	}

	coord
	WheelConstraint::range_min () const
	{
		return get_data(*this).range_min;
	}

	coord
	WheelConstraint::range_max () const
	{
		return get_data(*this).range_max;
	}

	bool
	WheelConstraint::has_range () const
	{
		return get_data(*this).has_range;
	}

	static void
	update_motor (WheelConstraint* c, bool has_motor, float speed)
	{
		WheelConstraintData& self = get_data(*c);

		self.has_motor   = has_motor;
		self.motor_speed = speed;
		self.update_params();
	}

	void
	WheelConstraint::set_motor (float degrees_per_second)
	{
		update_motor(this, true, degrees_per_second);
	}

	void
	WheelConstraint::clear_motor ()
	{
		update_motor(this, false, 0);
	}

	float
	WheelConstraint::motor () const
	{
		return get_data(*this).motor_speed;
	}

	bool
	WheelConstraint::has_motor () const
	{
		return get_data(*this).has_motor;
	}

	void
	WheelConstraint::set_force (float max_torque)
	{
		if (max_torque < 0)
			argument_error(__FILE__, __LINE__);

		WheelConstraintData& self = get_data(*this);

		self.has_force = true;
		self.force     = max_torque;
		self.update_params();
	}

	void
	WheelConstraint::clear_force ()
	{
		WheelConstraintData& self = get_data(*this);

		self.has_force = false;
		self.force     = 0;

		if (self.is_valid() && self.world)
		{
			View* view = self.pins[0].view();
			Body* body = view ? View_get_body(view, false) : NULL;
			if (body)
			{
				b2WheelJoint_SetMaxMotorTorque(
					self.b2joint, default_max_force(Body_get_id(body)));
			}
		}
	}

	float
	WheelConstraint::force () const
	{
		const WheelConstraintData& self = get_data(*this);

		if (self.has_force)
			return self.force;

		if (self.is_valid() && self.world)
			return b2WheelJoint_GetMaxMotorTorque(self.b2joint);

		return 0;
	}

	bool
	WheelConstraint::has_force () const
	{
		return get_data(*this).has_force;
	}


	struct ChaseConstraintData : public Constraint::Data
	{

		Pin target;

		bool has_force = false;

		float force    = 0;

		ChaseConstraintData ()
		{
			spring = DEFAULT_CHASE_SPRING;
		}

		b2JointId create_joint (
			b2WorldId world, b2BodyId body0, b2BodyId body1, float ppm) override
		{
			Point pos0 = pins[0].position() ? *pins[0].position() : view_center(pins[0].view());

			// the declaring side goes to bodyB because the mouse joint
			// assumes bodyA is static
			b2MouseJointDef def  = b2DefaultMouseJointDef();
			def.bodyIdA          = body1;
			def.bodyIdB          = body0;
			def.target           = b2Body_GetWorldPoint(body0, to_b2vec2(pos0, ppm));
			def.hertz            = spring;
			def.dampingRatio     = damping;
			def.maxForce         = has_force ? force : default_max_force(body0);
			def.collideConnected = collide;

			b2JointId id = b2CreateMouseJoint(world, &def);
			if (b2Joint_IsValid(id))
			{
				b2Vec2 target_pos;
				if (get_target_pos(&target_pos, ppm))
					b2MouseJoint_SetTarget(id, target_pos);
			}
			return id;
		}

		void apply_params (float ppm) override
		{
			b2MouseJoint_SetSpringHertz(       b2joint, spring);
			b2MouseJoint_SetSpringDampingRatio(b2joint, damping);
			if (has_force)
				b2MouseJoint_SetMaxForce(        b2joint, force);

			b2Vec2 target_pos;
			if (get_target_pos(&target_pos, ppm))
				b2MouseJoint_SetTarget(          b2joint, target_pos);
		}

		void on_world_update (float ppm) override
		{
			if (!is_valid() || !target.view())
				return;

			b2Vec2 pos;
			if (get_target_pos(&pos, ppm))
			{
				b2MouseJoint_SetTarget(b2joint, pos);
				b2Joint_WakeBodies(b2joint);
			}
		}

		bool get_target_pos (b2Vec2* pos, float ppm)
		{
			assert(pos);

			View* view = target.view();
			if (view)
			{
				Body* body = View_get_body(view, false);
				if (!body || Body_is_temporary(*body))
					return false;

				Point p = target.position() ? *target.position() : view_center(view);
				*pos    = b2Body_GetWorldPoint(Body_get_id(body), to_b2vec2(p, ppm));
				return true;
			}

			if (target.position())
			{
				*pos = to_b2vec2(*target.position(), ppm);
				return true;
			}

			return false;
		}

	};// ChaseConstraintData


	static ChaseConstraintData&
	get_data (ChaseConstraint& constraint)
	{
		return (ChaseConstraintData&) *constraint.self;
	}

	static const ChaseConstraintData&
	get_data (const ChaseConstraint& constraint)
	{
		return get_data(const_cast<ChaseConstraint&>(constraint));
	}


	static ChaseConstraint_CreateFun chase_constraint_create_fun = NULL;

	void
	ChaseConstraint_set_create_fun (ChaseConstraint_CreateFun fun)
	{
		chase_constraint_create_fun = fun;
	}

	ChaseConstraint*
	ChaseConstraint_create ()
	{
		return chase_constraint_create_fun
			?	chase_constraint_create_fun()
			:	new ChaseConstraint();
	}


	ChaseConstraint::ChaseConstraint ()
	:	Super(new ChaseConstraintData)
	{
	}

	ChaseConstraint::~ChaseConstraint ()
	{
	}

	void
	ChaseConstraint::set_target (const Pin& target)
	{
		ChaseConstraintData& self = get_data(*this);

		if (target.view() && target.view() == self.pins[0].view())
			argument_error(__FILE__, __LINE__, "can not chase itself");

		self.target = target;
		self.update_params();
	}

	const Pin&
	ChaseConstraint::target () const
	{
		return get_data(*this).target;
	}

	void
	ChaseConstraint::set_force (float max_force)
	{
		if (max_force < 0)
			argument_error(__FILE__, __LINE__);

		ChaseConstraintData& self = get_data(*this);

		self.has_force = true;
		self.force     = max_force;
		self.update_params();
	}

	void
	ChaseConstraint::clear_force ()
	{
		ChaseConstraintData& self = get_data(*this);

		self.has_force = false;
		self.force     = 0;

		if (self.is_valid() && self.world)
		{
			View* view = self.pins[0].view();
			Body* body = view ? View_get_body(view, false) : NULL;
			if (body)
				b2MouseJoint_SetMaxForce(self.b2joint, default_max_force(Body_get_id(body)));
		}
	}

	float
	ChaseConstraint::force () const
	{
		const ChaseConstraintData& self = get_data(*this);

		if (self.has_force)
			return self.force;

		if (self.is_valid() && self.world)
			return b2MouseJoint_GetMaxForce(self.b2joint);

		return 0;
	}

	bool
	ChaseConstraint::has_force () const
	{
		return get_data(*this).has_force;
	}


}// Reflex
