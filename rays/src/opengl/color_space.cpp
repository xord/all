#include "color_space.h"


#include "rays/exception.h"


namespace Rays
{


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
