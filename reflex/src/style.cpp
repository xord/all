#include "style.h"


#include <assert.h>
#include "reflex/exception.h"
#include "reflex/debug.h"
#include "view.h"
#include "selector.h"


namespace Reflex
{


	template <typename T, typename DefaultValue = T>
	class StyleValue
	{

		typedef StyleValue<T, DefaultValue> This;

		typedef T Value;

		public:

			StyleValue ()
			:	pwrapper(NULL)
			{
			}

			StyleValue (const Value& value)
			:	pwrapper(NULL)
			{
				operator=(value);
			}

			StyleValue (const This& obj)
			:	pwrapper(NULL)
			{
				operator=(obj);
			}

			This& operator = (const Value& value)
			{
				set_wrapper(new ValueWrapper(value));
				return *this;
			}

			This& operator = (const This& obj)
			{
				if (&obj == this) return *this;
				const ValueWrapper* p = obj.wrapper();
				set_wrapper(p ? new ValueWrapper(*p) : NULL);
				return *this;
			}

			~StyleValue ()
			{
				clear();
			}

			bool clear ()
			{
				return set_wrapper(NULL);
			}

			bool set (const Value& value)
			{
				const ValueWrapper* p = wrapper();
				if (p && p->value() == value)
					return false;

				set_wrapper(new ValueWrapper(value));
				return true;
			}

			const Value& get () const
			{
				static const Value DEFVAL = DefaultValue();

				const ValueWrapper* p = wrapper();
				return p ? p->value() : DEFVAL;
			}

			const Value& get (const Value& defval) const
			{
				const ValueWrapper* p = wrapper();
				return p ? p->value() : defval;
			}

			void override (const This& obj)
			{
				if (!obj)
					return;

				if (*this && !is_inherited())
					return;

				set_wrapper(obj.wrapper());
				set_inherited();
			}

			bool is_inherited () const
			{
				return get_pointer_flag(pwrapper);
			}

			operator bool () const
			{
				return wrapper() != NULL;
			}

			bool operator ! () const
			{
				return !operator bool();
			}

		private:

			class ValueWrapper : public Xot::RefCountable<>
			{

				public:

					ValueWrapper () : value_(DefaultValue()) {}

					ValueWrapper (const Value& value) : value_(value) {}

					ValueWrapper (const ValueWrapper& obj) : value_(obj.value_) {}

					const Value& value () const {return value_;}

				private:

					Value value_;

			};// ValueWrapper

			const ValueWrapper* pwrapper;

			const ValueWrapper* set_wrapper (const ValueWrapper* ptr)
			{
				const ValueWrapper* p = wrapper();
				if (ptr != p)
				{
					if (p) p->release();
					pwrapper = p = ptr;
					if (p) p->retain();
				}
				return p;
			}

			void set_inherited (bool state = true)
			{
				if (pwrapper)
					pwrapper = Xot::set_pointer_flag(pwrapper, state);
			}

			const ValueWrapper* wrapper () const
			{
				return Xot::set_pointer_flag(pwrapper, false);
			}

	};// StyleValue


	struct StyleLength::Data
	{

		Type type;

		Value value;

		Data ()
		:	type(NONE), value(0)
		{
		}

		bool is_variable () const
		{
			return type == PERCENT || type == FILL || type == FIT;
		}

		friend bool operator == (const Data& lhs, const Data& rhs)
		{
			return lhs.type == rhs.type && lhs.value == rhs.value;
		}

	};// StyleLength::Data


	StyleLength::StyleLength (Type type, Value value)
	{
		reset(type, value);
	}

	StyleLength
	StyleLength::copy () const
	{
		return StyleLength(type(), value());
	}

	void
	StyleLength::reset (Type type, Value value)
	{
		if (type < NONE)
			argument_error(__FILE__, __LINE__);
		if (type >= TYPE_MAX)
			argument_error(__FILE__, __LINE__);

		if (type == FIT && value != 1)
			argument_error(__FILE__, __LINE__);

		self->type  = type;
		self->value = value;
	}

	StyleLength::Type
	StyleLength::type () const
	{
		return self->type;
	}

	StyleLength::Value
	StyleLength::value () const
	{
		return self->value;
	}

	StyleLength::operator bool () const
	{
		return NONE < self->type && self->type < TYPE_MAX;
	}

	bool
	StyleLength::operator ! () const
	{
		return !operator bool();
	}

	bool
	operator == (const StyleLength& lhs, const StyleLength& rhs)
	{
		return (!lhs && !rhs) || *lhs.self == *rhs.self;
	}

	bool
	operator != (const StyleLength& lhs, const StyleLength& rhs)
	{
		return !operator ==(lhs, rhs);
	}


