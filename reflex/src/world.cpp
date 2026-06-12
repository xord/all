#include "world.h"


#include <assert.h>
#include <memory>
#include <map>
#include <utility>
#include <vector>
#include <box2d/box2d.h>
#include "reflex/event.h"
#include "reflex/exception.h"
#include "shape.h"
#include "view.h"
#include "body.h"
#include "fixture.h"


namespace Reflex
{


	static constexpr double DELTA_TIME = 1. / 60.;

	// Box2D 2.x allowed bodies to translate up to 2 meters per time step.
	// Box2D 3.x clamps speed in m/s instead with a much lower default,
	// so match the old limit here.
	static constexpr float MAX_LINEAR_SPEED = 2 * 60;


	class DebugDraw
	{

		public:

			DebugDraw (float ppm)
			:	ppm(ppm), painter(NULL)
			{
				b2draw                     = b2DefaultDebugDraw();
				b2draw.DrawPolygonFcn      = DrawPolygon;
				b2draw.DrawSolidPolygonFcn = DrawSolidPolygon;
				b2draw.DrawCircleFcn       = DrawCircle;
				b2draw.DrawSolidCircleFcn  = DrawSolidCircle;
				b2draw.DrawSolidCapsuleFcn = DrawSolidCapsule;
				b2draw.DrawSegmentFcn      = DrawSegment;
				b2draw.DrawTransformFcn    = DrawTransform;
				b2draw.DrawPointFcn        = DrawPoint;
				b2draw.DrawStringFcn       = DrawString;
				b2draw.drawShapes          = true;
				b2draw.drawJoints          = true;
				b2draw.drawMass            = true;
				b2draw.context             = this;
			}

			void begin (Painter* painter)
			{
				this->painter = painter;
				painter->push_state();
			}

			void end ()
			{
				painter->pop_state();
				painter = NULL;
			}

			b2DebugDraw* b2ptr ()
			{
				return &b2draw;
			}

		private:

			b2DebugDraw b2draw;

			float ppm;

			Painter* painter;

			static void set_fill (DebugDraw* draw, b2HexColor color)
			{
				draw->painter->set_fill(
					((color >> 16) & 0xff) / 255.f,
					((color >>  8) & 0xff) / 255.f,
					( color        & 0xff) / 255.f,
					0.5f);
				draw->painter->no_stroke();
			}

			static void set_stroke (DebugDraw* draw, b2HexColor color)
			{
				draw->painter->no_fill();
				draw->painter->set_stroke(
					((color >> 16) & 0xff) / 255.f,
					((color >>  8) & 0xff) / 255.f,
					( color        & 0xff) / 255.f,
					0.5f);
			}

			static void draw_polygon (
				DebugDraw* draw, const b2Vec2* vertices, int vertexCount)
			{
				std::unique_ptr<Point[]> points(new Point[vertexCount]);
				for (int i = 0; i < vertexCount; ++i)
					points[i] = to_point(vertices[i], draw->ppm);

				draw->painter->line(&points[0], vertexCount, true);
			}

			static void DrawPolygon (
				const b2Vec2* vertices, int vertexCount, b2HexColor color,
				void* context)
			{
				DebugDraw* draw = (DebugDraw*) context;
				assert(draw && draw->painter);

				set_stroke(draw, color);
				draw_polygon(draw, vertices, vertexCount);
			}

			static void DrawSolidPolygon (
				b2Transform transform, const b2Vec2* vertices, int vertexCount,
				float radius, b2HexColor color, void* context)
			{
				DebugDraw* draw = (DebugDraw*) context;
				assert(draw && draw->painter);

				std::vector<b2Vec2> points;
				points.reserve(vertexCount);
				for (int i = 0; i < vertexCount; ++i)
					points.emplace_back(b2TransformPoint(transform, vertices[i]));

				set_fill(draw, color);
				draw_polygon(draw, &points[0], vertexCount);
			}

			static void DrawCircle (
				b2Vec2 center, float radius, b2HexColor color, void* context)
			{
				DebugDraw* draw = (DebugDraw*) context;
				assert(draw && draw->painter);

				set_stroke(draw, color);
				draw->painter->ellipse(
					to_point(center, draw->ppm), to_coord(radius, draw->ppm));
			}

			static void DrawSolidCircle (
				b2Transform transform, float radius, b2HexColor color, void* context)
			{
				DebugDraw* draw = (DebugDraw*) context;
				assert(draw && draw->painter);

				set_fill(draw, color);
				draw->painter->ellipse(
					to_point(transform.p, draw->ppm), to_coord(radius, draw->ppm));
			}

