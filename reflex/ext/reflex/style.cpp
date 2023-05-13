#include "reflex/ruby/style.h"


#include <rays/ruby/color.h>
#include <rays/ruby/image.h>
#include "reflex/ruby/selector.h"
#include "defs.h"
#include "selector.h"


RUCY_DEFINE_VALUE_FROM_TO(Reflex::Style)

#define   THIS to<      Reflex::Style*>(self)
#define C_THIS to<const Reflex::Style*>(self)

#define CHECK  RUCY_CHECK_OBJ(Reflex::Style, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Reflex::Style>(klass);
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Reflex::Style&>(obj);
	return self;
}
RUCY_END

static
RUCY_DEFN(set_flow)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "Style#set_flow", argc, 1, 2);

	if (argv[0].is_nil())
	{
		if (argc >= 2 && !argv[1].is_nil())
			argument_error(__FILE__, __LINE__);

		THIS->clear_flow();
	}
	else
	{
		THIS->set_flow(
			(Reflex::Style::Flow) to<int>(argv[0]),
			argc >= 2 ? (Reflex::Style::Flow) to<int>(argv[1]) : Reflex::Style::FLOW_NONE);
	}

	return value(argc, argv);
}
RUCY_END

static
RUCY_DEF0(get_flow)
{
	CHECK;

	Reflex::Style::Flow main, sub;
	THIS->get_flow(&main, &sub);
	return array(main, sub);
}
RUCY_END

static
RUCY_DEF1(set_width, width)
{
	CHECK;

	if (width.is_nil())
		THIS->clear_width();
	else
		THIS->set_width(to<Reflex::StyleLength>(width));

	return width;
}
RUCY_END

static
RUCY_DEF0(get_width)
{
	CHECK;
	return value(THIS->width());
}
RUCY_END

static
RUCY_DEF1(set_height, height)
{
	CHECK;

	if (height.is_nil())
		THIS->clear_height();
	else
		THIS->set_height(to<Reflex::StyleLength>(height));

	return height;
}
RUCY_END

static
RUCY_DEF0(get_height)
{
	CHECK;
	return value(THIS->height());
}
RUCY_END

static
RUCY_DEFN(set_size)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "Style#set_size", argc, 1, 2);

	set_width( self, argv[0]);
	set_height(self, argc >= 2 ? argv[1] : argv[0]);

	return value(argc, argv);
}
RUCY_END

static
RUCY_DEF0(get_size)
{
	CHECK;
	return array(
		get_width(self),
		get_height(self));
}
RUCY_END

static
RUCY_DEF1(set_left, left)
{
	CHECK;

	if (left.is_nil())
		THIS->clear_left();
	else
		THIS->set_left(to<Reflex::StyleLength>(left));

	return left;
}
RUCY_END

static
RUCY_DEF0(get_left)
{
	CHECK;
	return value(THIS->left());
}
RUCY_END

static
RUCY_DEF1(set_top, top)
{
	CHECK;

	if (top.is_nil())
		THIS->clear_top();
	else
		THIS->set_top(to<Reflex::StyleLength>(top));

	return top;
}
RUCY_END

static
RUCY_DEF0(get_top)
{
	CHECK;
	return value(THIS->top());
}
RUCY_END

static
RUCY_DEF1(set_right, right)
{
	CHECK;

	if (right.is_nil())
		THIS->clear_right();
	else
		THIS->set_right(to<Reflex::StyleLength>(right));

	return right;
}
RUCY_END

static
RUCY_DEF0(get_right)
{
	CHECK;
	return value(THIS->right());
}
RUCY_END

static
RUCY_DEF1(set_bottom, bottom)
{
	CHECK;

	if (bottom.is_nil())
		THIS->clear_bottom();
	else
		THIS->set_bottom(to<Reflex::StyleLength>(bottom));

	return bottom;
}
RUCY_END

static
RUCY_DEF0(get_bottom)
{
	CHECK;
	return value(THIS->bottom());
}
RUCY_END

static
RUCY_DEF4(set_position, left, top, right, bottom)
{
	CHECK;

	set_left(  self, left);
	set_top(   self, top);
	set_right( self, right);
	set_bottom(self, bottom);

	return array(left, top, right, bottom);
}
RUCY_END

static
RUCY_DEF0(get_position)
{
	CHECK;
	return array(
		get_left(self),
		get_top(self),
		get_right(self),
		get_bottom(self));
}
RUCY_END

static
RUCY_DEF1(set_margin_left, left)
{
	CHECK;

	if (left.is_nil())
		THIS->clear_margin_left();
	else
		THIS->set_margin_left(to<Reflex::StyleLength>(left));

	return left;
}
RUCY_END