	struct Style::Data
	{

		struct WhiteColor : public Color
		{
			WhiteColor () : Color(1, 1) {}
		};

		struct TransparentColor : public Color
		{
			TransparentColor () : Color(0, 0) {}
		};

		struct MaxLength : public StyleLength
		{
			MaxLength () : StyleLength(PERCENT, 100) {}
		};

		typedef StyleValue<bool>        BoolValue;

		typedef StyleValue<int>         IntValue;

		typedef StyleValue<double>      FloatValue;

		typedef StyleValue<coord>       CoordValue;

		typedef StyleValue<Color>       ColorValue;

		typedef StyleValue<Image>       ImageValue;

		typedef StyleValue<StyleLength> LengthValue;

		View* owner;

		SelectorPtr pselector;

		IntValue flow;

		StyleValue<StyleLength, MaxLength> width, height;

		LengthValue         left,         top,         right,         bottom;

		LengthValue  margin_left,  margin_top,  margin_right,  margin_bottom;

		LengthValue padding_left, padding_top, padding_right, padding_bottom;

		LengthValue center_x, center_y;

		StyleValue<Color, WhiteColor>       fore_fill;

		StyleValue<Color, TransparentColor> fore_stroke, back_fill, back_stroke;

		CoordValue fore_stroke_width, back_stroke_width;

		ImageValue image;

		Data ()
		:	owner(NULL)
		{
		}

		Selector& selector ()
		{
			if (!pselector) pselector.reset(new Selector);
			return *pselector;
		}

		enum FlowOffset {FLOW_MASK = 0xffff, FLOW_SHIFT = 16};

		bool set_flow (Flow main, Flow sub)
		{
			return flow.set((main & FLOW_MASK) | ((sub & FLOW_MASK) << FLOW_SHIFT));
		}

		Flow flow_main () const
		{
			return (Flow) (flow.get(FLOW_NONE) & FLOW_MASK);
		}

		Flow flow_sub () const
		{
			return (Flow) ((flow.get(FLOW_NONE << FLOW_SHIFT) >> FLOW_SHIFT) & FLOW_MASK);
		}

	};// Data


	bool
	Style_set_owner (Style* style, View* owner)
	{
		assert(style);

		if (!!style->self->owner == !!owner)
			return false;

		style->self->owner = owner;
		return true;
	}

	template <typename T>
	static bool
	is_variable (const T& length)
	{
		return length.get().self->is_variable();
	}

	bool
	Style_has_variable_lengths (const Style& style)
	{
		Style::Data* s = style.self.get();
		if (!s) return false;

		return
			is_variable(s->width)  ||
			is_variable(s->height) ||

			is_variable(s->left)   ||
			is_variable(s->top)    ||
			is_variable(s->right)  ||
			is_variable(s->bottom) ||

			is_variable(s->margin_left)   ||
			is_variable(s->margin_top)    ||
			is_variable(s->margin_right)  ||
			is_variable(s->margin_bottom) ||

			is_variable(s->padding_left)   ||
			is_variable(s->padding_top)    ||
			is_variable(s->padding_right)  ||
			is_variable(s->padding_bottom) ||

			is_variable(s->center_x)  ||
			is_variable(s->center_y);
	}

	template <typename T>
	static void
	clear_inherited_value (T* value)
	{
		assert(value);

		if (value->is_inherited())
			value->clear();
	}

	void
	Style_clear_inherited_values (Style* style)
	{
		assert(style);

		Style::Data* self = style->self.get();

		clear_inherited_value(&self->flow);
		clear_inherited_value(&self->width);
		clear_inherited_value(&self->height);
		clear_inherited_value(&self->left);
		clear_inherited_value(&self->top);
		clear_inherited_value(&self->right);
		clear_inherited_value(&self->bottom);
		clear_inherited_value(&self->margin_left);
		clear_inherited_value(&self->margin_top);
		clear_inherited_value(&self->margin_right);
		clear_inherited_value(&self->margin_bottom);
		clear_inherited_value(&self->padding_left);
		clear_inherited_value(&self->padding_top);
		clear_inherited_value(&self->padding_right);
		clear_inherited_value(&self->padding_bottom);
		clear_inherited_value(&self->center_x);
		clear_inherited_value(&self->center_y);
		clear_inherited_value(&self->fore_fill);
		clear_inherited_value(&self->fore_stroke);
		clear_inherited_value(&self->fore_stroke_width);
		clear_inherited_value(&self->back_fill);
		clear_inherited_value(&self->back_stroke);
		clear_inherited_value(&self->back_stroke_width);
		clear_inherited_value(&self->image);
	}

