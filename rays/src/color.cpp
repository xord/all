#include "rays/color.h"


#include <limits.h>
#include <glm/gtx/color_space.hpp>
#include <xot/util.h>
#include "rays/exception.h"
#include "rays/color_space.h"
#include "coord.h"


namespace Rays
{


	Color
	gray (float gray, float alpha)
	{
		return Color(gray, alpha);
	}

	Color
	gray8 (int gray, int alpha)
	{
		Color c;
		c.reset8(gray, alpha);
		return c;
	}

	Color
	rgb (float red, float green, float blue, float alpha)
	{
		return Color(red, green, blue, alpha);
	}

	Color
	rgb8 (int red, int green, int blue, int alpha)
	{
		Color c;
		c.reset8(red, green, blue, alpha);
		return c;
	}

	Color
	hsv (float hue, float saturation, float value, float alpha)
	{
		hue = fmod(hue, 1.f);
		if (hue < 0) hue += 1.f;

		auto c = glm::rgbColor(Vec3(hue * 360.f, saturation, value));
		return Color(c[0], c[1], c[2], alpha);
	}


	Color::Color (float gray, float alpha)
	{
		reset(gray, alpha);
	}

	Color::Color (float red, float green, float blue, float alpha)
	{
		reset(red, green, blue, alpha);
	}

	Color::Color (void* pixel, const ColorSpace& cs)
	{
		reset(pixel, cs);
	}

	Color
	Color::dup () const
	{
		return *this;
	}

	Color&
	Color::reset (float gray, float alpha)
	{
		return reset(gray, gray, gray, alpha);
	}

	Color&
	Color::reset (float red, float green, float blue, float alpha)
	{
		Super::reset(red, green, blue, alpha);
		return *this;
	}

	Color&
	Color::reset8 (int gray, int alpha)
	{
		float g = uchar2float(gray);
		float a = uchar2float(alpha);
		return reset(g, g, g, a);
	}

	Color&
	Color::reset8 (int red, int green, int blue, int alpha)
	{
		Super::reset(
			uchar2float(red),
			uchar2float(green),
			uchar2float(blue),
			uchar2float(alpha));
		return *this;
	}

	Color&
	Color::reset (const void* pixel, const ColorSpace& cs)
	{
		if (!pixel || !cs)
			argument_error(__FILE__, __LINE__);

		if (cs.is_float())
		{
			float* p = (float*) pixel;
			switch (cs.type())
			{
				case GRAY_float:  reset(p[0]); break;
				case  RGB_float:  reset(p[0], p[1], p[2]); break;
				case  RGBA_float: reset(p[0], p[1], p[2], p[3]); break;
				case ARGB_float:  reset(p[1], p[2], p[3], p[0]); break;
				case  BGR_float:  reset(p[2], p[1], p[0]); break;
				case  BGRA_float: reset(p[2], p[1], p[0], p[3]); break;
				case ABGR_float:  reset(p[3], p[2], p[1], p[0]); break;
				default:          rays_error(__FILE__, __LINE__);
			}
		}
		else
		{
			uchar* p = (uchar*) pixel;
			switch (cs.type())
			{
				case GRAY_8:     reset8(*((uchar*)  pixel) / (float)  UCHAR_MAX); break;
				case GRAY_16:    reset8(*((ushort*) pixel) / (float)  USHRT_MAX); break;
				case GRAY_32:    reset8((float) (*((uint*) pixel) / (double) UINT_MAX)); break;
				case  RGB_888:   reset8(p[0], p[1], p[2]); break;
				case  RGBA_8888: reset8(p[0], p[1], p[2], p[3]); break;
				case ARGB_8888:  reset8(p[1], p[2], p[3], p[0]); break;
				case  RGBX_8888: reset8(p[0], p[1], p[2]); break;
				case XRGB_8888:  reset8(p[1], p[2], p[3]); break;
				case  BGR_888:   reset8(p[2], p[1], p[0]); break;
				case  BGRA_8888: reset8(p[2], p[1], p[0], p[3]); break;
				case ABGR_8888:  reset8(p[3], p[2], p[1], p[0]); break;
				case  BGRX_8888: reset8(p[2], p[1], p[0]); break;
				case XBGR_8888:  reset8(p[3], p[2], p[1]); break;
				default:         rays_error(__FILE__, __LINE__);
			}
		}

		return *this;
	}

