#include "reflex/ruby/view.h"


#include <vector>
#include <ranges>
#include <rays/ruby/point.h>
#include <rays/ruby/bounds.h>
#include <rays/ruby/polygon.h>
#include "reflex/ruby/selector.h"
#include "reflex/ruby/timer.h"
#include "reflex/ruby/style.h"
#include "reflex/ruby/shape.h"
#include "reflex/ruby/filter.h"
#include "reflex/ruby/window.h"
#include "defs.h"
#include "selector.h"


RUCY_DEFINE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::View)

#define   THIS    to<      Reflex::View*>(self)
#define C_THIS    to<const Reflex::View*>(self)

#define CHECK     RUCY_CHECK_OBJECT(Reflex::View, self)

#define CALL(fun) RUCY_CALL_SUPER(THIS, fun)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return value(new Reflex::RubyView<Reflex::View>, klass);
}
RUCY_END

static
RUCY_DEF0(show)
{
	CHECK;
	THIS->show();
	return self;
}
RUCY_END

static
RUCY_DEF0(hide)
{
	CHECK;
	THIS->hide();
	return self;
}
RUCY_END

static
RUCY_DEF0(hidden)
{
	CHECK;
	return value(THIS->hidden());
}
RUCY_END

static
RUCY_DEF0(redraw)
{
	CHECK;
	THIS->redraw();
	return self;
}
RUCY_END

static
RUCY_DEFN(focus)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "View#focus", argc, 0, 1);

	bool state = (argc >= 1) ? to<bool>(argv[0]) : true;

	THIS->focus(state);
	return self;
}
RUCY_END

static
RUCY_DEF0(blur)
{
	CHECK;
	THIS->blur();
	return self;
}
RUCY_END

static
RUCY_DEF0(has_focus)
{
	CHECK;
	return value(THIS->has_focus());
}
RUCY_END

static
RUCY_DEFN(start_timer)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "View#start_timer", argc, 1, 2);

	Reflex::Timer* timer = THIS->start_timer(
		to<float>(argv[0]),
		argc >= 2 ? to<int>(argv[1]) : 1);

	return value(timer);
}
RUCY_END

static
RUCY_DEF0(update_layout)
{
	CHECK;
	THIS->update_layout();
	return self;
}
RUCY_END

static
RUCY_DEF1(from_parent, point)
{
	CHECK;
	return value(THIS->from_parent(to<Rays::Point>(point)));
}
RUCY_END

static
RUCY_DEF1(to_parent, point)
{
	CHECK;
	return value(THIS->to_parent(to<Rays::Point>(point)));
}
RUCY_END

static
RUCY_DEF1(from_window, point)
{
	CHECK;
	return value(THIS->from_window(to<Rays::Point>(point)));
}
RUCY_END

static
RUCY_DEF1(to_window, point)
{
	CHECK;
	return value(THIS->to_window(to<Rays::Point>(point)));
}
RUCY_END

static
RUCY_DEF1(from_screen, point)
{
	CHECK;
	return value(THIS->from_screen(to<Rays::Point>(point)));
}
RUCY_END

static
RUCY_DEF1(to_screen, point)
{
	CHECK;
	return value(THIS->to_screen(to<Rays::Point>(point)));
}
RUCY_END

static
RUCY_DEF1(add_child, child)
{
	CHECK;
	THIS->add_child(to<Reflex::View*>(child));
	return child;
}
RUCY_END

static
RUCY_DEF1(remove_child, child)
{
	CHECK;
	THIS->remove_child(to<Reflex::View*>(child));
	return child;
}
RUCY_END

static
RUCY_DEF0(clear_children)
{
	CHECK;
	THIS->clear_children();
	return self;
}
RUCY_END

static
RUCY_DEFN(find_children)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "View#find_children", argc, 1, 2);

	bool recursive = (argc >= 2) ? to<bool>(argv[1]) : true;

	auto children =
		THIS->find_children(to<Reflex::Selector>(argv[0]), recursive) |
		std::views::transform([](auto& ref) {return value(ref);});
	return array(children.begin(), children.end());
}
RUCY_END

static
RUCY_DEF0(each_child)
{
	CHECK;

	Value ret;
	Reflex::View::child_iterator end = THIS->child_end();
	for (Reflex::View::child_iterator it = THIS->child_begin(); it != end; ++it)
		ret = rb_yield(value(it->get()));
	return ret;
}
RUCY_END