static
RUCY_DEF0(get_margin_left)
{
	CHECK;
	return value(THIS->margin_left());
}
RUCY_END

static
RUCY_DEF1(set_margin_top, top)
{
	CHECK;

	if (top.is_nil())
		THIS->clear_margin_top();
	else
		THIS->set_margin_top(to<Reflex::StyleLength>(top));

	return top;
}
RUCY_END

static
RUCY_DEF0(get_margin_top)
{
	CHECK;
	return value(THIS->margin_top());
}
RUCY_END

static
RUCY_DEF1(set_margin_right, right)
{
	CHECK;

	if (right.is_nil())
		THIS->clear_margin_right();
	else
		THIS->set_margin_right(to<Reflex::StyleLength>(right));

	return right;
}
RUCY_END

static
RUCY_DEF0(get_margin_right)
{
	CHECK;
	return value(THIS->margin_right());
}
RUCY_END

static
RUCY_DEF1(set_margin_bottom, bottom)
{
	CHECK;

	if (bottom.is_nil())
		THIS->clear_margin_bottom();
	else
		THIS->set_margin_bottom(to<Reflex::StyleLength>(bottom));

	return bottom;
}
RUCY_END

static
RUCY_DEF0(get_margin_bottom)
{
	CHECK;
	return value(THIS->margin_bottom());
}
RUCY_END

static
RUCY_DEF4(set_margin, left, top, right, bottom)
{
	CHECK;

	set_margin_left(  self, left);
	set_margin_top(   self, top);
	set_margin_right( self, right);
	set_margin_bottom(self, bottom);

	return array(left, top, right, bottom);
}
RUCY_END

static
RUCY_DEF0(get_margin)
{
	CHECK;
	return array(
		get_margin_left(self),
		get_margin_top(self),
		get_margin_right(self),
		get_margin_bottom(self));
}
RUCY_END

static
RUCY_DEF1(set_padding_left, left)
{
	CHECK;

	if (left.is_nil())
		THIS->clear_padding_left();
	else
		THIS->set_padding_left(to<Reflex::StyleLength>(left));

	return left;
}
RUCY_END

static
RUCY_DEF0(get_padding_left)
{
	CHECK;
	return value(THIS->padding_left());
}
RUCY_END

static
RUCY_DEF1(set_padding_top, top)
{
	CHECK;

	if (top.is_nil())
		THIS->clear_padding_top();
	else
		THIS->set_padding_top(to<Reflex::StyleLength>(top));

	return top;
}
RUCY_END

static
RUCY_DEF0(get_padding_top)
{
	CHECK;
	return value(THIS->padding_top());
}
RUCY_END

static
RUCY_DEF1(set_padding_right, right)
{
	CHECK;

	if (right.is_nil())
		THIS->clear_padding_right();
	else
		THIS->set_padding_right(to<Reflex::StyleLength>(right));

	return right;
}
RUCY_END

static
RUCY_DEF0(get_padding_right)
{
	CHECK;
	return value(THIS->padding_right());
}
RUCY_END

static
RUCY_DEF1(set_padding_bottom, bottom)
{
	CHECK;

	if (bottom.is_nil())
		THIS->clear_padding_bottom();
	else
		THIS->set_padding_bottom(to<Reflex::StyleLength>(bottom));

	return bottom;
}
RUCY_END

static
RUCY_DEF0(get_padding_bottom)
{
	CHECK;
	return value(THIS->padding_bottom());
}
RUCY_END

static
RUCY_DEF4(set_padding, left, top, right, bottom)
{
	CHECK;

	set_padding_left(  self, left);
	set_padding_top(   self, top);
	set_padding_right( self, right);
	set_padding_bottom(self, bottom);

	return array(left, top, right, bottom);
}
RUCY_END

static
RUCY_DEF0(get_padding)
{
	CHECK;
	return array(
		get_padding_left(self),
		get_padding_top(self),
		get_padding_right(self),
		get_padding_bottom(self));
}
RUCY_END

static
RUCY_DEF1(set_center_x, x)
{
	CHECK;

	if (x.is_nil())
		THIS->clear_center_x();
	else
		THIS->set_center_x(to<Reflex::StyleLength>(x));

	return x;
}
RUCY_END

static
RUCY_DEF0(get_center_x)
{
	CHECK;
	return value(THIS->center_x());
}
RUCY_END

