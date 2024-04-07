#include "view.h"


#include <limits.h>
#include <string.h>
#include <assert.h>
#include <memory>
#include <algorithm>
#include <rays/matrix.h>
#include "reflex/timer.h"
#include "reflex/filter.h"
#include "reflex/exception.h"
#include "reflex/debug.h"
#include "window.h"
#include "event.h"
#include "selector.h"
#include "timer.h"
#include "style.h"
#include "shape.h"
#include "world.h"
#include "body.h"
#include "fixture.h"


namespace Reflex
{


	static const char* WALL_NAME = "__WALL__";

	static const Point ZERO      = 0;


	struct View::Data
	{

		typedef std::set<Selector> SelectorSet;

		enum Flag
		{

			REDRAW               = Xot::bit(1, FLAG_LAST),

			APPLY_STYLE          = Xot::bit(2, FLAG_LAST),

			UPDATE_STYLE         = Xot::bit(3, FLAG_LAST),

			UPDATE_SHAPES        = Xot::bit(4, FLAG_LAST),

			UPDATE_LAYOUT        = Xot::bit(5, FLAG_LAST),

			SORT_CHILDREN        = Xot::bit(6, FLAG_LAST),

			FIT_TO_CONTENT       = Xot::bit(7, FLAG_LAST),

			HAS_VARIABLE_LENGTHS = Xot::bit(8, FLAG_LAST),

			NO_SHAPE             = Xot::bit(9, FLAG_LAST),

		};// Flag

		Window* window     = NULL;

		View* parent       = NULL;

		Bounds frame;

		float zoom         = 1;

		float angle        = 0;

		ushort capture     = CAPTURE_NONE;

		short hide_count   = 0;

		ushort child_index = 0;

		uint flags         =
			FLAG_CLIP | FLAG_RESIZE_TO_FIT | REDRAW | UPDATE_LAYOUT | UPDATE_STYLE;

		std::unique_ptr<Point>       ppivot;

		std::unique_ptr<Point>       pscroll;

		SelectorPtr                  pselector;

		std::unique_ptr<SelectorSet> pselectors_for_update;

		std::unique_ptr<Image>       pcache_image;

		std::unique_ptr<Timers>      ptimers;

		std::unique_ptr<Style>       pstyle;

		std::unique_ptr<StyleList>   pstyles;

		Shape::Ref                   pshape;

		std::unique_ptr<ShapeList>   pshapes;

		Filter::Ref                  pfilter;

		std::unique_ptr<Body>        pbody;

		std::unique_ptr<World>       pchild_world;

		std::unique_ptr<ChildList>   pchildren;

		std::unique_ptr<ChildList>   pchildren_sorted;

		Point& pivot ()
		{
			if (!ppivot) ppivot.reset(new Point);
			return *ppivot;
		}

		bool has_pivot () const
		{
			return ppivot && *ppivot != ZERO;
		}

		Point& scroll ()
		{
			if (!pscroll) pscroll.reset(new Point);
			return *pscroll;
		}

		bool has_scroll () const
		{
			return pscroll && *pscroll != ZERO;
		}

		Selector& selector ()
		{
			if (!pselector) pselector.reset(new Selector);
			return *pselector;
		}

		SelectorSet& selectors_for_update ()
		{
			if (!pselectors_for_update) pselectors_for_update.reset(new SelectorSet);
			return *pselectors_for_update;
		}

		Timers& timers ()
		{
			if (!ptimers) ptimers.reset(new Timers);
			return *ptimers;
		}

		Style& style (View* view)
		{
			if (!pstyle)
			{
				pstyle.reset(new Style);
				Style_set_owner(pstyle.get(), view);
			}
			return *pstyle;
		}

		StyleList& styles ()
		{
			if (!pstyles) pstyles.reset(new StyleList);
			return *pstyles;
		}

		ShapeList& shapes ()
		{
			if (!pshapes) pshapes.reset(new ShapeList);
			return *pshapes;
		}

		template <typename FUN>
		void each_shape (FUN fun)
		{
			if (pshape)
				fun(pshape.get());

			if (pshapes)
			{
				for (auto& shape : *pshapes)
					fun(shape.get());
			}
		}

		template <typename FUN>
		void each_shape (FUN fun) const
		{
			const_cast<Data*>(this)->each_shape(fun);
		}

		void update_shapes (bool force = false)
		{
			each_shape([=](Shape* shape)
			{
				Shape_update(shape, force);
			});
		}

		void resize_shapes (FrameEvent* e)
		{
			each_shape([=](Shape* shape)
			{
				shape->on_resize(e);
			});
		}

		Body& body ()
		{
			if (!pbody)
			{
				World* world = parent_world();
				Body* b      = world
					?	new Body(world, frame.position(), angle)
					:	Body_create_temporary();
				assert(b);

				pbody.reset(b);
				update_body_frame();
				update_body_states();
			}
			return *pbody;
		}

		void update_body_frame ()
		{
			if (!pbody) return;

			auto* pivot = ppivot.get();
			if (pivot && (pivot->x != 0 || pivot->y != 0) && angle != 0)
			{
				Matrix m;
				get_view2body_matrix(&m);
				pbody->set_transform(m * Point(0), angle);
			}
			else
				pbody->set_transform(frame.x, frame.y, angle);
		}

		void update_body_states ()
		{
			if (pbody && pbody->is_rotation_fixed() != has_flag(View::FLAG_FIX_ANGLE))
				pbody->fix_rotation(has_flag(View::FLAG_FIX_ANGLE));
		}

		void
		get_view2body_matrix (Matrix* m)
		{
			assert(*m == 1 && ppivot && *ppivot != 0);

			Point pivot = *ppivot * frame.size();
			m->translate(frame.position() + pivot)
				.rotate(angle)
				.translate(-pivot);
		}

		void
		get_body2view_matrix (Matrix* m)
		{
			assert(*m == 1 && ppivot && *ppivot != 0 && pbody);

			Point pos   = pbody->position();
			Point pivot = *ppivot * frame.size();
			float angle = pbody->angle();
			m->translate(pos.x, pos.y, frame.z)
				.rotate(angle)
				.translate( pivot)
				.rotate(-angle)
				.translate(-pivot);
		}

		void setup_body_and_shapes ()
		{
			std::unique_ptr<Body> old_body;
			if (pbody)
			{
				old_body = std::move(pbody);
				Body_copy_attributes(&body(), *old_body);
			}

			update_shapes(true);
		}

		World* parent_world (bool create = true)
		{
			if (!parent) return NULL;
			return parent->self->child_world(parent, create);
		}

		World* child_world (View* view, bool create = true)
		{
			if (!pchild_world && create)
			{
				pchild_world.reset(new World());
				create_walls(view);
			}

			return pchild_world.get();
		}

		void create_walls (View* view)
		{
			clear_walls(view);

			View* wall = new View(WALL_NAME);
			wall->add_shape(new WallShape(WallShape::ALL));
			wall->set_static();

			view->add_child(wall);
		}

		void clear_walls (View* view)
		{
			for (auto& wall : view->find_children(WALL_NAME))
				view->remove_child(wall.get());
		}

		ChildList* children (bool create = false, bool sort = false)
		{
			if (!pchildren)
			{
				if (!create) return NULL;
				pchildren.reset(new ChildList);
			}

			if (sort && check_and_remove_flag(SORT_CHILDREN))
				do_sort_children();

			return sort && pchildren_sorted ? pchildren_sorted.get() : pchildren.get();
		}

		void sort_children (bool order_only = false)
		{
			add_flag(SORT_CHILDREN);
			if (!order_only && pchildren_sorted) pchildren_sorted.reset();
		}

