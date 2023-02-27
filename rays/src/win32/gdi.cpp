#include "gdi.h"


#include <vector>


namespace Rays
{


	namespace Win32
	{


		typedef void (*DeleteHandleFunc) (HANDLE);


		static void
		delete_object (HANDLE handle)
		{
			DeleteObject(handle);
		}

		static void
		delete_dc (HANDLE handle)
		{
			DeleteDC((HDC) handle);
		}

		static void
		release_dc (HANDLE handle)
		{
			ReleaseDC(NULL, (HDC) handle);
		}


		template <typename HANDLE>
		class HandleObject
		{

			public:

				typedef HANDLE Handle;

				HandleObject (
					Handle handle = NULL, bool owner = true,
					DeleteHandleFunc delfun = delete_object)
				:	handle_(handle), delfun_(delfun)
				{
				}

				~HandleObject ()
				{
					reset();
				}

				void reset (
					Handle handle = NULL, bool owner = true,
					DeleteHandleFunc delfun = delete_object)
				{
					if (handle_ && delfun_) (*delfun_)(handle_);
					handle_ = handle;
					delfun_ = owner ? delfun : NULL;
				}

				Handle handle () const
				{
					return handle_;
				}

				operator bool () const
				{
					return !!handle_;
				}

				bool operator ! () const
				{
					return !operator bool();
				}

			private:

				Handle handle_;

				DeleteHandleFunc delfun_;

		};// HandleObject


		struct Pen::Data
		{

			HandleObject<HPEN> handle;

		};// Pen::Data


		Pen::Pen (HPEN handle, bool owner)
		{
			if (!handle) return;
			self->handle.reset(handle, owner);
		}

		Pen::Pen (int red, int green, int blue, int width, int style)
		{
			self->handle.reset(
				CreatePen(style, width, RGB(red, green, blue)));
		}

		Pen::~Pen ()
		{
		}

		bool
		Pen::get_color (int* red, int* green, int* blue) const
		{
			if (!*this || (!red && !green && !blue))
				return false;

			LOGPEN logpen;
			if (!GetObject(handle(), sizeof(logpen), &logpen))
				return false;

			if (red)   *red   = GetRValue(logpen.lopnColor);
			if (green) *green = GetGValue(logpen.lopnColor);
			if (blue)  *blue  = GetBValue(logpen.lopnColor);
			return true;
		}

		HPEN
		Pen::handle () const
		{
			return self->handle.handle();
		}

		Pen::operator bool () const
		{
			return !!self->handle;
		}

		bool
		Pen::operator ! () const
		{
			return !operator bool();
		}


		struct Brush::Data
		{

			HandleObject<HBRUSH> handle;

		};// Brush::Data


		Brush::Brush (HBRUSH handle, bool owner)
		{
			if (!handle) return;
			self->handle.reset(handle, owner);
		}

		Brush::Brush (int red, int green, int blue, int style)
		{
			LOGBRUSH logbrush = {0};
			logbrush.lbStyle = style;
			logbrush.lbColor = RGB(red, green, blue);
			logbrush.lbHatch = 0;

			self->handle.reset(CreateBrushIndirect(&logbrush));
		}

		Brush::~Brush ()
		{
		}

		bool
		Brush::get_color (int* red, int* green, int* blue) const
		{
			if (!*this || (!red && !green && !blue))
				return false;

			LOGBRUSH logbrush;
			if (!GetObject(handle(), sizeof(logbrush), &logbrush))
				return false;

			if (red)   *red   = GetRValue(logbrush.lbColor);
			if (green) *green = GetGValue(logbrush.lbColor);
			if (blue)  *blue  = GetBValue(logbrush.lbColor);
			return true;
		}

		HBRUSH
		Brush::handle () const
		{
			return self->handle.handle();
		}

		Brush::operator bool () const
		{
			return !!self->handle;
		}

		bool
		Brush::operator ! () const
		{
			return !operator bool();
		}


		struct Font::Data
		{

			HandleObject<HFONT> handle;

		};// Font::Data


