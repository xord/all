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

		ushort click_count, layer;

		double time;

		PrevPointerPtr prev;

		Data (
			ID id = -1, uint type = TYPE_NONE, Action action = ACTION_NONE,
			const Point& position = 0, uint modifiers = 0,
			bool drag = false, bool enter = false, bool exit = false,
			uint click_count = 0, uint layer = 0, double time = 0)
		:	id(id), type(type), action(action),
			position(position), modifiers(modifiers),
			flags(make_flags(drag, enter, exit)),
			click_count(click_count), layer(layer), time(time)
		{
			if (layer >= USHRT_MAX)
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
		if (self->prev)
			fun(&self->prev->self->position);
	}

	void
	Pointer_set_id (Pointer* pthis, Pointer::ID id)
	{
		pthis->self->id = id;
	}

	void
	Pointer_set_layer (Pointer* pthis, uint layer)
	{
		if (layer >= USHRT_MAX)
			argument_error(__FILE__, __LINE__);

		pthis->self->layer = layer;
	}

	void
	Pointer_set_prev (Pointer* pthis, const Pointer* prev)
	{
		if (prev)
			pthis->self->prev.reset(new Pointer(*prev));
		else
			pthis->self->prev.reset();
	}


	Pointer::Pointer ()
	{
	}

	Pointer::Pointer (
		ID id, uint type, Action action,
		const Point& position, uint modifiers, bool drag,
		uint click_count, uint layer, double time)
	:	self(new Data(
			id, type, action,
			position, modifiers, drag, false, false,
			click_count, layer, time))
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
	Pointer::layer () const
	{
		return self->layer;
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