		void add_flag (uint flag)
		{
			Xot::add_flag(&flags, flag);
		}

		void remove_flag (uint flag)
		{
			Xot::remove_flag(&flags, flag);
		}

		bool has_flag (uint flag) const
		{
			return Xot::has_flag(flags, flag);
		}

		bool check_and_remove_flag (uint flag)
		{
			return Xot::check_and_remove_flag(&flags, flag);
		}

		private:

			void do_sort_children ()
			{
				auto& children = *pchildren;

				size_t size = children.size();
				if (size >= USHRT_MAX)
					invalid_state_error(__FILE__, __LINE__, "too many children");

				ushort index = 0;
				bool have_z  = false;
				for (auto& child : children)
				{
					child->self->child_index = index++;
					have_z                  |= child->frame().z != 0;
				}

				if (!have_z)
				{
					pchildren_sorted.reset();
					return;
				}

				if (!pchildren_sorted)
				{
					pchildren_sorted.reset(
						new ChildList(children.begin(), children.end()));
				}

				std::sort(
					pchildren_sorted->begin(), pchildren_sorted->end(),
					[](const auto& a, const auto& b)
					{
						auto *aa = a->self.get(), *bb = b->self.get();
						if (aa->frame.z != bb->frame.z)
							return aa->frame.z     < bb->frame.z;
						else
							return aa->child_index < bb->child_index;
					});
			}

	};// View::Data


	class LayoutContext
	{

		public:

			LayoutContext (View* parent)
			:	parent(parent),
				parent_style(View_get_style(parent)),
				parent_frame(parent->self->frame)
			{
				Style::Flow flow_main, flow_sub;
				parent_style.get_flow(&flow_main, &flow_sub);
				get_flow_sign(&flow_main_h, &flow_main_v, flow_main);
				get_flow_sign(&flow_sub_h,  &flow_sub_v,  flow_sub);
			}

			void place_children ()
			{
				View::ChildList* children = parent->self->children();
				if (!children || children->empty())
					return;

				bool leftward = flow_main_h < 0 || flow_sub_h < 0;
				bool upward   = flow_main_v < 0 || flow_sub_v < 0;
				Point start_position(
					leftward ? parent_frame.width  : 0,
					upward   ? parent_frame.height : 0);
				Point position = start_position;

				for (iterator begin = children->begin(), end = children->end(); true;)
				{
					iterator line_end;
					coord main_fill_size = 0;
					coord sub_size_max   = 0;
					calc_line(&line_end, &main_fill_size, &sub_size_max, begin, end);

					for (iterator it = begin; it != line_end; ++it)
						place_child(it->get(), &position, main_fill_size, sub_size_max);

					if (line_end == end)
						break;

					flow_value(position.x, position.y, DIR_MAIN) =
						flow_value(start_position.x, start_position.y, DIR_MAIN);

					flow_value(position.x, position.y, DIR_SUB) +=
						sub_size_max * flow_value(flow_sub_h, flow_sub_v, DIR_SUB);

					begin = line_end;
				}
			}

		private:

			enum FlowDirection {DIR_MAIN, DIR_SUB};

			typedef View::ChildList::iterator iterator;

			View* parent;

			const Style& parent_style;

			const Bounds& parent_frame;

			schar flow_main_h, flow_main_v, flow_sub_h, flow_sub_v;

			static void get_flow_sign (schar* h, schar* v, Style::Flow flow)
			{
				switch (flow)
				{
					case Style::FLOW_RIGHT: *h = +1; *v =  0; break;
					case Style::FLOW_DOWN:  *h =  0; *v = +1; break;
					case Style::FLOW_LEFT:  *h = -1; *v =  0; break;
					case Style::FLOW_UP:    *h =  0; *v = -1; break;
					default:                *h =  0; *v =  0; break;
				}
			}

			void calc_line (
				iterator* line_end, coord* main_fill_size, coord* sub_size_max,
				iterator begin, iterator end)
			{
				*line_end       = end;
				*main_fill_size = 0;
				*sub_size_max   = 0;

				if (!has_flow())
					return;

				bool multiline     = flow_sub_h != 0 || flow_sub_v != 0;
				bool line_has_fill = false;
				coord parent_size  = flow_size(parent_frame, DIR_MAIN);
				coord pos          = 0;

				for (iterator it = begin; it != end; ++it)
				{
					const View* child  = it->get();
					const Style* style = child->self->pstyle.get();
					if (is_absolute(style))
						continue;

					const Bounds& frame = child->self->frame;
					coord main_size     = flow_size(frame, DIR_MAIN);
					bool child_has_fill = has_fill_length(style, DIR_MAIN);

					if (multiline && it != begin)
					{
						bool next_line   = (pos + main_size) > parent_size;
						bool double_fill = child_has_fill && line_has_fill;
						if (next_line || double_fill)
						{
							*line_end = it;
							break;
						}
					}

					if (!child_has_fill)
						pos += main_size;

					if (!has_fill_length(style, DIR_SUB))
					{
						coord sub_size = flow_size(frame, DIR_SUB);
						if (sub_size > *sub_size_max) *sub_size_max = sub_size;
					}

					line_has_fill |= child_has_fill;
				}

				*main_fill_size = parent_size - pos;
			}

			void place_child (
				View* child, Point* position, coord main_fill_size, coord sub_size_max)
			{
				const Style* style = child->self->pstyle.get();
				Bounds frame       = child->frame();
				bool update        = false;

				if (has_flow() && !is_absolute(style))
				{
					update |= fill_child(&frame, style, main_fill_size, sub_size_max);
					update |= place_in_flow(&frame, position);
				}

				update |= place_position(&frame, style);

				if (update)
					View_set_frame(child, frame);
			}

			bool fill_child (
				Bounds* frame,
				const Style* style, coord main_fill_size, coord sub_size_max)
			{
				bool update = false;

				if (has_fill_length(style, DIR_MAIN))
					update |= set_flow_size(frame, main_fill_size, DIR_MAIN);

				if (has_fill_length(style, DIR_SUB))
					update |= set_flow_size(frame, sub_size_max, DIR_SUB);

				return update;
			}

			bool place_in_flow (Bounds* frame, Point* position)
			{
				coord old_x = frame->x;
				coord old_y = frame->y;

				if (flow_main_h < 0) position->x -= frame->width;
				if (flow_main_v < 0) position->y -= frame->height;

				frame->x = position->x;
				frame->y = position->y;

				if (flow_main_h > 0) position->x += frame->width;
				if (flow_main_v > 0) position->y += frame->height;

				if (flow_sub_h < 0) frame->x -= frame->width;
				if (flow_sub_v < 0) frame->y -= frame->height;

				return frame->x != old_x || frame->y != old_y;
			}

			bool place_position (Bounds* frame, const Style* style)
			{
				if (!style)
					return false;

				const StyleLength& l = style->left();
				const StyleLength& t = style->top();
				const StyleLength& r = style->right();
				const StyleLength& b = style->bottom();
				if (!l && !t && !r && !b)
					return false;

				bool update = false;

				if (l && r)
				{
					coord ll, rr;
					update |= StyleLength_get_pixel_length(&ll, l, parent_frame.w);
					update |= StyleLength_get_pixel_length(&rr, r, parent_frame.w);
					frame->x = ll;
					frame->set_right(parent_frame.w - rr);
				}
				else if (l && !r)
					update |= StyleLength_get_pixel_length(&frame->x, l, parent_frame.w);
				else if (!l && r)
				{
					coord rr;
					update |= StyleLength_get_pixel_length(&rr, r, parent_frame.w);
					frame->x = parent_frame.w - (rr + frame->w);
				}

				if (t && b)
				{
					coord tt, bb;
					update |= StyleLength_get_pixel_length(&tt, t, parent_frame.h);
					update |= StyleLength_get_pixel_length(&bb, b, parent_frame.h);
					frame->y = tt;
					frame->set_bottom(parent_frame.h - bb);
				}
				else if (t && !b)
					update |= StyleLength_get_pixel_length(&frame->y, t, parent_frame.h);
				else if (!t && b)
				{
					coord bb;
					update |= StyleLength_get_pixel_length(&bb, b, parent_frame.h);
					frame->y = parent_frame.h - (bb + frame->h);
				}

				return update;
			}