		static HFONT
		create_font (const char* name, coord size = 0)
		{
			NONCLIENTMETRICSA metrics;
			memset(&metrics, 0, sizeof(metrics));
			metrics.cbSize = sizeof(metrics);

			if (!SystemParametersInfoA(
				SPI_GETNONCLIENTMETRICS, sizeof(metrics), &metrics, 0))
			{
				return NULL;
			}

			LOGFONTA& logfont = metrics.lfMessageFont;

			if (name)
				strcpy(logfont.lfFaceName, name);

			if (size == 0)
				logfont.lfHeight = 0;
			else
			{
				logfont.lfHeight = -MulDiv(
					size,
					GetDeviceCaps(screen_dc().handle(), LOGPIXELSY),
					72);
			}

			return CreateFontIndirectA(&logfont);
		}


		Font::Font (HFONT handle, bool owner)
		{
			if (!handle) return;
			self->handle.reset(handle, owner);
		}

		Font::Font (const char* name, coord size)
		{
			self->handle.reset(create_font(name, size));
		}

		Font::~Font ()
		{
		}

		static bool
		calc_size (
			coord* width, coord* height, HDC hdc, const char* str)
		{
			if (!width || !height || !hdc || !str) return false;

			bool empty = *str == '\0';
			if (empty) str = " ";

			RECT rect = {0, 0, 0, 0};
			int ret = DrawTextA(
				hdc, str, -1, &rect,
				DT_EXPANDTABS | DT_NOPREFIX | DT_CALCRECT);
			if (!ret) return false;

			*width  = empty ? 0 : rect.right  - rect.left;
			*height =             rect.bottom - rect.top;
			return true;
		}

		bool
		Font::get_extent (
			coord* width, coord* height, const char* str, HDC hdc)
		{
			if (!*this || (!width && !height))
				return false;

			if (width)  *width  = 0;
			if (height) *height = 0;

			DC dc = hdc ? DC(hdc) : screen_dc();
			if (!dc) return false;

			coord w = 0, h = 0;

			Font old = dc.font();
			dc.set_font(*this);
			bool ret = calc_size(&w, &h, dc.handle(), str);
			dc.set_font(old);

			if (width)  *width  = w;
			if (height) *height = h;

			return ret;
		}

		String
		Font::name () const
		{
			if (!*this) return "";

			LOGFONT logfont;
			int size = sizeof(logfont);
			if (GetObject(self->handle.handle(), size, &logfont) != size)
				return "";

			return logfont.lfFaceName;
		}

		coord
		Font::size () const
		{
			if (!*this) return 0;

			LOGFONT logfont;
			int size = sizeof(logfont);
			if (GetObject(self->handle.handle(), size, &logfont) != size)
				return 0;

			if (logfont.lfHeight >= 0)
				return logfont.lfHeight;

			if (logfont.lfHeight < 0)
			{
				return -MulDiv(
					logfont.lfHeight, 72,
					GetDeviceCaps(screen_dc().handle(), LOGPIXELSY));
			}
			else
				return logfont.lfHeight;
		}

		HFONT
		Font::handle () const
		{
			return self->handle.handle();
		}

		Font::operator bool () const
		{
			return !!self->handle;
		}

		bool
		Font::operator ! () const
		{
			return !operator bool();
		}


		struct Bitmap::Data
		{

			HandleObject<HBITMAP> handle;

		};// Bitmap::Data


#if 0
		static bool
		load_bitmap (uint id, HINSTANCE hinst = NULL)
		{
			if (!hinst) hinst = (HINSTANCE) GetModuleHandle(NULL);
			self->handle.reset(LoadBitmap(hinst, MAKEINTRESOURCE(id)));
			return !!self->handle;
		}
#endif

		Bitmap::Bitmap (HBITMAP handle, bool owner)
		{
			if (!handle) return;
			self->handle.reset(handle, owner);
		}

		Bitmap::Bitmap (HDC hdc, int width, int height)
		{
			self->handle.reset(CreateCompatibleBitmap(hdc, width, height));
		}

