#include "pointer.h"


#include <limits.h>
#include <xot/time.h>
#include "reflex/exception.h"


namespace Reflex
{


	class PrevPointerPtr : public Xot::PImpl<Pointer>
	{

		typedef Xot::PImpl<Pointer> Super;

		public:

			PrevPointerPtr () : Super(NULL) {}

	};// PrevPointerPtr


	struct Pointer::Data
	{

		enum Flag
		{

			DRAG  = Xot::bit(0),

			ENTER = Xot::bit(1),

			EXIT  = Xot::bit(2),

		};// Flag

		ID id;

		uint type;

		Action action;

		Point position;

		uint modifiers, flags;

		ushort click_count, view_index;

		double time;

		PrevPointerPtr prev, down;

		Data (
			ID id = -1, uint type = TYPE_NONE, Action action = ACTION_NONE,
			const Point& position = 0, uint modifiers = 0,
			bool drag = false, bool enter = false, bool exit = false,
			uint click_count = 0, uint view_index = 0, double time = 0)
		:	id(id), type(type), action(action),
			position(position), modifiers(modifiers),
			flags(make_flags(drag, enter, exit)),
			click_count(click_count), view_index(view_index), time(time)
		{
			if (view_index >= USHRT_MAX)
				argument_error(__FILE__, __LINE__);
		}

		uint make_flags (bool drag, bool enter, bool exit)
		{
			return
				(drag  ? DRAG  : 0) |
				(enter ? ENTER : 0) |
				(exit  ? EXIT  : 0);
		}

	};// Pointer::Data


	void
	Pointer_update_positions (Pointer* pthis, std::function<void(Point*)> fun)
	{
		auto& self = pthis->self;
		fun(&self->position);
		if (self->prev) fun(&self->prev->self->position);
		if (self->down) fun(&self->down->self->position);
	}

	void
	Pointer_set_id (Pointer* pthis, Pointer::ID id)
	{
		pthis->self->id = id;
	}

	void
	Pointer_set_view_index (Pointer* pthis, uint view_index)
	{
		if (view_index >= USHRT_MAX)
			argument_error(__FILE__, __LINE__);

		pthis->self->view_index = view_index;
	}

	void
	Pointer_set_prev (Pointer* pthis, const Pointer* prev)
	{
		pthis->self->prev.reset(prev ? new Pointer(*prev) : NULL);
	}

	void
	Pointer_set_down (Pointer* pthis, const Pointer* down)
	{
		pthis->self->down.reset(down ? new Pointer(*down) : NULL);
	}


	Pointer::Pointer ()
	{
	}

	Pointer::Pointer (
		ID id, uint type, Action action,
		const Point& position, uint modifiers, bool drag,
		uint click_count, uint view_index, double time)
	:	self(new Data(
			id, type, action,
			position, modifiers, drag, false, false,
			click_count, view_index, time))
	{
	}

	Pointer::Pointer (const This& obj)
	:	self(obj.self)
	{
	}

	Pointer&
	Pointer::operator = (const This& obj)
	{
		self.operator=(obj.self);
		return *this;
	}

	Pointer::~Pointer ()
	{
	}

	Pointer::ID
	Pointer::id () const
	{
		return self->id;
	}

	uint
	Pointer::type () const
	{
		return self->type;
	}

	Pointer::Action
	Pointer::action () const
	{
		return self->action;
	}

	const Point&
	Pointer::position () const
	{
		return self->position;
	}

	uint
	Pointer::modifiers () const
	{
		return self->modifiers;
	}

	bool
	Pointer::is_drag () const
	{
		return self->flags & Data::DRAG;
	}

	uint
	Pointer::click_count () const
	{
		return self->click_count;
	}

	uint
	Pointer::view_index () const
	{
		return self->view_index;
	}

	double
	Pointer::time () const
	{
		return self->time;
	}

	const Pointer*
	Pointer::prev () const
	{
		return self->prev.get();
	}

	const Pointer*
	Pointer::down () const
	{
		return self->down.get();
	}

	Pointer::operator bool () const
	{
		return
			self->type != TYPE_NONE &&
			ACTION_NONE < self->action && self->action <= STAY;
	}

	bool
	Pointer::operator ! () const
	{
		return !operator bool();
	}


}// Reflex
