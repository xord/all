#include "color_space.h"


#include <xot/util.h>
#include "rays/exception.h"


namespace Rays
{


	enum
	{

		          FIRST = GRAY_8,              LAST = ABGR_float,

		     GRAY_FIRST = GRAY_8,         GRAY_LAST = GRAY_float,

		    ALPHA_FIRST = ALPHA_8,       ALPHA_LAST = ALPHA_float,

		      RGB_FIRST = RGB_888,         RGB_LAST = ABGR_float,

		RGB_FLOAT_FIRST = RGB_float, RGB_FLOAT_LAST = ABGR_float,

	};


	ColorSpace::ColorSpace ()
	:	type_(COLORSPACE_UNKNOWN), premult(false)
	{
	}

	ColorSpace::ColorSpace (ColorSpaceType type, bool premultiplied)
	:	type_(type), premult(premultiplied)
	{
	}

	ColorSpaceType
	ColorSpace::type () const
	{
		return type_;
	}

	int
	ColorSpace::bpc () const
	{
		static const int BPPS[] =
		{
			0,                 // UNKNOWN
			8, 16, 24, 32, 32, // GRAY
			8, 16, 24, 32, 32, // ALPHA
			8, 8, 8, 8, 8,     // RGB(A),
			8, 8, 8, 8, 8,     // BGR(A)
			32, 32, 32,        // RGB(A) float
			32, 32, 32,        // BGR(A) float
		};
		if (type_ < 0 || COLORSPACE_MAX <= type_) return BPPS[COLORSPACE_UNKNOWN];
		return BPPS[type_];
	}

	int
	ColorSpace::Bpc () const
	{
		return Xot::bit2byte(bpc());
	}

	int
	ColorSpace::bpp () const
	{
		static const int BPPS[] =
		{
			0,                     // UNKNOWN
			8,  16,  24,  32,  32, // GRAY
			8,  16,  24,  32,  32, // ALPHA
			24, 32,  32,  32,  32, // RGB(A)
			24, 32,  32,  32,  32, // BGR(A)
			96, 128, 128,          // RGB(A) float
			96, 128, 128,          // BGR(A) float
		};
		if (type_ < 0 || COLORSPACE_MAX <= type_) return BPPS[COLORSPACE_UNKNOWN];
		return BPPS[type_];
	}

	int
	ColorSpace::Bpp () const
	{
		return Xot::bit2byte(bpp());
	}

	int
	ColorSpace::alpha_pos () const
	{
		return is_alpha_last() ? 3 : 0;
	}

	bool
	ColorSpace::is_gray () const
	{
		return GRAY_FIRST  <= (int) type_ && (int) type_ <= GRAY_LAST;
	}

	bool
	ColorSpace::is_alpha () const
	{
		return ALPHA_FIRST <= (int) type_ && (int) type_ <= ALPHA_LAST;
	}

	bool
	ColorSpace::is_rgb () const
	{
		return
			(RGB_888   <= type_ && type_ <= XRGB_8888) ||
			(RGB_float <= type_ && type_ <= ARGB_float);
	}

	bool
	ColorSpace::is_bgr () const
	{
		return
			(BGR_888   <= type_ && type_ <= XBGR_8888) ||
			(BGR_float <= type_ && type_ <= ABGR_float);
	}

	bool
	ColorSpace::is_float () const
	{
		return
			type_ == GRAY_float || type_ == ALPHA_float ||
			(RGB_FLOAT_FIRST <= (int) type_ && (int) type_ <= RGB_FLOAT_LAST);
	}

	bool
	ColorSpace::has_alpha () const
	{
		return
			(ALPHA_FIRST <= type_ && type_ <= ALPHA_LAST) ||
			type_ == RGBA_8888  || type_ == ARGB_8888  ||
			type_ == BGRA_8888  || type_ == ABGR_8888  ||
			type_ == RGBA_float || type_ == ARGB_float ||
			type_ == BGRA_float || type_ == ABGR_float;
	}

	bool
	ColorSpace::has_skip () const
	{
		return
			type_ == RGBX_8888  || type_ == XRGB_8888 ||
			type_ == BGRX_8888  || type_ == XBGR_8888;
	}

	bool
	ColorSpace::is_alpha_first () const
	{
		return
			type_ == ARGB_8888  || type_ == ABGR_8888 ||
			type_ == ARGB_float || type_ == ABGR_float;
	}

	bool
	ColorSpace::is_alpha_last () const
	{
		return
			type_ == RGBA_8888  || type_ == BGRA_8888 ||
			type_ == RGBA_float || type_ == BGRA_float;
	}

	bool
	ColorSpace::is_skip_first () const
	{
		return type_ == XRGB_8888  || type_ == XBGR_8888;
	}

	bool
	ColorSpace::is_skip_last () const
	{
		return type_ == RGBX_8888  || type_ == BGRX_8888;
	}

	bool
	ColorSpace::is_premult () const
	{
		return premult;
	}

	ColorSpace::operator bool () const
	{
		return FIRST <= (int) type_ && (int) type_ <= LAST;
	}

	bool
	ColorSpace::operator ! () const
	{
		return !operator bool();
	}


	void
	ColorSpace_get_gl_format_and_type (
		GLenum* format, GLenum* type, const ColorSpace& cs)
	{
		if (!format && !type)
			argument_error(__FILE__, __LINE__);

		if (!cs)
			invalid_state_error(__FILE__, __LINE__);

		if (format)
		{
			     if (cs.is_rgb())   *format = cs.has_alpha() ? GL_RGBA  : GL_RGB;
		#ifndef IOS
			else if (cs.is_bgr())   *format = cs.has_alpha() ? GL_BGRA  : GL_BGR;
		#endif
			else if (cs.is_gray())  *format = GL_LUMINANCE;
			else if (cs.is_alpha()) *format = GL_ALPHA;
			else
				rays_error(__FILE__, __LINE__, "invalid color space.");
		}

		if (type)
		{
			if (cs.is_float())
				*type = GL_FLOAT;
			else switch (cs.bpc())
			{
				case 8:  *type = GL_UNSIGNED_BYTE; break;
				case 16: *type = GL_UNSIGNED_SHORT; break;
			#ifndef IOS
				case 32: *type = GL_UNSIGNED_INT; break;
			#endif
				default:
					rays_error(__FILE__, __LINE__, "invalid bpc.");
			}
		}
	}


}// Rays
