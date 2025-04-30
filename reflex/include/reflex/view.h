// -*- c++ -*-
#pragma once
#ifndef __REFLEX_VIEW_H__
#define __REFLEX_VIEW_H__


#include <vector>
#include <xot/ref.h>
#include <xot/pimpl.h>
#include <xot/util.h>
#include <rays/point.h>
#include <rays/bounds.h>
#include <rays/painter.h>
#include <reflex/defs.h>
#include <reflex/selector.h>
#include <reflex/style.h>
#include <reflex/shape.h>
#include <reflex/event.h>


//#define REFLEX_VIEW_REF_DEBUG 1


namespace Reflex
{


	class Window;
	class Filter;


	class View : public Xot::RefCountable<>, public HasSelector
	{

		typedef View This;

		public:

			typedef Xot::Ref<This> Ref;

			typedef std::vector<Ref>        ChildList;

			typedef std::vector<Style>      StyleList;

			typedef std::vector<Shape::Ref> ShapeList;

			typedef ChildList::      iterator       child_iterator;

			typedef ChildList::const_iterator const_child_iterator;

			typedef StyleList::      iterator       style_iterator;

			typedef StyleList::const_iterator const_style_iterator;

			typedef ShapeList::      iterator       shape_iterator;

			typedef ShapeList::const_iterator const_shape_iterator;

			enum Flag
			{

				FLAG_CLIP          = Xot::bit(0),

				FLAG_CACHE         = Xot::bit(1),

				FLAG_RESIZE_TO_FIT = Xot::bit(2),

				FLAG_SCROLL_TO_FIT = Xot::bit(3),

				FLAG_FIX_ANGLE     = Xot::bit(4),

				FLAG_LAST          = FLAG_FIX_ANGLE

			};// Flag

			enum Capture
			{

				CAPTURE_NONE    = 0,

				CAPTURE_KEY     = Xot::bit(0),

				CAPTURE_POINTER = Xot::bit(1),

				CAPTURE_NOTE    = Xot::bit(2),

				CAPTURE_ALL     = CAPTURE_KEY | CAPTURE_POINTER | CAPTURE_NOTE,

			};// Capture

			View (const char* name = NULL);

			virtual void show ();

			virtual void hide ();

			virtual bool hidden () const;

			virtual void redraw ();

			virtual void focus (bool state = true);

			virtual void blur ();

			virtual bool has_focus () const;

			virtual Timer* start_timer    (float seconds, int count = 1);

			virtual Timer* start_interval (float seconds);

			virtual void update_layout ();

			virtual Point from_parent (const Point& point) const;

			virtual Point   to_parent (const Point& point) const;

			virtual Point from_window (const Point& point) const;

			virtual Point   to_window (const Point& point) const;

			virtual Point from_screen (const Point& point) const;

			virtual Point   to_screen (const Point& point) const;

			virtual void             add_child (View* child);

			virtual void          remove_child (View* child);

			virtual void           clear_children ();

			virtual ChildList       find_children (
				const Selector& selector, bool recursive = true) const;

			virtual       child_iterator child_begin ();

			virtual const_child_iterator child_begin () const;

			virtual       child_iterator child_end ();

			virtual const_child_iterator child_end () const;

			virtual       Style*         style (bool create = true);

			virtual const Style*         style () const;

			virtual void             add_style (const Style& style);

			virtual void          remove_style (const Style& style);

			virtual void           clear_styles ();

			virtual       Style*     get_style (
				const Selector& selector, bool create = true);

			virtual const Style*     get_style (const Selector& selector) const;

			virtual StyleList       find_styles (
				const Selector& selector, bool recursive = false) const;

			virtual       style_iterator style_begin ();

			virtual const_style_iterator style_begin () const;

			virtual       style_iterator style_end ();

			virtual const_style_iterator style_end () const;

			virtual void             set_shape (Shape* shape);

			virtual       Shape*         shape (bool create = true);

			virtual const Shape*         shape () const;

			virtual void             add_shape (Shape* shape);

			virtual void          remove_shape (Shape* shape);

			virtual void           clear_shapes ();

			virtual ShapeList       find_shapes (const Selector& selector) const;

			virtual       shape_iterator shape_begin ();

			virtual const_shape_iterator shape_begin () const;

			virtual       shape_iterator shape_end ();

			virtual const_shape_iterator shape_end () const;

			virtual void      set_filter (Filter* filter);

			virtual       Filter* filter ();

			virtual const Filter* filter () const;

			virtual void set_name (const char* name);

			virtual void    add_tag (const char* tag);

			virtual void remove_tag (const char* tag);

			virtual void  clear_tags ();

			virtual void set_selector (const Selector& selector);

			virtual void      set_frame (coord x, coord y, coord width, coord height);

			virtual void      set_frame (const Bounds& bounds);

			virtual const Bounds& frame () const;

			virtual Bounds      content_bounds () const;

			virtual void fit_to_content ();

			virtual void set_zoom (float zoom);

			virtual float    zoom () const;

			virtual void set_angle (float degree);