			template <typename T>
			T& flow_value (T& horizontal, T& vertical, FlowDirection dir) const
			{
				if (dir == DIR_MAIN)
					return is_horizontal() ? horizontal : vertical;
				else
					return is_horizontal() ? vertical   : horizontal;
			}

			bool set_flow_size (Bounds* frame, coord size, FlowDirection dir) const
			{
				coord& value = flow_value(frame->width, frame->height, dir);
				if (value == size) return false;

				value = size;
				return true;
			}

			const coord& flow_size (const Bounds& frame, FlowDirection dir) const
			{
				return flow_value(frame.width, frame.height, dir);
			}

			bool is_horizontal () const
			{
				return flow_main_h != 0;
			}

			bool is_absolute (const Style* style) const
			{
				if (!style) return false;

				if (is_horizontal())
					return style->top()  || style->bottom();
				else
					return style->left() || style->right();
			}

			bool has_flow () const
			{
				return flow_main_h != 0 || flow_main_v != 0;
			}

			bool has_fill_length (const Style* style, FlowDirection dir) const
			{
				if (!style) return false;

				const StyleLength& l = flow_value(style->width(), style->height(), dir);
				return l.type() == StyleLength::FILL;
			}

	};// LayoutContext


	void
	View_set_window (View* view, Window* window)
	{
		if (!view)
			argument_error(__FILE__, __LINE__);

		if (view->self->window)
		{
			Event e;
			view->on_detach(&e);
			view->set_capture(View::CAPTURE_NONE);
		}

		view->self->window = window;
		view->self->setup_body_and_shapes();

		View::ChildList* children = view->self->children();
		if (children)
		{
			for (auto& child : *children)
				View_set_window(child.get(), window);
		}

		if (view->self->window)
		{
			Event e;
			view->on_attach(&e);
			view->self->add_flag(View::Data::FIT_TO_CONTENT);
		}
	}

	static void
	apply_style_to_children_have_variable_lengths (View* parent)
	{
		View::ChildList* children = parent->self->children();
		if (!children) return;

		for (auto& child : *children)
		{
			if (child->self->has_flag(View::Data::HAS_VARIABLE_LENGTHS))
				child->self->add_flag(View::Data::APPLY_STYLE);
		}
	}

	static void
	update_view_layout (View* view, bool update_parent = false)
	{
		View::Data* self = view->self.get();

		self->add_flag(View::Data::UPDATE_LAYOUT);

		if (update_parent && self->parent)
			update_view_layout(self->parent);
	}

	static void
	update_view_frame (
		View* view, const Bounds& frame, float zoom, float angle,
		bool update_body = true)
	{
		View::Data* self = view->self.get();

		if (frame == self->frame && zoom == self->zoom && angle == self->angle)
			return;

		FrameEvent event(frame, self->frame, zoom, self->zoom, angle, self->angle);
		self->frame = frame;
		self->zoom  = zoom;
		self->angle = angle;

		bool moved   = event.is_move();
		bool resized = event.is_resize();
		bool zoomed  = event.is_zoom();
		bool rotated = event.is_rotate();

		if (moved)   view->on_move(&event);
		if (resized) view->on_resize(&event);
		if (zoomed)  view->on_zoom(&event);
		if (rotated) view->on_rotate(&event);

		if (resized)
		{
			view->self->resize_shapes(&event);
			apply_style_to_children_have_variable_lengths(view);
			update_view_layout(view, true);
		}

		if (update_body && (moved || rotated) && self->pbody)
			self->update_body_frame();

		if (moved && event.dz() != 0 && self->parent)
			self->parent->self->sort_children(true);

		if ((moved || resized) && self->parent)
			self->parent->self->add_flag(View::Data::FIT_TO_CONTENT);

		view->redraw();
	}

	void
	View_set_frame (View* view, const Bounds& frame)
	{
		if (!view)
			argument_error(__FILE__, __LINE__);

		update_view_frame(view, frame, view->zoom(), view->angle());
	}

	const Style&
	View_get_style (const View* view)
	{
		if (!view)
			argument_error(__FILE__, __LINE__);

		static const Style DEFAULT_STYLE;
		return view->self->pstyle ? *view->self->pstyle : DEFAULT_STYLE;
	}

	Body*
	View_get_body (View* view, bool create)
	{
		if (!view) return NULL;

		return create ? &view->self->body() : view->self->pbody.get();
	}

	bool
	View_is_active (const View& view)
	{
		return view.self->window;
	}

	static void
	find_all_children (
		View::ChildList* result, const View* view, const Selector& selector,
		bool recursive)
	{
		View::ChildList* children = view->self->children();
		if (!children) return;

		for (auto& child : *children)
		{
			if (!child)
				invalid_state_error(__FILE__, __LINE__);

			if (child->selector().contains(selector))
				result->push_back(child);

			if (recursive)
				find_all_children(result, child.get(), selector, true);
		}
	}

	static void
	find_all_styles (
		View::StyleList* result, const View* view, const Selector& selector,
		bool recursive)
	{
		View::StyleList* pstyles = view->self->pstyles.get();
		if (pstyles)
		{
			for (auto& style : *pstyles)
			{
				if (selector.contains(style.selector()))
					result->push_back(style);
			}
		}

		if (!recursive) return;

		View::ChildList* children = view->self->children();
		if (children)
		{
			for (auto& child : *children)
				find_all_styles(result, child.get(), selector, true);
		}
	}

	static void
	fire_timers (View* view, double now)
	{
		Timers* timers = view->self->ptimers.get();
		if (timers)
			timers->fire(now);
	}

	static void
	update_view_shapes (View* view)
	{
		View::Data* self = view->self.get();

		bool create_shape = self->pbody && !self->pshape;
		if (create_shape)
			view->shape();

		bool update = self->check_and_remove_flag(View::Data::UPDATE_SHAPES);
		if (update || create_shape)
			self->update_shapes(create_shape);
	}

	static void
	update_view_body (View* view)
	{
		View::Data* self = view->self.get();

		Body* body = self->pbody.get();
		if (!body) return;

		Bounds frame = view->frame();

		auto* pivot = self->ppivot.get();
		if (pivot && (pivot->x != 0 || pivot->y != 0) && self->angle != 0)
		{
			Matrix m;
			self->get_body2view_matrix(&m);
			frame.set_position(m * Point(0));
		}
		else
		{
			Point pos = body->position();
			frame.set_position(pos.x, pos.y, frame.z);
		}

		update_view_frame(view, frame, view->zoom(), body->angle(), false);
	}

	static void
	update_child_world (View* view, float dt)
	{
		View::Data* self = view->self.get();

		World* child_world = self->pchild_world.get();
		if (!child_world) return;

		child_world->on_update(dt);

		View::ChildList* children = self->children();
		if (children)
		{
			for (auto& child : *children)
				update_view_body(child.get());
		}
	}

	static void
	update_views_for_selectors (View* view)
	{
		View::Data* self = view->self.get();

		View::Data::SelectorSet* sels = self->pselectors_for_update.get();
		if (!sels)
			return;

		Selector* view_sel = self->pselector.get();
		View::ChildList children;

		for (auto& sel : *sels)
		{
			if (view_sel && view_sel->contains(sel))
				self->add_flag(View::Data::UPDATE_STYLE);

			children.clear();
			find_all_children(&children, view, sel, true);
			for (auto& child : children)
				child->self->add_flag(View::Data::UPDATE_STYLE);
		}

		sels->clear();
	}