			static void DrawSolidCapsule (
				b2Vec2 p1, b2Vec2 p2, float radius, b2HexColor color, void* context)
			{
				DebugDraw* draw = (DebugDraw*) context;
				assert(draw && draw->painter);

				set_fill(draw, color);
				draw->painter->ellipse(
					to_point(p1, draw->ppm), to_coord(radius, draw->ppm));
				draw->painter->ellipse(
					to_point(p2, draw->ppm), to_coord(radius, draw->ppm));
				draw->painter->line(
					to_point(p1, draw->ppm), to_point(p2, draw->ppm));
			}

			static void DrawSegment (
				b2Vec2 p1, b2Vec2 p2, b2HexColor color, void* context)
			{
				DebugDraw* draw = (DebugDraw*) context;
				assert(draw && draw->painter);

				set_stroke(draw, color);
				draw->painter->line(
					to_point(p1, draw->ppm), to_point(p2, draw->ppm));
			}

			static void DrawPoint (
				b2Vec2 p, float size, b2HexColor color, void* context)
			{
				DebugDraw* draw = (DebugDraw*) context;
				assert(draw && draw->painter);

				set_fill(draw, color);
				draw->painter->ellipse(
					to_point(p, draw->ppm), to_coord(size / 2, draw->ppm));
			}

			static void DrawTransform (b2Transform transform, void* context)
			{
			}

			static void DrawString (
				b2Vec2 p, const char* s, b2HexColor color, void* context)
			{
			}

	};// DebugDraw


	typedef std::pair<uint64_t, uint64_t> ShapePairKey;

	typedef std::pair<Shape*, Shape*> ShapePair;

	static ShapePairKey
	make_pair_key (b2ShapeId id1, b2ShapeId id2)
	{
		uint64_t key1 = b2StoreShapeId(id1);
		uint64_t key2 = b2StoreShapeId(id2);
		return key1 < key2
			?	std::make_pair(key1, key2)
			:	std::make_pair(key2, key1);
	}

	static Shape*
	get_shape (b2ShapeId id)
	{
		if (!b2Shape_IsValid(id)) return NULL;
		return (Shape*) b2Shape_GetUserData(id);
	}

	static bool
	should_collide (Shape* s1, Shape* s2)
	{
		if (!s1 || !s2)
			return false;

		View* v1 = s1->owner();
		View* v2 = s2->owner();
		if (!v1 || !v2 || !View_is_active(*v1) || !View_is_active(*v2))
			return false;

		return
			s1->will_contact(s2) &&
			s2->will_contact(s1) &&
			v1->will_contact(v2) &&
			v2->will_contact(v1);
	}

	static bool
	custom_filter_callback (b2ShapeId id1, b2ShapeId id2, void* context)
	{
		return should_collide(get_shape(id1), get_shape(id2));
	}

	static void
	call_contact_events (
		Shape* s1, Shape* s2, ContactEvent::Action action)
	{
		if (!s1 || !s2)
			return;

		View* v1 = s1->owner();
		View* v2 = s2->owner();
		if (!v1 || !v2 || !View_is_active(*v1) || !View_is_active(*v2))
			return;

		ContactEvent e1(action, s2), e2(action, s1);
		Shape_call_contact_event(s1, &e1);
		Shape_call_contact_event(s2, &e2);
	}


	struct World::Data
	{

		b2WorldId b2world;

		float ppm, time_scale;

		std::unique_ptr<DebugDraw> debug_draw;

		// pairs currently touching, tracked to deliver contact-end events
		// for shapes that Box2D has already forgotten on destruction
		std::map<ShapePairKey, ShapePair> active_pairs;

		Data ()
		:	b2world(b2_nullWorldId), ppm(0), time_scale(1)
		{
		}

		void begin_contact (b2ShapeId id1, b2ShapeId id2, bool is_sensor_event)
		{
			Shape* s1 = get_shape(id1);
			Shape* s2 = get_shape(id2);
			if (!s1 || !s2)
				return;

			// Box2D 3.x does not call the custom filter for sensor overlaps,
			// so respect will_contact() here
			if (is_sensor_event && !should_collide(s1, s2))
				return;

			ShapePairKey key = make_pair_key(id1, id2);
			if (!active_pairs.emplace(key, ShapePair(s1, s2)).second)
				return;// already touching

			call_contact_events(s1, s2, ContactEvent::BEGIN);
		}