static
RUCY_DEF1(add_style, style)
{
	CHECK;
	THIS->add_style(to<Reflex::Style&>(style));
	return style;
}
RUCY_END

static
RUCY_DEF1(remove_style, style)
{
	CHECK;
	THIS->remove_style(to<Reflex::Style&>(style));
	return style;
}
RUCY_END

static
RUCY_DEF1(get_style, selector)
{
	CHECK;

	Reflex::Style* s = NULL;
	if (selector)
		s = THIS->get_style(to<Reflex::Selector>(selector));
	else
		s = THIS->style();

	return s ? value(*s) : nil();
}
RUCY_END

static
RUCY_DEFN(find_styles)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "View#find_styles", argc, 1, 2);

	bool recursive = (argc >= 2) ? to<bool>(argv[1]) : false;

	auto styles =
		THIS->find_styles(to<Reflex::Selector>(argv[0]), recursive) |
		std::views::transform([](auto& ref) {return value(ref);});
	return array(styles.begin(), styles.end());
}
RUCY_END

static
RUCY_DEF0(each_style)
{
	CHECK;

	Value ret;
	Reflex::View::style_iterator end = THIS->style_end();
	for (Reflex::View::style_iterator it = THIS->style_begin(); it != end; ++it)
		ret = rb_yield(value(*it));
	return ret;
}
RUCY_END

static Reflex::Shape::Ref
to_shape (Value value)
{
	if (value.is_nil())
		return NULL;

	if (value.is_a(Rays::polygon_class()))
	{
		Reflex::PolygonShape* shape = new Reflex::PolygonShape();
		shape->set_polygon(to<Rays::Polygon&>(value));
		return shape;
	}
	else
		return to<Reflex::Shape*>(value);
}

static
RUCY_DEF1(set_shape, shape)
{
	CHECK;
	THIS->set_shape(to_shape(shape));
	return shape;
}
RUCY_END

static
RUCY_DEF0(get_shape)
{
	CHECK;
	return value(THIS->shape());
}
RUCY_END

static
RUCY_DEF1(add_shape, shape)
{
	CHECK;
	THIS->add_shape(to_shape(shape));
	return shape;
}
RUCY_END

static
RUCY_DEF1(remove_shape, shape)
{
	CHECK;
	THIS->remove_shape(to<Reflex::Shape*>(shape));
	return shape;
}
RUCY_END

static
RUCY_DEF0(clear_shapes)
{
	CHECK;
	THIS->clear_shapes();
	return self;
}
RUCY_END

static
RUCY_DEFN(find_shapes)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "View#find_shapes", argc, 1);

	auto shapes =
		THIS->find_shapes(to<Reflex::Selector>(argv[0])) |
		std::views::transform([](auto& ref) {return value(ref);});
	return array(shapes.begin(), shapes.end());
}
RUCY_END

static
RUCY_DEF0(each_shape)
{
	CHECK;

	Value ret;
	Reflex::View::shape_iterator end = THIS->shape_end();
	for (Reflex::View::shape_iterator it = THIS->shape_begin(); it != end; ++it)
		ret = rb_yield(value(it->get()));
	return ret;
}
RUCY_END

static
RUCY_DEF1(set_filter, filter)
{
	CHECK;
	THIS->set_filter(filter ? to<Reflex::Filter*>(filter) : NULL);
	return filter;
}
RUCY_END

static
RUCY_DEF0(get_filter)
{
	CHECK;
	return value(THIS->filter());
}
RUCY_END

static
RUCY_DEFN(set_frame)
{
	CHECK;
	THIS->set_frame(to<Rays::Bounds>(argc, argv));
	return value(THIS->frame());
}
RUCY_END

static
RUCY_DEF0(get_frame)
{
	CHECK;
	return value(THIS->frame());
}
RUCY_END

static
RUCY_DEF0(content_bounds)
{
	CHECK;
	return value(CALL(content_bounds()));
}
RUCY_END

static
RUCY_DEF0(fit_to_content)
{
	CHECK;
	THIS->fit_to_content();
	return self;
}
RUCY_END

static
RUCY_DEF1(set_angle, degree)
{
	CHECK;
	THIS->set_angle(to<float>(degree));
	return degree;
}
RUCY_END