	static float
	to_gray (const float* c)
	{
		return (c[0] + c[1] + c[2]) / 3;
	}

	static uint
	to_gray (const float* c, uint max)
	{
		return Xot::clip<uint>(0, max, to_gray(c) * max);
	}

	static void
	get_rgba (float* red, float* green, float* blue, float* alpha, const float* c)
	{
		if ((!red && !green && !blue && !alpha) || !c)
			argument_error(__FILE__, __LINE__);

		if (red)   *red   = c[0];
		if (green) *green = c[1];
		if (blue)  *blue  = c[2];
		if (alpha) *alpha = c[3];
	}

	static void
	get_rgba (uchar* red, uchar* green, uchar* blue, uchar* alpha, const float* c)
	{
		if ((!red && !green && !blue && !alpha) || !c)
			argument_error(__FILE__, __LINE__);

		if (red)   *red   = Color::float2uchar(c[0]);
		if (green) *green = Color::float2uchar(c[1]);
		if (blue)  *blue  = Color::float2uchar(c[2]);
		if (alpha) *alpha = Color::float2uchar(c[3]);
	}

	void
	Color::get (void* pixel, const ColorSpace& cs) const
	{
		if (!pixel || !cs)
			argument_error(__FILE__, __LINE__);

		const float* c = array;
		if (cs.is_float())
		{
			float* p = (float*) pixel;
			switch (cs.type())
			{
				case GRAY_float:  p[0] = to_gray(c); break;
				case  RGB_float:  get_rgba(p+0, p+1, p+2, NULL, c); break;
				case  RGBA_float: get_rgba(p+0, p+1, p+2, p+3,  c); break;
				case ARGB_float:  get_rgba(p+1, p+2, p+3, p+0,  c); break;
				case  BGR_float:  get_rgba(p+2, p+1, p+0, NULL, c); break;
				case  BGRA_float: get_rgba(p+2, p+1, p+0, p+3,  c); break;
				case ABGR_float:  get_rgba(p+3, p+2, p+1, p+0,  c); break;
				default:          rays_error(__FILE__, __LINE__);
			}
		}
		else
		{
			uchar* p = (uchar*) pixel;
			switch (cs.type())
			{
				case GRAY_8:  *(uchar*)  p = (uchar)  to_gray(c, UCHAR_MAX); break;
				case GRAY_16: *(ushort*) p = (ushort) to_gray(c, USHRT_MAX); break;
				case GRAY_32: *(uint*)   p = (uint)   to_gray(c, UINT_MAX);  break;
				case  RGB_888:   get_rgba(p+0, p+1, p+2, NULL, c); break;
				case  RGBA_8888: get_rgba(p+0, p+1, p+2, p+3,  c); break;
				case ARGB_8888:  get_rgba(p+1, p+2, p+3, p+0,  c); break;
				case  RGBX_8888: get_rgba(p+0, p+1, p+2, NULL, c); break;
				case XRGB_8888:  get_rgba(p+1, p+2, p+3, NULL, c); break;
				case  BGR_888:   get_rgba(p+2, p+1, p+0, NULL, c); break;
				case  BGRA_8888: get_rgba(p+2, p+1, p+0, p+3,  c); break;
				case ABGR_8888:  get_rgba(p+3, p+2, p+1, p+0,  c); break;
				case  BGRX_8888: get_rgba(p+2, p+1, p+0, NULL, c); break;
				case XBGR_8888:  get_rgba(p+3, p+2, p+1, NULL, c); break;
				default:         rays_error(__FILE__, __LINE__);
			}
		}
	}

	Color::operator bool () const
	{
		return alpha > 0;
	}

	bool
	Color::operator ! () const
	{
		return !operator bool();
	}

	bool
	operator == (const Color& lhs, const Color& rhs)
	{
		return lhs.r == rhs.r && lhs.g == rhs.g && lhs.b == rhs.b && lhs.a == rhs.a;
	}

	bool
	operator != (const Color& lhs, const Color& rhs)
	{
		return !operator==(lhs, rhs);
	}


}// Rays