static
RUCY_DEF1(set_center_y, y)
{
	CHECK;

	if (y.is_nil())
		THIS->clear_center_y();
	else
		THIS->set_center_y(to<Reflex::StyleLength>(y));

	return y;
}
RUCY_END

static
RUCY_DEF0(get_center_y)
{
	CHECK;
	return value(THIS->center_y());
}
RUCY_END

static
RUCY_DEF2(set_center, x, y)
{
	CHECK;

	set_center_x(self, x);
	set_center_y(self, y);

	return array(x, y);
}
RUCY_END

static
RUCY_DEF0(get_center)
{
	CHECK;
	return array(
		get_center_x(self),
		get_center_y(self));
}
RUCY_END

static
RUCY_DEFN(set_foreground_fill)
{
	CHECK;
	check_arg_count(
		__FILE__, __LINE__, "Style#set_foreground_fill", argc, 1, 2, 3, 4);

	if (argv[0].is_nil())
	{
		if (argc != 1)
			argument_error(__FILE__, __LINE__);

		THIS->clear_foreground_fill();
		return argv[0];
	}
	else
	{
		Reflex::Color color = to<Reflex::Color>(argc, argv);
		THIS->set_foreground_fill(color);
		return value(color);
	}
}
RUCY_END

static
RUCY_DEFN(set_foreground_stroke)
{
	CHECK;
	check_arg_count(
		__FILE__, __LINE__, "Style#set_foreground_stroke", argc, 1, 2, 3, 4);

	if (argv[0].is_nil())
	{
		if (argc != 1)
			argument_error(__FILE__, __LINE__);

		THIS->clear_foreground_stroke();
		return argv[0];
	}
	else
	{
		Reflex::Color color = to<Reflex::Color>(argc, argv);
		THIS->set_foreground_stroke(color);
		return value(color);
	}
}
RUCY_END

static
RUCY_DEF1(set_foreground_stroke_width, width)
{
	CHECK;

	if (width.is_nil())
		THIS->clear_foreground_stroke_width();
	else
		THIS->set_foreground_stroke_width(to<coord>(width));

	return width;
}
RUCY_END

static
RUCY_DEFN(set_background_fill)
{
	CHECK;
	check_arg_count(
		__FILE__, __LINE__, "Style#set_background_fill", argc, 1, 2, 3, 4);

	if (argv[0].is_nil())
	{
		if (argc != 1)
			argument_error(__FILE__, __LINE__);

		THIS->clear_background_fill();
		return argv[0];
	}
	else
	{
		Reflex::Color color = to<Reflex::Color>(argc, argv);
		THIS->set_background_fill(color);
		return value(color);
	}
}
RUCY_END

static
RUCY_DEFN(set_background_stroke)
{
	CHECK;
	check_arg_count(
		__FILE__, __LINE__, "Style#set_background_stroke", argc, 1, 2, 3, 4);

	if (argv[0].is_nil())
	{
		if (argc != 1)
			argument_error(__FILE__, __LINE__);

		THIS->clear_background_stroke();
		return argv[0];
	}
	else
	{
		Reflex::Color color = to<Reflex::Color>(argc, argv);
		THIS->set_background_stroke(color);
		return value(color);
	}
}
RUCY_END

static
RUCY_DEF1(set_background_stroke_width, width)
{
	CHECK;

	if (width.is_nil())
		THIS->clear_background_stroke_width();
	else
		THIS->set_background_stroke_width(to<coord>(width));

	return width;
}
RUCY_END

static
RUCY_DEF0(get_foreground_fill)
{
	CHECK;
	return value(THIS->foreground_fill());
}
RUCY_END

static
RUCY_DEF0(get_foreground_stroke)
{
	CHECK;
	return value(THIS->foreground_stroke());
}
RUCY_END

static
RUCY_DEF0(get_foreground_stroke_width)
{
	CHECK;
	return value(THIS->foreground_stroke_width());
}
RUCY_END

static
RUCY_DEF0(get_background_fill)
{
	CHECK;
	return value(THIS->background_fill());
}
RUCY_END

static
RUCY_DEF0(get_background_stroke)
{
	CHECK;
	return value(THIS->background_stroke());
}
RUCY_END

static
RUCY_DEF0(get_background_stroke_width)
{
	CHECK;
	return value(THIS->background_stroke_width());
}
RUCY_END

static
RUCY_DEF1(set_image, image)
{
	CHECK;

	if (image.is_nil())
		THIS->clear_image();
	else
		THIS->set_image(to<Reflex::Image&>(image));

	return image;
}
RUCY_END

static
RUCY_DEF0(get_image)
{
	CHECK;
	return THIS->image() ? value(THIS->image()) : nil();
}
RUCY_END

