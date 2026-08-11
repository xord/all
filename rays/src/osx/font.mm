// -*- objc -*-
#include "../font.h"


#include <memory>
#import <ApplicationServices/ApplicationServices.h>
#import <AppKit/AppKit.h>
#include <xot/string.h>
#include "rays/exception.h"


namespace Rays
{


	typedef std::shared_ptr<const __CFDictionary>       CFDictionaryPtr;

	typedef std::shared_ptr<const __CFAttributedString> CFAttributedStringPtr;

	typedef std::shared_ptr<const __CTFontDescriptor>   CTFontDescriptorPtr;

	typedef std::shared_ptr<CGDataProvider>             CGDataProviderPtr;

	typedef std::shared_ptr<CGFont>                     CGFontPtr;

	typedef std::shared_ptr<const __CTLine>             CTLinePtr;


	struct RawFont::Data
	{

		CTFontRef font = NULL;

		~Data ()
		{
			if (font)
			{
				CFRelease(font);
				font = NULL;
			}
		}

	};// RawFont::Data


	static const struct {int weight; CGFloat native;} NATIVE_WEIGHTS[] =
	{
		{Font::WEIGHT_MIN,        -1.0},
		{Font::WEIGHT_THIN,       NSFontWeightUltraLight},
		{Font::WEIGHT_EXTRALIGHT, NSFontWeightThin},
		{Font::WEIGHT_LIGHT,      NSFontWeightLight},
		{Font::WEIGHT_NORMAL,     NSFontWeightRegular},
		{Font::WEIGHT_MEDIUM,     NSFontWeightMedium},
		{Font::WEIGHT_SEMIBOLD,   NSFontWeightSemibold},
		{Font::WEIGHT_BOLD,       NSFontWeightBold},
		{Font::WEIGHT_EXTRABOLD,  NSFontWeightHeavy},
		{Font::WEIGHT_BLACK,      NSFontWeightBlack},
		{Font::WEIGHT_MAX,        1.0}
	};

	static CGFloat
	to_native_weight (int weight)
	{
		size_t last = sizeof(NATIVE_WEIGHTS) / sizeof(NATIVE_WEIGHTS[0]) - 1;
		for (size_t i = 1; i <= last; ++i)
		{
			if (weight > NATIVE_WEIGHTS[i].weight) continue;

			const auto& lo = NATIVE_WEIGHTS[i - 1];
			const auto& hi = NATIVE_WEIGHTS[i];
			CGFloat t      = (CGFloat) (weight - lo.weight) / (hi.weight - lo.weight);
			return lo.native + (hi.native - lo.native) * t;
		}
		return NATIVE_WEIGHTS[last].native;
	}

	static CTFontRef
	create_styled_font (CTFontRef base, coord size, int weight, bool italic)
	{
		Xot::CFStringPtr family(CTFontCopyFamilyName(base), CFRelease);
		if (!family) return NULL;

		NSDictionary* traits     =
		@{
			(id) kCTFontWeightTrait:   @(to_native_weight(weight)),
			(id) kCTFontSymbolicTrait: @(italic ? kCTFontTraitItalic : 0)
		};
		NSDictionary* attributes =
		@{
			(id) kCTFontFamilyNameAttribute: (__bridge NSString*) family.get(),
			(id) kCTFontTraitsAttribute:     traits
		};

		CTFontDescriptorPtr descriptor(
			CTFontDescriptorCreateWithAttributes((__bridge CFDictionaryRef) attributes),
			CFRelease);
		if (!descriptor) return NULL;

		return CTFontCreateWithFontDescriptor(descriptor.get(), size, NULL);
	}


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
			CFAttributedStringCreate(NULL, Xot::String(str).to_cfstr().get(), attr.get()),
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
		return rawfont;
	}


	RawFont::RawFont ()
	{
	}

	RawFont::RawFont (const char* name, coord size, int weight, bool italic)
	{
		CTFontRef font = name
			?	CTFontCreateWithName(Xot::String(name).to_cfstr().get(), size, NULL)
			:	CTFontCreateUIFontForLanguage(kCTFontUIFontSystem, size, NULL);

		if (font && (weight != Font::WEIGHT_NORMAL || italic))
		{
			CTFontRef styled = create_styled_font(font, size, weight, italic);
			if (styled)
			{
				CFRelease(font);
				font = styled;
			}
		}

		self->font = font;
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

		if (!context)
			argument_error(__FILE__, __LINE__);
		if (!str)
			argument_error(__FILE__, __LINE__);

		if (*str == '\0') return;

		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

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

		Xot::CFStringPtr str(CTFontCopyFullName(self->font), CFRelease);
		return Xot::to_s(str);
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