	void
	Style_override (Style* overridden, const Style& overrides)
	{
		assert(overridden);

		Style::Data* from  = overrides.self.get();
		Style::Data* to    = overridden->self.get();
		if (!from || !to) return;

		to->flow             .override(from->flow);
		to->width            .override(from->width);
		to->height           .override(from->height);
		to->left             .override(from->left);
		to->top              .override(from->top);
		to->right            .override(from->right);
		to->bottom           .override(from->bottom);
		to->margin_left      .override(from->margin_left);
		to->margin_top       .override(from->margin_top);
		to->margin_right     .override(from->margin_right);
		to->margin_bottom    .override(from->margin_bottom);
		to->padding_left     .override(from->padding_left);
		to->padding_top      .override(from->padding_top);
		to->padding_right    .override(from->padding_right);
		to->padding_bottom   .override(from->padding_bottom);
		to->center_x         .override(from->center_x);
		to->center_y         .override(from->center_y);
		to->fore_fill        .override(from->fore_fill);
		to->fore_stroke      .override(from->fore_stroke);
		to->fore_stroke_width.override(from->fore_stroke_width);
		to->back_fill        .override(from->back_fill);
		to->back_stroke      .override(from->back_stroke);
		to->back_stroke_width.override(from->back_stroke_width);
		to->image            .override(from->image);
	}

	bool
	StyleLength_get_pixel_length (
		coord* pixel_length, const StyleLength& style_length, coord parent_size)
	{
		assert(pixel_length);

		if (!style_length)
			return false;

		coord old_length = *pixel_length;

		StyleLength::Value value = style_length.value();
		switch (style_length.type())
		{
			case StyleLength::PIXEL:
				*pixel_length = value;
				break;

			case StyleLength::PERCENT:
				*pixel_length =
					(value == 100) ? parent_size : floor(parent_size * value / 100);
				break;

			case StyleLength::FILL:
				break;

			default:
				invalid_state_error(__FILE__, __LINE__);
		}

		return *pixel_length != old_length;
	}

	static void
	update_frame (View* view, const Style& style)
	{
		assert(view);

		View* parent = view->parent();
		if (!parent) return;

		Bounds frame               = view->frame();
		const Bounds& parent_frame = parent->frame();

		bool update = false;
		update |=
			StyleLength_get_pixel_length(&frame.w, style.width(),  parent_frame.w);
		update |=
			StyleLength_get_pixel_length(&frame.h, style.height(), parent_frame.h);

		if (update)
			View_set_frame(view, frame);
	}

	void
	Style_apply_to (const Style& style, View* view)
	{
		assert(view);

		//update_margin(view, values);
		//update_padding(view, values);
		update_frame(view, style);
		//update_background(view, values);
	}

	bool
	Style_has_width (const Style& style)
	{
		return style.self->width;
	}

	bool
	Style_has_height (const Style& style)
	{
		return style.self->height;
	}

	static void
	update_owner (const Style& style)
	{
		View* owner = style.self->owner;
		if (!owner) return;

		View_update_styles(owner, style.selector());
	}


	Style::Style (const char* name)
	{
		if (name) set_name(name);
	}

	Style::~Style ()
	{
	}

	void
	Style::set_name (const char* name)
	{
		update_owner(*this);
		HasSelector::set_name(name);
		update_owner(*this);
	}

	void
	Style::add_tag (const char* tag)
	{
		update_owner(*this);
		HasSelector::add_tag(tag);
		update_owner(*this);
	}

	void
	Style::remove_tag (const char* tag)
	{
		update_owner(*this);
		HasSelector::remove_tag(tag);
		update_owner(*this);
	}

	void
	Style::clear_tags ()
	{
		update_owner(*this);
		HasSelector::clear_tags();
		update_owner(*this);
	}

	void
	Style::set_selector (const Selector& selector)
	{
		update_owner(*this);
		HasSelector::set_selector(selector);
		update_owner(*this);
	}

	enum FlowDir {FLOW_INVALID = 0, FLOW_H, FLOW_V};

	static FlowDir
	get_flow_dir (Style::Flow flow)
	{
		switch (flow)
		{
			case Style::FLOW_LEFT:
			case Style::FLOW_RIGHT: return FLOW_H;
			case Style::FLOW_UP:
			case Style::FLOW_DOWN:  return FLOW_V;
			default:                return FLOW_INVALID;
		}
	}

