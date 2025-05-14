#include "window.h"


#include <assert.h>
#include <algorithm>
#include <set>
#include "reflex/exception.h"
#include "view.h"
#include "event.h"


namespace Reflex
{


	using ViewList              = std::vector<View::Ref>;

	using PointerMap            = std::map<Pointer::ID, Pointer>;

	using ExtractedPointerIDSet = std::set<Pointer::ID>;

	using CaptureTargetIDList   = Window::Data::CaptureTargetIDList;


	void
	Window_register (Window* win)
	{
		auto& all = Window_all();

		auto it = std::find(all.begin(), all.end(), win);
		if (it != all.end())
			invalid_state_error(__FILE__, __LINE__);

		all.push_back(win);
	}

	void
	Window_unregister (Window* win)
	{
		auto& all = Window_all();

		auto it = std::find(all.begin(), all.end(), win);
		if (it == all.end()) return;

		all.erase(it);
	}

	Application::WindowList&
	Window_all ()
	{
		static Application::WindowList windows;
		return windows;
	}

	Window*
	Window_get_active ()
	{
		for (auto& w : Window_all())
		{
			if (Xot::has_flag(w->self->flags, Window::Data::ACTIVE))
				return w;
		}
		return NULL;
	}


	Window::Data::Data ()
	:	flags(Window_default_flags())
	{
		prev_time_update = prev_time_draw = Xot::time();
	}

	Window::Data::~Data ()
	{
	}


	void
	Window_set_focus (Window* window, View* view)
	{
		if (!window)
			argument_error(__FILE__, __LINE__);
		if (!view)
			argument_error(__FILE__, __LINE__);

		View* current = window->self->focus.get();
		if (current == view) return;

		window->self->focus.reset(view);

		if (current)
		{
			FocusEvent e(FocusEvent::BLUR, view, current);
			current->on_focus(&e);
			current->redraw();
		}

		if (view)
		{
			FocusEvent e(FocusEvent::FOCUS, view, current);
			view->on_focus(&e);
			view->redraw();
		}
	}

	static Window_CreateRootViewFun create_root_view_fun = NULL;

	void
	Window_set_create_root_view_fun (Window_CreateRootViewFun fun)
	{
		create_root_view_fun = fun;
	}

	static View*
	create_root_view ()
	{
		return create_root_view_fun ? create_root_view_fun() : new View();
	}

	void
	Window_register_capture (Window* window, View* view, Pointer::ID target)
	{
		if (!view)
			argument_error(__FILE__, __LINE__);

		if (view->window() != window)
			invalid_state_error(__FILE__, __LINE__);

		if (target < 0) return;

		auto& targets = window->self->captures[view];
		if (std::find(targets.begin(), targets.end(), target) != targets.end())
			return;

		targets.insert(
			target == CAPTURE_ALL_EVENTS ? targets.begin() : targets.end(),
			target);
	}

	void
	Window_unregister_capture (Window* window, View* view, Pointer::ID target)
	{
		if (!view)
			argument_error(__FILE__, __LINE__);

		auto captures_it = window->self->captures.find(view);
		if (captures_it == window->self->captures.end()) return;

		auto& targets   = captures_it->second;
		auto targets_it = std::find(targets.begin(), targets.end(), target);
		if (targets_it == targets.end()) return;

		targets.erase(targets_it);
	}

	static void
	cleanup_captures (Window* window)
	{
		assert(window);

		auto& caps = window->self->captures;
		for (auto it = caps.begin(), end = caps.end(); it != end;)
		{
			auto t = it++;
			if (t->second.empty()) caps.erase(t);
		}
	}

	void
	Window_call_activate_event (Window* window)
	{
		if (!window) return;

		Xot::add_flag(&window->self->flags, Window::Data::ACTIVE);

		Event e;
		window->on_activate(&e);
	}

	void
	Window_call_deactivate_event (Window* window)
	{
		if (!window) return;

		Event e;
		window->on_deactivate(&e);

		Xot::remove_flag(&window->self->flags, Window::Data::ACTIVE);
	}

