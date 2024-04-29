#include "reflex/ruby/reflex.h"


#include "reflex/ruby/view.h"
#include "reflex/ruby/timer.h"
#include "../../src/window.h"
#include "../../src/timer.h"
#include "defs.h"


static Reflex::View*
create_root_view ()
{
	return new Reflex::RubyView<Reflex::View>;
}

static Reflex::Timer*
create_timer ()
{
	return new Reflex::RubyTimer<Reflex::Timer>;
}


static
RUCY_DEF0(init)
{
	Reflex::init();
	Reflex::Window_set_create_root_view_fun(create_root_view);
	Reflex::Timer_set_create_fun(create_timer);

	return self;
}
RUCY_END

static
RUCY_DEF0(fin)
{
	Reflex::Window_set_create_root_view_fun(NULL);
	Reflex::Timer_set_create_fun(NULL);
	Reflex::fin();

	return self;
}
RUCY_END


static Module mReflex;

void
Init_reflex ()
{
	mReflex = define_module("Reflex");
	mReflex.define_singleton_method("init!", init);
	mReflex.define_singleton_method("fin!", fin);

	using namespace Reflex;

	#define DEFINE_CONST(name) mReflex.define_const(#name, name)

	DEFINE_CONST(KEY_A);
	DEFINE_CONST(KEY_B);
	DEFINE_CONST(KEY_C);
	DEFINE_CONST(KEY_D);
	DEFINE_CONST(KEY_E);
	DEFINE_CONST(KEY_F);
	DEFINE_CONST(KEY_G);
	DEFINE_CONST(KEY_H);
	DEFINE_CONST(KEY_I);
	DEFINE_CONST(KEY_J);
	DEFINE_CONST(KEY_K);
	DEFINE_CONST(KEY_L);
	DEFINE_CONST(KEY_M);
	DEFINE_CONST(KEY_N);
	DEFINE_CONST(KEY_O);
	DEFINE_CONST(KEY_P);
	DEFINE_CONST(KEY_Q);
	DEFINE_CONST(KEY_R);
	DEFINE_CONST(KEY_S);
	DEFINE_CONST(KEY_T);
	DEFINE_CONST(KEY_U);
	DEFINE_CONST(KEY_V);
	DEFINE_CONST(KEY_W);
	DEFINE_CONST(KEY_X);
	DEFINE_CONST(KEY_Y);
	DEFINE_CONST(KEY_Z);

	DEFINE_CONST(KEY_0);
	DEFINE_CONST(KEY_1);
	DEFINE_CONST(KEY_2);
	DEFINE_CONST(KEY_3);
	DEFINE_CONST(KEY_4);
	DEFINE_CONST(KEY_5);
	DEFINE_CONST(KEY_6);
	DEFINE_CONST(KEY_7);
	DEFINE_CONST(KEY_8);
	DEFINE_CONST(KEY_9);

	DEFINE_CONST(KEY_MINUS);
	DEFINE_CONST(KEY_EQUAL);
	DEFINE_CONST(KEY_COMMA);
	DEFINE_CONST(KEY_PERIOD);
	DEFINE_CONST(KEY_SEMICOLON);
	DEFINE_CONST(KEY_QUOTE);
	DEFINE_CONST(KEY_SLASH);
	DEFINE_CONST(KEY_BACKSLASH);
	DEFINE_CONST(KEY_UNDERSCORE);
	DEFINE_CONST(KEY_GRAVE);
	DEFINE_CONST(KEY_YEN);
	DEFINE_CONST(KEY_LBRACKET);
	DEFINE_CONST(KEY_RBRACKET);

	DEFINE_CONST(KEY_ENTER);
	DEFINE_CONST(KEY_RETURN);
	DEFINE_CONST(KEY_SPACE);
	DEFINE_CONST(KEY_TAB);
	DEFINE_CONST(KEY_DELETE);
	DEFINE_CONST(KEY_BACKSPACE);
	DEFINE_CONST(KEY_INSERT);
	DEFINE_CONST(KEY_ESCAPE);

	DEFINE_CONST(KEY_LEFT);
	DEFINE_CONST(KEY_RIGHT);
	DEFINE_CONST(KEY_UP);
	DEFINE_CONST(KEY_DOWN);
	DEFINE_CONST(KEY_HOME);
	DEFINE_CONST(KEY_END);
	DEFINE_CONST(KEY_PAGEUP);
	DEFINE_CONST(KEY_PAGEDOWN);

	DEFINE_CONST(KEY_SHIFT);
	DEFINE_CONST(KEY_LSHIFT);
	DEFINE_CONST(KEY_RSHIFT);
	DEFINE_CONST(KEY_CONTROL);
	DEFINE_CONST(KEY_LCONTROL);
	DEFINE_CONST(KEY_RCONTROL);
	DEFINE_CONST(KEY_ALT);
	DEFINE_CONST(KEY_LALT);
	DEFINE_CONST(KEY_RALT);
	DEFINE_CONST(KEY_LWIN);
	DEFINE_CONST(KEY_RWIN);
	DEFINE_CONST(KEY_COMMAND);
	DEFINE_CONST(KEY_LCOMMAND);
	DEFINE_CONST(KEY_RCOMMAND);
	DEFINE_CONST(KEY_OPTION);
	DEFINE_CONST(KEY_LOPTION);
	DEFINE_CONST(KEY_ROPTION);
	DEFINE_CONST(KEY_FUNCTION);

	DEFINE_CONST(KEY_F1);
	DEFINE_CONST(KEY_F2);
	DEFINE_CONST(KEY_F3);
	DEFINE_CONST(KEY_F4);
	DEFINE_CONST(KEY_F5);
	DEFINE_CONST(KEY_F6);
	DEFINE_CONST(KEY_F7);
	DEFINE_CONST(KEY_F8);
	DEFINE_CONST(KEY_F9);
	DEFINE_CONST(KEY_F10);
	DEFINE_CONST(KEY_F11);
	DEFINE_CONST(KEY_F12);
	DEFINE_CONST(KEY_F13);
	DEFINE_CONST(KEY_F14);
	DEFINE_CONST(KEY_F15);
	DEFINE_CONST(KEY_F16);
	DEFINE_CONST(KEY_F17);
	DEFINE_CONST(KEY_F18);
	DEFINE_CONST(KEY_F19);
	DEFINE_CONST(KEY_F20);
	DEFINE_CONST(KEY_F21);
	DEFINE_CONST(KEY_F22);
	DEFINE_CONST(KEY_F23);
	DEFINE_CONST(KEY_F24);

	DEFINE_CONST(KEY_NUM_0);
	DEFINE_CONST(KEY_NUM_1);
	DEFINE_CONST(KEY_NUM_2);
	DEFINE_CONST(KEY_NUM_3);
	DEFINE_CONST(KEY_NUM_4);
	DEFINE_CONST(KEY_NUM_5);
	DEFINE_CONST(KEY_NUM_6);
	DEFINE_CONST(KEY_NUM_7);
	DEFINE_CONST(KEY_NUM_8);
	DEFINE_CONST(KEY_NUM_9);

	DEFINE_CONST(KEY_NUM_PLUS);
	DEFINE_CONST(KEY_NUM_MINUS);
	DEFINE_CONST(KEY_NUM_MULTIPLY);
	DEFINE_CONST(KEY_NUM_DIVIDE);
	DEFINE_CONST(KEY_NUM_EQUAL);
	DEFINE_CONST(KEY_NUM_COMMA);
	DEFINE_CONST(KEY_NUM_DECIMAL);
	DEFINE_CONST(KEY_NUM_CLEAR);
	DEFINE_CONST(KEY_NUM_ENTER);

	DEFINE_CONST(KEY_CAPSLOCK);
	DEFINE_CONST(KEY_NUMLOCK);
	DEFINE_CONST(KEY_SCROLLLOCK);

	DEFINE_CONST(KEY_PRINTSCREEN);
	DEFINE_CONST(KEY_PAUSE);
	DEFINE_CONST(KEY_BREAK);
	DEFINE_CONST(KEY_SECTION);
	DEFINE_CONST(KEY_HELP);

	DEFINE_CONST(KEY_EISU);
	DEFINE_CONST(KEY_KANA);
	DEFINE_CONST(KEY_KANJI);
	DEFINE_CONST(KEY_IME_ON);
	DEFINE_CONST(KEY_IME_OFF);
	DEFINE_CONST(KEY_IME_MODECHANGE);
	DEFINE_CONST(KEY_CONVERT);
	DEFINE_CONST(KEY_NONCONVERT);
	DEFINE_CONST(KEY_ACCEPT);
	DEFINE_CONST(KEY_PROCESS);

	DEFINE_CONST(KEY_VOLUME_UP);
	DEFINE_CONST(KEY_VOLUME_DOWN);
	DEFINE_CONST(KEY_MUTE);

	DEFINE_CONST(KEY_SLEEP);
	DEFINE_CONST(KEY_EXEC);
	DEFINE_CONST(KEY_PRINT);
	DEFINE_CONST(KEY_APPS);
	DEFINE_CONST(KEY_SELECT);
	DEFINE_CONST(KEY_CLEAR);

	DEFINE_CONST(KEY_NAVIGATION_VIEW);
	DEFINE_CONST(KEY_NAVIGATION_MENU);
	DEFINE_CONST(KEY_NAVIGATION_UP);
	DEFINE_CONST(KEY_NAVIGATION_DOWN);
	DEFINE_CONST(KEY_NAVIGATION_LEFT);
	DEFINE_CONST(KEY_NAVIGATION_RIGHT);
	DEFINE_CONST(KEY_NAVIGATION_ACCEPT);
	DEFINE_CONST(KEY_NAVIGATION_CANCEL);

	DEFINE_CONST(KEY_BROWSER_BACK);
	DEFINE_CONST(KEY_BROWSER_FORWARD);
	DEFINE_CONST(KEY_BROWSER_REFRESH);
	DEFINE_CONST(KEY_BROWSER_STOP);
	DEFINE_CONST(KEY_BROWSER_SEARCH);
	DEFINE_CONST(KEY_BROWSER_FAVORITES);
	DEFINE_CONST(KEY_BROWSER_HOME);

	DEFINE_CONST(KEY_MEDIA_PREV_TRACK);
	DEFINE_CONST(KEY_MEDIA_NEXT_TRACK);
	DEFINE_CONST(KEY_MEDIA_PLAY_PAUSE);
	DEFINE_CONST(KEY_MEDIA_STOP);

	DEFINE_CONST(KEY_LAUNCH_MAIL);
	DEFINE_CONST(KEY_LAUNCH_MEDIA_SELECT);
	DEFINE_CONST(KEY_LAUNCH_APP1);
	DEFINE_CONST(KEY_LAUNCH_APP2);

	DEFINE_CONST(MOD_SHIFT);
	DEFINE_CONST(MOD_CONTROL);
	DEFINE_CONST(MOD_ALT);
	DEFINE_CONST(MOD_WIN);
	DEFINE_CONST(MOD_OPTION);
	DEFINE_CONST(MOD_COMMAND);
	DEFINE_CONST(MOD_HELP);
	DEFINE_CONST(MOD_FUNCTION);
	DEFINE_CONST(MOD_NUMPAD);
	DEFINE_CONST(MOD_CAPS);

	#undef DEFINE_CONST
}


namespace Reflex
{


	Module
	reflex_module ()
	{
		return mReflex;
	}


}// Reflex
