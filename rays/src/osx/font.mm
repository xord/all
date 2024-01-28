// -*- objc -*-
#include "../font.h"


#include <memory>
#import <ApplicationServices/ApplicationServices.h>
#import <AppKit/AppKit.h>
#include "rays/exception.h"
#include "helper.h"


namespace Rays
{


	typedef std::shared_ptr<const __CFDictionary>       CFDictionaryPtr;

	typedef std::shared_ptr<const __CFAttributedString> CFAttributedStringPtr;

	typedef std::shared_ptr<CGDataProvider>             CGDataProviderPtr;

	typedef std::shared_ptr<CGFont>                     CGFontPtr;

	typedef std::shared_ptr<const __CTLine>             CTLinePtr;


	struct RawFont::Data
	{

		CTFontRef font = NULL;

		String path;

		~Data ()
		{
			if (font)
			{
				CFRelease(font);
				font = NULL;
			}
		}

	};// RawFont::Data


	static CTLinePtr
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

		CFDictionaryPtr attr(
			CFDictionaryCreate(
				NULL, (const void**) &keys, (const void**) &values, nkeys,
				&kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks),
			CFRelease);

		CFAttributedStringPtr attrstr(
			CFAttributedStringCreate(NULL, cfstring(str).get(), attr.get()),
			CFRelease);

		return CTLinePtr(
			CTLineCreateWithAttributedString(attrstr.get()),
			CFRelease);
	}

	const FontFamilyMap&
	get_font_families ()
	{
		static const FontFamilyMap MAP = []() {
			NSFontManager* fm = NSFontManager.sharedFontManager;

			FontFamilyMap map;
			for (NSString* family in fm.availableFontFamilies)
			{
				FontFamilyMap::mapped_type array;
				for (NSArray<NSString*>* members in [fm availableMembersOfFontFamily: family])
					array.emplace_back(members[0].UTF8String);
				map[family.UTF8String] = array;
			}
			return map;
		}();
		return MAP;
	}

	RawFont
	RawFont_load (const char* path, coord size)
	{
		if (!path)
			argument_error(__FILE__, __LINE__);

		CGDataProviderPtr data_provider(
			CGDataProviderCreateWithFilename(path),
			CGDataProviderRelease);
		if (!data_provider)
			rays_error(__FILE__, __LINE__, "failed to create CGDataProvider");

		CGFontPtr cgfont(
			CGFontCreateWithDataProvider(data_provider.get()),
			CGFontRelease);
		if (!cgfont)
			rays_error(__FILE__, __LINE__, "failed to create CGFont");

		CTFontRef ctfont = CTFontCreateWithGraphicsFont(
			cgfont.get(), size, NULL, NULL);
		if (!ctfont)
			rays_error(__FILE__, __LINE__, "failed to create CTFont");

		RawFont rawfont;
		rawfont.self->font = ctfont;
		rawfont.self->path = path;
		return rawfont;
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

	RawFont::RawFont (const This& obj, coord size)
	{
		const char* path = obj.self->path.empty() ? NULL : obj.self->path.c_str();
		if (path)
			*this = RawFont_load(path, size);
		else
			self->font = CTFontCreateWithName(cfstring(obj.name()).get(), size, NULL);
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

		CTLinePtr line = make_line(self->font, str);
		if (!line)
			rays_error(__FILE__, __LINE__, "creating CTLineRef failed.");

		coord width, height, ascent = 0;
		width  = ceil(get_width(str));
		height = ceil(get_height(&ascent));
		ascent = floor(ascent);

		CGRect rect = CGRectMake(x, context_height - height - y, width, height);
		CGContextClearRect(context, rect);
		CGContextSetRGBFillColor(context, 1, 1, 1, 1);

		CGContextSaveGState(context);
		CGContextSetTextMatrix(context, CGAffineTransformIdentity);
		CGContextSetTextPosition(context, x, context_height - ascent - y);
		CTLineDraw(line.get(), context);
		CGContextRestoreGState(context);
	}

	String
	RawFont::name () const
	{
		if (!*this) return "";

		CFStringPtr str(CTFontCopyFullName(self->font), CFRelease);

		enum {BUFSIZE = 2048};
		char buf[BUFSIZE + 1];
		if (!CFStringGetCString(str.get(), buf, BUFSIZE, kCFStringEncodingUTF8))
			buf[0] = '\0';

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

		CTLinePtr line = make_line(self->font, str);
		if (!line)
			rays_error(__FILE__, __LINE__, "creating CTLineRef failed.");

		return CTLineGetTypographicBounds(line.get(), NULL, NULL, NULL);
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
