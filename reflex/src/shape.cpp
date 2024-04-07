#include "shape.h"


#include <assert.h>
#include <box2d/b2_body.h>
#include <box2d/b2_fixture.h>
#include <box2d/b2_circle_shape.h>
#include <box2d/b2_edge_shape.h>
#include <box2d/b2_chain_shape.h>
#include <box2d/b2_polygon_shape.h>
#include <rays/polygon.h>
#include "reflex/exception.h"
#include "reflex/debug.h"
#include "selector.h"
#include "view.h"
#include "world.h"
#include "body.h"
#include "fixture.h"


namespace Reflex
{


	static const Style*
	get_style (const Shape* shape)
	{
		assert(shape);

		const View* owner = shape->owner();
		if (!owner) return NULL;

		return &View_get_style(owner);
	}

	static bool
	is_default_shape (const Shape* shape)
	{
		assert(shape);

		const View* owner = shape->owner();
		if (!owner) return false;

		return shape == owner->shape();
	}

	static const Color*
	get_fill (const Shape* shape)
	{
		assert(shape);

		const Style* style = get_style(shape);
		if (!style) return NULL;

		return is_default_shape(shape)
			?	&style->background_fill()
			:	&style->foreground_fill();
	}

	static coord
	get_stroke_width (const Shape* shape)
	{
		assert(shape);

		const Style* style = get_style(shape);
		if (!style) return 0;

		return is_default_shape(shape)
			?	style->background_stroke_width()
			:	style->foreground_stroke_width();
	}

	static bool
	has_fill (const Shape* shape)
	{
		assert(shape);

		const Color* fill = get_fill(shape);
		return fill && *fill;
	}

	static bool
	has_stroke_width (const Shape* shape)
	{
		assert(shape);

		return get_stroke_width(shape) > 0;
	}

	static bool
	triangulate (Polygon::TrianglePointList* triangles, const Polygon& polygon)
	{
		class TriangulatablePolygon : public Polygon
		{
			public:
				using Polygon::triangulate;
		};

		return ((const TriangulatablePolygon&) polygon).triangulate(triangles);
	}


	class FixtureBuilder
	{

		public:

			FixtureBuilder (Shape* shape, const b2Shape* head = NULL)
			:	shape(shape), head(NULL), tail(NULL)
			{
				assert(shape);

				if (head) add(head);
			}

			void add (const b2Shape* b2shape)
			{
				assert(b2shape);

				Body* body = View_get_body(shape->owner());
				if (!body)
					invalid_state_error(__FILE__, __LINE__);

				append(new Fixture(body, b2shape, shape));
			}

			Fixture* fixtures () const
			{
				return head;
			}

		private:

			Shape* shape;

			Fixture *head, *tail;

			void append (Fixture* fixture)
			{
				if (!fixture) return;

				if (tail)
					tail->set_next(fixture);
				else
				{
					assert(!head && !tail);
					head = tail = fixture;
				}

				while (tail && tail->next())
					tail = tail->next();
			}

	};// FixtureBuilder


	static Fixture*
	create_empty_fixture (Shape* shape)
	{
		assert(shape);

		b2CircleShape b2shape;
		return FixtureBuilder(shape, &b2shape).fixtures();
	}

	static Fixture*
	create_solid_fixtures (Shape* shape, const Polygon& polygon, float ppm)
	{
		assert(shape);

		Polygon::TrianglePointList triangles;
		if (!triangulate(&triangles, polygon))
			return NULL;

		assert((triangles.size() % 3) == 0);

		if (triangles.empty())
			return NULL;

		std::vector<b2Vec2> b2points;
		b2points.reserve(triangles.size());
		for (const auto& point : triangles)
			b2points.emplace_back(to_b2vec2(point, ppm));

		FixtureBuilder builder(shape);
		for (size_t i = 0; i < b2points.size(); i += 3)
		{
			b2PolygonShape b2shape;
			b2shape.Set(&b2points[i], 3);
			if (b2shape.m_count != 3)
				continue;// skip too small triangle

			builder.add(&b2shape);
		}

		return builder.fixtures();
	}

	static void
	add_polyline (
		FixtureBuilder* builder, const Polyline& polyline, float ppm,
		std::vector<b2Vec2>* buffer)
	{
		assert(builder && buffer);

		buffer->clear();
		buffer->reserve(polyline.size());
		for (const auto& point : polyline)
			buffer->emplace_back(to_b2vec2(point, ppm));

		b2ChainShape b2shape;
		if (polyline.loop())
			b2shape.CreateLoop(&(*buffer)[0], (int32) buffer->size());
		else
		{
			b2shape.CreateChain(
				&(*buffer)[0],
				(int32) buffer->size(),
				(*buffer)[0],
				(*buffer)[buffer->size() - 1]);
		}

		builder->add(&b2shape);
	}

