#include "rays/ruby/bitmap.h"


#include "rays/ruby/color_space.h"
#include "rays/ruby/color.h"
#include "rays/ruby/font.h"
#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(RAYS_EXPORT, Rays::Bitmap)

#define THIS  to<Rays::Bitmap*>(self)

#define CHECK RUCY_CHECK_OBJECT(Rays::Bitmap, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Rays::Bitmap>(klass);
}
RUCY_END

static
RUCY_DEFN(initialize)
{
	RUCY_CHECK_OBJ(Rays::Bitmap, self);
	check_arg_count(__FILE__, __LINE__, "Bitmap#initialize", argc, 2, 3);

	*THIS = Rays::Bitmap(
		to<int>(argv[0]), to<int>(argv[1]),
		argc >= 3 ? to<Rays::ColorSpace>(argv[2]) : Rays::RGBA);

	return self;
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	RUCY_CHECK_OBJ(Rays::Bitmap, self);

	*THIS = to<Rays::Bitmap&>(obj).dup();
	return self;
}
RUCY_END

static
RUCY_DEF0(width)
{
	CHECK;

	return value(THIS->width());
}
RUCY_END

static
RUCY_DEF0(height)
{
	CHECK;

	return value(THIS->height());
}
RUCY_END

static
RUCY_DEF0(color_space)
{
	CHECK;

	return value(THIS->color_space());
}
RUCY_END

