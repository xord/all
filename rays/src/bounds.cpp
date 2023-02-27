#include "rays/bounds.h"


#include <float.h>
#include <algorithm>
#include "rays/exception.h"


namespace Rays
{


	Bounds::Bounds (coord size)
	{
		reset(size);
	}

	Bounds::Bounds (coord width, coord height, coord depth)
	{
		reset(width, height, depth);
	}

	Bounds::Bounds (coord x, coord y, coord width, coord height)
	{
		reset(x, y, width, height);
	}

	Bounds::Bounds (
		coord x, coord y, coord z, coord width, coord height, coord depth)
	{
		reset(x, y, z, width, height, depth);
	}

	Bounds::Bounds (const Point& size)
	{
		reset(size);
	}

	Bounds::Bounds (const Point& position, const Point& size)
	{
		reset(position, size);
	}

	Bounds
	Bounds::dup () const
	{
		return *this;
	}

	bool
	Bounds::is_intersect (const Bounds& other, int dimension) const
	{
		if (dimension < 1 || 3 < dimension)
			argument_error(__FILE__, __LINE__);

		Point size = (*this & other).size();
		for (int i = 0; i < dimension; ++i)
			if (size[i] <= 0) return false;

		return true;
	}

	bool
	Bounds::is_include (coord x, coord y, coord z, int dimension) const
	{
		return is_include(Point(x, y, z), dimension);
	}

	bool
	Bounds::is_include (const Point& point, int dimension) const
	{
		if (dimension < 1 || 3 < dimension)
			argument_error(__FILE__, __LINE__);

		const Point &pos = position(), &size_ = size();
		for (int i = 0; i < dimension; ++i)
		{
			coord value = point[i], min_ = pos[i], max_ = min_ + size_[i];
			if (value < min_ || max_ <= value)
				return false;
		}

		return true;
	}

	Bounds&
	Bounds::reset (coord size)
	{
		return reset(size, size, 0);
	}

	Bounds&
	Bounds::reset (coord width, coord height, coord depth)
	{
		this->x =
		this->y =
		this->z = 0;
		this->w = width;
		this->h = height;
		this->d = depth;
		return *this;
	}

	Bounds&
	Bounds::reset (coord x, coord y, coord width, coord height)
	{
		return reset(x, y, 0, width, height, 0);
	}

	Bounds&
	Bounds::reset (coord x, coord y, coord z, coord width, coord height, coord depth)
	{
		this->x = x;
		this->y = y;
		this->z = z;
		this->w = width;
		this->h = height;
		this->d = depth;
		return *this;
	}

	Bounds&
	Bounds::reset (const Point& size)
	{
		this->x = this->y = this->z = 0;
		this->w = size.x;
		this->h = size.y;
		this->d = size.z;
		return *this;
	}

	Bounds&
	Bounds::reset (const Point& position, const Point& size)
	{
		this->x = position.x;
		this->y = position.y;
		this->z = position.z;
		this->w = size.x;
		this->h = size.y;
		this->d = size.z;
		return *this;
	}

	Bounds&
	Bounds::move_to (coord x, coord y, coord z)
	{
		this->x = x;
		this->y = y;
		this->z = z;
		return *this;
	}

	Bounds&
	Bounds::move_to (const Point& point)
	{
		return move_to(point.x, point.y, point.z);
	}

	Bounds&
	Bounds::move_by (coord x, coord y, coord z)
	{
		this->x += x;
		this->y += y;
		this->z += z;
		return *this;
	}

	Bounds&
	Bounds::move_by (const Point& point)
	{
		return move_by(point.x, point.y, point.z);
	}

	Bounds&
	Bounds::resize_to (coord width, coord height, coord depth)
	{
		this->w = width;
		this->h = height;
		this->d = depth;
		return *this;
	}

	Bounds&
	Bounds::resize_to (const Point& point)
	{
		return resize_to(point.x, point.y, point.z);
	}

	Bounds&
	Bounds::resize_by (coord width, coord height, coord depth)
	{
		this->w += width;
		this->h += height;
		this->d += depth;
		return *this;
	}

	Bounds&
	Bounds::resize_by (const Point& point)
	{
		return resize_by(point.x, point.y, point.z);
	}

	Bounds&
	Bounds::inset_by (coord x, coord y, coord z)
	{
		this->x += x;
		this->y += y;
		this->z += z;
		this->w -= x * 2;
		this->h -= y * 2;
		this->d -= z * 2;
		return *this;
	}

	Bounds&
	Bounds::inset_by (const Point& point)
	{
		return inset_by(point.x, point.y, point.z);
	}

	void
	Bounds::set_left (coord left)
	{
		w -= left - x;
		x  = left;
	}

	coord
	Bounds::left () const
	{
		return x;
	}

	void
	Bounds::set_right (coord right)
	{
		w = right - x + (right >= 0 ? 1 : -1);
	}

	coord
	Bounds::right () const
	{
		return x + w - 1;
	}

	void
	Bounds::set_top (coord top)
	{
		h -= top - y;
		y  = top;
	}

	coord
	Bounds::top () const
	{
		return y;
	}

	void
	Bounds::set_bottom (coord bottom)
	{
		h = bottom - y + (bottom >= 0 ? 1 : -1);
	}