	static Fixture*
	create_line_fixtures (Shape* shape, const Polygon& polygon, float ppm)
	{
		assert(shape);

		FixtureBuilder builder(shape);

		std::vector<b2Vec2> b2points;
		for (const auto& polyline : polygon)
			add_polyline(&builder, polyline, ppm, &b2points);

		return builder.fixtures();
	}


	struct Shape::Data
	{

		enum Flags
		{

			UPDATE_POLYGON = Xot::bit(0),

			DEFAULT_FLAGS  = UPDATE_POLYGON

		};// Flags

		View* owner = NULL;

		uint flags  = DEFAULT_FLAGS;

		Polygon polygon;

		SelectorPtr              pselector;

		std::unique_ptr<Bounds>  pframe;

		std::unique_ptr<Fixture> pfixtures;

		virtual ~Data ()
		{
		}

		virtual void set_frame (const Bounds& frame)
		{
			if (pframe && *pframe == frame)
				return;

			if (pframe)
				*pframe = frame;
			else
				pframe.reset(new Bounds(frame));

			update_polygon_later();
		}

		virtual Bounds get_frame () const
		{
			if (pframe)
				return *pframe;
			else if (owner)
				return owner->frame().dup().move_to(0, 0);
			else
				return 0;
		}

		virtual bool has_frame () const
		{
			return (bool) pframe;
		}

		void update_polygon_later ()
		{
			if (!owner) return;

			Xot::add_flag(&flags, UPDATE_POLYGON);
			View_update_shapes(owner);
		}

		void update_polygon (Shape* shape, bool force = false)
		{
			assert(shape);

			bool update = Xot::check_and_remove_flag(&flags, UPDATE_POLYGON);
			if (!update && !force) return;

			if (!owner || !View_is_active(*owner))
				polygon = Polygon();
			else
			{
				Polygon poly = get_polygon_for_shape();
				if (!force && poly.self == polygon.self)
					return;

				polygon = poly;//clip_polygon(poly);
			}

			update_fixtures(shape);
		}

		Polygon clip_polygon (const Polygon& polygon)
		{
			if (!pframe || !polygon)
				return polygon;

			return polygon & Rays::create_rect(0, 0, pframe->width, pframe->height);
		}

		void update_fixtures (Shape* shape)
		{
			if (pfixtures)
			{
				std::unique_ptr<Fixture> old_fix = std::move(pfixtures);
				Fixture_copy_attributes(&fixtures(shape), *old_fix);
			}
			else if (has_body())
				fixtures(shape);
		}

		Fixture& fixtures (Shape* shape)
		{
			assert(shape);

			if (!pfixtures)
			{
				Fixture* fix;
				if (has_body())
				{
					fix = create_fixtures(shape);
					if (!fix) fix = create_empty_fixture(shape);
				}
				else
					fix = Fixture_create_temporary();

				assert(fix);
				pfixtures.reset(fix);
			}
			return *pfixtures;
		}

		bool has_body () const
		{
			Body* body = View_get_body(owner, false);
			return body && !Body_is_temporary(*body);
		}

		virtual Fixture* create_fixtures (Shape* shape)
		{
			if (!owner)
				invalid_state_error(__FILE__, __LINE__);

			// if the view has been added to the window but on_update() has not yet
			// been called, update_polygon() has also never been called.
			update_polygon(shape);

			Polygon polygon = get_polygon_for_fixtures();
			if (!polygon || polygon.empty())
				return NULL;

			float ppm = owner->meter2pixel();

			if (has_fill(shape))
				return create_solid_fixtures(shape, polygon, ppm);
			else if (has_stroke_width(shape))
			{
				Polygon hole;
				if (!polygon.expand(&hole, -get_stroke_width(shape)))
					return NULL;

				return create_solid_fixtures(shape, polygon - hole, ppm);
			}
			else
				return create_line_fixtures(shape, polygon, ppm);
		}

		virtual Polygon get_polygon_for_shape () const = 0;

		virtual Polygon get_polygon_for_fixtures () const
		{
			return polygon;
		}

	};// Shape::Data


