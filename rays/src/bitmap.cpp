#include "bitmap.h"


#include <algorithm>
#include "rays/exception.h"


namespace Rays
{


	template <typename Fun>
	static void
	each_alpha_pixel (Bitmap* bitmap, Fun fun)
	{
		if (!bitmap)
			argument_error(__FILE__, __LINE__);
		if (!*bitmap)
			argument_error(__FILE__, __LINE__);

		const ColorSpace& cs = bitmap->color_space();
		if (!cs.has_alpha() || cs.is_alpha())
			return;

		int width  = bitmap->width();
		int height = bitmap->height();
		int Bpp    = cs.Bpp();
		int apos   = cs.alpha_pos();

		for (int y = 0; y < height; ++y)
		{
			uchar* p = bitmap->at<uchar>(0, y);
			for (int x = 0; x < width; ++x, p += Bpp)
				fun(p, apos);
		}
	}

	void
	Bitmap_premultiply (Bitmap* bitmap)
	{
		if (bitmap && bitmap->color_space().is_float())
		{
			each_alpha_pixel(bitmap, [](uchar* p, int apos)
			{
				float* f = (float*) p;
				float a  = f[apos];
				for (int i = 0; i < 4; ++i)
					if (i != apos) f[i] *= a;
			});
		}
		else
		{
			each_alpha_pixel(bitmap, [](uchar* p, int apos)
			{
				uint a = p[apos];
				for (int i = 0; i < 4; ++i)
					if (i != apos) p[i] = (uchar) ((p[i] * a + 127) / 255);
			});
		}
	}

	void
	Bitmap_unpremultiply (Bitmap* bitmap)
	{
		if (bitmap && bitmap->color_space().is_float())
		{
			each_alpha_pixel(bitmap, [](uchar* p, int apos)
			{
				float* f = (float*) p;
				float a  = f[apos];
				if (a <= 0) return;
				for (int i = 0; i < 4; ++i)
					if (i != apos) f[i] = std::min(f[i] / a, 1.f);
			});
		}
		else
		{
			each_alpha_pixel(bitmap, [](uchar* p, int apos)
			{
				uint a = p[apos];
				if (a == 0) return;
				for (int i = 0; i < 4; ++i)
					if (i != apos) p[i] = (uchar) std::min<uint>((p[i] * 255 + a / 2) / a, 255);
			});
		}
	}


}// Rays
