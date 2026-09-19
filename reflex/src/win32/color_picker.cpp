#include "../color_picker.h"


#include <xot/windows.h>
#include <commdlg.h>
#include "reflex/exception.h"
#include "window.h"


namespace Reflex
{


	// the custom color slots of the dialog live as long as the process
	static COLORREF custom_colors[16] =
	{
		RGB(255, 255, 255), RGB(255, 255, 255), RGB(255, 255, 255), RGB(255, 255, 255),
		RGB(255, 255, 255), RGB(255, 255, 255), RGB(255, 255, 255), RGB(255, 255, 255),
		RGB(255, 255, 255), RGB(255, 255, 255), RGB(255, 255, 255), RGB(255, 255, 255),
		RGB(255, 255, 255), RGB(255, 255, 255), RGB(255, 255, 255), RGB(255, 255, 255)
	};


	static BYTE
	to_byte (float value)
	{
		if (value < 0) value = 0;
		if (value > 1) value = 1;
		return (BYTE) (value * 255 + 0.5f);
	}

	static COLORREF
	to_colorref (const Color& color)
	{
		return RGB(to_byte(color.red), to_byte(color.green), to_byte(color.blue));
	}

	static Color
	to_color (COLORREF colorref)
	{
		return Color(
			GetRValue(colorref) / 255.f,
			GetGValue(colorref) / 255.f,
			GetBValue(colorref) / 255.f);
	}

	void
	ColorPicker_show (ColorPicker* ppicker, const Color* initial)
	{
		if (!ppicker)
			argument_error(__FILE__, __LINE__);

		ColorPicker::Ref picker = ppicker;

		Window* owner    = picker->owner();
		CHOOSECOLORW cc  = {0};
		cc.lStructSize   = sizeof(cc);
		cc.hwndOwner     = owner ? Window_get_hwnd(owner) : NULL;
		cc.lpCustColors  = custom_colors;
		cc.Flags         = CC_FULLOPEN | CC_ANYCOLOR;
		if (initial)
		{
			cc.rgbResult = to_colorref(*initial);
			cc.Flags    |= CC_RGBINIT;
		}

		// the dialog has no alpha, so the picked color always has alpha 1
		BOOL picked = ChooseColorW(&cc);// runs a modal loop
		if (picked)
		{
			ColorEvent e(to_color(cc.rgbResult));
			ColorPicker_call_color_event(picker, &e);
		}
		else if (CommDlgExtendedError() != 0)
			system_error(__FILE__, __LINE__);

		Event e;
		ColorPicker_call_close_event(picker, &e);
	}


}// Reflex
