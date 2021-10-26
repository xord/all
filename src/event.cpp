#include "event.h"


#include "reflex/timer.h"
#include "reflex/shape.h"
#include "reflex/exception.h"
#include "view.h"
#include "pointer.h"


namespace Reflex
{


	struct Event::Data
	{

		bool blocked;

		double time;

		Data (bool blocked = false, double time = Xot::time())
		:	blocked(blocked), time(time)
		{
		}

	};// Event::Data


	Event::Event ()
	{
	}

	Event::Event (const Event* src)
	:	self(new Data(*src->self))
	{
	}

	Event::~Event ()
	{
	}

	void
	Event::block ()
	{
		self->blocked = true;
	}

	bool
	Event::is_blocked () const
	{
		return self->blocked;
	}

	double
	Event::time () const
	{
		return self->time;
	}


	struct UpdateEvent::Data
	{

		double now;

		float dt;

		Data (double now, float dt)
		:	now(now), dt(dt)
		{
		}

	};// UpdateEvent::Data


	UpdateEvent::UpdateEvent (double now, float dt)
	:	self(new Data(now, dt))
	{
	}

	UpdateEvent::UpdateEvent (const UpdateEvent* src)
	:	Event(src), self(new Data(*src->self))
	{
	}

	UpdateEvent::~UpdateEvent ()
	{
	}

	UpdateEvent
	UpdateEvent::dup () const
	{
		return UpdateEvent(this);
	}

	double
	UpdateEvent::now () const
	{
		return self->now;
	}

	float
	UpdateEvent::dt () const
	{
		return self->dt;
	}


	struct DrawEvent::Data
	{

		View* view;

		Painter* painter;

		Bounds bounds;

		float dt, fps;

		Data (float dt, float fps)
		:	view(NULL), painter(NULL), dt(dt), fps(fps)
		{
		}

	};// DrawEvent::Data


	void
	DrawEvent_set_view (DrawEvent* pthis, View* view)
	{
		pthis->self->view = view;
	}

	void
	DrawEvent_set_painter (DrawEvent* pthis, Painter* painter)
	{
		pthis->self->painter = painter;
	}

	void
	DrawEvent_set_bounds (DrawEvent* pthis, const Bounds& bounds)
	{
		pthis->self->bounds = bounds;
	}


	DrawEvent::DrawEvent (float dt, float fps)
	:	self(new Data(dt, fps))
	{
	}

	DrawEvent::DrawEvent (const DrawEvent* src)
	:	Event(src), self(new Data(*src->self))
	{
	}

	DrawEvent
	DrawEvent::dup () const
	{
		return DrawEvent(this);
	}

	Painter*
	DrawEvent::painter ()
	{
		return self->painter;
	}

	const Painter*
	DrawEvent::painter () const
	{
		return const_cast<DrawEvent*>(this)->painter();
	}

	const Bounds&
	DrawEvent::bounds () const
	{
		return self->bounds;
	}

	float
	DrawEvent::dt () const
	{
		return self->dt;
	}

	float
	DrawEvent::fps () const
	{
		return self->fps;
	}


	struct FrameEvent::Data
	{

		Bounds frame;

		coord dx, dy, dw, dh;

		float angle, dangle;

		Data (
			const Bounds& frame, coord dx, coord dy, coord dw, coord dh,
			float angle, float dangle)
		:	frame(frame), dx(dx), dy(dy), dw(dw), dh(dh), angle(angle), dangle(dangle)
		{
		}

	};// FrameEvent::Data


	FrameEvent::FrameEvent (
		const Bounds& frame, coord dx, coord dy, coord dwidth, coord dheight,
		float angle, float dangle)
	:	self(new Data(frame, dx, dy, dwidth, dheight, angle, dangle))
	{
	}

	FrameEvent::FrameEvent (
		const Bounds& frame, const Bounds& prev_frame,
		float angle, float prev_angle)
	:	self(new Data(
			frame,
			frame.x - prev_frame.x, frame.y - prev_frame.y,
			frame.w - prev_frame.w, frame.h - prev_frame.h,
			angle, angle - prev_angle))
	{
	}

