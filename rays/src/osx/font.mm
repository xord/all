// -*- objc -*-
#include "../font.h"


#include <ApplicationServices/ApplicationServices.h>
#include "rays/exception.h"
#include "helper.h"


namespace Rays
{


	struct RawFont::Data
	{

		CTFontRef font;

		Data ()
		:	font(NULL)
		{
		}

		~Data ()
		{
			if (font)
			{
				CFRelease(font);
				font = NULL;
			}
		}

	};// RawFont::Data


	static CTLineRef
	make_line (CTFontRef font, const char* str)
	{
		if (!font || !str || *str == '\0')
			return NULL;

		CFStringRef keys[] = {
			kCTFontAttributeName,
			kCTForegroundColorFromContextAttributeName
		};
		CFTypeRef values[] = {
			font,
			kCFBooleanTrue
		};
		size_t nkeys = sizeof(keys) / sizeof(keys[0]);

		CFDictionaryRef attr = CFDictionaryCreate(
			NULL, (const void**) &keys, (const void**) &values, nkeys,
			&kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

		CFAttributedStringRef attrstr = CFAttributedStringCreate(
			NULL, cfstring(str).get(), attr);
		CFRelease(attr);

		CTLineRef line = CTLineCreateWithAttributedString(attrstr);
		CFRelease(attrstr);

		return line;
	}


	RawFont::RawFont ()
	{
	}

	RawFont::RawFont (const char* name, coord size)
	{
		self->font = name
			?	CTFontCreateWithName(cfstring(name).get(), size, NULL)
			:	CTFontCreateUIFontForLanguage(kCTFontUIFontSystem, size, NULL);
	}

	RawFont::~RawFont ()
	{
	}

	void
	RawFont::draw_string (
		void* context_, coord context_height,
		const char* str, coord x, coord y) const
	{
		CGContextRef context = (CGContextRef) context_;

		if (!*this || !context || !str)
			argument_error(__FILE__, __LINE__);

		if (*str == '\0') return;

		CTLineRef line = make_line(self->font, str);
		if (!line)
			rays_error(__FILE__, __LINE__, "creating CTLineRef failed.");

		coord width = 0, height = 0, ascent = 0;
		width  = get_width(str);
		height = get_height(&ascent);

		height = ceil(height);
		ascent = floor(ascent);

		CGRect rect = CGRectMake(x, context_height - height - y, width, height);
		CGContextClearRect(context, rect);
		CGContextSetRGBFillColor(context, 1, 1, 1, 1);

		CGContextSaveGState(context);
		CGContextSetTextMatrix(context, CGAffineTransformIdentity);
		CGContextSetTextPosition(context, x, context_height - ascent - y);
		CTLineDraw(line, context);
		CGContextRestoreGState(context);

		CFRelease(line);
	}

	String
	RawFont::name () const
	{
		if (!*this) return "";

		CFStringRef str = CTFontCopyFullName(self->font);

		enum {BUFSIZE = 2048};
		char buf[BUFSIZE + 1];
		if (!CFStringGetCString(str, buf, BUFSIZE, kCFStringEncodingUTF8))
			buf[0] = '\0';

		CFRelease(str);
		return buf;
	}

	coord
	RawFont::size () const
	{
		if (!*this) return 0;
		return CTFontGetSize(self->font);
	}

	coord
	RawFont::get_width (const char* str) const
	{
		if (!str)
			argument_error(__FILE__, __LINE__);

		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		if (*str == '\0') return 0;

		CTLineRef line = make_line(self->font, str);
		if (!line)
			rays_error(__FILE__, __LINE__, "creating CTLineRef failed.");

		coord w = CTLineGetTypographicBounds(line, NULL, NULL, NULL);
		CFRelease(line);

		return w;
	}

	coord
	RawFont::get_height (coord* ascent, coord* descent, coord* leading) const
	{
		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		CGFloat asc  = CTFontGetAscent(self->font);
		CGFloat desc = CTFontGetDescent(self->font);
		CGFloat lead = CTFontGetLeading(self->font);

		if (ascent)  *ascent  = asc;
		if (descent) *descent = desc;
		if (leading) *leading = lead;

		return asc + desc + lead;
	}

	RawFont::operator bool () const
	{
		return !!self->font;
	}

	bool
	RawFont::operator ! () const
	{
		return !operator bool();
	}


}// Rays