	void
	Window_call_update_event (Window* window)
	{
		Window::Data* self = window->self.get();

		double now = Xot::time();
		UpdateEvent e(now, now - self->prev_time_update);
		self->prev_time_update = now;

		window->on_update(&e);
		if (e.is_blocked()) return;

		View_update_tree(window->root(), e);
	}

	void
	Window_call_draw_event (Window* window, DrawEvent* event)
	{
		if (!window)
			argument_error(__FILE__, __LINE__);
		if (!event)
			argument_error(__FILE__, __LINE__);

		Painter* painter = window->painter();
		if (!painter)
			Xot::invalid_state_error(__FILE__, __LINE__);

		Rays::Bounds frame = window->frame();

		DrawEvent_set_painter(event, painter);
		DrawEvent_set_bounds(event, Bounds(0, 0, frame.width, frame.height));

		painter->begin();
		painter->push_state();
		painter->clear();

		window->on_draw(event);
		if (!event->is_blocked())
			View_draw_tree(window->root(), event, 0, frame.move_to(0));

		painter->pop_state();
		painter->end();
	}

	static bool
	is_capturing (
		const View* view, const CaptureTargetIDList& targets, View::Capture type)
	{
		return
			!targets.empty() &&
			targets[0] == CAPTURE_ALL_EVENTS &&
			(view->capture() & type) == type;
	}

	void
	Window_call_key_event (Window* window, KeyEvent* event)
	{
		assert(window);

		if (!event)
			argument_error(__FILE__, __LINE__);

		for (auto& [view, targets] : window->self->captures)
		{
			if (
				!view->window() ||
				!is_capturing(view.get(), targets, View::CAPTURE_KEY))
			{
				continue;
			}

			KeyEvent e = event->dup();
			KeyEvent_set_captured(&e, true);
			View_call_key_event(const_cast<View*>(view.get()), &e);
		}

		if (!event->is_blocked())
			window->on_key(event);

		if (!event->is_blocked())
		{
			switch (event->action())
			{
				case KeyEvent::DOWN: window->on_key_down(event); break;
				case KeyEvent::UP:   window->on_key_up(event);   break;
				default: break;
			}
		}

		if (!event->is_blocked() && window->self->focus)
			View_call_key_event(window->self->focus.get(), event);

		cleanup_captures(window);
	}

	static Pointer::ID
	get_next_pointer_id (Window* window)
	{
		return window->self->next_pointer_id++;
	}

	static void
	setup_mouse_pointer (Window* window, Pointer* pointer)
	{
		static const uint MOUSE_BUTTONS =
			Pointer::MOUSE_LEFT  |
			Pointer::MOUSE_RIGHT |
			Pointer::MOUSE_MIDDLE;

		Window::Data* self = window->self.get();

		auto action        = pointer->action();
		auto& prev_pointer = self->prev_mouse_pointer;

		auto id    = prev_pointer ? prev_pointer.id() : get_next_pointer_id(window);
		auto* down = prev_pointer.down();
		if (
			Pointer_mask_flag(prev_pointer, MOUSE_BUTTONS) == 0 &&
			(action == Pointer::DOWN || prev_pointer.action() == Pointer::UP))
		{
			id   = get_next_pointer_id(window);
			down = NULL;
		}

		Pointer_set_id(pointer, id);
		Pointer_add_flag(pointer, Pointer_mask_flag(prev_pointer, MOUSE_BUTTONS));
		Pointer_set_prev(pointer, &prev_pointer);
		Pointer_set_down(pointer, down);

		if (action == Pointer::DOWN)
			Pointer_add_flag(pointer, pointer->types() & MOUSE_BUTTONS);

		prev_pointer = *pointer;
		Pointer_set_prev(&prev_pointer, NULL);

		if (action == Pointer::UP || action == Pointer::CANCEL)
			Pointer_remove_flag(&prev_pointer, prev_pointer.types() & MOUSE_BUTTONS);
	}