	bool
	Shape_set_owner (Shape* shape, View* owner)
	{
		if (!shape)
			argument_error(__FILE__, __LINE__);

		Shape::Data* self = shape->self.get();

		if (owner == self->owner)
			return false;

		if (owner && self->owner)
			invalid_state_error(__FILE__, __LINE__);

		self->owner = owner;
		return true;
	}

	bool
	Shape_has_frame (const Shape& shape)
	{
		return shape.self->has_frame();
	}

	void
	Shape_update (Shape* shape, bool force)
	{
		if (!shape)
			argument_error(__FILE__, __LINE__);

		shape->self->update_polygon(shape, force);
	}

	void
	Shape_call_contact_event (Shape* shape, ContactEvent* event)
	{
		if (!shape || !event)
			argument_error(__FILE__, __LINE__);

		shape->on_contact(event);

		switch (event->action())
		{
			case ContactEvent::BEGIN: shape->on_contact_begin(event); break;
			case ContactEvent::END:   shape->on_contact_end(event);   break;
			default: break;
		}

		if (event->is_blocked()) return;

		View_call_contact_event(shape->owner(), event);
	}


	Shape::Shape (Data* data, const char* name)
	:	self(data)
	{
		if (name) set_name(name);
	}

	Shape::~Shape ()
	{
	}

	View*
	Shape::owner ()
	{
		return self->owner;
	}

	const View*
	Shape::owner () const
	{
		return const_cast<Shape*>(this)->owner();
	}

	void
	Shape::set_frame (coord x, coord y, coord width, coord height)
	{
		set_frame(Bounds(x, y, width, height));
	}

	void
	Shape::set_frame (const Bounds& frame)
	{
		self->set_frame(frame);
	}

	Bounds
	Shape::frame () const
	{
		return self->get_frame();
	}

	void
	Shape::set_density (float density)
	{
		if (density == this->density()) return;

		self->fixtures(this).set_density(density);
	}

	float
	Shape::density () const
	{
		const Fixture* f = self->pfixtures.get();
		return f ? f->density() : 0;
	}

	void
	Shape::set_friction (float friction)
	{
		if (friction == this->friction()) return;

		self->fixtures(this).set_friction(friction);
	}

	float
	Shape::friction () const
	{
		const Fixture* f = self->pfixtures.get();
		return f ? f->friction() : 0;
	}

	void
	Shape::set_restitution (float restitution)
	{
		if (restitution == this->restitution()) return;

		self->fixtures(this).set_restitution(restitution);
	}

	float
	Shape::restitution () const
	{
		const Fixture* f = self->pfixtures.get();
		return f ? f->restitution() : 0;
	}

	void
	Shape::set_sensor (bool state)
	{
		if (state == is_sensor()) return;

		self->fixtures(this).set_sensor(state);
	}

	bool
	Shape::is_sensor () const
	{
		const Fixture* f = self->pfixtures.get();
		return f ? f->is_sensor() : false;
	}

	void
	Shape::on_draw (DrawEvent* e)
	{
		assert(e && e->painter());

		e->painter()->polygon(self->polygon);
	}

	void
	Shape::on_resize (FrameEvent* e)
	{
		if (!self->has_frame())
			self->update_polygon_later();
	}

	bool
	Shape::will_contact (Shape* s)
	{
		return true;
	}

	void
	Shape::on_contact (ContactEvent* e)
	{
	}

	void
	Shape::on_contact_begin (ContactEvent* e)
	{
	}

	void
	Shape::on_contact_end (ContactEvent* e)
	{
	}

	SelectorPtr*
	Shape::get_selector_ptr ()
	{
		return &self->pselector;
	}


	struct FixedFrameShapeData : public Shape::Data
	{

		void set_frame (const Bounds& frame) override
		{
			// updating frame for shape has fixed frame is not supported.
			not_implemented_error(__FILE__, __LINE__);
		}

		Bounds get_frame () const override
		{
			return get_fixed_frame();
		}

		bool has_frame () const override
		{
			return has_fixed_frame();
		}

		virtual Bounds get_fixed_frame () const = 0;

		virtual bool   has_fixed_frame () const = 0;

	};// FixedFrameShapeData


	struct PolygonShapeData : public FixedFrameShapeData
	{

		Polygon polygon;

		Polygon get_polygon_for_shape () const override
		{
			return polygon;
		}

		Bounds get_fixed_frame () const override
		{
			return polygon.bounds();
		}

		bool has_fixed_frame () const override
		{
			return !polygon.empty(true);
		}

	};// PolygonShapeData