		void end_contact (b2ShapeId id1, b2ShapeId id2)
		{
			auto it = active_pairs.find(make_pair_key(id1, id2));
			if (it == active_pairs.end())
				return;

			ShapePair pair = it->second;
			active_pairs.erase(it);

			call_contact_events(pair.first, pair.second, ContactEvent::END);
		}

		void handle_contact_events ()
		{
			b2ContactEvents contacts = b2World_GetContactEvents(b2world);
			for (int i = 0; i < contacts.beginCount; ++i)
			{
				const auto& e = contacts.beginEvents[i];
				begin_contact(e.shapeIdA, e.shapeIdB, false);
			}
			for (int i = 0; i < contacts.endCount; ++i)
			{
				const auto& e = contacts.endEvents[i];
				end_contact(e.shapeIdA, e.shapeIdB);
			}

			b2SensorEvents sensors = b2World_GetSensorEvents(b2world);
			for (int i = 0; i < sensors.beginCount; ++i)
			{
				const auto& e = sensors.beginEvents[i];
				begin_contact(e.sensorShapeId, e.visitorShapeId, true);
			}
			for (int i = 0; i < sensors.endCount; ++i)
			{
				const auto& e = sensors.endEvents[i];
				end_contact(e.sensorShapeId, e.visitorShapeId);
			}
		}

	};// World::Data


	World::World (float pixels_per_meter)
	{
		assert(pixels_per_meter > 0);

		self->ppm = pixels_per_meter;

		b2WorldDef def         = b2DefaultWorldDef();
		def.gravity            = b2Vec2{0, 0};
		def.maximumLinearSpeed = MAX_LINEAR_SPEED;
		def.userData           = this;

		self->b2world = b2CreateWorld(&def);
		if (!b2World_IsValid(self->b2world))
			physics_error(__FILE__, __LINE__);

		b2World_SetCustomFilterCallback(
			self->b2world, custom_filter_callback, this);
	}

	World::~World ()
	{
		self->active_pairs.clear();

		b2DestroyWorld(self->b2world);
		self->b2world = b2_nullWorldId;
	}

	void
	World::update (float duration)
	{
		float dt = DELTA_TIME * self->time_scale;
		if (dt <= 0) return;

		int count = (int) (duration / DELTA_TIME);
		if (count < 1) count = 1;

		for (int i = 0; i < count; ++i)
		{
			b2World_Step(self->b2world, dt, 4);
			self->handle_contact_events();
		}
	}

	float
	World::meter2pixel (float meter) const
	{
		return meter == 1 ? self->ppm : meter * self->ppm;
	}

	void
	World::set_gravity (const Point& gravity)
	{
		b2Vec2 b2gravity = to_b2vec2(gravity, self->ppm);
		b2Vec2 current   = b2World_GetGravity(self->b2world);
		if (b2gravity.x == current.x && b2gravity.y == current.y)
			return;

		b2World_SetGravity(self->b2world, b2gravity);
	}

	Point
	World::gravity () const
	{
		return to_point(b2World_GetGravity(self->b2world), self->ppm);
	}

	void
	World::set_time_scale (float scale)
	{
		self->time_scale = scale;
	}

	float
	World::time_scale () const
	{
		return self->time_scale;
	}

	void
	World::set_debug (bool state)
	{
		if (state == debug()) return;

		if (state)
		{
			assert(!self->debug_draw);
			self->debug_draw.reset(new DebugDraw(self->ppm));
		}
		else
			self->debug_draw.reset();
	}

	bool
	World::debug () const
	{
		return !!self->debug_draw;
	}

	void
	World::on_update (float dt)
	{
		update(DELTA_TIME);
	}

	void
	World::on_draw (Painter* painter)
	{
		if (!self->debug_draw) return;

		self->debug_draw->begin(painter);
		b2World_Draw(self->b2world, self->debug_draw->b2ptr());
		self->debug_draw->end();
	}


	World*
	World_get_temporary ()
	{
		static World world;
		return &world;
	}

	b2WorldId
	World_get_b2id (const World* world)
	{
		return world ? world->self->b2world : b2_nullWorldId;
	}

	void
	World_end_contacts_for (World* world, b2ShapeId shape_id)
	{
		if (!world) return;

		uint64_t key = b2StoreShapeId(shape_id);

		std::vector<ShapePair> ended;
		auto& pairs = world->self->active_pairs;
		for (auto it = pairs.begin(); it != pairs.end();)
		{
			if (it->first.first == key || it->first.second == key)
			{
				ended.emplace_back(it->second);
				it = pairs.erase(it);
			}
			else
				++it;
		}

		for (auto& pair : ended)
			call_contact_events(pair.first, pair.second, ContactEvent::END);
	}


}// Reflex