	static PointerList::const_iterator
	find_prev_pointer (const Pointer& pointer, const PointerList& prev_pointers)
	{
		const auto* sys_id   = Pointer_get_system_id(pointer);
		const auto* prev_pos = Pointer_get_prev_position(pointer);

		return std::find_if(
			prev_pointers.begin(), prev_pointers.end(),
			[&](const Pointer& p)
			{
				if (sys_id)
				{
					const auto* id = Pointer_get_system_id(p);
					if (id && *id == *sys_id) return true;
				}
				return prev_pos && *prev_pos == p.position();
			});
	}

	static void
	setup_pointer (Window* window, Pointer* pointer)
	{
		Window::Data* self = window->self.get();

		PointerList& prev_pointers  = self->prev_pointers;
		auto it                     = find_prev_pointer(*pointer, prev_pointers);
		const Pointer* prev_pointer = it != prev_pointers.end() && *it ? &*it : NULL;

		if (prev_pointer)
		{
			Pointer_set_id(pointer, prev_pointer->id());
			Pointer_set_prev(pointer, prev_pointer);
			Pointer_set_down(pointer, prev_pointer->down());
			prev_pointers.erase(it);
		}
		else
			Pointer_set_id(pointer, get_next_pointer_id(window));

		auto action = pointer->action();
		if (action != Pointer::UP && action != Pointer::CANCEL)
		{
			prev_pointers.emplace_back(*pointer);
			Pointer_set_prev(&prev_pointers.back(), NULL);
		}
	}

	static void
	setup_pointer_event (Window* window, PointerEvent* event)
	{
		for (size_t i = 0; i < event->size(); ++i)
		{
			Pointer& pointer = PointerEvent_pointer_at(event, i);
			if (pointer.types() & Pointer::MOUSE)
				setup_mouse_pointer(window, &pointer);
			else
				setup_pointer(window, &pointer);
		}
	}

	static void
	get_views_capturing_all_pointers (Window* window, ViewList* result)
	{
		assert(window && result);

		result->clear();
		for (const auto& [view, targets] : window->self->captures)
		{
			if (is_capturing(view.get(), targets, View::CAPTURE_POINTER))
				result->emplace_back(view);
		}
	}

	static void
	capture_all_pointers (
		Window* window, const PointerEvent& event, ViewList& views_capturing_all)
	{
		assert(window);

		if (views_capturing_all.empty()) return;

		PointerEvent_each_pointer(&event, [&](const auto& pointer)
		{
			if (pointer.action() == Pointer::DOWN)
			{
				for (auto& view : views_capturing_all)
					Window_register_capture(window, view, pointer.id());
			}
		});
	}

	static void
	extract_pointer (
		PointerEvent* event, ExtractedPointerIDSet* extracteds,
		const Pointer& pointer)
	{
		PointerEvent_add_pointer(event, pointer);
		extracteds->insert(pointer.id());
	}

	static void
	extract_targeted_pointers (
		PointerEvent* event, ExtractedPointerIDSet* extracteds,
		const CaptureTargetIDList& targets, const PointerMap& pointers)
	{
		assert(event->empty());

		for (auto pointer_id : targets)
		{
			auto it = pointers.find(pointer_id);
			if (it != pointers.end())
				extract_pointer(event, extracteds, it->second);
		}
	}

	static void
	capture_targeted_pointers_and_call_events (
		ExtractedPointerIDSet* extracteds, bool* blocked,
		Window* window, const PointerMap& pointers)
	{
		for (auto& [view, targets] : window->self->captures)
		{
			if (!view->window() || targets.empty()) continue;

			PointerEvent event;
			PointerEvent_set_captured(&event, true);
			extract_targeted_pointers(&event, extracteds, targets, pointers);
			if (event.empty()) continue;

			PointerEvent_update_for_capturing_view(&event, view);
			View_call_pointer_event(const_cast<View*>(view.get()), &event);

			if (event.is_blocked()) *blocked = true;
		}
	}