	static PolygonShapeData&
	get_data (PolygonShape& shape)
	{
		return (PolygonShapeData&) *shape.self;
	}

	static const PolygonShapeData&
	get_data (const PolygonShape& shape)
	{
		return get_data(const_cast<PolygonShape&>(shape));
	}


	PolygonShape::PolygonShape (const char* name)
	:	Super(new PolygonShapeData, name)
	{
	}

	PolygonShape::~PolygonShape ()
	{
	}

	void
	PolygonShape::set_polygon (const Polygon& polygon)
	{
		get_data(*this).polygon = polygon;

		self->update_polygon_later();
	}

	const Polygon&
	PolygonShape::polygon () const
	{
		return get_data(*this).polygon;
	}


	struct LineShapeData : public FixedFrameShapeData
	{

		std::vector<Point> points;

		bool loop = false;

		Polygon get_polygon_for_shape () const override
		{
			if (points.empty())
				return Polygon();

			return Rays::create_line(&points[0], points.size(), loop);
		}

		Bounds get_fixed_frame () const override
		{
			if (points.empty()) return Bounds(-1, -1, -1);

			Bounds b(points[0], 0);
			for (const auto& point : points)
				b |= point;
			return b;
		}

		bool has_fixed_frame () const override
		{
			return !points.empty();
		}

	};// LineShapeData


	static LineShapeData&
	get_data (LineShape& shape)
	{
		return (LineShapeData&) *shape.self;
	}

	static const LineShapeData&
	get_data (const LineShape& shape)
	{
		return get_data(const_cast<LineShape&>(shape));
	}


	LineShape::LineShape (const char* name)
	:	Super(new LineShapeData, name)
	{
	}

	LineShape::~LineShape ()
	{
	}

	void
	LineShape::add_point (coord x, coord y, coord z)
	{
		add_point(Point(x, y, z));
	}

	void
	LineShape::add_point (const Point& point)
	{
		get_data(*this).points.emplace_back(point);

		self->update_polygon_later();
	}

	void
	LineShape::add_points (const Point* points, size_t size)
	{
		auto& array = get_data(*this).points;
		array.insert(array.end(), points, points + size);

		self->update_polygon_later();
	}

	void
	LineShape::set_loop (bool loop)
	{
		get_data(*this).loop = loop;
	}

	bool
	LineShape::loop () const
	{
		return get_data(*this).loop;
	}


	struct RectShapeData : public Shape::Data
	{

		typedef Shape::Data Super;

		coord round_left_top     = 0;
		coord round_right_top    = 0;
		coord round_left_bottom  = 0;
		coord round_right_bottom = 0;

		uint nsegment = 0;

		Fixture* create_fixtures (Shape* shape) override
		{
			Bounds frame = get_frame();
			bool rect    = frame.size() != 0;
			if (rect && !has_rounds())
				return create_rect_fixture(shape, frame);
			else if (rect && nsegment <= 1)
				return create_rect_fixture_without_division(shape, frame);
			else
				return Super::create_fixtures(shape);
		}

		Fixture* create_rect_fixture (Shape* shape, const Bounds& frame)
		{
			assert(shape);

			if (!owner)
				invalid_state_error(__FILE__, __LINE__);

			float ppm = owner->meter2pixel();
			coord l   = to_b2coord(frame.x,           ppm);
			coord t   = to_b2coord(frame.y,           ppm);
			coord r   = to_b2coord(frame.x + frame.w, ppm);
			coord b   = to_b2coord(frame.x + frame.h, ppm);
			b2Vec2 b2points[] = {{l, t}, {l, b}, {r, b}, {r, t}};

			b2PolygonShape b2shape;
			b2shape.Set(&b2points[0], 4);

			return FixtureBuilder(shape, &b2shape).fixtures();
		}

		Fixture* create_rect_fixture_without_division (
			Shape* shape, const Bounds& frame)
		{
			assert(shape);

			if (!owner)
				invalid_state_error(__FILE__, __LINE__);

			Polygon polygon = Rays::create_rect(
				frame.x, frame.y, frame.width, frame.height,
				round_left_top,    round_right_top,
				round_left_bottom, round_right_bottom,
				1);
			assert(polygon.size() == 1);

			float ppm                = owner->meter2pixel();
			const Polyline& polyline = polygon[0];
			assert(polyline[0].size() <= 8);

			b2Vec2 b2points[8];
			for (size_t i = 0; i < polyline.size(); ++i)
				b2points[i] = to_b2vec2(polyline[i], ppm);

			b2PolygonShape b2shape;
			b2shape.Set(&b2points[0], polyline.size());

			return FixtureBuilder(shape, &b2shape).fixtures();
		}

