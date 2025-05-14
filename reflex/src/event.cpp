#include "event.h"


#include <algorithm>
#include "reflex/device.h"
#include "reflex/timer.h"
#include "reflex/shape.h"
#include "reflex/midi.h"
#include "reflex/exception.h"
#include "view.h"
#include "pointer.h"


namespace Reflex
{


	struct Event::Data
	{

		double time;

		bool blocked;

		Data* parent = NULL;

		Data (double time = -1, bool blocked = false)
		:	time(time >= 0 ? time : Xot::time()), blocked(blocked)
		{
		}

		void block (bool parent)
		{
			blocked = true;
			if (parent && this->parent) this->parent->block(true);
		}

	};// Event::Data


	Event::Event (double time)
	:	self(new Data(time))
	{
	}

	Event::Event (const Event* src)
	:	self(new Data(*src->self))
	{
		self->parent = src->self.get();
	}

	Event::~Event ()
	{
	}

	void
	Event::block (bool parent)
	{
		self->block(parent);
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


	struct DeviceEvent::Data
	{

		Device::Ref device;

	};// DeviceEvent::Data


	DeviceEvent::DeviceEvent (Device* device)
	{
		if (device) self->device = device;
	}

	DeviceEvent::DeviceEvent (const DeviceEvent* src)
	:	Event(src), self(new Data(*src->self))
	{
	}

	DeviceEvent
	DeviceEvent::dup () const
	{
		return DeviceEvent(this);
	}

	Device*
	DeviceEvent::device ()
	{
		return self->device;
	}

	const Device*
	DeviceEvent::device () const
	{
		return self->device;
	}


	struct UpdateEvent::Data
	{

		double now;

		float dt;

		Data (double now = 0, float dt = 0)
		:	now(now), dt(dt)
		{
		}

	};// UpdateEvent::Data


	UpdateEvent::UpdateEvent ()
	{
	}

	UpdateEvent::UpdateEvent (double now, float dt)
	:	self(new Data(now, dt))
	{
	}

	UpdateEvent::UpdateEvent (const UpdateEvent* src)
	:	Event(src), self(new Data(*src->self))
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

		Data (float dt = 0, float fps = 0)
		:	view(NULL), painter(NULL), dt(dt), fps(fps)
		{
		}

	};// DrawEvent::Data


	void
	DrawEvent_set_view (DrawEvent* pthis, View* view)
	{
		if (!pthis)
			argument_error(__FILE__, __LINE__);

		pthis->self->view = view;
	}

	void
	DrawEvent_set_painter (DrawEvent* pthis, Painter* painter)
	{
		if (!pthis)
			argument_error(__FILE__, __LINE__);

		pthis->self->painter = painter;
	}

	void
	DrawEvent_set_bounds (DrawEvent* pthis, const Bounds& bounds)
	{
		if (!pthis)
			argument_error(__FILE__, __LINE__);

		pthis->self->bounds = bounds;
	}


	DrawEvent::DrawEvent ()
	{
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

		coord dx, dy, dz, dw, dh, dd;

		float zoom, dzoom;

		float angle, dangle;

		Data (
			const Bounds& frame = 0,
			coord dx = 0, coord dy = 0, coord dz = 0,
			coord dw = 0, coord dh = 0, coord dd = 0,
			float zoom  = 0, float dzoom  = 0,
			float angle = 0, float dangle = 0)
		:	frame(frame), dx(dx), dy(dy), dz(dz), dw(dw), dh(dh), dd(dd),
			zoom(zoom), dzoom(dzoom), angle(angle), dangle(dangle)
		{
		}

	};// FrameEvent::Data


	FrameEvent::FrameEvent ()
	{
	}

	FrameEvent::FrameEvent (
		const Bounds& frame,
		coord dx, coord dy, coord dz, coord dwidth, coord dheight, coord ddepth,
		float zoom, float dzoom, float angle, float dangle)
	:	self(new Data(
			frame, dx, dy, dz, dwidth, dheight, ddepth, zoom, dzoom, angle, dangle))
	{
	}