static
RUCY_DEF0(get_angle)
{
	CHECK;
	return value(THIS->angle());
}
RUCY_END

static
RUCY_DEFN(set_pivot)
{
	CHECK;

	if (argv[0].is_a(Rays::point_class()))
	{
		check_arg_count(__FILE__, __LINE__, "View#pivot=(Point)", argc, 1);

		THIS->set_pivot(to<Rays::Point&>(argv[0]));
	}
	else
	{
		if (argv[0].is_array())
		{
			argc = argv[0].size();
			argv = &argv[0][0];
		}
		check_arg_count(__FILE__, __LINE__, "View#pivot=(Numeric, ...)", argc, 2, 3);

		const Rays::Point& p = THIS->pivot();
		float x =                          to<float>(argv[0]);
		float y =                          to<float>(argv[1]);
		float z = (argc >= 3 && argv[2]) ? to<float>(argv[2]) : p.z;
		THIS->set_pivot(x, y, z);
	}

	return value(THIS->pivot());
}
RUCY_END

static
RUCY_DEF0(get_pivot)
{
	CHECK;
	return value(THIS->pivot());
}
RUCY_END

static
RUCY_DEFN(scroll_to)
{
	CHECK;

	if (argv[0].is_a(Rays::point_class()))
	{
		check_arg_count(__FILE__, __LINE__, "View#scroll_to(Point)", argc, 1);

		THIS->scroll_to(to<Rays::Point&>(argv[0]));
	}
	else
	{
		if (argv[0].is_array())
		{
			argc = argv[0].size();
			argv = &argv[0][0];
		}
		check_arg_count(__FILE__, __LINE__, "View#scroll_to(Numeric, ...)", argc, 2, 3);

		const Rays::Point& p = THIS->scroll();
		coord x = (argc >= 1 && argv[0]) ? to<coord>(argv[0]) : p.x;
		coord y = (argc >= 2 && argv[1]) ? to<coord>(argv[1]) : p.y;
		coord z = (argc >= 3 && argv[2]) ? to<coord>(argv[2]) : p.z;
		THIS->scroll_to(x, y, z);
	}

	return self;
}
RUCY_END

static
RUCY_DEFN(scroll_by)
{
	CHECK;

	if (argv[0].is_a(Rays::point_class()))
	{
		check_arg_count(__FILE__, __LINE__, "View#scroll_by", argc, 1);

		THIS->scroll_by(to<Rays::Point&>(argv[0]));
	}
	else
	{
		if (argv[0].is_array())
		{
			argc = argv[0].size();
			argv = &argv[0][0];
		}
		check_arg_count(__FILE__, __LINE__, "View#scroll_by(Numeric, ...)", argc, 2, 3);

		coord x = (argc >= 1 && argv[0]) ? to<coord>(argv[0]) : 0;
		coord y = (argc >= 2 && argv[1]) ? to<coord>(argv[1]) : 0;
		coord z = (argc >= 3 && argv[2]) ? to<coord>(argv[2]) : 0;
		THIS->scroll_by(x, y, z);
	}

	return self;
}
RUCY_END

static
RUCY_DEF0(get_scroll)
{
	CHECK;
	return value(THIS->scroll());
}
RUCY_END

static
RUCY_DEF1(set_zoom, zoom)
{
	CHECK;
	THIS->set_zoom(to<float>(zoom));
	return zoom;
}
RUCY_END

static
RUCY_DEF0(get_zoom)
{
	CHECK;
	return value(THIS->zoom());
}
RUCY_END

static
RUCY_DEF1(set_capture, types)
{
	CHECK;
	THIS->set_capture(to<uint>(types));
	return types;
}
RUCY_END

static
RUCY_DEF0(get_capture)
{
	CHECK;
	return value(THIS->capture());
}
RUCY_END

static
RUCY_DEF1(set_clip, clip)
{
	CHECK;

	if (clip)
		THIS->   add_flag(Reflex::View::FLAG_CLIP);
	else
		THIS->remove_flag(Reflex::View::FLAG_CLIP);

	return clip;
}
RUCY_END

static
RUCY_DEF0(get_clip)
{
	CHECK;
	return value(THIS->has_flag(Reflex::View::FLAG_CLIP));
}
RUCY_END