static void
set_pixels (Rays::Bitmap* bmp, Value pixels)
{
	int w = bmp->width(), h = bmp->height();
	const auto& cs = bmp->color_space();
	if (pixels.size() != (w * h * (cs.is_float() ? cs.Bpp() / cs.Bpc() : 1)))
	{
		argument_error(
			__FILE__, __LINE__,
			"The size of the pixel array does not match the size of the bitmap");
	}

	const Value* array = pixels.as_array();

	switch (cs.type())
	{
		case Rays::GRAY_8:
		case Rays::ALPHA_8:
			for (int y = 0; y < h; ++y)
			{
				const Value* pa = &array[w * y];
				auto* pb        = bmp->at<uint8_t>(0, y);
				for (int x = 0; x < w; ++x, ++pa, ++pb)
					*pb = to<uint8_t>(*pa);
			}
			break;

		case Rays::GRAY_16:
		case Rays::ALPHA_16:
			for (int y = 0; y < h; ++y)
			{
				const Value* pa = &array[w * y];
				auto* pb        = bmp->at<uint16_t>(0, y);
				for (int x = 0; x < w; ++x, ++pa, ++pb)
					*pb = to<uint16_t>(*pa);
			}
			break;

		case Rays::GRAY_32:
		case Rays::ALPHA_32:
			for (int y = 0; y < h; ++y)
			{
				const Value* pa = &array[w * y];
				auto* pb        = bmp->at<uint32_t>(0, y);
				for (int x = 0; x < w; ++x, ++pa, ++pb)
					*pb = to<uint32_t>(*pa);
			}
			break;

		case Rays::GRAY_float:
		case Rays::ALPHA_float:
			for (int y = 0; y < h; ++y)
			{
				const Value* pa = &array[w * y];
				auto* pb        = bmp->at<float>(0, y);
				for (int x = 0; x < w; ++x, ++pa, ++pb)
					*pb = to<float>(*pa);
			}
			break;

		case Rays::RGB_888:
			for (int y = 0; y < h; ++y)
			{
				const Value* pa = &array[w * y];
				auto* pb        = bmp->at<uint8_t>(0, y);
				for (int x = 0; x < w; ++x, ++pa, pb += 3)
				{
					uint32_t argb = to<uint32_t>(*pa);
					pb[0] = (uint8_t) (argb >> 16 & 0xff);
					pb[1] = (uint8_t) (argb >> 8  & 0xff);
					pb[2] = (uint8_t) (argb >> 0  & 0xff);
				}
			}
			break;

		case Rays::RGBA_8888:
		case Rays::RGBX_8888:
			for (int y = 0; y < h; ++y)
			{
				const Value* pa = &array[w * y];
				auto* pb        = bmp->at<uint8_t>(0, y);
				for (int x = 0; x < w; ++x, ++pa, pb += 4)
				{
					uint32_t argb = to<uint32_t>(*pa);
					pb[0] = (uint8_t) (argb >> 16 & 0xff);
					pb[1] = (uint8_t) (argb >> 8  & 0xff);
					pb[2] = (uint8_t) (argb >> 0  & 0xff);
					pb[3] = (uint8_t) (argb >> 24 & 0xff);
				}
			}
			break;

		case Rays::ARGB_8888:
		case Rays::XRGB_8888:
			for (int y = 0; y < h; ++y)
			{
				const Value* pa = &array[w * y];
				auto* pb        = bmp->at<uint8_t>(0, y);
				for (int x = 0; x < w; ++x, ++pa, pb += 4)
				{
					uint32_t argb = to<uint32_t>(*pa);
					pb[0] = (uint8_t) (argb >> 24 & 0xff);
					pb[1] = (uint8_t) (argb >> 16 & 0xff);
					pb[2] = (uint8_t) (argb >> 8  & 0xff);
					pb[3] = (uint8_t) (argb >> 0  & 0xff);
				}
			}
			break;

		case Rays::BGR_888:
			for (int y = 0; y < h; ++y)
			{
				const Value* pa = &array[w * y];
				auto* pb        = bmp->at<uint8_t>(0, y);
				for (int x = 0; x < w; ++x, ++pa, pb += 3)
				{
					uint32_t argb = to<uint32_t>(*pa);
					pb[0] = (uint8_t) (argb >> 0  & 0xff);
					pb[1] = (uint8_t) (argb >> 8  & 0xff);
					pb[2] = (uint8_t) (argb >> 16 & 0xff);
				}
			}
			break;

		case Rays::BGRA_8888:
		case Rays::BGRX_8888:
			for (int y = 0; y < h; ++y)
			{
				const Value* pa = &array[w * y];
				auto* pb        = bmp->at<uint8_t>(0, y);
				for (int x = 0; x < w; ++x, ++pa, pb += 4)
				{
					uint32_t argb = to<uint32_t>(*pa);
					pb[0] = (uint8_t) (argb >> 0  & 0xff);
					pb[1] = (uint8_t) (argb >> 8  & 0xff);
					pb[2] = (uint8_t) (argb >> 16 & 0xff);
					pb[3] = (uint8_t) (argb >> 24 & 0xff);
				}
			}
			break;

		case Rays::ABGR_8888:
		case Rays::XBGR_8888:
			for (int y = 0; y < h; ++y)
			{
				const Value* pa = &array[w * y];
				auto* pb        = bmp->at<uint8_t>(0, y);
				for (int x = 0; x < w; ++x, ++pa, pb += 4)
				{
					uint32_t argb = to<uint32_t>(*pa);
					pb[0] = (uint8_t) (argb >> 24 & 0xff);
					pb[1] = (uint8_t) (argb >> 0  & 0xff);
					pb[2] = (uint8_t) (argb >> 8  & 0xff);
					pb[3] = (uint8_t) (argb >> 16 & 0xff);
				}
			}
			break;

		case Rays::RGB_float:
			for (int y = 0; y < h; ++y)
			{
				const Value* pa = &array[3 * w * y];
				auto* pb        = bmp->at<float>(0, y);
				for (int x = 0; x < w; ++x, pa += 3, pb += 3)
				{
					pb[0] = to<float>(pa[0]);
					pb[1] = to<float>(pa[1]);
					pb[2] = to<float>(pa[2]);
				}
			}
			break;

		case Rays::RGBA_float:
			for (int y = 0; y < h; ++y)
			{
				const Value* pa = &array[4 * w * y];
				auto* pb        = bmp->at<float>(0, y);
				for (int x = 0; x < w; ++x, pa += 4, pb += 4)
				{
					pb[0] = to<float>(pa[0]);
					pb[1] = to<float>(pa[1]);
					pb[2] = to<float>(pa[2]);
					pb[3] = to<float>(pa[3]);
				}
			}
			break;

		case Rays::ARGB_float:
			for (int y = 0; y < h; ++y)
			{
				const Value* pa = &array[4 * w * y];
				auto* pb        = bmp->at<float>(0, y);
				for (int x = 0; x < w; ++x, pa += 4, pb += 4)
				{
					pb[0] = to<float>(pa[3]);
					pb[1] = to<float>(pa[0]);
					pb[2] = to<float>(pa[1]);
					pb[3] = to<float>(pa[2]);
				}
			}
			break;

		case Rays::BGR_float:
			for (int y = 0; y < h; ++y)
			{
				const Value* pa = &array[3 * w * y];
				auto* pb        = bmp->at<float>(0, y);
				for (int x = 0; x < w; ++x, pa += 3, pb += 3)
				{
					pb[0] = to<float>(pa[2]);
					pb[1] = to<float>(pa[1]);
					pb[2] = to<float>(pa[0]);
				}
			}
			break;

		case Rays::BGRA_float:
			for (int y = 0; y < h; ++y)
			{
				const Value* pa = &array[4 * w * y];
				auto* pb        = bmp->at<float>(0, y);
				for (int x = 0; x < w; ++x, pa += 4, pb += 4)
				{
					pb[0] = to<float>(pa[2]);
					pb[1] = to<float>(pa[1]);
					pb[2] = to<float>(pa[0]);
					pb[3] = to<float>(pa[3]);
				}
			}
			break;

		case Rays::ABGR_float:
			for (int y = 0; y < h; ++y)
			{
				const Value* pa = &array[4 * w * y];
				auto* pb        = bmp->at<float>(0, y);
				for (int x = 0; x < w; ++x, pa += 4, pb += 4)
				{
					pb[0] = to<float>(pa[3]);
					pb[1] = to<float>(pa[2]);
					pb[2] = to<float>(pa[1]);
					pb[3] = to<float>(pa[0]);
				}
			}
			break;

		default:
			argument_error(__FILE__, __LINE__);
	}
}

