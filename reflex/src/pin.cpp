#include "reflex/pin.h"


#include "reflex/exception.h"
#include "view.h"
#include "constraint.h"


namespace Reflex
{


	struct Pin::Data
	{

		Xot::WeakRef<View> view;

		std::unique_ptr<Point> pposition;

	};// Pin::Data


	template <typename T>
	static T*
	setup_constraint (
		T* constraint,
		View* view0, const Point* position0,
		View* view1, const Point* position1)
	{
		if (!view0)
			invalid_state_error(__FILE__, __LINE__, "the pin has no view");

		Constraint_set_pins(constraint, view0, position0, view1, position1);
		View_add_constraint(view0, constraint);
		return constraint;
	}


	Pin::Pin ()
	{
	}

	Pin::Pin (coord x, coord y)
	:	Pin(NULL, Point(x, y))
	{
	}

	Pin::Pin (const Point& position)
	:	Pin(NULL, position)
	{
	}

	Pin::Pin (View* view)
	{
		self->view = view;
	}

	Pin::Pin (View* view, coord x, coord y)
	:	Pin(view, Point(x, y))
	{
	}

	Pin::Pin (View* view, const Point& position)
	{
		self->view = view;
		self->pposition.reset(new Point(position));
	}

	SnapConstraint*
	Pin::snap (Pin target)
	{
		return setup_constraint(
			Xot::Ref<SnapConstraint>(SnapConstraint_create()).get(),
			view(), position(), target.view(), target.position());
	}

	LinkConstraint*
	Pin::link (Pin target)
	{
		return setup_constraint(
			Xot::Ref<LinkConstraint>(LinkConstraint_create()).get(),
			view(), position(), target.view(), target.position());
	}

	WheelConstraint*
	Pin::wheel (Pin target)
	{
		return setup_constraint(
			Xot::Ref<WheelConstraint>(WheelConstraint_create()).get(),
			view(), position(), target.view(), target.position());
	}

	ChaseConstraint*
	Pin::chase (Pin target)
	{
		if (target.view() && target.view() == view())
			argument_error(__FILE__, __LINE__, "can not chase itself");

		ChaseConstraint* chase = setup_constraint(
			Xot::Ref<ChaseConstraint>(ChaseConstraint_create()).get(),
			view(), position(), NULL, NULL);
		chase->set_target(target);
		return chase;
	}

	View*
	Pin::view ()
	{
		return self->view.get();
	}

	const View*
	Pin::view () const
	{
		return const_cast<Pin*>(this)->view();
	}

	const Point*
	Pin::position () const
	{
		return self->pposition ? self->pposition.get() : NULL;
	}

	Pin::operator bool () const
	{
		return true;
	}

	bool
	Pin::operator ! () const
	{
		return !operator bool();
	}


}// Reflex