	static void
	get_styles_for_selector (
		View::StyleList* result, View* view, const Selector& selector)
	{
		View* parent = view->parent();
		if (parent)
			get_styles_for_selector(result, parent, selector);

		find_all_styles(result, view, selector, false);
	}

	static bool
	get_styles_for_view (View::StyleList* result, View* view)
	{
		result->clear();

		Selector* sel = view->self->pselector.get();
		if (!sel || sel->empty())
			return false;

		get_styles_for_selector(result, view, *sel);
		return !result->empty();
	}

	static void
	update_view_style (View* view)
	{
		View::Data* self = view->self.get();

		Style* pstyle = self->pstyle.get();
		if (pstyle)
			Style_clear_inherited_values(pstyle);

		View::StyleList styles;
		if (get_styles_for_view(&styles, view))
		{
			if (!pstyle)
				pstyle = &self->style(view);

			for (auto& st : styles)
				Style_override(pstyle, st);
		}

		const Style& style = View_get_style(view);
		if (Style_has_variable_lengths(style))
			self->add_flag(View::Data::HAS_VARIABLE_LENGTHS);
		else
			self->remove_flag(View::Data::HAS_VARIABLE_LENGTHS);

		self->add_flag(View::Data::APPLY_STYLE);
	}

	static void
	fit_view_to_content (View* view)
	{
		Bounds bounds = view->content_bounds();
		if (!bounds) return;

		if (view->self->has_flag(View::FLAG_SCROLL_TO_FIT))
			view->scroll_to(-bounds.position());
		else
			bounds.size() += bounds.position();

		if (view->self->has_flag(View::FLAG_RESIZE_TO_FIT))
		{
			Bounds frame = view->frame();

			const Style* style = view->style(false);
			if ((!style || !Style_has_width( *style))) frame.w = bounds.w;
			if ((!style || !Style_has_height(*style))) frame.h = bounds.h;
			frame.d = bounds.d;

			view->set_frame(frame);
		}
	}

	void
	View_update_tree (View* view, const UpdateEvent& event)
	{
		if (!view)
			argument_error(__FILE__, __LINE__);

		View::Data* self = view->self.get();

		fire_timers(view, event.now());

		View::ChildList* children = self->children();
		if (children)
		{
			for (auto& child : *children)
				View_update_tree(child.get(), event);
		}

		update_view_shapes(view);
		update_child_world(view, event.dt());

		UpdateEvent e = event.dup();
		view->on_update(&e);

		update_views_for_selectors(view);

		if (self->check_and_remove_flag(View::Data::UPDATE_STYLE))
			update_view_style(view);

		if (self->check_and_remove_flag(View::Data::APPLY_STYLE))
			Style_apply_to(View_get_style(view), view);

		if (self->check_and_remove_flag(View::Data::UPDATE_LAYOUT))
			view->update_layout();

		if (self->check_and_remove_flag(View::Data::FIT_TO_CONTENT))
			fit_view_to_content(view);
	}

	static bool
	use_cache (View* view)
	{
		View::Data* self = view->self.get();

		return
			self->has_flag(View::FLAG_CACHE) ||
			(self->pfilter && *self->pfilter);
	}

	static bool
	reset_cache_image (View* view, const Painter& painter)
	{
		assert(use_cache(view));
		View::Data* self = view->self.get();

		Image* image = self->pcache_image.get();
		int w        = ceil(self->frame.width);
		int h        = ceil(self->frame.height);
		if (
			image &&
			image->width()         == w &&
			image->height()        == h &&
			image->pixel_density() == painter.pixel_density())
		{
			return false;
		}

		self->pcache_image.reset(
			new Image(w, h, Rays::RGBA, painter.pixel_density()));
		return true;
	}

	static void
	setup_painter (Painter* painter, const Color& fill, const Color& stroke)
	{
		painter->set_fill(fill);
		painter->set_stroke(stroke);
	}

	static void
	draw_default_shape (View* view, DrawEvent* event)
	{
		Painter* painter         = event->painter();
		const Style& style       = View_get_style(view);
		const Color& back_fill   = style.background_fill();
		const Color& back_stroke = style.background_stroke();

		Shape* shape = view->shape(false);
		if (shape)
		{
			setup_painter(painter, back_fill, back_stroke);
			shape->on_draw(event);
		}
		else if (back_fill || back_stroke)
		{
			setup_painter(painter, back_fill, back_stroke);
			painter->rect(event->bounds());
		}
	}

	static void
	draw_content (View* view, DrawEvent* event)
	{
		draw_default_shape(view, event);

		const Style& style = View_get_style(view);
		setup_painter(
			event->painter(), style.foreground_fill(), style.foreground_stroke());

		View::ShapeList* pshapes = view->self->pshapes.get();
		if (pshapes && !pshapes->empty())
		{
			for (auto& pshape : *pshapes)
				pshape->on_draw(event);
		}

		view->on_draw(event);
	}

	static void
	draw_view (
		View* view, DrawEvent* event, const Point& offset, const Bounds& clip)
	{
		View::Data* self = view->self.get();

		Painter* p = event->painter();
		p->push_state();

		if (self->has_flag(View::FLAG_CLIP) && !self->pbody)
			p->set_clip(clip);
		else
			p->no_clip();

		draw_content(view, event);

		p->pop_state();

		if (event->is_blocked()) return;

		View::ChildList* children = self->children(false, true);
		if (children)
		{
			for (auto& child : *children)
			{
				if (event->bounds() & child->self->frame)
					View_draw_tree(child.get(), event, offset, clip);
			}
		}

		World* child_world = self->pchild_world.get();
		if (child_world)
		{
			p->push_state();
			child_world->on_draw(p);
			p->pop_state();
		}
	}

	static void
	draw_view_to_cache (View* view, DrawEvent* event)
	{
		Painter* view_painter = event->painter();
		Painter cache_painter = view->self->pcache_image->painter();

		DrawEvent_set_painter(event, &cache_painter);

		cache_painter.begin();
		draw_view(view, event, 0, event->bounds());
		cache_painter.end();

		DrawEvent_set_painter(event, view_painter);
	}

	static bool
	draw_view_with_cache (View* view, DrawEvent* event, bool redraw)
	{
		View::Data* self = view->self.get();

		if (!use_cache(view))
		{
			self->pcache_image.reset();
			return false;
		}

		Painter* painter = event->painter();

		if (reset_cache_image(view, *painter) || redraw)
		{
			if (!self->pcache_image)
				return false;

			draw_view_to_cache(view, event);
		}

		painter->push_state();
		painter->set_fill(1);
		painter->no_stroke();
		painter->no_shader();

		if (self->pfilter && *self->pfilter)
			self->pfilter->apply(painter, *self->pcache_image);
		else
			painter->image(*self->pcache_image, event->bounds());

		painter->pop_state();

		return true;
	}