	void
	Style::set_flow (Flow main, Flow sub)
	{
		if (main <  FLOW_NONE)
			argument_error(__FILE__, __LINE__);
		if (main >= FLOW_MAX)
			argument_error(__FILE__, __LINE__);
		if (sub  <  FLOW_NONE)
			argument_error(__FILE__, __LINE__);
		if (sub  >= FLOW_MAX)
			argument_error(__FILE__, __LINE__);
		if (main != FLOW_NONE && (get_flow_dir(main) == get_flow_dir(sub)))
			argument_error(__FILE__, __LINE__);
		if (main == FLOW_NONE && sub != FLOW_NONE)
			argument_error(__FILE__, __LINE__);

		self->set_flow(main, sub);

		update_owner(*this);
	}

	void
	Style::clear_flow ()
	{
		if (self->flow.clear())
			update_owner(*this);
	}

	void
	Style::get_flow (Flow* main, Flow* sub) const
	{
		if (!main && !sub)
			argument_error(__FILE__, __LINE__);

		if (main) *main = self->flow_main();
		if (sub)  *sub  = self->flow_sub();
	}

	void
	Style::set_width (const StyleLength& width)
	{
		if (self->width.set(width))
			update_owner(*this);
	}

	void
	Style::set_height (const StyleLength& height)
	{
		if (self->height.set(height))
			update_owner(*this);
	}

	void
	Style::clear_width ()
	{
		if (self->width.clear())
			update_owner(*this);
	}

	void
	Style::clear_height ()
	{
		if (self->height.clear())
			update_owner(*this);
	}

	const StyleLength&
	Style::width () const
	{
		return self->width.get();
	}

	const StyleLength&
	Style::height () const
	{
		return self->height.get();
	}

	void
	Style::set_left (const StyleLength& left)
	{
		if (self->left.set(left))
			update_owner(*this);
	}

	void
	Style::set_top (const StyleLength& top)
	{
		if (self->top.set(top))
			update_owner(*this);
	}

	void
	Style::set_right (const StyleLength& right)
	{
		if (self->right.set(right))
			update_owner(*this);
	}

	void
	Style::set_bottom (const StyleLength& bottom)
	{
		if (self->bottom.set(bottom))
			update_owner(*this);
	}

	void
	Style::clear_left ()
	{
		if (self->left.clear())
			update_owner(*this);
	}

	void
	Style::clear_top ()
	{
		if (self->top.clear())
			update_owner(*this);
	}

	void
	Style::clear_right ()
	{
		if (self->right.clear())
			update_owner(*this);
	}

	void
	Style::clear_bottom ()
	{
		if (self->bottom.clear())
			update_owner(*this);
	}

	const StyleLength&
	Style::left () const
	{
		return self->left.get();
	}

	const StyleLength&
	Style::top () const
	{
		return self->top.get();
	}

	const StyleLength&
	Style::right () const
	{
		return self->right.get();
	}

	const StyleLength&
	Style::bottom () const
	{
		return self->bottom.get();
	}

	void
	Style::set_margin_left (const StyleLength& left)
	{
		if (self->margin_left.set(left))
			update_owner(*this);
	}

	void
	Style::set_margin_top (const StyleLength& top)
	{
		if (self->margin_top.set(top))
			update_owner(*this);
	}

	void
	Style::set_margin_right (const StyleLength& right)
	{
		if (self->margin_right.set(right))
			update_owner(*this);
	}

	void
	Style::set_margin_bottom (const StyleLength& bottom)
	{
		if (self->margin_bottom.set(bottom))
			update_owner(*this);
	}

	void
	Style::clear_margin_left ()
	{
		if (self->margin_left.clear())
			update_owner(*this);
	}

	void
	Style::clear_margin_top ()
	{
		if (self->margin_top.clear())
			update_owner(*this);
	}

	void
	Style::clear_margin_right ()
	{
		if (self->margin_right.clear())
			update_owner(*this);
	}

	void
	Style::clear_margin_bottom ()
	{
		if (self->margin_bottom.clear())
			update_owner(*this);
	}

	const StyleLength&
	Style::margin_left () const
	{
		return self->margin_left.get();
	}

	const StyleLength&
	Style::margin_top () const
	{
		return self->margin_top.get();
	}

	const StyleLength&
	Style::margin_right () const
	{
		return self->margin_right.get();
	}

	const StyleLength&
	Style::margin_bottom () const
	{
		return self->margin_bottom.get();
	}

	void
	Style::set_padding_left (const StyleLength& left)
	{
		if (self->padding_left.set(left))
			update_owner(*this);
	}

	void
	Style::set_padding_top (const StyleLength& top)
	{
		if (self->padding_top.set(top))
			update_owner(*this);
	}

	void
	Style::set_padding_right (const StyleLength& right)
	{
		if (self->padding_right.set(right))
			update_owner(*this);
	}