			virtual float    angle () const;

			virtual void     set_pivot (float x, float y, float z = 0);

			virtual void     set_pivot (const Point& pivot);

			virtual const Point& pivot () const;

			virtual void         scroll_to (coord x, coord y, coord z = 0);

			virtual void         scroll_to (const Point& scroll);

			virtual void         scroll_by (coord x, coord y, coord z = 0);

			virtual void         scroll_by (const Point& dscroll);

			virtual const Point& scroll () const;

			virtual void set_capture (uint types);

			virtual uint     capture () const;

			virtual void    add_flag (uint flags);

			virtual void remove_flag (uint flags);

			virtual bool    has_flag (uint flags) const;

			virtual       View* parent ();

			virtual const View* parent () const;

			virtual       Window* window ();

			virtual const Window* window () const;

			//
			// for physics body
			//
			virtual void apply_force (coord x, coord y);

			virtual void apply_force (const Point& force);

			virtual void apply_torque (float torque);

			virtual void apply_linear_impulse (coord x, coord y);

			virtual void apply_linear_impulse (const Point& impulse);

			virtual void apply_angular_impulse (float impulse);

			virtual void set_static (bool state = true);

			virtual bool  is_static () const;

			virtual void set_dynamic (bool state = true);

			virtual bool  is_dynamic () const;

			virtual void set_density (float density);

			virtual float    density () const;

			virtual void set_friction (float friction);

			virtual float    friction () const;

			virtual void set_restitution (float restitution);

			virtual float    restitution () const;

			virtual void set_sensor (bool state);

			virtual bool  is_sensor () const;

			virtual void set_linear_velocity (coord x, coord y);

			virtual void set_linear_velocity (const Point& velocity);

			virtual Point    linear_velocity () const;

			virtual void set_angular_velocity (float velocity);

			virtual float    angular_velocity () const;

			virtual void set_gravity_scale (float scale);

			virtual float    gravity_scale () const;

			//
			// for physics child world
			//
			virtual void create_world (float pixels_per_meter);

			virtual void update_world (float duration = 0);

			virtual float meter2pixel (float meter = 1, bool create_world = true);

			virtual float meter2pixel (float meter = 1) const;

			virtual void set_gravity (coord x, coord y);

			virtual void set_gravity (const Point& vector);

			virtual Point    gravity () const;

			virtual void set_time_scale (float scale);

			virtual float    time_scale () const;

			virtual       View* wall ();

			virtual const View* wall () const;

			virtual void set_debug (bool debug = true);

			virtual bool     debug () const;

			//
			// event handlers
			//
			virtual void on_attach (Event* e);

			virtual void on_detach (Event* e);

			virtual void on_show (Event* e);

			virtual void on_hide (Event* e);

			virtual void on_update (UpdateEvent* e);

			virtual void on_draw   (DrawEvent* e);

			virtual void on_move   (FrameEvent* e);

			virtual void on_resize (FrameEvent* e);

			virtual void on_zoom   (FrameEvent* e);

			virtual void on_rotate (FrameEvent* e);

			virtual void on_scroll (ScrollEvent* e);

			virtual void on_focus (FocusEvent* e);

			virtual void on_key      (KeyEvent* e);

			virtual void on_key_down (KeyEvent* e);

			virtual void on_key_up   (KeyEvent* e);

			virtual void on_pointer        (PointerEvent* e);

			virtual void on_pointer_down   (PointerEvent* e);

			virtual void on_pointer_up     (PointerEvent* e);

			virtual void on_pointer_move   (PointerEvent* e);

			virtual void on_pointer_cancel (PointerEvent* e);

			virtual void on_wheel (WheelEvent* e);

			virtual void on_note     (NoteEvent* e);

			virtual void on_note_on  (NoteEvent* e);

			virtual void on_note_off (NoteEvent* e);

			virtual void on_capture (CaptureEvent* e);

			virtual void on_timer (TimerEvent* e);

			virtual bool will_contact (View* v);

			virtual void   on_contact       (ContactEvent* e);

			virtual void   on_contact_begin (ContactEvent* e);

			virtual void   on_contact_end   (ContactEvent* e);

			virtual operator bool () const;

			virtual bool operator ! () const;

			struct Data;

			Xot::PImpl<Data> self;

			#ifdef REFLEX_VIEW_REF_DEBUG
				void retain (intptr_t data) const override
				{
					RefCountable::retain(data);
					String spaces = "";
					for (int i = 0; i < refc_count(); ++i) spaces += " ";
					printf("(%d)%s-> %s\n", refc_count(), spaces.c_str(), name());
				}

				void release (intptr_t data) const override
				{
					RefCountable::release(data);
					String spaces = "";
					for (int i = 0; i < refc_count(); ++i) spaces += " ";
					printf("(%d)%s<- %s\n", refc_count(), spaces.c_str(), name());
				}
			#endif// REFLEX_VIEW_REF_DEBUG

		protected:

			virtual ~View ();

			virtual SelectorPtr* get_selector_ptr ();

	};// View


}// Reflex


#endif//EOH