	void
	View_draw_tree (
		View* view, DrawEvent* event, const Point& offset, const Bounds& clip)
	{
		if (!view)
			argument_error(__FILE__, __LINE__);

		View::Data* self = view->self.get();

		bool redraw = self->check_and_remove_flag(View::Data::REDRAW);

		if (view->hidden() || event->is_blocked())
			return;

		if (self->frame.width <= 0 || self->frame.height <= 0)
			return;

		Bounds bounds = self->frame;
		Point pos     = bounds.position();
		Bounds clip2  = bounds.dup().move_by(offset) & clip;

		bounds.set_position(0, 0, bounds.z);
		if (self->pscroll)
		{
			bounds.move_by(-*self->pscroll);
			pos   .move_by( *self->pscroll);
		}

		Painter* p = event->painter();
		p->push_matrix();
		p->translate(pos);

		if (self->angle != 0)
		{
			const Point* pivot = self->ppivot.get();
			if (pivot) p->translate( pivot->x * bounds.w,  pivot->y * bounds.h);
			p->rotate(self->angle);
			if (pivot) p->translate(-pivot->x * bounds.w, -pivot->y * bounds.h);
		}

		float zoom = self->zoom;
		if (zoom != 1 && zoom > 0)
			p->scale(zoom, zoom);

		DrawEvent e = event->dup();
		DrawEvent_set_view(&e, view);
		DrawEvent_set_bounds(&e, bounds);

		if (!draw_view_with_cache(view, &e, redraw))
		{
			pos += offset;
			draw_view(view, &e, pos, clip2);
		}

		p->pop_matrix();
	}

	void
	View_update_styles (View* view, const Selector& selector)
	{
		if (!view)
			argument_error(__FILE__, __LINE__);

		View::Data* self = view->self.get();

		if (selector.empty())
			self->add_flag(View::Data::UPDATE_STYLE);
		else
			self->selectors_for_update().insert(selector);
	}

	void
	View_update_shapes (View* view)
	{
		if (!view)
			argument_error(__FILE__, __LINE__);

		view->self->add_flag(View::Data::UPDATE_SHAPES);
	}

	void
	View_call_key_event (View* view, KeyEvent* event)
	{
		if (!view || !event)
			argument_error(__FILE__, __LINE__);

		if (view->hidden()) return;

		KeyEvent e = event->dup();
		view->on_key(&e);

		switch (e.action())
		{
			case KeyEvent::DOWN: view->on_key_down(&e); break;
			case KeyEvent::UP:   view->on_key_up(&e);   break;
			default: break;
		}
	}

	static void
	call_children (View* parent, std::function<bool(View*)> fun, bool sort = true)
	{
		auto* children = parent->self->children(false, sort);
		if (!children) return;

		for (auto it = children->rbegin(), end = children->rend(); it != end; ++it)
		{
			if (!fun(it->get()))
				break;
		}
	}

	static void
	call_pointer_events_for_each_child (View* parent, PointerEvent* event)
	{
		call_children(parent, [&](View* child) {
			PointerEvent e = event->dup();
			PointerEvent_update_for_child_view(&e, child);
			View_call_pointer_event(child, &e);
			return !e.is_blocked();
		});
	}

	static void
	call_pointer_events (View* view, PointerEvent* event)
	{
		if (view->self->pbody)
			view->self->pbody->awake();

		view->on_pointer(event);

		switch ((*event)[0].action())
		{
			case Pointer::DOWN:   view->on_pointer_down(event);   break;
			case Pointer::UP:     view->on_pointer_up(event);     break;
			case Pointer::MOVE:   view->on_pointer_move(event);   break;
			case Pointer::CANCEL: view->on_pointer_cancel(event); break;
			default: break;
		}

		if (!event->is_captured())
			PointerEvent_increment_view_indices(event);
	}

	static void
	register_captures (View* view, const PointerEvent& event)
	{
		Window* win = view->window();
		if (!win)
			invalid_state_error(__FILE__, __LINE__);

		PointerEvent_each_pointer(&event, [&](const auto& pointer)
		{
			if (pointer.action() == Pointer::DOWN)
				Window_register_capture(win, view, pointer.id(), pointer.view_index());
		});
	}

	static void
	unregister_captures (View* view, const PointerEvent& event)
	{
		Window* win = view->window();
		if (!win)
			invalid_state_error(__FILE__, __LINE__);

		PointerEvent_each_pointer(&event, [&](const auto& pointer)
		{
			auto action = pointer.action();
			if (action == Pointer::UP || action == Pointer::CANCEL)
				Window_unregister_capture(win, view, pointer.id());
		});
	}

	void
	View_call_pointer_event (View* view, PointerEvent* event)
	{
		if (!view || !event)
			argument_error(__FILE__, __LINE__);

		if (view->hidden() || event->empty())
			return;

		PointerEvent e = event->dup();

		if (!e.is_captured())
			call_pointer_events_for_each_child(view, &e);

		if (!e.is_blocked())
		{
			register_captures(view, e);
			call_pointer_events(view, &e);
		}

		unregister_captures(view, e);
	}

	void
	View_call_wheel_event (View* view, WheelEvent* event)
	{
		if (!view || !event)
			argument_error(__FILE__, __LINE__);

		if (view->hidden()) return;

		const Bounds& frame = view->frame();

		if (!frame.is_include(event->position()))
			return;

		WheelEvent e = event->dup();
		WheelEvent_set_position(&e, e.position() - frame.position());

		call_children(view, [&](View* child) {
			View_call_wheel_event(child, &e);
			return !e.is_blocked();
		});

		if (e.is_blocked()) return;

		view->on_wheel(&e);
	}

	void
	View_call_contact_event (View* view, ContactEvent* event)
	{
		if (!view || !event)
			argument_error(__FILE__, __LINE__);

		ContactEvent e = event->dup();
		view->on_contact(&e);

		switch (e.action())
		{
			case ContactEvent::BEGIN: view->on_contact_begin(&e); break;
			case ContactEvent::END:   view->on_contact_end(&e);   break;
			default: break;
		}
	}


	View::View (const char* name)
	{
		if (name) set_name(name);
	}

	View::~View ()
	{
		clear_children();// to delete child shapes before world.
	}

	void
	View::show ()
	{
		if (self->hide_count <= SHRT_MIN)
			invalid_state_error(__FILE__, __LINE__);

		int new_count = self->hide_count - 1;
		if (new_count == 0)
		{
			Event e;
			on_show(&e);
			if (e.is_blocked()) return;

			redraw();
		}

		self->hide_count = new_count;
	}

	void
	View::hide ()
	{
		if (self->hide_count >= SHRT_MAX)
			invalid_state_error(__FILE__, __LINE__);

		int new_count = self->hide_count + 1;
		if (new_count == 1)
		{
			Event e;
			on_hide(&e);
			if (e.is_blocked()) return;

			redraw();
		}

		self->hide_count = new_count;
	}

	bool
	View::hidden () const
	{
		return self->hide_count > 0;
	}

	void
	View::redraw ()
	{
		if (self->has_flag(Data::REDRAW))
			return;

		self->add_flag(Data::REDRAW);

		if (self->parent)
			self->parent->redraw();
		else if (self->window)
			self->window->redraw();
	}

	void
	View::focus (bool state)
	{
		Window* w = window();
		if (!w) return;

		if (state)
			Window_set_focus(w, this);
		else if (w->focus() == this)
			Window_set_focus(w, NULL);
	}

	void
	View::blur ()
	{
		focus(false);
	}

	bool
	View::has_focus () const
	{
		const Window* w = window();
		return w && w->focus() == this;
	}

	Timer*
	View::start_timer (float seconds, int count)
	{
		return self->timers().add(this, seconds, count);
	}

	Timer*
	View::start_interval (float seconds)
	{
		return start_timer(seconds, -1);
	}

	void
	View::update_layout ()
	{
		LayoutContext(this).place_children();
		redraw();
	}