static
RUCY_DEF1(set_cache, cache)
{
	CHECK;

	if (cache)
		THIS->   add_flag(Reflex::View::FLAG_CACHE);
	else
		THIS->remove_flag(Reflex::View::FLAG_CACHE);

	return cache;
}
RUCY_END

static
RUCY_DEF0(get_cache)
{
	CHECK;
	return value(THIS->has_flag(Reflex::View::FLAG_CACHE));
}
RUCY_END

static
RUCY_DEF1(set_resize_to_fit, resize)
{
	CHECK;

	if (resize)
		THIS->   add_flag(Reflex::View::FLAG_RESIZE_TO_FIT);
	else
		THIS->remove_flag(Reflex::View::FLAG_RESIZE_TO_FIT);

	return resize;
}
RUCY_END

static
RUCY_DEF0(get_resize_to_fit)
{
	CHECK;
	return value(THIS->has_flag(Reflex::View::FLAG_RESIZE_TO_FIT));
}
RUCY_END

static
RUCY_DEF1(set_scroll_to_fit, scroll)
{
	CHECK;

	if (scroll)
		THIS->   add_flag(Reflex::View::FLAG_SCROLL_TO_FIT);
	else
		THIS->remove_flag(Reflex::View::FLAG_SCROLL_TO_FIT);

	return scroll;
}
RUCY_END

static
RUCY_DEF0(get_scroll_to_fit)
{
	CHECK;
	return value(THIS->has_flag(Reflex::View::FLAG_SCROLL_TO_FIT));
}
RUCY_END

static
RUCY_DEF1(set_fix_angle, fix)
{
	CHECK;

	if (fix)
		THIS->   add_flag(Reflex::View::FLAG_FIX_ANGLE);
	else
		THIS->remove_flag(Reflex::View::FLAG_FIX_ANGLE);

	return fix;
}
RUCY_END

static
RUCY_DEF0(get_fix_angle)
{
	CHECK;
	return value(THIS->has_flag(Reflex::View::FLAG_FIX_ANGLE));
}
RUCY_END

static
RUCY_DEF0(parent)
{
	CHECK;
	return value(THIS->parent());
}
RUCY_END

static
RUCY_DEF0(window)
{
	CHECK;
	return value(THIS->window());
}
RUCY_END

static
RUCY_DEFN(apply_force)
{
	CHECK;
	THIS->apply_force(to<Rays::Point>(argc, argv));
	return self;
}
RUCY_END

static
RUCY_DEF1(apply_torque, torque)
{
	CHECK;
	THIS->apply_torque(to<float>(torque));
	return self;
}
RUCY_END

static
RUCY_DEFN(apply_linear_impulse)
{
	CHECK;
	THIS->apply_linear_impulse(to<Rays::Point>(argc, argv));
	return self;
}
RUCY_END

static
RUCY_DEF1(apply_angular_impulse, impulse)
{
	CHECK;
	THIS->apply_angular_impulse(to<float>(impulse));
	return self;
}
RUCY_END

static
RUCY_DEF1(set_static, state)
{
	CHECK;
	THIS->set_static(state);
	return state;
}
RUCY_END

static
RUCY_DEF0(is_static)
{
	CHECK;
	return value(THIS->is_static());
}
RUCY_END

static
RUCY_DEF1(set_dynamic, state)
{
	CHECK;
	THIS->set_dynamic(state);
	return state;
}
RUCY_END

static
RUCY_DEF0(is_dynamic)
{
	CHECK;
	return value(THIS->is_dynamic());
}
RUCY_END

static
RUCY_DEF1(set_density, density)
{
	CHECK;
	THIS->set_density(to<float>(density));
	return density;
}
RUCY_END

static
RUCY_DEF0(get_density)
{
	CHECK;
	return value(THIS->density());
}
RUCY_END

static
RUCY_DEF1(set_friction, friction)
{
	CHECK;
	THIS->set_friction(to<float>(friction));
	return friction;
}
RUCY_END

static
RUCY_DEF0(get_friction)
{
	CHECK;
	return value(THIS->friction());
}
RUCY_END

static
RUCY_DEF1(set_restitution, restitution)
{
	CHECK;
	THIS->set_restitution(to<float>(restitution));
	return restitution;
}
RUCY_END

static
RUCY_DEF0(get_restitution)
{
	CHECK;
	return value(THIS->restitution());
}
RUCY_END