	static void
	extract_hovering_pointers (
		PointerEvent* event, ExtractedPointerIDSet* extracteds,
		const PointerMap& pointers)
	{
		assert(event && event->empty() && extracteds);

		for (const auto& [_, pointer] : pointers)
		{
			// dragging pointers is captured as a targeted
			if (pointer.is_drag()) continue;

			extract_pointer(event, extracteds, pointer);
		}
	}

	static void
	capture_hovering_pointers_and_call_events (
		ExtractedPointerIDSet* extracteds, bool* blocked,
		const ViewList& views_capturing_all, const PointerMap& pointers)
	{
		assert(extracteds);

		if (views_capturing_all.empty()) return;

		PointerEvent event;
		PointerEvent_set_captured(&event, true);
		extract_hovering_pointers(&event, extracteds, pointers);
		if (event.empty()) return;

		for (auto& view : views_capturing_all)
		{
			if (!view->window()) continue;

			PointerEvent e = event.dup();
			PointerEvent_update_for_capturing_view(&e, view);
			View_call_pointer_event(const_cast<View*>(view.get()), &e);

			if (e.is_blocked()) *blocked = true;
		}
	}

	static void
	erase_extracted_pointers (
		PointerMap* pointers, const ExtractedPointerIDSet& extracteds)
	{
		assert(pointers);

		for (auto id : extracteds)
		{
			auto it = pointers->find(id);
			if (it != pointers->end()) pointers->erase(it);
		}
	}

	static void
	erase_extracted_pointers (
		PointerEvent* event, const ExtractedPointerIDSet& extracteds)
	{
		assert(event);

		for (auto id : extracteds)
			PointerEvent_erase_pointer(event, id);
	}

	static void
	call_captured_pointer_events (Window* window, PointerEvent* event)
	{
		assert(window && event);

		ViewList views_capturing_all;
		get_views_capturing_all_pointers(window, &views_capturing_all);
		capture_all_pointers(window, *event, views_capturing_all);

		PointerMap pointers;
		PointerEvent_each_pointer(event, [&](const auto& pointer)
		{
			if (pointer.id() >= 0) pointers[pointer.id()] = pointer;
		});

		ExtractedPointerIDSet extracteds;
		bool blocked = false;

		capture_targeted_pointers_and_call_events(
			&extracteds, &blocked, window, pointers);
		erase_extracted_pointers(&pointers, extracteds);

		capture_hovering_pointers_and_call_events(
			&extracteds, &blocked, views_capturing_all, pointers);
		erase_extracted_pointers(event, extracteds);

		if (blocked) event->block();
	}

	void
	Window_call_pointer_event (Window* window, PointerEvent* event)
	{
		assert(window);

		if (!event)
			argument_error(__FILE__, __LINE__);

		setup_pointer_event(window, event);

		call_captured_pointer_events(window, event);

		if (!event->is_blocked() && !event->empty())
			window->on_pointer(event);

		if (!event->is_blocked() && !event->empty())
		{
			switch ((*event)[0].action())
			{
				case Pointer::DOWN:   window->on_pointer_down(event);   break;
				case Pointer::UP:     window->on_pointer_up(event);     break;
				case Pointer::MOVE:   window->on_pointer_move(event);   break;
				case Pointer::CANCEL: window->on_pointer_cancel(event); break;
				default: break;
			}
		}

		if (!event->is_blocked() && !event->empty())
		{
			PointerEvent_update_for_child_view(event, window->root());
			View_call_pointer_event(window->root(), event);
		}

		cleanup_captures(window);
	}

	void
	Window_call_wheel_event (Window* window, WheelEvent* event)
	{
		assert(window);

		if (!event)
			argument_error(__FILE__, __LINE__);

		window->on_wheel(event);

		View_call_wheel_event(window->root(), event);
	}