	void
	Style::set_padding_bottom (const StyleLength& bottom)
	{
		if (self->padding_bottom.set(bottom))
			update_owner(*this);
	}

	void
	Style::clear_padding_left ()
	{
		if (self->padding_left.clear())
			update_owner(*this);
	}

	void
	Style::clear_padding_top ()
	{
		if (self->padding_top.clear())
			update_owner(*this);
	}

	void
	Style::clear_padding_right ()
	{
		if (self->padding_right.clear())
			update_owner(*this);
	}

	void
	Style::clear_padding_bottom ()
	{
		if (self->padding_bottom.clear())
			update_owner(*this);
	}

	const StyleLength&
	Style::padding_left () const
	{
		return self->padding_left.get();
	}

	const StyleLength&
	Style::padding_top () const
	{
		return self->padding_top.get();
	}

	const StyleLength&
	Style::padding_right () const
	{
		return self->padding_right.get();
	}

	const StyleLength&
	Style::padding_bottom () const
	{
		return self->padding_bottom.get();
	}

	void
	Style::set_center_x (const StyleLength& x)
	{
		if (self->center_x.set(x))
			update_owner(*this);
	}

	void
	Style::set_center_y (const StyleLength& y)
	{
		if (self->center_y.set(y))
			update_owner(*this);
	}

	void
	Style::clear_center_x ()
	{
		if (self->center_x.clear())
			update_owner(*this);
	}

	void
	Style::clear_center_y ()
	{
		if (self->center_y.clear())
			update_owner(*this);
	}

	const StyleLength&
	Style::center_x () const
	{
		return self->center_x.get();
	}

	const StyleLength&
	Style::center_y () const
	{
		return self->center_y.get();
	}

	void
	Style::set_foreground_fill (const Color& fill)
	{
		if (self->fore_fill.set(fill))
			update_owner(*this);
	}

	void
	Style::set_foreground_stroke (const Color& stroke)
	{
		if (self->fore_stroke.set(stroke))
			update_owner(*this);
	}

	void
	Style::set_foreground_stroke_width (coord width)
	{
		if (self->fore_stroke_width.set(width))
			update_owner(*this);
	}

	void
	Style::set_background_fill (const Color& fill)
	{
		if (self->back_fill.set(fill))
			update_owner(*this);
	}

	void
	Style::set_background_stroke (const Color& stroke)
	{
		if (self->back_stroke.set(stroke))
			update_owner(*this);
	}

	void
	Style::set_background_stroke_width (coord width)
	{
		if (self->back_stroke_width.set(width))
			update_owner(*this);
	}

	void
	Style::clear_foreground_fill ()
	{
		if (self->fore_fill.clear())
			update_owner(*this);
	}

	void
	Style::clear_foreground_stroke ()
	{
		if (self->fore_stroke.clear())
			update_owner(*this);
	}

	void
	Style::clear_foreground_stroke_width ()
	{
		if (self->fore_stroke_width.clear())
			update_owner(*this);
	}

	void
	Style::clear_background_fill ()
	{
		if (self->back_fill.clear())
			update_owner(*this);
	}

	void
	Style::clear_background_stroke ()
	{
		if (self->back_stroke.clear())
			update_owner(*this);
	}

	void
	Style::clear_background_stroke_width ()
	{
		if (self->back_stroke_width.clear())
			update_owner(*this);
	}

	const Color&
	Style::foreground_fill () const
	{
		return self->fore_fill.get();
	}

	const Color&
	Style::foreground_stroke () const
	{
		return self->fore_stroke.get();
	}

	coord
	Style::foreground_stroke_width () const
	{
		return self->fore_stroke_width.get();
	}

	const Color&
	Style::background_fill () const
	{
		return self->back_fill.get();
	}

	const Color&
	Style::background_stroke () const
	{
		return self->back_stroke.get();
	}

	coord
	Style::background_stroke_width () const
	{
		return self->back_stroke_width.get();
	}

	void
	Style::set_image (const Image& image)
	{
		if (self->image.set(image))
			update_owner(*this);
	}

	void
	Style::clear_image ()
	{
		if (self->image.clear())
			update_owner(*this);
	}

	const Image&
	Style::image () const
	{
		return self->image.get();
	}

	bool
	operator == (const Style& lhs, const Style& rhs)
	{
		return lhs.self.get() == rhs.self.get();
	}

	bool
	operator != (const Style& lhs, const Style& rhs)
	{
		return !operator==(lhs, rhs);
	}

	SelectorPtr*
	Style::get_selector_ptr ()
	{
		return &self->pselector;
	}


}// Reflex