		Polygon get_polygon_for_shape () const override
		{
			return Rays::create_rect(
				get_frame(),
				round_left_top,    round_right_top,
				round_left_bottom, round_right_bottom,
				nsegment);
		}

		Polygon get_polygon_for_fixtures () const override
		{
			if (nsegment <= 0 && has_rounds())
				return Rays::create_rect(get_frame(), 0, 0, 0, 0, 1);
			else
				return Super::get_polygon_for_fixtures();
		}

		bool has_rounds () const
		{
			return
				round_left_top     != 0 ||
				round_right_top    != 0 ||
				round_left_bottom  != 0 ||
				round_right_bottom != 0;
		}

	};// RectShapeData


	static RectShapeData&
	get_data (RectShape& shape)
	{
		return (RectShapeData&) *shape.self;
	}

	static const RectShapeData&
	get_data (const RectShape& shape)
	{
		return get_data(const_cast<RectShape&>(shape));
	}


	RectShape::RectShape (const char* name)
	:	Super(new RectShapeData, name)
	{
	}

	RectShape::~RectShape ()
	{
	}

	void
	RectShape::set_round (coord round)
	{
		set_round(round, round, round, round);
	}

	void
	RectShape::set_round (
		coord left_top, coord right_top, coord left_bottom, coord right_bottom)
	{
		RectShapeData& data = get_data(*this);
		data.round_left_top     = left_top;
		data.round_right_top    = right_top;
		data.round_left_bottom  = left_bottom;
		data.round_right_bottom = right_bottom;

		self->update_polygon_later();
	}

	void
	RectShape::set_round_left_top (coord round)
	{
		get_data(*this).round_left_top = round;

		self->update_polygon_later();
	}

	coord
	RectShape::round_left_top () const
	{
		return get_data(*this).round_left_top;
	}

	void
	RectShape::set_round_right_top (coord round)
	{
		get_data(*this).round_right_top = round;

		self->update_polygon_later();
	}

	coord
	RectShape::round_right_top () const
	{
		return get_data(*this).round_right_top;
	}

	void
	RectShape::set_round_left_bottom (coord round)
	{
		get_data(*this).round_left_bottom = round;

		self->update_polygon_later();
	}

	coord
	RectShape::round_left_bottom () const
	{
		return get_data(*this).round_left_bottom;
	}

	void
	RectShape::set_round_right_bottom (coord round)
	{
		get_data(*this).round_right_bottom = round;

		self->update_polygon_later();
	}

	coord
	RectShape::round_right_bottom () const
	{
		return get_data(*this).round_right_bottom;
	}

	void
	RectShape::set_nsegment (uint nsegment)
	{
		get_data(*this).nsegment = nsegment;

		self->update_polygon_later();
	}

	uint
	RectShape::nsegment () const
	{
		return get_data(*this).nsegment;
	}


	struct EllipseShapeData : public Shape::Data
	{

		typedef Shape::Data Super;

		enum
		{
			DEFAULT_ANGLE_FROM = 0,
			DEFAULT_ANGLE_TO   = 360,

			ANGLE_MAX = DEFAULT_ANGLE_TO - DEFAULT_ANGLE_FROM
		};

		Point hole_size;

		float angle_from = DEFAULT_ANGLE_FROM;
		float angle_to   = DEFAULT_ANGLE_TO;

		uint nsegment = 0;

		bool has_hole () const
		{
			return hole_size.x != 0 && hole_size.y != 0;
		}

		bool has_angle () const
		{
			return
				angle_from != (float) DEFAULT_ANGLE_FROM ||
				angle_to   != (float) DEFAULT_ANGLE_TO;
		}

		Fixture* create_fixtures (Shape* shape) override
		{
			Bounds frame = get_frame();
			bool circle  = frame.size() != 0 && frame.width == frame.height;
			if (circle && !has_angle() && !has_hole() && has_fill(shape))
				return create_circle_fixture(shape, frame);
			else
				return Super::create_fixtures(shape);
		}

		Fixture* create_circle_fixture (Shape* shape, const Bounds& frame)
		{
			assert(shape);

			if (!owner)
				invalid_state_error(__FILE__, __LINE__);

			float ppm = owner->meter2pixel();

			b2CircleShape b2shape;
			b2shape.m_p      = to_b2vec2(frame.center(), ppm);
			b2shape.m_radius = to_b2coord(frame.width / 2, ppm);

			return FixtureBuilder(shape, &b2shape).fixtures();
		}

