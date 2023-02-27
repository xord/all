// -*- c++ -*-
#pragma once
#ifndef __XOT_UTIL_H__
#define __XOT_UTIL_H__


#include <stdint.h>
#include <math.h>
#include <assert.h>
#include <xot/defs.h>
#include <xot/time.h>


namespace Xot
{


	int bit2byte (int bits);

	int byte2bit (int bytes);


	void seed (uint value = (uint) (time() * 1000));

	double random (double max_ = 1);

	double random (double min_, double max_);


	template <typename T = uint>
	inline constexpr T
	bit (int nth, T base = 0x1)
	{
		return (T) (base << nth);
	}

	template <typename T>
	inline constexpr T
	clip (T minval, T maxval, T value)
	{
		return value > maxval ? maxval : (value < minval ? minval : value);
	}


	inline constexpr double
	deg2rad (double degree)
	{
		return degree / 180.0 * M_PI;
	}

	inline constexpr double
	rad2deg (double radian)
	{
		return radian / M_PI * 180.0;
	}


	template <typename T>
	inline void
	add_flag (T* pvalue, uint flag)
	{
		assert(pvalue);

		*pvalue |= flag;
	}

	template <typename T>
	inline void
	remove_flag (T* pvalue, uint flag)
	{
		assert(pvalue);

		*pvalue &= ~flag;
	}

	template <typename T>
	inline bool
	has_flag (T value, uint flag)
	{
		if (flag == 0) return false;
		return (value & flag) == flag;
	}

	template <typename T>
	inline bool
	check_and_remove_flag (T* pvalue, uint flag)
	{
		assert(pvalue);

		bool has = has_flag(*pvalue, flag);
		remove_flag(pvalue, flag);
		return has;
	}


	static const uintptr_t POINTER_FLAG = 0x1;

	template <typename T>
	inline T*
	set_pointer_flag (T* pointer, bool flag = true)
	{
		uintptr_t intval = *(uintptr_t*) &pointer;
		if (flag)
			intval |= POINTER_FLAG;
		else
			intval &= ~POINTER_FLAG;

		return *(T**) &intval;
	}

	template <typename T>
	inline const T*
	set_pointer_flag (const T* pointer, bool flag = true)
	{
		return set_pointer_flag(const_cast<T*>(pointer), flag);
	}

	template <typename T>
	inline bool
	get_pointer_flag (const T* pointer)
	{
		const uintptr_t& intval = *(uintptr_t*) &pointer;
		return intval & POINTER_FLAG;
	}


}// Xot


#endif//EOH
