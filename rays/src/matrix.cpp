#include "matrix.h"


#include <glm/mat4x4.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <xot/util.h>
#include "rays/exception.h"
#include "rays/point.h"
#include "coord.h"


namespace Rays
{


	Matrix::Matrix (coord value)
	{
		reset(value);
	}

	Matrix::Matrix (
		coord x0, coord x1, coord x2, coord x3,
		coord y0, coord y1, coord y2, coord y3,
		coord z0, coord z1, coord z2, coord z3,
		coord w0, coord w1, coord w2, coord w3)
	{
		reset(x0, x1, x2, x3, y0, y1, y2, y3, z0, z1, z2, z3, w0, w1, w2, w3);
	}

	Matrix::Matrix (const coord* elements, size_t size)
	{
		reset(elements, size);
	}

	Matrix
	Matrix::dup () const
	{
		return *this;
	}

	Matrix&
	Matrix::reset (coord value)
	{
		return reset(
			value, 0, 0, 0,
			0, value, 0, 0,
			0, 0, value, 0,
			0, 0, 0, value);
	}

	Matrix&
	Matrix::reset (
		coord x0, coord x1, coord x2, coord x3,
		coord y0, coord y1, coord y2, coord y3,
		coord z0, coord z1, coord z2, coord z3,
		coord w0, coord w1, coord w2, coord w3)
	{
		this->x0 = x0; this->x1 = x1; this->x2 = x2; this->x3 = x3;
		this->y0 = y0; this->y1 = y1; this->y2 = y2; this->y3 = y3;
		this->z0 = z0; this->z1 = z1; this->z2 = z2; this->z3 = z3;
		this->w0 = w0; this->w1 = w1; this->w2 = w2; this->w3 = w3;
		return *this;
	}

	Matrix&
	Matrix::reset (const coord* elements, size_t size)
	{
		if (size != 16)
			argument_error(__FILE__, __LINE__);

		const coord* e = elements;
		x0 = e[ 0]; x1 = e[ 1]; x2 = e[ 2]; x3 = e[ 3];
		y0 = e[ 4]; y1 = e[ 5]; y2 = e[ 6]; y3 = e[ 7];
		z0 = e[ 8]; z1 = e[ 9]; z2 = e[10]; z3 = e[11];
		w0 = e[12]; w1 = e[13]; w2 = e[14]; w3 = e[15];
		return *this;
	}

	Matrix&
	Matrix::translate (coord x, coord y, coord z)
	{
		to_glm(*this) = glm::translate(to_glm(*this), Vec3(x, y, z));
		return *this;
	}

	Matrix&
	Matrix::translate (const Coord3& translate)
	{
		to_glm(*this) = glm::translate(to_glm(*this), to_glm(translate));
		return *this;
	}

	Matrix&
	Matrix::scale (coord x, coord y, coord z)
	{
		to_glm(*this) = glm::scale(to_glm(*this), Vec3(x, y, z));
		return *this;
	}

	Matrix&
	Matrix::scale (const Coord3& scale)
	{
		to_glm(*this) = glm::scale(to_glm(*this), to_glm(scale));
		return *this;
	}

	Matrix&
	Matrix::rotate (float degree, coord x, coord y, coord z)
	{
		to_glm(*this) = glm::rotate(
			to_glm(*this), (float) Xot::deg2rad(degree), Vec3(x, y, z));
		return *this;
	}

	Matrix&
	Matrix::rotate (float degree, const Coord3& axis)
	{
		to_glm(*this) = glm::rotate(
			to_glm(*this), (float) Xot::deg2rad(degree), to_glm(axis));
		return *this;
	}

	coord&
	Matrix::at (int row, int column)
	{
		return array[column * 4 + row];
	}

	coord
	Matrix::at (int row, int column) const
	{
		return const_cast<Matrix*>(this)->at(row, column);
	}

	String
	Matrix::inspect () const
	{
		return Xot::stringf(
			"%f %f %f %f, %f %f %f %f, %f %f %f %f, %f %f %f %f",
			x0, x1, x2, x3, y0, y1, y2, y3, z0, z1, z2, z3, w0, w1, w2, w3);
	}

	coord&
	Matrix::operator [] (int index)
	{
		return array[index];
	}

	coord
	Matrix::operator [] (int index) const
	{
		return const_cast<Matrix*>(this)->operator[](index);
	}

	Matrix&
	Matrix::operator *= (const Matrix& rhs)
	{
		to_glm(*this) *= to_glm(rhs);
		return *this;
	}

	Point
	Matrix::operator * (const Point& rhs) const
	{
		Vec4 v = to_glm(*this) * Vec4(rhs.x, rhs.y, rhs.z, 1);
		return to_rays<Point>(Vec3(v));
	}

	Matrix
	Matrix::operator * (const Matrix& rhs) const
	{
		return to_rays(to_glm(*this) * to_glm(rhs));
	}

	bool
	operator == (const Matrix& lhs, const Matrix& rhs)
	{
		return to_glm(lhs) == to_glm(rhs);
	}

	bool
	operator != (const Matrix& lhs, const Matrix& rhs)
	{
		return to_glm(lhs) != to_glm(rhs);
	}


}// Rays