	static void
	get_from_parent_matrix (Matrix* m, const View* view)
	{
		View::Data* self = view->self.get();

		const auto& frame  = self->frame;
		const auto* scroll = self->has_scroll() ? self->pscroll.get() : NULL;
		auto angle         = self->angle;
		auto zoom          = self->zoom;

		if (zoom != 1 && zoom > 0) m->scale(1 / zoom, 1 / zoom);
		if (angle != 0)
		{
			const auto* pivot = self->has_pivot() ? self->ppivot.get() : NULL;
			if (pivot) m->translate( pivot->x * frame.w,  pivot->y * frame.h);
			m->rotate(-angle);
			if (pivot) m->translate(-pivot->x * frame.w, -pivot->y * frame.h);
		}
		m->translate(-frame.position());
		if (scroll) m->translate(-*scroll);
	}

	static void
	get_to_parent_matrix (Matrix* m, const View* view)
	{
		View::Data* self = view->self.get();

		const auto& frame  = self->frame;
		const auto* scroll = self->has_scroll() ? self->pscroll.get() : NULL;
		auto angle         = self->angle;
		auto zoom          = self->zoom;

		if (scroll) m->translate(*scroll);
		m->translate(frame.position());
		if (angle != 0)
		{
			const auto* pivot = self->has_pivot() ? self->ppivot.get() : NULL;
			if (pivot) m->translate( pivot->x * frame.w,  pivot->y * frame.h);
			m->rotate(angle);
			if (pivot) m->translate(-pivot->x * frame.w, -pivot->y * frame.h);
		}
		if (zoom != 1 && zoom > 0) m->scale(zoom, zoom);
	}

	Point
	View::from_parent (const Point& point) const
	{
		if (self->zoom == 1 && self->angle == 0 && !self->has_scroll())
			return point - self->frame.position();
		else
		{
			Matrix m(1);
			get_from_parent_matrix(&m, this);
			return m * point;
		}
	}

	Point
	View::to_parent (const Point& point) const
	{
		if (self->zoom == 1 && self->angle == 0 && !self->has_scroll())
			return point + self->frame.position();
		else
		{
			Matrix m(1);
			get_to_parent_matrix(&m, this);
			return m * point;
		}
	}

	Point
	View::from_window (const Point& point) const
	{
		if (!window())
			invalid_state_error(__FILE__, __LINE__);

		const auto* parent = self->parent;
		return from_parent(parent ? parent->from_window(point) : point);
	}

	Point
	View::to_window (const Point& point) const
	{
		if (!window())
			invalid_state_error(__FILE__, __LINE__);

		const auto* parent = self->parent;
		return parent ? parent->to_window(to_parent(point)) : to_parent(point);
	}

	Point
	View::from_screen (const Point& point) const
	{
		const Window* w = window();
		if (!w)
			invalid_state_error(__FILE__, __LINE__);

		return w->from_screen(from_window(point));
	}

	Point
	View::to_screen (const Point& point) const
	{
		const Window* w = window();
		if (!w)
			invalid_state_error(__FILE__, __LINE__);

		return w->to_screen(to_window(point));
	}

	static void
	set_parent (View* view, View* parent)
	{
		View::Data* self = view->self.get();

		if (parent == self->parent) return;

		self->parent = parent;
		View_set_window(view, parent ? parent->window() : NULL);
	}

	static void
	erase_child_from_children (View* parent, View* child)
	{
		View::ChildList* children = parent->self->children();
		if (!children) return;

		auto end = children->end();
		auto it  = std::find(children->begin(), end, child);
		assert(it != end);

		children->erase(it);
		if (children->empty())
		{
			parent->self->pchildren.reset();
			parent->self->pchildren_sorted.reset();
		}
	}

	void
	View::add_child (View* child)
	{
		if (!child || child == this)
			argument_error(__FILE__, __LINE__);

		bool found  = std::find(child_begin(), child_end(), child) != child_end();
		bool belong = child->parent() == this;
		if (found && belong)
			return;
		else if (found != belong)
			invalid_state_error(__FILE__, __LINE__);

		self->children(true)->push_back(child);

		View* prev_parent = child->parent();
		set_parent(child, this);

		if (prev_parent)
			erase_child_from_children(prev_parent, child);

		self->sort_children();

		update_view_layout(this);
	}

	void
	View::remove_child (View* child)
	{
		if (!child || child == this)
			argument_error(__FILE__, __LINE__);

		bool found  = std::find(child_begin(), child_end(), child) != child_end();
		bool belong = child->parent() == this;
		if (!found && !belong)
			return;
		else if (found != belong)
			invalid_state_error(__FILE__, __LINE__);

		set_parent(child, NULL);

		erase_child_from_children(this, child);

		self->sort_children();

		update_view_layout(this);
	}

	void
	View::clear_children ()
	{
		auto* children = self->children();
		if (!children || children->empty()) return;

		for (auto& child : *children)
			remove_child(child);
	}

	View::ChildList
	View::find_children (const Selector& selector, bool recursive) const
	{
		ChildList result;
		find_all_children(&result, this, selector, recursive);
		return result;
	}

	static View::ChildList empty_children;

	View::child_iterator
	View::child_begin ()
	{
		if (!self->pchildren) return empty_children.begin();
		return self->pchildren->begin();
	}

	View::const_child_iterator
	View::child_begin () const
	{
		if (!self->pchildren) return empty_children.begin();
		return self->pchildren->begin();
	}

	View::child_iterator
	View::child_end ()
	{
		if (!self->pchildren) return empty_children.end();
		return self->pchildren->end();
	}

	View::const_child_iterator
	View::child_end () const
	{
		if (!self->pchildren) return empty_children.end();
		return self->pchildren->end();
	}

	Style*
	View::style (bool create)
	{
		return create ? &self->style(this) : self->pstyle.get();
	}

	const Style*
	View::style () const
	{
		return const_cast<View*>(this)->style(false);
	}

	static Style*
	add_view_style (View* view, Style style)
	{
		if (!Style_set_owner(&style, view))
			return NULL;

		View::StyleList* pstyles = &view->self->styles();
		pstyles->push_back(style);
		return &pstyles->back();
	}

	void
	View::add_style (const Style& style)
	{
		add_view_style(this, style);
	}

	void
	View::remove_style (const Style& style)
	{
		if (!self->pstyles) return;

		auto end = style_end();
		auto it = std::find(style_begin(), end, style);
		if (it == end) return;

		if (!Style_set_owner(&*it, NULL))
			invalid_state_error(__FILE__, __LINE__);

		self->pstyles->erase(it);
		if (self->pstyles->empty())
			self->pstyles.reset();
	}

	void
	View::clear_styles ()
	{
		while (self->pstyles && !self->pstyles->empty())
			remove_style(*self->pstyles->begin());
	}

	Style*
	View::get_style (const Selector& selector, bool create)
	{
		if (selector.empty())
			return style(create);

		StyleList* pstyles = self->pstyles.get();
		if (pstyles)
		{
			for (auto& style : *pstyles)
			{
				if (selector == style.selector())
					return &style;
			}
		}

		if (create)
		{
			Style s;
			s.set_selector(selector);
			return add_view_style(this, s);
		}

		return NULL;
	}

	const Style*
	View::get_style (const Selector& selector) const
	{
		return const_cast<View*>(this)->get_style(selector);
	}

	View::StyleList
	View::find_styles (const Selector& selector, bool recursive) const
	{
		StyleList result;
		find_all_styles(&result, this, selector, recursive);
		return result;
	}

	static View::StyleList empty_styles;

	View::style_iterator
	View::style_begin ()
	{
		if (!self->pstyles) return empty_styles.begin();
		return self->pstyles->begin();
	}

	View::const_style_iterator
	View::style_begin () const
	{
		if (!self->pstyles) return empty_styles.begin();
		return self->pstyles->begin();
	}

	View::style_iterator
	View::style_end ()
	{
		if (!self->pstyles) return empty_styles.end();
		return self->pstyles->end();
	}