static
RUCY_DEF1(equal, style)
{
	CHECK;
	return value(*THIS == to<Reflex::Style&>(style));
}
RUCY_END


static Class cStyle;

void
Init_reflex_style ()
{
	Module mReflex = define_module("Reflex");

	cStyle = mReflex.define_class("Style");
	cStyle.define_alloc_func(alloc);
	cStyle.define_private_method("initialize_copy", initialize_copy);

	cStyle.define_method("set_flow", set_flow);
	cStyle.define_method("get_flow", get_flow);

	cStyle.define_method("width=",  set_width);
	cStyle.define_method("width",   get_width);
	cStyle.define_method("height=", set_height);
	cStyle.define_method("height",  get_height);
	cStyle.define_method("size=",   set_size);
	cStyle.define_method("size",    get_size);

	cStyle.define_method("left=",     set_left);
	cStyle.define_method("left",      get_left);
	cStyle.define_method("top=",      set_top);
	cStyle.define_method("top",       get_top);
	cStyle.define_method("right=",    set_right);
	cStyle.define_method("right",     get_right);
	cStyle.define_method("bottom=",   set_bottom);
	cStyle.define_method("bottom",    get_bottom);
	cStyle.define_method("position=", set_position);
	cStyle.define_method("position",  get_position);

	cStyle.define_method("margin_left=",   set_margin_left);
	cStyle.define_method("margin_left",    get_margin_left);
	cStyle.define_method("margin_top=",    set_margin_top);
	cStyle.define_method("margin_top",     get_margin_top);
	cStyle.define_method("margin_right=",  set_margin_right);
	cStyle.define_method("margin_right",   get_margin_right);
	cStyle.define_method("margin_bottom=", set_margin_bottom);
	cStyle.define_method("margin_bottom",  get_margin_bottom);
	cStyle.define_method("margin=",        set_margin);
	cStyle.define_method("margin",         get_margin);

	cStyle.define_method("padding_left=",   set_padding_left);
	cStyle.define_method("padding_left",    get_padding_left);
	cStyle.define_method("padding_top=",    set_padding_top);
	cStyle.define_method("padding_top",     get_padding_top);
	cStyle.define_method("padding_right=",  set_padding_right);
	cStyle.define_method("padding_right",   get_padding_right);
	cStyle.define_method("padding_bottom=", set_padding_bottom);
	cStyle.define_method("padding_bottom",  get_padding_bottom);
	cStyle.define_method("padding=",        set_padding);
	cStyle.define_method("padding",         get_padding);

	cStyle.define_method("center_x=", set_center_x);
	cStyle.define_method("center_x",  get_center_x);
	cStyle.define_method("center_y=", set_center_y);
	cStyle.define_method("center_y",  get_center_y);
	cStyle.define_method("center=",   set_center);
	cStyle.define_method("center",    get_center);

	cStyle.define_method("foreground_fill=",         set_foreground_fill);
	cStyle.define_method("foreground_fill",          get_foreground_fill);
	cStyle.define_method("foreground_stroke=",       set_foreground_stroke);
	cStyle.define_method("foreground_stroke",        get_foreground_stroke);
	cStyle.define_method("foreground_stroke_width=", set_foreground_stroke_width);
	cStyle.define_method("foreground_stroke_width",  get_foreground_stroke_width);
	cStyle.define_method("background_fill=",         set_background_fill);
	cStyle.define_method("background_fill",          get_background_fill);
	cStyle.define_method("background_stroke=",       set_background_stroke);
	cStyle.define_method("background_stroke",        get_background_stroke);
	cStyle.define_method("background_stroke_width=", set_background_stroke_width);
	cStyle.define_method("background_stroke_width",  get_background_stroke_width);

	cStyle.define_method("image=", set_image);
	cStyle.define_method("image",  get_image);

	cStyle.define_method("==", equal);

	cStyle.define_const("FLOW_NONE",  Reflex::Style::FLOW_NONE);
	cStyle.define_const("FLOW_DOWN",  Reflex::Style::FLOW_DOWN);
	cStyle.define_const("FLOW_RIGHT", Reflex::Style::FLOW_RIGHT);
	cStyle.define_const("FLOW_UP",    Reflex::Style::FLOW_UP);
	cStyle.define_const("FLOW_LEFT",  Reflex::Style::FLOW_LEFT);

	define_selector_methods<Reflex::Style>(cStyle);
}


namespace Reflex
{


	Class
	style_class ()
	{
		return cStyle;
	}


}// Reflex