	FrameEvent::FrameEvent (const FrameEvent* src)
	:	Event(src), self(new Data(*src->self))
	{
	}

	FrameEvent
	FrameEvent::dup () const
	{
		return FrameEvent(this);
	}

	const Bounds&
	FrameEvent::frame () const
	{
		return self->frame;
	}

	coord
	FrameEvent::dx () const
	{
		return self->dx;
	}

	coord
	FrameEvent::dy () const
	{
		return self->dy;
	}

	coord
	FrameEvent::dwidth () const
	{
		return self->dw;
	}

	coord
	FrameEvent::dheight () const
	{
		return self->dh;
	}

	float
	FrameEvent::angle () const
	{
		return self->angle;
	}

	float
	FrameEvent::dangle () const
	{
		return self->dangle;
	}

	bool
	FrameEvent::is_move () const
	{
		return self->dx != 0 || self->dy != 0;
	}

	bool
	FrameEvent::is_resize () const
	{
		return self->dw != 0 || self->dh != 0;
	}

	bool
	FrameEvent::is_rotate () const
	{
		return self->dangle != 0;
	}


	struct ScrollEvent::Data
	{

		Point scroll, dscroll;

		Data (const Point& scroll, const Point& dscroll)
		:	scroll(scroll), dscroll(dscroll)
		{
		}

	};// ScrollEvent::Data


	ScrollEvent::ScrollEvent ()
	:	self(new Data(0, 0))
	{
	}

	ScrollEvent::ScrollEvent (coord x, coord y, coord z, coord dx, coord dy, coord dz)
	:	self(new Data(Point(x, y, z), Point(dx, dy, dz)))
	{
	}

	ScrollEvent::ScrollEvent (const ScrollEvent* src)
	:	Event(src), self(new Data(*src->self))
	{
	}

	ScrollEvent
	ScrollEvent::dup () const
	{
		return ScrollEvent(this);
	}

	Point&
	ScrollEvent::scroll ()
	{
		return self->scroll;
	}

	const Point&
	ScrollEvent::scroll () const
	{
		return const_cast<ScrollEvent*>(this)->scroll();
	}

	Point&
	ScrollEvent::dscroll ()
	{
		return self->dscroll;
	}

	const Point&
	ScrollEvent::dscroll () const
	{
		return const_cast<ScrollEvent*>(this)->dscroll();
	}


	struct FocusEvent::Data
	{

		Action action;

		View *current, *last;

		Data (Action action = ACTION_NONE, View* current = NULL, View* last = NULL)
		:	action(action), current(current), last(last)
		{
		}

	};// FocusEvent::Data


	FocusEvent::FocusEvent ()
	{
	}

	FocusEvent::FocusEvent (Action action, View* current, View* last)
	:	self(new Data(action, current, last))
	{
	}

	FocusEvent::FocusEvent (const FocusEvent* src)
	:	Event(src), self(new Data(*src->self))
	{
	}

	FocusEvent
	FocusEvent::dup () const
	{
		return FocusEvent(this);
	}

	FocusEvent::Action
	FocusEvent::action () const
	{
		return self->action;
	}

	View*
	FocusEvent::current () const
	{
		return self->current;
	}

	View*
	FocusEvent::last () const
	{
		return self->last;
	}


	struct KeyEvent::Data
	{

		Action action;

		String chars;

		int code;

		uint modifiers;

		int repeat;

		bool captured;

		Data (
			Action action = ACTION_NONE, const char* chars = NULL, int code = KEY_NONE,
			uint modifiers = MOD_NONE, int repeat = 0, bool captured = false)
		:	action(action), chars(chars ? chars : ""), code(code),
			modifiers(modifiers), repeat(repeat), captured(captured)
		{
		}

	};// KeyEvent::Data


	void
	KeyEvent_set_captured (KeyEvent* pthis, bool captured)
	{
		if (!pthis)
			argument_error(__FILE__, __LINE__);

		pthis->self->captured = captured;
	}


	KeyEvent::KeyEvent ()
	{
	}