	static void
	Window_call_note_event (Window* window, NoteEvent* event)
	{
		assert(window);

		if (!event)
			argument_error(__FILE__, __LINE__);

		for (auto& [view, targets] : window->self->captures)
		{
			if (
				!view->window() ||
				!is_capturing(view.get(), targets, View::CAPTURE_MIDI))
			{
				continue;
			}

			NoteEvent e = event->dup();
			NoteEvent_set_captured(&e, true);
			View_call_note_event(const_cast<View*>(view.get()), &e);
		}

		if (!event->is_blocked())
			window->on_note(event);

		if (!event->is_blocked())
		{
			switch (event->action())
			{
				case NoteEvent::ON:  window->on_note_on(event);  break;
				case NoteEvent::OFF: window->on_note_off(event); break;
				default: break;
			}
		}

		if (!event->is_blocked() && window->self->focus)
			View_call_note_event(window->self->focus.get(), event);
	}

	static void
	Window_call_control_change_event (Window* window, ControlChangeEvent* event)
	{
		assert(window);

		if (!event)
			argument_error(__FILE__, __LINE__);

		for (auto& [view, targets] : window->self->captures)
		{
			if (
				!view->window() ||
				!is_capturing(view.get(), targets, View::CAPTURE_MIDI))
			{
				continue;
			}

			ControlChangeEvent e = event->dup();
			ControlChangeEvent_set_captured(&e, true);
			View_call_control_change_event(const_cast<View*>(view.get()), &e);
		}

		if (!event->is_blocked())
			window->on_control_change(event);

		if (!event->is_blocked() && window->self->focus)
			View_call_control_change_event(window->self->focus.get(), event);
	}

	void
	Window_call_midi_event (Window* window, MIDIEvent* event)
	{
		if (!window) return;

		if (!event)
			argument_error(__FILE__, __LINE__);

		for (auto& [view, targets] : window->self->captures)
		{
			if (
				!view->window() ||
				!is_capturing(view.get(), targets, View::CAPTURE_MIDI))
			{
				continue;
			}

			MIDIEvent e = event->dup();
			MIDIEvent_set_captured(&e, true);
			View_call_midi_event(const_cast<View*>(view.get()), &e);
		}

		if (!event->is_blocked())
			window->on_midi(event);

		if (!event->is_blocked() && window->self->focus)
			View_call_midi_event(window->self->focus.get(), event);

		if (!event->is_blocked())
		{
			NoteEvent note_e;
			if (MIDIEvent_to_note_event(&note_e, *event))
				Window_call_note_event(window, &note_e);

			ControlChangeEvent cc_e;
			if (MIDIEvent_to_control_change_event(&cc_e, *event))
				Window_call_control_change_event(window, &cc_e);
		}

		cleanup_captures(window);
	}


	Window::Window ()
	:	self(Window_create_data())
	{
		Window_initialize(this);

		self->root.reset(create_root_view());
		self->root->set_name(VIEW_TAG_ROOT);
		View_set_window(self->root.get(), this);

		self->painter.canvas(0, 0, 1, 1, Window_get_pixel_density(*this));
	}

	Window::~Window ()
	{
		//close(true);
	}

	void
	Window::show ()
	{
		int new_count = self->hide_count - 1;
		if (new_count == 0)
		{
			Event e;
			on_show(&e);
			if (e.is_blocked()) return;

			Window_show(this);
		}

		self->hide_count = new_count;
	}

	void
	Window::hide ()
	{
		int new_count = self->hide_count + 1;
		if (new_count == 1)
		{
			Event e;
			on_hide(&e);
			if (e.is_blocked()) return;

			Window_hide(this);
		}

		self->hide_count = new_count;
	}

	bool
	Window::hidden () const
	{
		return self->hide_count > 0;
	}

	void
	Window::close (bool force)
	{
		Event e;
		on_close(&e);
		if (!force && e.is_blocked()) return;

		View_set_window(self->root.get(), NULL);
		self->root.reset();

		Window_close(this);
	}