	FrameEvent::FrameEvent (
		const Bounds& frame, const Bounds& prev_frame,
		float zoom, float prev_zoom, float angle, float prev_angle)
	:	self(new Data(
			frame,
			frame.x - prev_frame.x, frame.y - prev_frame.y, frame.z - prev_frame.z,
			frame.w - prev_frame.w, frame.h - prev_frame.h, frame.d - prev_frame.d,
			zoom,  zoom  - prev_zoom,
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
	FrameEvent::dz () const
	{
		return self->dz;
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

	coord
	FrameEvent::ddepth () const
	{
		return self->dd;
	}

	float
	FrameEvent::zoom () const
	{
		return self->zoom;
	}

	float
	FrameEvent::dzoom () const
	{
		return self->dzoom;
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
		return self->dx != 0 || self->dy != 0 || self->dz != 0;
	}

	bool
	FrameEvent::is_resize () const
	{
		return self->dw != 0 || self->dh != 0 || self->dd != 0;
	}

	bool
	FrameEvent::is_zoom () const
	{
		return self->dzoom != 0;
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
	KeyEvent_set_chars (KeyEvent* pthis, const char* chars)
	{
		pthis->self->chars = chars ? chars : "";
	}

	void
	KeyEvent_set_captured (KeyEvent* pthis, bool captured)
	{
		pthis->self->captured = captured;
	}


	KeyEvent::KeyEvent ()
	{
	}

	KeyEvent::KeyEvent (
		Action action, const char* chars, int code, uint modifiers, int repeat,
		double time)
	:	Event(time), self(new Data(action, chars, code, modifiers, repeat))
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
		if (self->chars.empty()) return NULL;
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

		Data* parent = NULL;

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

	void
	PointerEvent_update_for_child_view (PointerEvent* pthis, const View* child)
	{
		if (!pthis)
			argument_error(__FILE__, __LINE__);
		if (!child)
			argument_error(__FILE__, __LINE__);

		const Bounds& frame = child->frame();

		std::vector<Pointer> pointers;
		for (const auto& pointer : pthis->self->pointers)
		{
			if (!frame.is_include(pointer.position()))
				continue;

			pointers.emplace_back(pointer);
			Pointer_update_positions(&pointers.back(), [&](Point* pos)
			{
				*pos = child->from_parent(*pos);
			});
		}
		pthis->self->pointers = pointers;
	}

	void
	PointerEvent_update_for_capturing_view (PointerEvent* pthis, const View* view)
	{
		if (!pthis)
			argument_error(__FILE__, __LINE__);
		if (!view)
			argument_error(__FILE__, __LINE__);

		for (auto& pointer : pthis->self->pointers)
		{
			Pointer_update_positions(&pointer, [=](Point* pos)
			{
				*pos = view->from_window(*pos);
			});
		}
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
		self->parent = src->self.get();
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


	struct MIDIEvent::Data
	{

		MIDI::Ref midi;

		uchar bytes[3] = {0};

		bool captured  = false;

	};// MIDIEvent


	bool
	MIDIEvent_to_note_event (NoteEvent* result, const MIDIEvent& event)
	{
		auto a = event.action();
		if (a != MIDIEvent::NOTE_ON && a != MIDIEvent::NOTE_OFF)
			return false;

		*result = NoteEvent(
			a == MIDIEvent::NOTE_ON ? NoteEvent::ON : NoteEvent::OFF,
			event.channel(), event.data1(), event.data2() / 127.f, event.time());
		return true;
	}

	bool
	MIDIEvent_to_control_change_event (
		ControlChangeEvent* result, const MIDIEvent& event)
	{
		if (event.action() != MIDIEvent::CONTROL_CHANGE)
			return false;

		*result = ControlChangeEvent(
			event.channel(), event.data1(), event.data2() / 127.f, event.time());
		return true;
	}

	void
	MIDIEvent_set_captured (MIDIEvent* pthis, bool captured)
	{
		pthis->self->captured = captured;
	}


	MIDIEvent::MIDIEvent ()
	{
	}

	MIDIEvent::MIDIEvent (MIDI* midi, const uchar* bytes, double time)
	:	Event(time)
	{
		self->midi = midi;
		memcpy(self->bytes, bytes, sizeof(uchar) * 3);
	}

	MIDIEvent::MIDIEvent (const MIDIEvent* src)
	:	Event(src), self(new Data(*src->self))
	{
	}

	MIDIEvent
	MIDIEvent::dup () const
	{
		return MIDIEvent(this);
	}

	MIDI*
	MIDIEvent::midi () const
	{
		return self->midi;
	}

	MIDIEvent::Action
	MIDIEvent::action () const
	{
		switch (self->bytes[0] >> 4)
		{
			case 0x9: return NOTE_ON;
			case 0x8: return NOTE_OFF;
			case 0xA: return KEY_PRESSURE;
			case 0xB: return CONTROL_CHANGE;
			case 0xC: return PROGRAM_CHANGE;
			case 0xD: return CHANNEL_PRESSURE;
			case 0xE: return PITCH_BEND_CHANGE;
			case 0xF: return SYSTEM;
			default:  return ACTION_NONE;
		}
	}

	int
	MIDIEvent::channel () const
	{
		auto a = action();
		if (a == ACTION_NONE || a == SYSTEM)
			return -1;

		return self->bytes[0] & 0xF;
	}

	uchar
	MIDIEvent::data1 () const
	{
		return self->bytes[1];
	}

	uchar
	MIDIEvent::data2 () const
	{
		return self->bytes[2];
	}

	bool
	MIDIEvent::is_captured () const
	{
		return self->captured;
	}


	struct NoteEvent::Data
	{

		Action action  = ACTION_NONE;

		int channel    = 0;

		int note       = 0;

		float velocity = 0;

		bool captured  = false;

	};// NoteEvent::Data


	void
	NoteEvent_set_captured (NoteEvent* pthis, bool captured)
	{
		pthis->self->captured = captured;
	}


	NoteEvent::NoteEvent ()
	{
	}

	NoteEvent::NoteEvent (
		Action action, int channel, int note, float velocity, double time)
	:	Event(time)
	{
		self->action   = action;
		self->channel  = channel;
		self->note     = note;
		self->velocity = velocity;
	}

	NoteEvent::NoteEvent (const NoteEvent* src)
	:	Event(src), self(new Data(*src->self))
	{
	}

	NoteEvent
	NoteEvent::dup () const
	{
		return NoteEvent(this);
	}

	NoteEvent::Action
	NoteEvent::action () const
	{
		return self->action;
	}

	int
	NoteEvent::channel () const
	{
		return self->channel;
	}

	int
	NoteEvent::note () const
	{
		return self->note;
	}

	float
	NoteEvent::frequency () const
	{
		static const int A4 = 69;
		return 440 * std::pow(2.0, (note() - A4) / 12.0);
	}

	float
	NoteEvent::velocity () const
	{
		return self->velocity;
	}

	bool
	NoteEvent::is_captured () const
	{
		return self->captured;
	}


	struct ControlChangeEvent::Data
	{

		int channel    = 0;

		int controller = 0;

		float value    = 0;

		bool captured  = false;

	};// ControlChangeEvent::Data


	void
	ControlChangeEvent_set_captured (ControlChangeEvent* pthis, bool captured)
	{
		pthis->self->captured = captured;
	}


	ControlChangeEvent::ControlChangeEvent ()
	{
	}

	ControlChangeEvent::ControlChangeEvent (
		int channel, int controller, float value, double time)
	:	Event(time)
	{
		self->channel    = channel;
		self->controller = controller;
		self->value      = value;
	}

	ControlChangeEvent::ControlChangeEvent (const ControlChangeEvent* src)
	:	Event(src), self(new Data(*src->self))
	{
	}

	ControlChangeEvent
	ControlChangeEvent::dup () const
	{
		return ControlChangeEvent(this);
	}

	int
	ControlChangeEvent::channel () const
	{
		return self->channel;
	}

	int
	ControlChangeEvent::controller () const
	{
		return self->controller;
	}

	float
	ControlChangeEvent::value () const
	{
		return self->value;
	}

	bool
	ControlChangeEvent::is_captured () const
	{
		return self->captured;
	}


	struct CaptureEvent::Data
	{

		uint begin, end;

		Data (uint begin = 0, uint end = 0)
		:	begin(begin), end(end)
		{
		}

	};// CaptureEvent::Data


	CaptureEvent::CaptureEvent ()
	{
	}

	CaptureEvent::CaptureEvent (uint begin, uint end)
	:	self(new Data(begin, end))
	{
	}

	CaptureEvent::CaptureEvent (const CaptureEvent* src)
	:	Event(src), self(new Data(*src->self))
	{
	}

	CaptureEvent
	CaptureEvent::dup () const
	{
		return CaptureEvent(this);
	}

	uint
	CaptureEvent::begin () const
	{
		return self->begin;
	}

	uint
	CaptureEvent::end () const
	{
		return self->end;
	}


	struct TimerEvent::Data
	{

		Timer::Ref timer;

		Data (Timer* timer = NULL)
		:	timer(timer)
		{
		}

	};// TimerEvent::Data


	TimerEvent::TimerEvent ()
	{
	}

	TimerEvent::TimerEvent (Timer* timer)
	:	self(new Data(timer))
	{
	}

	TimerEvent::TimerEvent (const TimerEvent* src)
	:	Event(src), self(new Data(*src->self))
	{
	}

	TimerEvent
	TimerEvent::dup () const
	{
		return TimerEvent(this);
	}

	Timer*
	TimerEvent::timer ()
	{
		return self->timer;
	}

	const Timer*
	TimerEvent::timer () const
	{
		return const_cast<TimerEvent*>(this)->timer();
	}

	View*
	TimerEvent::owner () const
	{
		return self->timer ? self->timer->owner() : NULL;
	}

	int
	TimerEvent::id () const
	{
		return self->timer ? self->timer->id() : Timer::ID_INVALID;
	}

	float
	TimerEvent::interval () const
	{
		return self->timer ? self->timer->interval() : -1;
	}

	int
	TimerEvent::count () const
	{
		return self->timer ? self->timer->count() : 0;
	}

	bool
	TimerEvent::is_finished () const
	{
		return self->timer ? self->timer->is_finished() : true;
	}


	struct ContactEvent::Data
	{

		Action action;

		Shape* shape;

		View* view;

		Data (Action action = ACTION_NONE, Shape* shape = NULL, View* view = NULL)
		:	action(action), shape(shape), view(view)
		{
		}

	};// ContactEvent::Data


	ContactEvent::ContactEvent ()
	{
	}

	ContactEvent::ContactEvent (Action action, Shape* shape)
	:	self(new Data(action, shape, shape ? shape->owner() : NULL))
	{
	}

	ContactEvent::ContactEvent (const ContactEvent* src)
	:	Event(src), self(new Data(*src->self))
	{
	}

	ContactEvent
	ContactEvent::dup () const
	{
		return ContactEvent(this);
	}

	ContactEvent::Action
	ContactEvent::action () const
	{
		return self->action;
	}

	Shape*
	ContactEvent::shape ()
	{
		return self->shape;
	}

	const Shape*
	ContactEvent::shape () const
	{
		return const_cast<ContactEvent*>(this)->shape();
	}

	View*
	ContactEvent::view ()
	{
		return self->view;
	}

	const View*
	ContactEvent::view () const
	{
		return const_cast<ContactEvent*>(this)->view();
	}


	struct MotionEvent::Data
	{

		Point gravity;

		Data (const Point& gravity)
		:	gravity(gravity)
		{
		}

	};// MotionEvent::Data


	MotionEvent::MotionEvent (const Point& gravity)
	:	self(new Data(gravity))
	{
	}

	MotionEvent::MotionEvent (const MotionEvent* src)
	:	Event(src), self(new Data(*src->self))
	{
	}

	MotionEvent
	MotionEvent::dup () const
	{
		return MotionEvent(this);
	}

	const Point&
	MotionEvent::gravity () const
	{
		return self->gravity;
	}


}// Reflex