	View::const_style_iterator
	View::style_end () const
	{
		if (!self->pstyles) return empty_styles.end();
		return self->pstyles->end();
	}

	void
	View::set_shape (Shape* shape)
	{
		if (!shape)
			self->add_flag(Data::NO_SHAPE);
		else
			self->remove_flag(Data::NO_SHAPE);

		Shape::Ref& pshape = self->pshape;
		if (shape == pshape.get()) return;

		if (pshape) Shape_set_owner(pshape, NULL);
		pshape.reset(shape);
		if (pshape) Shape_set_owner(pshape, this);
	}

	Shape*
	View::shape (bool create)
	{
		if (create && !self->pshape && !self->has_flag(Data::NO_SHAPE))
			set_shape(new RectShape);

		return self->pshape.get();
	}

	const Shape*
	View::shape () const
	{
		return const_cast<View*>(this)->shape(false);
	}

	void
	View::add_shape (Shape* shape)
	{
		if (!shape) return;

		Shape_set_owner(shape, this);
		self->shapes().push_back(shape);
	}

	void
	View::remove_shape (Shape* shape)
	{
		if (!shape || !self->pshapes)
			return;

		auto end = shape_end();
		auto it  = std::find(shape_begin(), end, shape);
		if (it == end) return;

		Shape_set_owner(it->get(), NULL);

		self->pshapes->erase(it);
		if (self->pshapes->empty())
			self->pshapes.reset();
	}

	void
	View::clear_shapes ()
	{
		set_shape(NULL);
		while (self->pshapes && !self->pshapes->empty())
			remove_shape(self->pshapes->begin()->get());
	}

	View::ShapeList
	View::find_shapes (const Selector& selector) const
	{
		ShapeList result;
		ShapeList* pshapes = self->pshapes.get();
		if (pshapes)
		{
			for (auto& shape : *pshapes)
			{
				if (selector.contains(shape->selector()))
					result.push_back(shape);
			}
		}
		return result;
	}

	static View::ShapeList empty_shapes;

	View::shape_iterator
	View::shape_begin ()
	{
		if (!self->pshapes) return empty_shapes.begin();
		return self->pshapes->begin();
	}

	View::const_shape_iterator
	View::shape_begin () const
	{
		if (!self->pshapes) return empty_shapes.begin();
		return self->pshapes->begin();
	}

	View::shape_iterator
	View::shape_end ()
	{
		if (!self->pshapes) return empty_shapes.end();
		return self->pshapes->end();
	}

	View::const_shape_iterator
	View::shape_end () const
	{
		if (!self->pshapes) return empty_shapes.end();
		return self->pshapes->end();
	}

	void
	View::set_filter (Filter* filter)
	{
		self->pfilter = filter;
	}

	Filter*
	View::filter ()
	{
		return self->pfilter.get();
	}

	const Filter*
	View::filter () const
	{
		return const_cast<View*>(this)->filter();
	}

	void
	View::set_name (const char* name)
	{
		const char* current = this->name();
		if (name && current && strcmp(name, current) == 0)
			return;

		HasSelector::set_name(name);
		self->add_flag(Data::UPDATE_STYLE);
	}

	void
	View::add_tag (const char* tag)
	{
		if (has_tag(tag)) return;

		HasSelector::add_tag(tag);
		self->add_flag(Data::UPDATE_STYLE);
	}

	void
	View::remove_tag (const char* tag)
	{
		if (!has_tag(tag)) return;

		HasSelector::remove_tag(tag);
		self->add_flag(Data::UPDATE_STYLE);
	}

	void
	View::clear_tags ()
	{
		if (tag_begin() == tag_end()) return;

		HasSelector::clear_tags();
		self->add_flag(Data::UPDATE_STYLE);
	}

	void
	View::set_selector (const Selector& selector)
	{
		if (selector == this->selector()) return;

		HasSelector::set_selector(selector);
		self->add_flag(Data::UPDATE_STYLE);
	}

	void
	View::set_frame (coord x, coord y, coord width, coord height)
	{
		set_frame(Bounds(x, y, width, height));
	}

	void
	View::set_frame (const Bounds& frame)
	{
		const Bounds& current = self->frame;

		if (frame.w != current.w && !Style_has_width(*style()))
			style()->set_width(StyleLength::NONE);

		if (frame.h != current.h && !Style_has_height(*style()))
			style()->set_height(StyleLength::NONE);

		View_set_frame(this, frame);
	}

	const Bounds&
	View::frame () const
	{
		return self->frame;
	}

	Bounds
	View::content_bounds () const
	{
		Bounds bounds = Rays::invalid_bounds();
		self->each_shape([&](const Shape* shape)
		{
			if (!shape || !Shape_has_frame(*shape))
				return;

			Bounds frame = shape->frame();
			if (frame) bounds |= frame;
		});
		return bounds;
	}

	void
	View::fit_to_content ()
	{
		self->add_flag(View::Data::FIT_TO_CONTENT);
	}

	void
	View::set_zoom (float zoom)
	{
		if (zoom == self->zoom) return;

		if (zoom == 0)
			argument_error(__FILE__, __LINE__);

		update_view_frame(this, self->frame, zoom, self->angle);
		redraw();
	}

	float
	View::zoom () const
	{
		return self->zoom;
	}

	void
	View::set_angle (float degree)
	{
		update_view_frame(this, self->frame, self->zoom, degree);
	}

	float
	View::angle () const
	{
		return self->angle;
	}

	void
	View::set_pivot (float x, float y, float z)
	{
		self->pivot().reset(x, y, z);
	}

	void
	View::set_pivot (const Point& pivot)
	{
		set_pivot(pivot.x, pivot.y, pivot.z);
	}

	const Point&
	View::pivot () const
	{
		return self->ppivot ? self->pivot() : ZERO;
	}

	void
	View::scroll_to (coord x, coord y, coord z)
	{
		scroll_to(Point(x, y, z));
	}

	void
	View::scroll_to (const Point& scroll)
	{
		if (scroll == this->scroll()) return;

		Point old = self->scroll();
		self->scroll() = scroll;

		ScrollEvent e(
			scroll.x,         scroll.y,         scroll.z,
			scroll.x - old.x, scroll.y - old.y, scroll.z - old.z);
		on_scroll(&e);

		redraw();
	}

	void
	View::scroll_by (coord x, coord y, coord z)
	{
		const Point& p = scroll();
		scroll_to(p.x + x, p.y + y, p.z + z);
	}

	void
	View::scroll_by (const Point& dscroll)
	{
		scroll_by(dscroll.x, dscroll.y, dscroll.z);
	}

	const Point&
	View::scroll () const
	{
		return self->pscroll ? self->scroll() : ZERO;
	}

	void
	View::set_capture (uint types)
	{
		Window* w = window();
		if (!w || types == self->capture) return;

		uint old      = self->capture;
		self->capture = types;

		bool registered = old   != CAPTURE_NONE;
		bool capture    = types != CAPTURE_NONE;

		if (capture && !registered)
			Window_register_capture(w, this, CAPTURE_ALL);
		else if (!capture && registered)
			Window_unregister_capture(w, this, CAPTURE_ALL);

		CaptureEvent e(~old & types, old & ~types);
		on_capture(&e);
	}

	uint
	View::capture () const
	{
		return self->capture;
	}

	void
	View::add_flag (uint flags)
	{
		self->add_flag(flags);

		self->update_body_states();
	}

	void
	View::remove_flag (uint flags)
	{
		self->remove_flag(flags);

		self->update_body_states();
	}

	bool
	View::has_flag (uint flags) const
	{
		return self->has_flag(flags);
	}

	View*
	View::parent ()
	{
		return self->parent;
	}