static inline Value
to_rgb_value (uint8_t r, uint8_t g, uint8_t b)
{
	return value(
		((uint) r) << 16 |
		((uint) g) << 8  |
		((uint) b));
}

static inline Value
to_argb_value (uint8_t r, uint8_t g, uint8_t b, uint8_t a)
{
	return value(
		((uint) a) << 24 |
		((uint) r) << 16 |
		((uint) g) << 8  |
		((uint) b));
}

static void
get_pixels (auto* pixels, const Rays::Bitmap& bmp)
{
	int w = bmp.width(), h = bmp.height();
	const auto& cs = bmp.color_space();

	pixels->clear();
	pixels->reserve(w * h * (cs.is_float() ? cs.Bpp() / cs.Bpc() : 1));

	switch (cs.type())
	{
		case Rays::GRAY_8:
		case Rays::ALPHA_8:
			for (int y = 0; y < h; ++y)
			{
				const auto* p = bmp.at<uint8_t>(0, y);
				for (int x = 0; x < w; ++x, ++p)
					pixels->push_back(value(*p));
			}
			break;

		case Rays::GRAY_16:
		case Rays::ALPHA_16:
			for (int y = 0; y < h; ++y)
			{
				const auto* p = bmp.at<uint16_t>(0, y);
				for (int x = 0; x < w; ++x, ++p)
					pixels->push_back(value(*p));
			}
			break;

		case Rays::GRAY_32:
		case Rays::ALPHA_32:
			for (int y = 0; y < h; ++y)
			{
				const auto* p = bmp.at<uint32_t>(0, y);
				for (int x = 0; x < w; ++x, ++p)
					pixels->push_back(value(*p));
			}
			break;

		case Rays::GRAY_float:
		case Rays::ALPHA_float:
			for (int y = 0; y < h; ++y)
			{
				const auto* p = bmp.at<float>(0, y);
				for (int x = 0; x < w; ++x, ++p)
					pixels->push_back(value(*p));
			}
			break;

		case Rays::RGB_888:
			for (int y = 0; y < h; ++y)
			{
				const auto* p = bmp.at<uint8_t>(0, y);
				for (int x = 0; x < w; ++x, p += 3)
					pixels->push_back(to_rgb_value(p[0], p[1], p[2]));
			}
			break;

		case Rays::RGBA_8888:
		case Rays::RGBX_8888:
			for (int y = 0; y < h; ++y)
			{
				const auto* p = bmp.at<uint8_t>(0, y);
				for (int x = 0; x < w; ++x, p += 4)
					pixels->push_back(to_argb_value(p[0], p[1], p[2], p[3]));
			}
			break;

		case Rays::ARGB_8888:
		case Rays::XRGB_8888:
			for (int y = 0; y < h; ++y)
			{
				const auto* p = bmp.at<uint8_t>(0, y);
				for (int x = 0; x < w; ++x, p += 4)
					pixels->push_back(to_argb_value(p[1], p[2], p[3], p[0]));
			}
			break;

		case Rays::BGR_888:
			for (int y = 0; y < h; ++y)
			{
				const auto* p = bmp.at<uint8_t>(0, y);
				for (int x = 0; x < w; ++x, p += 3)
					pixels->push_back(to_rgb_value(p[2], p[1], p[0]));
			}
			break;

		case Rays::BGRA_8888:
		case Rays::BGRX_8888:
			for (int y = 0; y < h; ++y)
			{
				const auto* p = bmp.at<uint8_t>(0, y);
				for (int x = 0; x < w; ++x, p += 4)
					pixels->push_back(to_argb_value(p[2], p[1], p[0], p[3]));
			}
			break;

		case Rays::ABGR_8888:
		case Rays::XBGR_8888:
			for (int y = 0; y < h; ++y)
			{
				const auto* p = bmp.at<uint8_t>(0, y);
				for (int x = 0; x < w; ++x, p += 4)
					pixels->push_back(to_argb_value(p[3], p[2], p[1], p[0]));
			}
			break;

		case Rays::RGB_float:
			for (int y = 0; y < h; ++y)
			{
				const auto* p = bmp.at<float>(0, y);
				for (int x = 0; x < w; ++x, p += 3)
				{
					pixels->push_back(value(p[0]));
					pixels->push_back(value(p[1]));
					pixels->push_back(value(p[2]));
				}
			}
			break;

		case Rays::RGBA_float:
			for (int y = 0; y < h; ++y)
			{
				const auto* p = bmp.at<float>(0, y);
				for (int x = 0; x < w; ++x, p += 4)
				{
					pixels->push_back(value(p[0]));
					pixels->push_back(value(p[1]));
					pixels->push_back(value(p[2]));
					pixels->push_back(value(p[3]));
				}
			}
			break;

		case Rays::ARGB_float:
			for (int y = 0; y < h; ++y)
			{
				const auto* p = bmp.at<float>(0, y);
				for (int x = 0; x < w; ++x, p += 4)
				{
					pixels->push_back(value(p[1]));
					pixels->push_back(value(p[2]));
					pixels->push_back(value(p[3]));
					pixels->push_back(value(p[0]));
				}
			}
			break;

		case Rays::BGR_float:
			for (int y = 0; y < h; ++y)
			{
				const auto* p = bmp.at<float>(0, y);
				for (int x = 0; x < w; ++x, p += 3)
				{
					pixels->push_back(value(p[2]));
					pixels->push_back(value(p[1]));
					pixels->push_back(value(p[0]));
				}
			}
			break;

		case Rays::BGRA_float:
			for (int y = 0; y < h; ++y)
			{
				const auto* p = bmp.at<float>(0, y);
				for (int x = 0; x < w; ++x, p += 4)
				{
					pixels->push_back(value(p[2]));
					pixels->push_back(value(p[1]));
					pixels->push_back(value(p[0]));
					pixels->push_back(value(p[3]));
				}
			}
			break;

		case Rays::ABGR_float:
			for (int y = 0; y < h; ++y)
			{
				const auto* p = bmp.at<float>(0, y);
				for (int x = 0; x < w; ++x, p += 4)
				{
					pixels->push_back(value(p[3]));
					pixels->push_back(value(p[2]));
					pixels->push_back(value(p[1]));
					pixels->push_back(value(p[0]));
				}
			}
			break;

		default:
			argument_error(__FILE__, __LINE__);
	}
}

