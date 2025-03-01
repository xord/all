#include "rays/point.h"


#include <math.h>
#include <xot/util.h>
#include "rays/exception.h"
#include "glm.h"
#include "coord.h"


namespace Rays
{


	Point::Point (coord value)
	{
		reset(value);
	}

	Point::Point (coord x, coord y, coord z)
	{
		reset(x, y, z);
	}

	Point
	Point::dup () const
	{
		return *this;
	}

	Point&
	Point::reset (coord value)
	{
		Super::reset(value);
		return *this;
	}

	Point&
	Point::reset (coord x, coord y, coord z)
	{
		Super::reset(x, y, z);
		return *this;
	}

	Point&
	Point::move_to (coord x, coord y, coord z)
	{
		reset(x, y, z);
		return *this;
	}

	Point&
	Point::move_to (const This& point)
	{
		reset(point.x, point.y, point.z);
		return *this;
	}

	Point&
	Point::move_by (coord x, coord y, coord z)
	{
		reset(this->x + x, this->y + y, this->z + z);
		return *this;
	}

	Point&
	Point::move_by (const This& point)
	{
		reset(this->x + point.x, this->y + point.y, this->z + point.z);
		return *this;
	}

	void
	Point::rotate (float degree)
	{
		to_glm(*this) = glm::rotateZ(to_glm(*this), (float) Xot::deg2rad(degree));
	}

	coord
	Point::length () const
	{
		return glm::length(to_glm(*this));
	}

	Point
	Point::normal () const
	{
		if (dot(*this, *this) == 0)
			invalid_state_error(__FILE__, __LINE__);

		return to_rays<Point>(glm::normalize(to_glm(*this)));
	}

	void
	Point::normalize ()
	{
		*this = normal();
	}

	Point
	Point::operator - () const
	{
		return to_rays<Point>(-to_glm(*this));
	}

	Point&
	Point::operator += (coord rhs)
	{
		to_glm(*this) += rhs;
		return *this;
	}

	Point&
	Point::operator += (const This& rhs)
	{
		to_glm(*this) += to_glm(rhs);
		return *this;
	}

	Point&
	Point::operator -= (coord rhs)
	{
		to_glm(*this) -= rhs;
		return *this;
	}

	Point&
	Point::operator -= (const This& rhs)
	{
		to_glm(*this) -= to_glm(rhs);
		return *this;
	}

	Point&
	Point::operator *= (coord rhs)
	{
		to_glm(*this) *= rhs;
		return *this;
	}

	Point&
	Point::operator *= (const This& rhs)
	{
		to_glm(*this) *= to_glm(rhs);
		return *this;
	}

	Point&
	Point::operator /= (coord rhs)
	{
		if (rhs == 0)
			argument_error(__FILE__, __LINE__);

		to_glm(*this) /= rhs;
		return *this;
	}

	Point&
	Point::operator /= (const This& rhs)
	{
		if (rhs.x == 0)
			argument_error(__FILE__, __LINE__);
		if (rhs.y == 0)
			argument_error(__FILE__, __LINE__);
		if (rhs.z == 0)
			argument_error(__FILE__, __LINE__);

		to_glm(*this) /= to_glm(rhs);
		return *this;
	}

	bool
	operator == (const Point& lhs, const Point& rhs)
	{
		return to_glm(lhs) == to_glm(rhs);
	}

	bool
	operator != (const Point& lhs, const Point& rhs)
	{
		return to_glm(lhs) != to_glm(rhs);
	}

	Point
	operator + (coord lhs, const Point& rhs)
	{
		return to_rays<Point>(lhs + to_glm(rhs));
	}

	Point
	operator + (const Point& lhs, coord rhs)
	{
		return to_rays<Point>(to_glm(lhs) + rhs);
	}

	Point
	operator + (const Point& lhs, const Point& rhs)
	{
		return to_rays<Point>(to_glm(lhs) + to_glm(rhs));
	}

	Point
	operator - (coord lhs, const Point& rhs)
	{
		return to_rays<Point>(lhs - to_glm(rhs));
	}

	Point
	operator - (const Point& lhs, coord rhs)
	{
		return to_rays<Point>(to_glm(lhs) - rhs);
	}

	Point
	operator - (const Point& lhs, const Point& rhs)
	{
		return to_rays<Point>(to_glm(lhs) - to_glm(rhs));
	}

	Point
	operator * (coord lhs, const Point& rhs)
	{
		return to_rays<Point>(lhs * to_glm(rhs));
	}

	Point
	operator * (const Point& lhs, coord rhs)
	{
		return to_rays<Point>(to_glm(lhs) * rhs);
	}

	Point
	operator * (const Point& lhs, const Point& rhs)
	{
		return to_rays<Point>(to_glm(lhs) * to_glm(rhs));
	}

	Point
	operator / (coord lhs, const Point& rhs)
	{
		if (rhs.x == 0)
			argument_error(__FILE__, __LINE__);
		if (rhs.y == 0)
			argument_error(__FILE__, __LINE__);
		if (rhs.z == 0)
			argument_error(__FILE__, __LINE__);

		return to_rays<Point>(lhs / to_glm(rhs));
	}

	Point
	operator / (const Point& lhs, coord rhs)
	{
		if (rhs == 0)
			argument_error(__FILE__, __LINE__);

		return to_rays<Point>(to_glm(lhs) / rhs);
	}

	Point
	operator / (const Point& lhs, const Point& rhs)
	{
		if (rhs.x == 0)
			argument_error(__FILE__, __LINE__);
		if (rhs.y == 0)
			argument_error(__FILE__, __LINE__);
		if (rhs.z == 0)
			argument_error(__FILE__, __LINE__);

		return to_rays<Point>(to_glm(lhs) / to_glm(rhs));
	}


	coord
	dot (const Point& p1, const Point& p2)
	{
		return glm::dot(to_glm(p1), to_glm(p2));
	}

	Point
	cross (const Point& p1, const Point& p2)
	{
		return to_rays<Point>(glm::cross(to_glm(p1), to_glm(p2)));
	}


}// Rays