		Bitmap::~Bitmap ()
		{
		}

		int
		Bitmap::width () const
		{
			BITMAP bmp;
			if (!*this || !GetObject(handle(), sizeof(bmp), &bmp))
				return 0;
			return bmp.bmWidth;
		}

		int
		Bitmap::height () const
		{
			BITMAP bmp;
			if (!*this || !GetObject(handle(), sizeof(bmp), &bmp))
				return 0;
			return bmp.bmHeight;
		}

		HBITMAP
		Bitmap::handle () const
		{
			return self->handle.handle();
		}

		Bitmap::operator bool () const
		{
			return self->handle.handle();
		}

		bool
		Bitmap::operator ! () const
		{
			return !operator bool();
		}


		struct DCState
		{

			HPEN hpen;

			Pen pen;

			HBRUSH hbrush;

			Brush brush;

			HFONT hfont;

			Font font;

			HBITMAP hbitmap;

			Bitmap bitmap;

			COLORREF textcolor, backcolor;

			int backmode;

			DCState ()
			:	hpen(NULL), hbrush(NULL), hfont(NULL), hbitmap(NULL),
				textcolor(RGB(0, 0, 0)), backcolor(RGB(255, 255, 255)),
				backmode(OPAQUE)
			{
			}

			bool init (
				HDC hdc,
				const Pen&    pen_,
				const Brush&  brush_,
				const Font&   font_,
				const Bitmap& bitmap_)
			{
				if (!hdc) return false;

				pen       = pen_;
				brush     = brush_;
				font      = font_;
				bitmap    = bitmap_;
				hpen      = (HPEN)    GetCurrentObject(hdc, OBJ_PEN);
				hbrush    = (HBRUSH)  GetCurrentObject(hdc, OBJ_BRUSH);
				hfont     = (HFONT)   GetCurrentObject(hdc, OBJ_FONT);
				hbitmap   = (HBITMAP) GetCurrentObject(hdc, OBJ_BITMAP);
				textcolor = GetTextColor(hdc);
				backcolor = GetBkColor(hdc);
				backmode  = GetBkMode(hdc);
				return true;
			}

		};// DCState

		typedef std::vector<DCState> DCStateStack;


		struct DC::Data
		{

			HandleObject<HDC> handle;

			DCStateStack stack;

			Pen pen;

			Brush brush;

			Font font;

			Bitmap bitmap;

		};// DC::Data


		DC::DC (HDC handle, bool owner, DeleteType deltype)
		{
			if (!handle) return;

			DeleteHandleFunc delfun = NULL;
			switch (deltype)
			{
				case DELETE_DC:  delfun = delete_dc; break;
				case RELEASE_DC: delfun = release_dc; break;
			}

			self->handle.reset(handle, owner, delfun);
		}

		DC::~DC ()
		{
			assert(self->stack.empty());
		}

#if 0
		bool
		DC::get_text_size (coord* width, coord* height, const char* text)
		{
			return calc_text_size(width, height, text, handle());
		}
#endif

		Pen
		DC::pen () const
		{
			HPEN hpen = (HPEN) GetCurrentObject(handle(), OBJ_PEN);
			if (hpen == self->pen.handle())
				return self->pen;
			else
				return hpen;
		}

		bool
		DC::set_pen (const Pen& pen)
		{
			if (!*this) return false;
			SelectObject(handle(), pen.handle());
			self->pen = pen;
			return true;
		}

		Brush
		DC::brush () const
		{
			HBRUSH hbrush = (HBRUSH) GetCurrentObject(handle(), OBJ_BRUSH);
			if (hbrush == self->brush.handle())
				return self->brush;
			else
				return hbrush;
		}

		bool
		DC::set_brush (const Brush& brush)
		{
			if (!*this) return false;
			SelectObject(handle(), brush.handle());
			self->brush = brush;
			return true;
		}

		Font
		DC::font () const
		{
			HFONT hfont = (HFONT) GetCurrentObject(handle(), OBJ_FONT);
			if (hfont == self->font.handle())
				return self->font;
			else
				return hfont;
		}

