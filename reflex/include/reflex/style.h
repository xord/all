// -*- c++ -*-
#pragma once
#ifndef __REFLEX_STYLE_H__
#define __REFLEX_STYLE_H__


#include <xot/pimpl.h>
#include <rays/color.h>
#include <rays/image.h>
#include <reflex/defs.h>
#include <reflex/selector.h>


namespace Reflex
{


	class StyleLength
	{

		typedef StyleLength This;

		public:

			typedef coord Value;

			enum Type
			{

				NONE = 0,

				PIXEL,

				PERCENT,

				FILL,

				FIT,

				TYPE_MAX

			};// Type

			StyleLength (Type type = NONE, Value value = 0);

			This copy () const;

			void reset (Type type = NONE, Value value = 0);

			Value value () const;

			Type type () const;

			operator bool () const;

			bool operator ! () const;

			friend bool operator == (const This& lhs, const This& rhs);

			friend bool operator != (const This& lhs, const This& rhs);

			struct Data;

			Xot::PSharedImpl<Data> self;

	};// StyleLength


	class Style : public HasSelector
	{

		typedef Style This;

		public:

			enum Flow
			{

				FLOW_NONE = 0,

				FLOW_RIGHT,

				FLOW_DOWN,

				FLOW_LEFT,

				FLOW_UP,

				FLOW_MAX

			};// Flow

			Style (const char* name = NULL);

			~Style ();

			void set_name (const char* name);

			void    add_tag (const char* tag);

			void remove_tag (const char* tag);

			void  clear_tags ();

			void set_selector (const Selector& selector);

			void   set_flow (Flow main, Flow sub = FLOW_NONE);

			void clear_flow ();

			void   get_flow (Flow* main, Flow* sub) const;

			void           set_width (const StyleLength& width);

			void         clear_width ();

			const StyleLength& width () const;

			void           set_height (const StyleLength& height);

			void         clear_height ();

			const StyleLength& height () const;

			void           set_left (const StyleLength& left);

			void         clear_left ();

			const StyleLength& left () const;

			void           set_top (const StyleLength& top);

			void         clear_top ();

			const StyleLength& top () const;

			void           set_right (const StyleLength& right);

			void         clear_right ();

			const StyleLength& right () const;

			void           set_bottom (const StyleLength& bottom);

			void         clear_bottom ();

			const StyleLength& bottom () const;

			void           set_margin_left (const StyleLength& left);

			void         clear_margin_left ();

			const StyleLength& margin_left () const;

			void           set_margin_top (const StyleLength& top);

			void         clear_margin_top ();

			const StyleLength& margin_top () const;

			void           set_margin_right (const StyleLength& right);

			void         clear_margin_right ();

			const StyleLength& margin_right () const;

			void           set_margin_bottom (const StyleLength& bottom);

			void         clear_margin_bottom ();

			const StyleLength& margin_bottom () const;

			void           set_padding_left (const StyleLength& left);

			void         clear_padding_left ();

			const StyleLength& padding_left () const;

			void           set_padding_top (const StyleLength& top);

			void         clear_padding_top ();

			const StyleLength& padding_top () const;

			void           set_padding_right (const StyleLength& right);

			void         clear_padding_right ();

			const StyleLength& padding_right () const;

			void           set_padding_bottom (const StyleLength& bottom);

			void         clear_padding_bottom ();

			const StyleLength& padding_bottom () const;

			void           set_center_x (const StyleLength& x);

			void         clear_center_x ();

			const StyleLength& center_x () const;

			void           set_center_y (const StyleLength& y);

			void         clear_center_y ();

			const StyleLength& center_y () const;

			void     set_foreground_fill (const Color& fill);

			void   clear_foreground_fill ();

			const Color& foreground_fill () const;

			void     set_foreground_stroke (const Color& stroke);

			void   clear_foreground_stroke ();

			const Color& foreground_stroke () const;

			void     set_foreground_stroke_width (coord width);

			void   clear_foreground_stroke_width ();

			coord        foreground_stroke_width () const;

			void     set_background_fill (const Color& fill);

			void   clear_background_fill ();

			const Color& background_fill () const;

			void     set_background_stroke (const Color& stroke);

			void   clear_background_stroke ();

			const Color& background_stroke () const;

			void     set_background_stroke_width (coord width);

			void   clear_background_stroke_width ();

			coord        background_stroke_width () const;

			void     set_image (const Image& image);

			void   clear_image ();

			const Image& image () const;

			friend bool operator == (const This& lhs, const This& rhs);

			friend bool operator != (const This& lhs, const This& rhs);

			struct Data;

			Xot::PSharedImpl<Data> self;

		protected:

			virtual SelectorPtr* get_selector_ptr ();

	};// Style


}// Reflex


#endif//EOH