static
RUCY_DEF1(set_sensor, state)
{
	CHECK;
	THIS->set_sensor(state);
	return state;
}
RUCY_END

static
RUCY_DEF0(is_sensor)
{
	CHECK;
	return value(THIS->is_sensor());
}
RUCY_END

static
RUCY_DEFN(set_linear_velocity)
{
	CHECK;
	THIS->set_linear_velocity(to<Rays::Point>(argc, argv));
	return value(THIS->linear_velocity());
}
RUCY_END

static
RUCY_DEF0(get_linear_velocity)
{
	CHECK;
	return value(THIS->linear_velocity());
}
RUCY_END

static
RUCY_DEF1(set_angular_velocity, velocity)
{
	CHECK;
	THIS->set_angular_velocity(to<float>(velocity));
	return velocity;
}
RUCY_END

static
RUCY_DEF0(get_angular_velocity)
{
	CHECK;
	return value(THIS->angular_velocity());
}
RUCY_END

static
RUCY_DEF1(set_gravity_scale, scale)
{
	CHECK;
	THIS->set_gravity_scale(to<float>(scale));
	return scale;
}
RUCY_END

static
RUCY_DEF0(get_gravity_scale)
{
	CHECK;
	return value(THIS->gravity_scale());
}
RUCY_END

static
RUCY_DEF1(create_world, pixels_per_meter)
{
	CHECK;
	THIS->create_world(to<float>(pixels_per_meter));
}
RUCY_END

static
RUCY_DEFN(update_world)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "View#update_world", argc, 0, 1);

	float duration = argc >= 1 ? to<float>(argv[0]) : 0;
	THIS->update_world(duration);
	return self;
}
RUCY_END

static
RUCY_DEFN(meter2pixel)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "View#meter2pixel", argc, 0, 1, 2);

	float meter       = argc >= 1 ? to<float>(argv[0]) : 1;
	bool create_world = argc >= 2 ? to<bool> (argv[1]) : true;
	return value(THIS->meter2pixel(meter, create_world));
}
RUCY_END

static
RUCY_DEFN(set_gravity)
{
	CHECK;
	THIS->set_gravity(to<Rays::Point>(argc, argv));
	return value(THIS->gravity());
}
RUCY_END

static
RUCY_DEF0(get_gravity)
{
	CHECK;
	return value(THIS->gravity());
}
RUCY_END

static
RUCY_DEF1(set_time_scale, scale)
{
	CHECK;
	THIS->set_time_scale(to<float>(scale));
	return scale;
}
RUCY_END

static
RUCY_DEF0(get_time_scale)
{
	CHECK;
	return value(THIS->time_scale());
}
RUCY_END

static
RUCY_DEF0(wall)
{
	CHECK;
	return value(THIS->wall());
}
RUCY_END

static
RUCY_DEF1(set_debug, state)
{
	CHECK;
	THIS->set_debug(state);
	return state;
}
RUCY_END

static
RUCY_DEF0(get_debug)
{
	CHECK;
	return value(THIS->debug());
}
RUCY_END