	KeyEvent::KeyEvent (
		Action action, const char* chars, int code, uint modifiers, int repeat)
	:	self(new Data(action, chars, code, modifiers, repeat))
	{
	}

	KeyEvent::KeyEvent (const KeyEvent* src)
	:	Event(src), self(new Data(*src->self))
	{
	}

	KeyEvent
	KeyEvent::dup () const
	{
		return KeyEvent(this);
	}

	KeyEvent::Action
	KeyEvent::action () const
	{
		return self->action;
	}

	const char*
	KeyEvent::chars () const
	{
		return self->chars;
	}

	int
	KeyEvent::code () const
	{
		return self->code;
	}

	uint
	KeyEvent::modifiers () const
	{
		return self->modifiers;
	}

	int
	KeyEvent::repeat () const
	{
		return self->repeat;
	}

	bool
	KeyEvent::is_captured () const
	{
		return self->captured;
	}


	struct PointerEvent::Data
	{

		std::vector<Pointer> pointers;

		bool captured;

		Data (bool captured = false)
		:	captured(captured)
		{
		}

	};// PointerEvent::Data


	void
	PointerEvent_add_pointer (PointerEvent* pthis, const Pointer& pointer)
	{
		if (!pthis)
			argument_error(__FILE__, __LINE__);

		pthis->self->pointers.emplace_back(pointer);
	}

	void
	PointerEvent_erase_pointer (PointerEvent* pthis, Pointer::ID id)
	{
		if (!pthis)
			argument_error(__FILE__, __LINE__);

		auto& pointers = pthis->self->pointers;
		auto it = std::find_if(
			pointers.begin(), pointers.end(),
			[=](const auto& pointer)
			{
				return pointer.id() == id;
			});

		if (it == pointers.end()) return;

		pointers.erase(it);
	}

	Pointer&
	PointerEvent_pointer_at (PointerEvent* pthis, size_t index)
	{
		if (!pthis)
			argument_error(__FILE__, __LINE__);

		auto& pointers = pthis->self->pointers;
		if (index >= pointers.size())
			index_error(__FILE__, __LINE__);

		return pointers[index];
	}

	void
	PointerEvent_each_pointer (
		const PointerEvent* pthis, std::function<void(const Pointer&)> fun)
	{
		if (!pthis)
			argument_error(__FILE__, __LINE__);

		for (const auto& pointer : pthis->self->pointers)
			fun(pointer);
	}

	void
	PointerEvent_set_captured (PointerEvent* pthis, bool captured)
	{
		if (!pthis)
			argument_error(__FILE__, __LINE__);

		pthis->self->captured = captured;
	}

	static void
	filter_and_offset_pointer_positions (PointerEvent* event, const Bounds& frame)
	{
		assert(event);

		const Point& offset = frame.position();

		std::vector<Pointer> pointers;
		for (const auto& pointer : event->self->pointers)
		{
			if (!frame.is_include(pointer.position()))
				continue;

			pointers.emplace_back(pointer);
			Pointer_update_positions(&pointers.back(), [&](Point* pos)
			{
				*pos -= offset;
			});
		}

		event->self->pointers = pointers;
	}

	static void
	scroll_and_zoom_pointer_positions (
		PointerEvent* event, const Point& scroll, float zoom)
	{
		assert(event);

		if (zoom == 0)
			argument_error(__FILE__, __LINE__);

		if (scroll == 0 && zoom == 1)
			return;

		for (auto& pointer : event->self->pointers)
		{
			Pointer_update_positions(&pointer, [=](Point* pos)
			{
				*pos -= scroll;
				*pos /= zoom;
			});
		}
	}

	void
	PointerEvent_update_for_child_view (PointerEvent* pthis, const View* view)
	{
		if (!pthis || !view)
			argument_error(__FILE__, __LINE__);

		filter_and_offset_pointer_positions(pthis, view->frame());
		scroll_and_zoom_pointer_positions(pthis, view->scroll(), view->zoom());
	}