	coord
	Bounds::bottom () const
	{
		return y + h - 1;
	}

	void
	Bounds::set_back (coord back)
	{
		d -= back - z;
		z  = back;
	}

	coord
	Bounds::back () const
	{
		return z;
	}

	void
	Bounds::set_front (coord front)
	{
		d = front - z + (front >= 0 ? 1 : -1);
	}

	coord
	Bounds::front () const
	{
		return z + d - 1;
	}

	void
	Bounds::set_position (coord x, coord y, coord z)
	{
		this->x = x;
		this->y = y;
		this->z = z;
	}

	void
	Bounds::set_position (const Point& position)
	{
		x = position.x;
		y = position.y;
		z = position.z;
	}

	Point&
	Bounds::position ()
	{
		return (*this)[0];
	}

	const Point&
	Bounds::position () const
	{
		return const_cast<This*>(this)->position();
	}

	void
	Bounds::set_size (coord width, coord height, coord depth)
	{
		w = width;
		h = height;
		d = depth;
	}

	void
	Bounds::set_size (const Point& size)
	{
		set_size(size.x, size.y, size.z);
	}

	Point&
	Bounds::size ()
	{
		return (*this)[1];
	}

	const Point&
	Bounds::size () const
	{
		return const_cast<This*>(this)->size();
	}

	void
	Bounds::set_center (coord x, coord y, coord z)
	{
		this->x = x - w / 2;
		this->y = y - h / 2;
		this->z = z - d / 2;
	}

	void
	Bounds::set_center (const Point& center)
	{
		set_center(center.x, center.y, center.z);
	}

	Point
	Bounds::center () const
	{
		return Point(x + w / 2, y + h / 2, z + d / 2);
	}

	String
	Bounds::inspect () const
	{
		return Xot::stringf("x=%f y=%f z=%f width=%f height=%f depth=%f", x, y, z, w, h, d);
	}

	Point&
	Bounds::operator [] (size_t index)
	{
		if (index > 1)
			argument_error(__FILE__, __LINE__);

		return ((Point*) array)[index];
	}

	const Point&
	Bounds::operator [] (size_t index) const
	{
		return const_cast<Bounds*>(this)->operator[](index);
	}

	Bounds::operator bool () const
	{
		return w >= 0 && h >= 0 && d >= 0;
	}

	bool
	Bounds::operator ! () const
	{
		return !operator bool();
	}

	Bounds&
	Bounds::operator &= (const Bounds& rhs)
	{
		if (!rhs)
			argument_error(__FILE__, __LINE__);

		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		coord x = std::max(this->x,           rhs.x);
		coord y = std::max(this->y,           rhs.y);
		coord z = std::max(this->z,           rhs.z);
		coord w = std::min(this->x + this->w, rhs.x + rhs.w) - x;
		coord h = std::min(this->y + this->h, rhs.y + rhs.h) - y;
		coord d = std::min(this->z + this->d, rhs.z + rhs.d) - z;

		return reset(
			x, y, z,
			std::max(w, (coord) 0),
			std::max(h, (coord) 0),
			std::max(d, (coord) 0));
	}

	Bounds&
	Bounds::operator |= (const Bounds& rhs)
	{
		if (!rhs) return *this;

		coord x = std::min(this->x,           rhs.x);
		coord y = std::min(this->y,           rhs.y);
		coord z = std::min(this->z,           rhs.z);
		coord w = std::max(this->x + this->w, rhs.x + rhs.w) - x;
		coord h = std::max(this->y + this->h, rhs.y + rhs.h) - y;
		coord d = std::max(this->z + this->d, rhs.z + rhs.d) - z;

		return reset(x, y, z, w, h, d);
	}

	Bounds&
	Bounds::operator |= (const Point& rhs)
	{
		coord x = std::min(this->x,           rhs.x);
		coord y = std::min(this->y,           rhs.y);
		coord z = std::min(this->z,           rhs.z);
		coord w = std::max(this->x + this->w, rhs.x) - x;
		coord h = std::max(this->y + this->h, rhs.y) - y;
		coord d = std::max(this->z + this->d, rhs.z) - z;

		return reset(x, y, z, w, h, d);
	}

	bool
	operator == (const Bounds& lhs, const Bounds& rhs)
	{
		return
			lhs.x == rhs.x &&
			lhs.y == rhs.y &&
			lhs.z == rhs.z &&
			lhs.w == rhs.w &&
			lhs.h == rhs.h &&
			lhs.d == rhs.d;
	}

	bool
	operator != (const Bounds& lhs, const Bounds& rhs)
	{
		return !operator==(lhs, rhs);
	}

	Bounds
	operator & (const Bounds& lhs, const Bounds& rhs)
	{
		Bounds t = lhs;
		t &= rhs;
		return t;
	}

	Bounds
	operator | (const Bounds& lhs, const Bounds& rhs)
	{
		Bounds t = lhs;
		t |= rhs;
		return t;
	}

	Bounds
	operator | (const Bounds& lhs, const Point& rhs)
	{
		Bounds t = lhs;
		t |= rhs;
		return t;
	}


	Bounds
	invalid_bounds ()
	{
		coord max  =  FLT_MAX / 2;
		coord size = -FLT_MAX;
		return Bounds(max, max, max, size, size, size);
	}


}// Rays
