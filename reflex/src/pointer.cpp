#include "pointer.h"


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

			DRAG          = Xot::bit(0, TYPE_LAST),

			ENTER         = Xot::bit(1, TYPE_LAST),

			EXIT          = Xot::bit(2, TYPE_LAST),

			HAS_SYSTEM_ID = Xot::bit(3, TYPE_LAST),

			HAS_PREV_POS  = Xot::bit(4, TYPE_LAST),

		};// Flag

		ID id, system_id;

		uint types;

		Action action;

		Point position, prev_position;

		uint modifiers, click_count, flags;

		double time;

		PrevPointerPtr prev, down;

		Data (
			ID id = -1, uint types = TYPE_NONE, Action action = ACTION_NONE,
			const Point& position = 0, uint modifiers = 0, uint click_count = 0,
			bool drag = false, bool enter = false, bool exit = false,
			double time = 0)
		:	id(id), types(types), action(action),
			position(position), modifiers(modifiers), click_count(click_count),
			flags(make_flags(drag, enter, exit)),
			time(time)
		{
		}

		uint make_flags (bool drag, bool enter, bool exit)
		{
			return
				(drag  ? DRAG  : 0) |
				(enter ? ENTER : 0) |
				(exit  ? EXIT  : 0);
		}

		bool is_valid () const
		{
			return id >= 0 && types != TYPE_NONE && action != ACTION_NONE;
		}

	};// Pointer::Data


	void
	Pointer_update_positions (Pointer* it, std::function<void(Point*)> fun)
	{
		auto& self = it->self;
		fun(&self->position);
		if (self->prev) fun(&self->prev->self->position);
		if (self->down) fun(&self->down->self->position);
	}

	void
	Pointer_set_id (Pointer* it, Pointer::ID id)
	{
		it->self->id = id;
	}

	void
	Pointer_add_flag (Pointer* it, uint flag)
	{
		Xot::add_flag(&it->self->flags, flag);
	}

	void
	Pointer_remove_flag (Pointer* it, uint flag)
	{
		Xot::remove_flag(&it->self->flags, flag);
	}

	uint
	Pointer_mask_flag (const Pointer& it, uint mask)
	{
		return Xot::mask_flag(it.self->flags, mask);
	}

	void
	Pointer_set_prev (Pointer* it, const Pointer* prev)
	{
		it->self->prev.reset(prev && *prev ? new Pointer(*prev) : NULL);
	}

	void
	Pointer_set_down (Pointer* it, const Pointer* down)
	{
		it->self->down.reset(down && *down ? new Pointer(*down) : NULL);
	}

	void
	Pointer_set_system_id (Pointer*it, Pointer::ID id)
	{
		it->self->system_id = id;
		Xot::add_flag(&it->self->flags, Pointer::Data::HAS_SYSTEM_ID);
	}

	const Pointer::ID*
	Pointer_get_system_id (const Pointer& it)
	{
		if (!Xot::has_flag(it.self->flags, Pointer::Data::HAS_SYSTEM_ID))
			return NULL;
		return &it.self->system_id;
	}

	void
	Pointer_set_prev_position (Pointer* it, const Point& position)
	{
		it->self->prev_position = position;
		Xot::add_flag(&it->self->flags, Pointer::Data::HAS_PREV_POS);
	}

	const Point*
	Pointer_get_prev_position (const Pointer& it)
	{
		if (!Xot::has_flag(it.self->flags, Pointer::Data::HAS_PREV_POS))
			return NULL;
		return &it.self->prev_position;
	}


	Pointer::Pointer ()
	{
	}

	Pointer::Pointer (
		ID id, uint types, Action action,
		const Point& position, uint modifiers, uint click_count, bool drag,
		double time)
	:	self(new Data(
			id, types, action,
			position, modifiers, click_count, drag, false, false,
			time))
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
	Pointer::types () const
	{
		return self->types;
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

	uint
	Pointer::click_count () const
	{
		return self->click_count;
	}

	bool
	Pointer::is_drag () const
	{
		return Xot::has_flag(self->flags, Data::DRAG);
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
		if (self->down)
			return self->down.get();
		else if (action() == DOWN)
			return this;
		else
			return NULL;
	}

	Pointer::operator bool () const
	{
		return self->is_valid();
	}

	bool
	Pointer::operator ! () const
	{
		return !operator bool();
	}


}// Reflex