static
RUCY_DEF1(on_attach, event)
{
	CHECK;
	CALL(on_attach(to<Reflex::Event*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_detach, event)
{
	CHECK;
	CALL(on_detach(to<Reflex::Event*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_show, event)
{
	CHECK;
	CALL(on_show(to<Reflex::Event*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_hide, event)
{
	CHECK;
	CALL(on_hide(to<Reflex::Event*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_update, event)
{
	CHECK;
	CALL(on_update(to<Reflex::UpdateEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_draw, event)
{
	CHECK;
	CALL(on_draw(to<Reflex::DrawEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_move, event)
{
	CHECK;
	CALL(on_move(to<Reflex::FrameEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_resize, event)
{
	CHECK;
	CALL(on_resize(to<Reflex::FrameEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_zoom, event)
{
	CHECK;
	CALL(on_zoom(to<Reflex::FrameEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_rotate, event)
{
	CHECK;
	CALL(on_rotate(to<Reflex::FrameEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_scroll, event)
{
	CHECK;
	CALL(on_scroll(to<Reflex::ScrollEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_focus, event)
{
	CHECK;
	CALL(on_focus(to<Reflex::FocusEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_key, event)
{
	CHECK;
	CALL(on_key(to<Reflex::KeyEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_key_down, event)
{
	CHECK;
	CALL(on_key_down(to<Reflex::KeyEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_key_up, event)
{
	CHECK;
	CALL(on_key_up(to<Reflex::KeyEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_pointer, event)
{
	CHECK;
	CALL(on_pointer(to<Reflex::PointerEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_pointer_down, event)
{
	CHECK;
	CALL(on_pointer_down(to<Reflex::PointerEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_pointer_up, event)
{
	CHECK;
	CALL(on_pointer_up(to<Reflex::PointerEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_pointer_move, event)
{
	CHECK;
	CALL(on_pointer_move(to<Reflex::PointerEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_pointer_cancel, event)
{
	CHECK;
	CALL(on_pointer_cancel(to<Reflex::PointerEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_wheel, event)
{
	CHECK;
	CALL(on_wheel(to<Reflex::WheelEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_capture, event)
{
	CHECK;
	CALL(on_capture(to<Reflex::CaptureEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_timer, event)
{
	CHECK;
	CALL(on_timer(to<Reflex::TimerEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(will_contact, view)
{
	CHECK;
	return value(CALL(will_contact(to<Reflex::View*>(view))));
}
RUCY_END

static
RUCY_DEF1(on_contact, event)
{
	CHECK;
	CALL(on_contact(to<Reflex::ContactEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_contact_begin, event)
{
	CHECK;
	CALL(on_contact_begin(to<Reflex::ContactEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_contact_end, event)
{
	CHECK;
	CALL(on_contact_end(to<Reflex::ContactEvent*>(event)));
}
RUCY_END


static Class cView;

void
Init_reflex_view ()
{
	Module mReflex = define_module("Reflex");

	cView = mReflex.define_class("View");
	cView.define_alloc_func(alloc);
	cView.define_method("show",    show);
	cView.define_method("hide",    hide);
	cView.define_method("hidden?", hidden);
	cView.define_method("redraw",  redraw);
	cView.define_method("focus",  focus);
	cView.define_method("blur",   blur);
	cView.define_method("focus?", has_focus);
	cView.define_private_method("start_timer", start_timer);
	cView.define_method("update_layout", update_layout);

	cView.define_method("from_parent", from_parent);
	cView.define_method(  "to_parent",   to_parent);
	cView.define_method("from_window", from_window);
	cView.define_method(  "to_window",   to_window);
	cView.define_method("from_screen", from_screen);
	cView.define_method(  "to_screen",   to_screen);

	cView.define_method(   "add_child",      add_child);
	cView.define_method("remove_child",   remove_child);
	cView.define_method( "clear_children", clear_children);
	cView.define_method(  "find_children",  find_children);
	cView.define_method(  "each_child",     each_child);

	cView.define_method(   "add_style",    add_style);
	cView.define_method("remove_style", remove_style);
	cView.define_method(   "get_style",    get_style);
	cView.define_method(  "find_styles",  find_styles);
	cView.define_method(  "each_style",   each_style);

	cView.define_method(       "shape=",   set_shape);
	cView.define_method(       "shape",    get_shape);
	cView.define_method(   "add_shape",    add_shape);
	cView.define_method("remove_shape", remove_shape);
	cView.define_method( "clear_shapes", clear_shapes);
	cView.define_method(  "find_shapes",  find_shapes);
	cView.define_method(  "each_shape",   each_shape);

	cView.define_method("filter=", set_filter);
	cView.define_method("filter",  get_filter);

	cView.define_method("frame=", set_frame);
	cView.define_method("frame",  get_frame);
	cView.define_method("content_bounds", content_bounds);
	cView.define_method("fit_to_content", fit_to_content);
	cView.define_method("angle=", set_angle);
	cView.define_method("angle",  get_angle);
	cView.define_method("pivot=", set_pivot);
	cView.define_method("pivot",  get_pivot);
	cView.define_method("scroll_to", scroll_to);
	cView.define_method("scroll_by", scroll_by);
	cView.define_method("scroll", get_scroll);
	cView.define_method("zoom=", set_zoom);
	cView.define_method("zoom",  get_zoom);
	cView.define_method("capture=", set_capture);
	cView.define_method("capture",  get_capture);
	cView.define_method("clip=", set_clip);
	cView.define_method("clip?", get_clip);
	cView.define_method("cache=", set_cache);
	cView.define_method("cache?", get_cache);
	cView.define_method("resize_to_fit=", set_resize_to_fit);
	cView.define_method("resize_to_fit?", get_resize_to_fit);
	cView.define_method("scroll_to_fit=", set_scroll_to_fit);
	cView.define_method("scroll_to_fit?", get_scroll_to_fit);
	cView.define_method("fix_angle=", set_fix_angle);
	cView.define_method("fix_angle?", get_fix_angle);
	cView.define_method("parent", parent);
	cView.define_method("window", window);

	cView.define_method("apply_force",           apply_force);
	cView.define_method("apply_torque",          apply_torque);
	cView.define_method("apply_linear_impulse",  apply_linear_impulse);
	cView.define_method("apply_angular_impulse", apply_angular_impulse);
	cView.define_method("static=",  set_static);
	cView.define_method("static?",   is_static);
	cView.define_method("dynamic=", set_dynamic);
	cView.define_method("dynamic?",  is_dynamic);
	cView.define_method("density=",     set_density);
	cView.define_method("density",      get_density);
	cView.define_method("friction=",    set_friction);
	cView.define_method("friction",     get_friction);
	cView.define_method("restitution=", set_restitution);
	cView.define_method("restitution",  get_restitution);
	cView.define_method("sensor=",      set_sensor);
	cView.define_method("sensor?",       is_sensor);
	cView.define_method("linear_velocity=",  set_linear_velocity);
	cView.define_method("linear_velocity",   get_linear_velocity);
	cView.define_method("angular_velocity=", set_angular_velocity);
	cView.define_method("angular_velocity",  get_angular_velocity);
	cView.define_method("gravity_scale=", set_gravity_scale);
	cView.define_method("gravity_scale",  get_gravity_scale);

	cView.define_method("create_world", create_world);
	cView.define_method("update_world", update_world);
	cView.define_method("meter2pixel", meter2pixel);
	cView.define_method("gravity=", set_gravity);
	cView.define_method("gravity",  get_gravity);
	cView.define_method("time_scale=", set_time_scale);
	cView.define_method("time_scale",  get_time_scale);
	cView.define_method("wall", wall);
	cView.define_method("debug=", set_debug);
	cView.define_method("debug?", get_debug);

	cView.define_method("on_attach", on_attach);
	cView.define_method("on_detach", on_detach);
	cView.define_method("on_show",   on_show);
	cView.define_method("on_hide",   on_hide);
	cView.define_method("on_update", on_update);
	cView.define_method("on_draw",   on_draw);
	cView.define_method("on_move",   on_move);
	cView.define_method("on_resize", on_resize);
	cView.define_method("on_zoom",   on_zoom);
	cView.define_method("on_rotate", on_rotate);
	cView.define_method("on_scroll", on_scroll);
	cView.define_method("on_focus",  on_focus);
	cView.define_method("on_key",      on_key);
	cView.define_method("on_key_down", on_key_down);
	cView.define_method("on_key_up",   on_key_up);
	cView.define_method("on_pointer",        on_pointer);
	cView.define_method("on_pointer_down",   on_pointer_down);
	cView.define_method("on_pointer_up",     on_pointer_up);
	cView.define_method("on_pointer_move",   on_pointer_move);
	cView.define_method("on_pointer_cancel", on_pointer_cancel);
	cView.define_method("on_wheel",   on_wheel);
	cView.define_method("on_capture", on_capture);
	cView.define_method("on_timer",   on_timer);
	cView.define_method(        "will_contact?",     will_contact);
	cView.define_private_method("call_contact!",       on_contact);
	cView.define_private_method("call_contact_begin!", on_contact_begin);
	cView.define_private_method("call_contact_end!",   on_contact_end);

	cView.define_const("CAPTURE_NONE",    Reflex::View::CAPTURE_NONE);
	cView.define_const("CAPTURE_KEY",     Reflex::View::CAPTURE_KEY);
	cView.define_const("CAPTURE_POINTER", Reflex::View::CAPTURE_POINTER);
	cView.define_const("CAPTURE_NOTE",    Reflex::View::CAPTURE_NOTE);
	cView.define_const("CAPTURE_ALL",     Reflex::View::CAPTURE_ALL);

	define_selector_methods<Reflex::View>(cView);
}


namespace Reflex
{


	Class
	view_class ()
	{
		return cView;
	}


}// Reflex