static
RUCY_DEF1(set_pixels, pixels)
{
	CHECK;

	if (sizeof(VALUE) <= 4)
	{
		not_implemented_error(
			__FILE__, __LINE__, "Bitmap#pixels=() does not support 32-bit platforms");
	}

	set_pixels(THIS, pixels);
	return pixels;
}
RUCY_END

static
RUCY_DEF0(get_pixels)
{
	CHECK;

	if (sizeof(VALUE) <= 4)
	{
		not_implemented_error(
			__FILE__, __LINE__, "Bitmap#pixels() does not support 32-bit platforms");
	}

	std::vector<VALUE> pixels;
	get_pixels(&pixels, *THIS);
	return array((const Value*) &pixels[0], pixels.size());
}
RUCY_END

static
RUCY_DEF3(set_at, x, y, color)
{
	CHECK;

	bool is_array     = color.is_array();
	size_t argc       = is_array ? color.size()     : 1;
	const Value* argv = is_array ? color.as_array() : &color;
	to<Rays::Color>(argc, argv)
		.get(THIS->at<void>(to<int>(x), to<int>(y)), THIS->color_space());

	return color;
}
RUCY_END

static
RUCY_DEF2(get_at, x, y)
{
	CHECK;

	int xx = to<int>(x);
	int yy = to<int>(y);
	return value(Rays::Color(THIS->at<void>(xx, yy), THIS->color_space()));
}
RUCY_END


static Class cBitmap;

void
Init_rays_bitmap ()
{
	Module mRays = define_module("Rays");

	cBitmap = mRays.define_class("Bitmap");
	cBitmap.define_alloc_func(alloc);
	cBitmap.define_private_method("initialize",      initialize);
	cBitmap.define_private_method("initialize_copy", initialize_copy);
	cBitmap.define_method("width",  width);
	cBitmap.define_method("height", height);
	cBitmap.define_method("color_space", color_space);
	cBitmap.define_method("pixels=", set_pixels);
	cBitmap.define_method("pixels",  get_pixels);
	cBitmap.define_method("[]=", set_at);
	cBitmap.define_method("[]",  get_at);
}


namespace Rays
{


	Class
	bitmap_class ()
	{
		return cBitmap;
	}


}// Rays
