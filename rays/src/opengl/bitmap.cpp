#include "../bitmap.h"


#include "rays/exception.h"
#include "../texture.h"
#include "opengl.h"
#include "color_space.h"
#include "frame_buffer.h"


namespace Rays
{


	Bitmap
	Bitmap_from (const Texture& tex)
	{
		if (!tex)
			argument_error(__FILE__, __LINE__);

		Bitmap bmp;
		Bitmap_setup(
			&bmp, tex.width(), tex.height(), tex.color_space(), NULL, false);

		GLenum format, type;
		ColorSpace_get_gl_format_and_type(&format, &type, tex.color_space());

		FrameBuffer fb(tex);
		FrameBufferBinder binder(fb.id());

		for (int y = 0; y < bmp.height(); ++y)
		{
			GLvoid* ptr = (GLvoid*) bmp.at<uchar>(0, y);
			glReadPixels(0, y, bmp.width(), 1, format, type, ptr);
		}

		return bmp;
	}


}// Rays
