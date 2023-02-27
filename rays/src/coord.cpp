#include "coord.h"


#include <xot/string.h>
#include "rays/exception.h"


namespace Rays
{


	Coord2&
	Coord2::reset (coord value)
	{
		return reset(value, value);
	}

	Coord2&
	Coord2::reset (coord x, coord y)
	{
		this->x = x;
		this->y = y;
		return *this;
	}

	size_t
	Coord2::size () const
	{
		return SIZE;
	}

	String
	Coord2::inspect () const
	{
		return Xot::stringf("x=%f y=%f", x, y);
	}

	coord&
	Coord2::operator [] (size_t index)
	{
		if (index >= 2)
			argument_error(__FILE__, __LINE__);

		return array[index];
	}

	const coord&
	Coord2::operator [] (size_t index) const
	{
		return const_cast<Coord2*>(this)->operator[](index);
	}


	Coord3&
	Coord3::operator = (const Coord2& rhs)
	{
		x = rhs.x;
		y = rhs.y;
		z = 0;
		return *this;
	}

	Coord3&
	Coord3::reset (coord value)
	{
		return reset(value, value);
	}

	Coord3&
	Coord3::reset (coord x, coord y, coord z)
	{
		this->x = x;
		this->y = y;
		this->z = z;
		return *this;
	}

	size_t
	Coord3::size () const
	{
		return SIZE;
	}

	String
	Coord3::inspect () const
	{
		return Xot::stringf("x=%f y=%f z=%f", x, y, z);
	}

	coord&
	Coord3::operator [] (size_t index)
	{
		if (index >= 3)
			argument_error(__FILE__, __LINE__);

		return array[index];
	}

	const coord&
	Coord3::operator [] (size_t index) const
	{
		return const_cast<Coord3*>(this)->operator[](index);
	}


	Coord4&
	Coord4::operator = (const Coord2& rhs)
	{
		x = rhs.x;
		y = rhs.y;
		z = 0;
		w = 1;
		return *this;
	}

	Coord4&
	Coord4::operator = (const Coord3& rhs)
	{
		x = rhs.x;
		y = rhs.y;
		z = rhs.z;
		w = 1;
		return *this;
	}

	Coord4&
	Coord4::reset (coord value)
	{
		return reset(value, value, value);
	}

	Coord4&
	Coord4::reset (coord x, coord y, coord z, coord w)
	{
		this->x = x;
		this->y = y;
		this->z = z;
		this->w = w;
		return *this;
	}

	size_t
	Coord4::size () const
	{
		return SIZE;
	}

	String
	Coord4::inspect () const
	{
		return Xot::stringf("x=%f y=%f z=%f w=%f", x, y, z, w);
	}

	coord&
	Coord4::operator [] (size_t index)
	{
		if (index >= 4)
			argument_error(__FILE__, __LINE__);

		return array[index];
	}

	const coord&
	Coord4::operator [] (size_t index) const
	{
		return const_cast<Coord4*>(this)->operator[](index);
	}


}// Rays