	const View*
	View::parent () const
	{
		return const_cast<This*>(this)->parent();
	}

	Window*
	View::window ()
	{
		return self->window;
	}

	const Window*
	View::window () const
	{
		return const_cast<View*>(this)->window();
	}

	void
	View::apply_force (coord x, coord y)
	{
		self->body().apply_force(x, y);
	}

	void
	View::apply_force (const Point& force)
	{
		self->body().apply_force(force);
	}

	void
	View::apply_torque (float torque)
	{
		self->body().apply_torque(torque);
	}

	void
	View::apply_linear_impulse (coord x, coord y)
	{
		self->body().apply_linear_impulse(x, y);
	}

	void
	View::apply_linear_impulse (const Point& impulse)
	{
		self->body().apply_linear_impulse(impulse);
	}

	void
	View::apply_angular_impulse (float impulse)
	{
		self->body().apply_angular_impulse(impulse);
	}

	void
	View::set_static (bool state)
	{
		set_dynamic(!state);
	}

	bool
	View::is_static () const
	{
		return self->pbody ? !self->pbody->is_dynamic() : false;
	}

	void
	View::set_dynamic (bool state)
	{
		Body& b = self->body();
		if (state == b.is_dynamic())
			return;

		b.set_dynamic(state);
	}

	bool
	View::is_dynamic () const
	{
		return self->pbody ? self->pbody->is_dynamic() : false;
	}

	void
	View::set_density (float density)
	{
		Shape* s = shape();
		if (!s)
			invalid_state_error(__FILE__, __LINE__, "view has no shape.");

		s->set_density(density);
	}

	float
	View::density () const
	{
		const Shape* s = self->pshape.get();
		return s ? s->density() : 0;
	}

	void
	View::set_friction (float friction)
	{
		Shape* s = shape();
		if (!s)
			invalid_state_error(__FILE__, __LINE__, "view has no shape.");

		s->set_friction(friction);
	}

	float
	View::friction () const
	{
		const Shape* s = self->pshape.get();
		return s ? s->friction() : 0;
	}

	void
	View::set_restitution (float restitution)
	{
		Shape* s = shape();
		if (!s)
			invalid_state_error(__FILE__, __LINE__, "view has no shape.");

		s->set_restitution(restitution);
	}

	float
	View::restitution () const
	{
		const Shape* s = self->pshape.get();
		return s ? s->restitution() : 0;
	}

	void
	View::set_sensor (bool state)
	{
		Shape* s = shape();
		if (!s)
			invalid_state_error(__FILE__, __LINE__, "view has no shape.");

		s->set_sensor(state);
	}

	bool
	View::is_sensor () const
	{
		const Shape* s = self->pshape.get();
		return s ? s->is_sensor() : false;
	}

	void
	View::set_linear_velocity (coord x, coord y)
	{
		self->body().set_linear_velocity(x, y);
	}

	void
	View::set_linear_velocity (const Point& velocity)
	{
		self->body().set_linear_velocity(velocity);
	}

	Point
	View::linear_velocity () const
	{
		const Body* b = self->pbody.get();
		return b ? b->linear_velocity() : 0;
	}

	void
	View::set_angular_velocity (float velocity)
	{
		self->body().set_angular_velocity(velocity);
	}

	float
	View::angular_velocity () const
	{
		const Body* b = self->pbody.get();
		return b ? b->angular_velocity() : 0;
	}

	void
	View::set_gravity_scale (float scale)
	{
		self->body().set_gravity_scale(scale);
	}

	float
	View::gravity_scale () const
	{
		const Body* b = self->pbody.get();
		return b ? b->gravity_scale() : 1;
	}

	void
	View::update_physics (float duration)
	{
		World* w = self->pchild_world.get();
		if (w) w->update(duration);
	}

	float
	View::meter2pixel (float meter, bool create_world)
	{
		Body* body = self->pbody.get();
		if (body)
			return body->meter2pixel(meter);

		World* child_world = self->pchild_world.get();
		if (child_world)
			return child_world->meter2pixel(meter);

		World* parent_world = self->parent_world(false);
		if (parent_world)
			return parent_world->meter2pixel(meter);

		if (!create_world)
			invalid_state_error(__FILE__, __LINE__);

		child_world = self->child_world(this);
		if (!child_world)
			invalid_state_error(__FILE__, __LINE__);

		return child_world->meter2pixel(meter);
	}

	float
	View::meter2pixel (float meter) const
	{
		return const_cast<View*>(this)->meter2pixel(meter, false);
	}

	void
	View::set_gravity (float x, float y)
	{
		set_gravity(Point(x, y));
	}

	void
	View::set_gravity (const Point& vector)
	{
		self->child_world(this)->set_gravity(vector);
	}

	Point
	View::gravity () const
	{
		World* w = self->pchild_world.get();
		return w ? w->gravity() : 0;
	}

	void
	View::set_time_scale (float scale)
	{
		self->child_world(this)->set_time_scale(scale);
	}

	float
	View::time_scale () const
	{
		World* w = self->pchild_world.get();
		return w ? w->time_scale() : 1;
	}

	View*
	View::wall ()
	{
		self->child_world(this);

		ChildList children = find_children(WALL_NAME);
		if (children.empty()) return NULL;

		return children[0].get();
	}

	const View*
	View::wall () const
	{
		return const_cast<View*>(this)->wall();
	}

	void
	View::set_debug (bool state)
	{
		World* w = self->child_world(this);
		if (w) w->set_debug(state);
	}

	bool
	View::debug () const
	{
		World* w = self->pchild_world.get();
		return w ? w->debug() : false;
	}

	void
	View::on_attach (Event* e)
	{
	}

	void
	View::on_detach (Event* e)
	{
	}

	void
	View::on_show (Event* e)
	{
	}

	void
	View::on_hide (Event* e)
	{
	}

	void
	View::on_update (UpdateEvent* e)
	{
	}

	void
	View::on_draw (DrawEvent* e)
	{
	}

	void
	View::on_move (FrameEvent* e)
	{
	}

	void
	View::on_resize (FrameEvent* e)
	{
	}

	void
	View::on_zoom (FrameEvent* e)
	{
	}

	void
	View::on_rotate (FrameEvent* e)
	{
	}

	void
	View::on_scroll (ScrollEvent* e)
	{
	}

	void
	View::on_focus (FocusEvent* e)
	{
	}

	void
	View::on_key (KeyEvent* e)
	{
	}

	void
	View::on_key_down (KeyEvent* e)
	{
	}

	void
	View::on_key_up (KeyEvent* e)
	{
	}

	void
	View::on_pointer (PointerEvent* e)
	{
	}

	void
	View::on_pointer_down (PointerEvent* e)
	{
	}

	void
	View::on_pointer_up (PointerEvent* e)
	{
	}

	void
	View::on_pointer_move (PointerEvent* e)
	{
	}

	void
	View::on_pointer_cancel (PointerEvent* e)
	{
	}

	void
	View::on_wheel (WheelEvent* e)
	{
		//scroll_by(e->dx, e->dy, e->dz);
	}

	void
	View::on_capture (CaptureEvent* e)
	{
	}

	void
	View::on_timer (TimerEvent* e)
	{
	}

	bool
	View::will_contact (View* v)
	{
		return true;
	}

	void
	View::on_contact (ContactEvent* e)
	{
	}

	void
	View::on_contact_begin (ContactEvent* e)
	{
	}

	void
	View::on_contact_end (ContactEvent* e)
	{
	}

	View::operator bool () const
	{
		return true;
	}

	bool
	View::operator ! () const
	{
		return !operator bool();
	}

	SelectorPtr*
	View::get_selector_ptr ()
	{
		return &self->pselector;
	}


}// Reflex