	void
	PointerEvent_update_for_capturing_view (PointerEvent* pthis, const View* view)
	{
		if (!pthis || !view)
			argument_error(__FILE__, __LINE__);

		for (auto& pointer : pthis->self->pointers)
		{
			Pointer_update_positions(&pointer, [=](Point* pos)
			{
				*pos = view->from_window(*pos);
			});
		}

		scroll_and_zoom_pointer_positions(pthis, view->scroll(), view->zoom());
	}


	PointerEvent::PointerEvent ()
	{
	}

	PointerEvent::PointerEvent (const Pointer* pointers, size_t size)
	{
		for (size_t i = 0; i < size; ++i)
			self->pointers.emplace_back(pointers[i]);
	}

	PointerEvent::PointerEvent (const PointerEvent* src)
	:	Event(src), self(new Data(*src->self))
	{
	}

	PointerEvent
	PointerEvent::dup () const
	{
		return PointerEvent(this);
	}

	size_t
	PointerEvent::size () const
	{
		return self->pointers.size();
	}

	bool
	PointerEvent::empty () const
	{
		return size() == 0;
	}

	bool
	PointerEvent::is_captured () const
	{
		return self->captured;
	}

	const Pointer&
	PointerEvent::operator [] (size_t index) const
	{
		if (index >= self->pointers.size())
			index_error(__FILE__, __LINE__);

		return self->pointers[index];
	}


	struct WheelEvent::Data
	{

		Point position, dposition;

		uint modifiers;

		Data (
			const Point& position = 0, const Point& dposition = 0,
			uint modifiers = 0)
		:	position(position), dposition(dposition), modifiers(modifiers)
		{
		}

	};// WheelEvent::Data


	void
	WheelEvent_set_position (WheelEvent* pthis, const Point& position)
	{
		if (!pthis)
			argument_error(__FILE__, __LINE__);

		pthis->self->position = position;
	}


	WheelEvent::WheelEvent ()
	{
	}

	WheelEvent::WheelEvent (
		coord x, coord y, coord z, coord dx, coord dy, coord dz, uint modifiers)
	:	self(new Data(Point(x, y, z), Point(dx, dy, dz), modifiers))
	{
	}

	WheelEvent::WheelEvent (const WheelEvent* src)
	:	Event(src), self(new Data(*src->self))
	{
	}

	WheelEvent
	WheelEvent::dup () const
	{
		return WheelEvent(this);
	}

	Point&
	WheelEvent::position ()
	{
		return self->position;
	}

	const Point&
	WheelEvent::position () const
	{
		return const_cast<WheelEvent*>(this)->position();
	}

	Point&
	WheelEvent::dposition ()
	{
		return self->dposition;
	}

	const Point&
	WheelEvent::dposition () const
	{
		return const_cast<WheelEvent*>(this)->dposition();
	}

	uint
	WheelEvent::modifiers () const
	{
		return self->modifiers;
	}


	CaptureEvent::CaptureEvent ()
	:	begin(0), end(0)
	{
	}

	CaptureEvent::CaptureEvent (uint begin, uint end)
	:	begin(begin), end(end)
	{
	}


	TimerEvent::TimerEvent (Timer* timer)
	:	timer(timer)
	{
	}

	View*
	TimerEvent::owner () const
	{
		return timer ? timer->owner() : NULL;
	}

	int
	TimerEvent::id () const
	{
		return timer ? timer->id() : Timer::ID_INVALID;
	}

	float
	TimerEvent::interval () const
	{
		return timer ? timer->interval() : -1;
	}

	void
	TimerEvent::set_count (int count)
	{
		if (timer) timer->set_count(count);
	}

	int
	TimerEvent::count () const
	{
		return timer ? timer->count() : 0;
	}

	bool
	TimerEvent::is_finished () const
	{
		return timer ? timer->is_finished() : true;
	}


	ContactEvent::ContactEvent ()
	:	type(NONE), shape(NULL), view(NULL)
	{
	}

	ContactEvent::ContactEvent (Type type, Shape* shape)
	:	type(type), shape(shape), view(shape ? shape->owner() : NULL)
	{
	}


	MotionEvent::MotionEvent (const Point& gravity)
	:	gravity(gravity)
	{
	}


}// Reflex