		bool
		DC::set_font (const Font& font)
		{
			if (!*this) return false;
			SelectObject(handle(), font.handle());
			self->font = font;
			return true;
		}

		Bitmap
		DC::bitmap () const
		{
			HBITMAP hbmp = (HBITMAP) GetCurrentObject(handle(), OBJ_BITMAP);
			if (hbmp == self->bitmap.handle())
				return self->bitmap;
			else
				return hbmp;
		}

		bool
		DC::set_bitmap (const Bitmap& bitmap)
		{
			if (!*this) return false;
			SelectObject(handle(), bitmap.handle());
			self->bitmap = bitmap;
			return true;
		}

		COLORREF
		DC::text_color () const
		{
			return GetTextColor(handle());
		}

		bool
		DC::set_text_color (COLORREF color)
		{
			if (!*this) return false;
			SetTextColor(handle(), color);
			return true;
		}

		COLORREF
		DC::back_color () const
		{
			return GetBkColor(handle());
		}

		bool
		DC::set_back_color (COLORREF color)
		{
			if (!*this) return false;
			SetBkColor(handle(), color);
			return true;
		}

		int
		DC::back_mode () const
		{
			return GetBkMode(handle());
		}

		bool
		DC::set_back_mode (int mode)
		{
			if (!*this) return false;
			SetBkMode(handle(), mode);
			return true;
		}

		bool
		DC::push ()
		{
			if (!*this) return false;

			self->stack.push_back(DCState());
			return self->stack.back().init(
				self->handle.handle(),
				self->pen,
				self->brush,
				self->font,
				self->bitmap);
		}

		bool
		DC::pop ()
		{
			if (!*this || self->stack.empty()) return false;

			HDC hdc = self->handle.handle();
			DCState& state = self->stack.back();

			SelectObject(hdc, state.hpen);
			SelectObject(hdc, state.hbrush);
			SelectObject(hdc, state.hfont);
			SelectObject(hdc, state.hbitmap);
			SetTextColor(hdc, state.textcolor);
			SetBkColor(hdc,   state.backcolor);
			SetBkMode(hdc,    state.backmode);
			self->pen    = state.pen;
			self->brush  = state.brush;
			self->font   = state.font;
			self->bitmap = state.bitmap;

			self->stack.pop_back();
			return true;
		}

		HDC
		DC::handle () const
		{
			return self->handle.handle();
		}

		DC::operator bool () const
		{
			return !!self->handle;
		}

		bool
		DC::operator ! () const
		{
			return !operator bool();
		}


		struct MemoryDC::Data
		{

			Bitmap bitmap, old_bitmap;

		};// MemoryDC::Data


		MemoryDC::MemoryDC ()
		:	DC()
		{
		}

		MemoryDC::MemoryDC (HDC hdc, int width, int height)
		:	DC(CreateCompatibleDC(hdc), true)
		{
			Bitmap bmp = Bitmap(hdc, width, height);
			if (!bmp) return;

			self->bitmap     = bmp;
			self->old_bitmap = bitmap();

			set_bitmap(self->bitmap);
		}

		MemoryDC::MemoryDC (HDC hdc, const Bitmap& bmp)
		:	DC(CreateCompatibleDC(hdc), true)
		{
			if (!bmp) return;

			self->bitmap     = bmp;
			self->old_bitmap = bitmap();

			set_bitmap(self->bitmap);
		}

		MemoryDC::~MemoryDC ()
		{
			set_bitmap(self->old_bitmap);
		}

		const Bitmap&
		MemoryDC::bitmap () const
		{
			return self->bitmap;
		}

		MemoryDC::operator bool () const
		{
			return Super::operator bool() && self->bitmap;
		}

		bool
		MemoryDC::operator ! () const
		{
			return !operator bool();
		}


		DC
		screen_dc ()
		{
			return DC(GetDC(NULL), true, DC::RELEASE_DC);
		}


	}// Win32


}// Rays