		Polygon get_polygon_for_shape () const override
		{
			return Rays::create_ellipse(
				get_frame(), hole_size, angle_from, angle_to, nsegment);
		}

		Polygon get_polygon_for_fixtures () const override
		{
			if (nsegment <= 0)
			{
				return Rays::create_ellipse(
					get_frame(), hole_size, angle_from, angle_to, 8);
			}
			else
				return Super::get_polygon_for_fixtures();
		}

	};// EllipseShapeData


	static EllipseShapeData&
	get_data (EllipseShape& shape)
	{
		return (EllipseShapeData&) *shape.self;
	}

	static const EllipseShapeData&
	get_data (const EllipseShape& shape)
	{
		return get_data(const_cast<EllipseShape&>(shape));
	}


	EllipseShape::EllipseShape (const char* name)
	:	Super(new EllipseShapeData, name)
	{
	}

	EllipseShape::~EllipseShape ()
	{
	}

	void
	EllipseShape::set_hole_size (coord width, coord height)
	{
		get_data(*this).hole_size.reset(width, height);

		self->update_polygon_later();
	}

	void
	EllipseShape::set_hole_size (const Point& hole_size)
	{
		set_hole_size(hole_size.x, hole_size.y);
	}

	const Point&
	EllipseShape::hole_size () const
	{
		return get_data(*this).hole_size;
	}

	void
	EllipseShape::set_angle_from (float degree)
	{
		get_data(*this).angle_from = degree;

		self->update_polygon_later();
	}

	float
	EllipseShape::angle_from () const
	{
		return get_data(*this).angle_from;
	}

	void
	EllipseShape::set_angle_to (float degree)
	{
		get_data(*this).angle_to = degree;

		self->update_polygon_later();
	}

	float
	EllipseShape::angle_to () const
	{
		return get_data(*this).angle_to;
	}

	void
	EllipseShape::set_nsegment (uint num_of_segments)
	{
		get_data(*this).nsegment = num_of_segments;

		self->update_polygon_later();
	}

	uint
	EllipseShape::nsegment () const
	{
		return get_data(*this).nsegment;
	}


	struct WallShapeData : public Shape::Data
	{

		uint positions  = 0;

		coord thickness = 0;

		Polygon get_polygon_for_shape () const override
		{
			Bounds frame = get_frame();

			Polygon poly;
			add_wall_polygon(&poly, WallShape::LEFT,   frame);
			add_wall_polygon(&poly, WallShape::TOP,    frame);
			add_wall_polygon(&poly, WallShape::RIGHT,  frame);
			add_wall_polygon(&poly, WallShape::BOTTOM, frame);
			return poly;
		}

		void add_wall_polygon (
			Polygon* polygon, WallShape::Position position, const Bounds& frame) const
		{
			assert(polygon);

			if (positions & position)
				*polygon = *polygon | create_wall_polygon(position, frame, thickness);
		}

		static Polygon create_wall_polygon (
			WallShape::Position pos, const Bounds& frame, coord thickness)
		{
			coord w = frame.width, h = frame.height, t = thickness, tt = thickness * 2;
			switch (pos)
			{
				case WallShape::LEFT:   return Rays::create_rect(-t, -t, t,      h + tt);
				case WallShape::TOP:    return Rays::create_rect(-t, -t, w + tt, t);
				case WallShape::RIGHT:  return Rays::create_rect( w, -t, t,      h + tt);
				case WallShape::BOTTOM: return Rays::create_rect(-t,  h, w + tt, t);
				default: argument_error(__FILE__, __LINE__, "invalid wall position.");
			}
			return Polygon();
		}

	};// WallShapeData


	static WallShapeData&
	get_data (WallShape& shape)
	{
		return (WallShapeData&) *shape.self;
	}

	static const WallShapeData&
	get_data (const WallShape& shape)
	{
		return get_data(const_cast<WallShape&>(shape));
	}


	WallShape::WallShape (uint positions, coord thickness)
	:	Super(new WallShapeData)
	{
		WallShapeData& data = get_data(*this);
		data.positions = positions;
		data.thickness = thickness;
	}

	void
	WallShape::on_draw (DrawEvent* e)
	{
		// wall is invisible, so draw nothing
	}


}// Reflex