	void
	Window::redraw ()
	{
		self->redraw = true;
	}

	Point
	Window::from_screen (const Point& point) const
	{
		return point - frame().position();
	}

	Point
	Window::to_screen (const Point& point) const
	{
		return point + frame().position();
	}

	void
	Window::set_title (const char* title)
	{
		Window_set_title(this, title);
	}

	const char*
	Window::title () const
	{
		return Window_get_title(*this);
	}

	void
	Window::set_frame (coord x, coord y, coord width, coord height)
	{
		Window_set_frame(this, x, y, width, height);
	}

	void
	Window::set_frame (const Bounds& bounds)
	{
		set_frame(bounds.x, bounds.y, bounds.width, bounds.height);
	}

	Bounds
	Window::frame () const
	{
		return Window_get_frame(*this);
	}

	void
	Window::set_flag (uint flags)
	{
		Window_set_flags(this, flags);

		self->flags = flags;
	}

	uint
	Window::flags () const
	{
		return self->flags;
	}

	void
	Window::add_flag (uint flags)
	{
		uint value = self->flags;
		Xot::add_flag(&value, flags);

		Window_set_flags(this, value);

		self->flags = value;
	}

	void
	Window::remove_flag (uint flags)
	{
		uint value = self->flags;
		Xot::remove_flag(&value, flags);

		Window_set_flags(this, value);

		self->flags = value;
	}

	bool
	Window::has_flag (uint flags) const
	{
		return Xot::has_flag(self->flags, flags);
	}

	Screen
	Window::screen () const
	{
		return Window_get_screen(*this);
	}

	View*
	Window::root ()
	{
		return self->root.get();
	}

	const View*
	Window::root () const
	{
		return const_cast<Window*>(this)->root();
	}

	View*
	Window::focus ()
	{
		return self->focus.get();
	}

	const View*
	Window::focus () const
	{
		return const_cast<Window*>(this)->focus();
	}

	Painter*
	Window::painter ()
	{
		return &self->painter;
	}

	const Painter*
	Window::painter () const
	{
		return const_cast<Window*>(this)->painter();
	}

	void
	Window::on_activate (Event* e)
	{
	}

	void
	Window::on_deactivate (Event* e)
	{
	}

	void
	Window::on_show (Event* e)
	{
	}

	void
	Window::on_hide (Event* e)
	{
	}

	void
	Window::on_close (Event* e)
	{
	}

	void
	Window::on_update (UpdateEvent* e)
	{
	}

	void
	Window::on_draw (DrawEvent* e)
	{
	}

	void
	Window::on_move (FrameEvent* e)
	{
	}

	void
	Window::on_resize (FrameEvent* e)
	{
	}

	void
	Window::on_key (KeyEvent* e)
	{
	}

	void
	Window::on_key_down (KeyEvent* e)
	{
	}

	void
	Window::on_key_up (KeyEvent* e)
	{
	}

	void
	Window::on_pointer (PointerEvent* e)
	{
	}

	void
	Window::on_pointer_down (PointerEvent* e)
	{
	}

	void
	Window::on_pointer_up (PointerEvent* e)
	{
	}

	void
	Window::on_pointer_move (PointerEvent* e)
	{
	}

	void
	Window::on_pointer_cancel (PointerEvent* e)
	{
	}

	void
	Window::on_wheel (WheelEvent* e)
	{
	}

	void
	Window::on_midi (MIDIEvent* e)
	{
	}

	void
	Window::on_note (NoteEvent* e)
	{
	}

	void
	Window::on_note_on (NoteEvent* e)
	{
	}

	void
	Window::on_note_off (NoteEvent* e)
	{
	}

	void
	Window::on_control_change (ControlChangeEvent* e)
	{
	}

	Window::operator bool () const
	{
		return self && *self;
	}

	bool
	Window::operator ! () const
	{
		return !operator bool();
	}


}// Reflex
