#include "reflex/ruby/event.h"


#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::KeyEvent)

#define THIS  to<Reflex::KeyEvent*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::KeyEvent, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Reflex::KeyEvent>(klass);
}
RUCY_END

static
RUCY_DEF5(initialize, action, chars, code, modifiers, repeat)
{
	CHECK;

	*THIS = Reflex::KeyEvent(
		(Reflex::KeyEvent::Action) to<uint>(action),
		chars.c_str(),
		to<int>(code),
		to<uint>(modifiers),
		to<int>(repeat));

	return rb_call_super(0, NULL);
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Reflex::KeyEvent&>(obj).dup();
	return self;
}
RUCY_END

static
RUCY_DEF0(get_action)
{
	CHECK;
	return value(THIS->action());
}
RUCY_END

static
RUCY_DEF0(get_key)
{
	CHECK;
	switch (THIS->code())
	{
		#define CASE(key)         case Reflex::KEY_##key
		#define SYMBOL1(name)     SYMBOL2(_##name, #name)
		#define SYMBOL2(var, sym) {RUCY_SYMBOL(var, sym); return var.value();}

		CASE(A): SYMBOL1(a);
		CASE(B): SYMBOL1(b);
		CASE(C): SYMBOL1(c);
		CASE(D): SYMBOL1(d);
		CASE(E): SYMBOL1(e);
		CASE(F): SYMBOL1(f);
		CASE(G): SYMBOL1(g);
		CASE(H): SYMBOL1(h);
		CASE(I): SYMBOL1(i);
		CASE(J): SYMBOL1(j);
		CASE(K): SYMBOL1(k);
		CASE(L): SYMBOL1(l);
		CASE(M): SYMBOL1(m);
		CASE(N): SYMBOL1(n);
		CASE(O): SYMBOL1(o);
		CASE(P): SYMBOL1(p);
		CASE(Q): SYMBOL1(q);
		CASE(R): SYMBOL1(r);
		CASE(S): SYMBOL1(s);
		CASE(T): SYMBOL1(t);
		CASE(U): SYMBOL1(u);
		CASE(V): SYMBOL1(v);
		CASE(W): SYMBOL1(w);
		CASE(X): SYMBOL1(x);
		CASE(Y): SYMBOL1(y);
		CASE(Z): SYMBOL1(z);

		CASE(0):
		CASE(NUM_0): SYMBOL1(0);
		CASE(1):
		CASE(NUM_1): SYMBOL1(1);
		CASE(2):
		CASE(NUM_2): SYMBOL1(2);
		CASE(3):
		CASE(NUM_3): SYMBOL1(3);
		CASE(4):
		CASE(NUM_4): SYMBOL1(4);
		CASE(5):
		CASE(NUM_5): SYMBOL1(5);
		CASE(6):
		CASE(NUM_6): SYMBOL1(6);
		CASE(7):
		CASE(NUM_7): SYMBOL1(7);
		CASE(8):
		CASE(NUM_8): SYMBOL1(8);
		CASE(9):
		CASE(NUM_9): SYMBOL1(9);

		CASE(MINUS):      SYMBOL1(minus);
		CASE(EQUAL):      SYMBOL1(equal);
		CASE(COMMA):      SYMBOL1(comma);
		CASE(PERIOD):     SYMBOL1(period);
		CASE(SEMICOLON):  SYMBOL1(semicolon);
		CASE(QUOTE):      SYMBOL1(quote);
		CASE(SLASH):      SYMBOL1(slash);
		CASE(BACKSLASH):  SYMBOL1(backslash);
		CASE(UNDERSCORE): SYMBOL1(underscore);
		CASE(GRAVE):      SYMBOL1(grave);
		CASE(YEN):        SYMBOL1(yen);
		CASE(LBRACKET):   SYMBOL1(lbracket);
		CASE(RBRACKET):   SYMBOL1(rbracket);

#if defined(OSX) || defined(IOS) || defined(WIN32)
		CASE(ENTER):     SYMBOL1(enter);
#else
		CASE(ENTER):     SYMBOL1(enter);
		CASE(RETURN):    SYMBOL1(_return, "return");
#endif
		CASE(SPACE):     SYMBOL1(space);
		CASE(TAB):       SYMBOL1(tab);
		CASE(DELETE):    SYMBOL2(_delete, "delete");
		CASE(BACKSPACE): SYMBOL1(backspace);
		CASE(INSERT):    SYMBOL1(insert);
		CASE(ESCAPE):    SYMBOL1(escape);

		CASE(LEFT):     SYMBOL1(left);
		CASE(RIGHT):    SYMBOL1(right);
		CASE(UP):       SYMBOL1(up);
		CASE(DOWN):     SYMBOL1(down);
		CASE(HOME):     SYMBOL1(home);
		CASE(END):      SYMBOL1(end);
		CASE(PAGEUP):   SYMBOL1(pageup);
		CASE(PAGEDOWN): SYMBOL1(pagedown);

#if !defined(OSX) && !defined(IOS)
		CASE(SHIFT):
#endif
		CASE(LSHIFT):
		CASE(RSHIFT):   SYMBOL1(shift);
#if !defined(OSX) && !defined(IOS)
		CASE(CONTROL):
#endif
		CASE(LCONTROL):
		CASE(RCONTROL): SYMBOL1(control);
		CASE(ALT):
		CASE(LALT):
		CASE(RALT):     SYMBOL1(alt);
		CASE(LWIN):
		CASE(RWIN):     SYMBOL1(win);
		CASE(LCOMMAND):
		CASE(RCOMMAND): SYMBOL1(command);
		CASE(LOPTION):
		CASE(ROPTION):  SYMBOL1(option);
		CASE(FUNCTION): SYMBOL1(function);

		CASE(F1):  SYMBOL1(f1);
		CASE(F2):  SYMBOL1(f2);
		CASE(F3):  SYMBOL1(f3);
		CASE(F4):  SYMBOL1(f4);
		CASE(F5):  SYMBOL1(f5);
		CASE(F6):  SYMBOL1(f6);
		CASE(F7):  SYMBOL1(f7);
		CASE(F8):  SYMBOL1(f8);
		CASE(F9):  SYMBOL1(f9);
		CASE(F10): SYMBOL1(f10);
		CASE(F11): SYMBOL1(f11);
		CASE(F12): SYMBOL1(f12);
		CASE(F13): SYMBOL1(f13);
		CASE(F14): SYMBOL1(f14);
		CASE(F15): SYMBOL1(f15);
		CASE(F16): SYMBOL1(f16);
		CASE(F17): SYMBOL1(f17);
		CASE(F18): SYMBOL1(f18);
		CASE(F19): SYMBOL1(f19);
		CASE(F20): SYMBOL1(f20);
		CASE(F21): SYMBOL1(f21);
		CASE(F22): SYMBOL1(f22);
		CASE(F23): SYMBOL1(f23);
		CASE(F24): SYMBOL1(f24);

		CASE(NUM_PLUS):     SYMBOL1(plus);
		CASE(NUM_MINUS):    SYMBOL1(minus);
		CASE(NUM_MULTIPLY): SYMBOL1(multiply);
		CASE(NUM_DIVIDE):   SYMBOL1(divide);
		CASE(NUM_EQUAL):    SYMBOL1(equal);
		CASE(NUM_COMMA):    SYMBOL1(comma);
		CASE(NUM_DECIMAL):  SYMBOL1(decimal);
		CASE(NUM_CLEAR):    SYMBOL1(clear);
		CASE(NUM_ENTER):    SYMBOL1(enter);

		CASE(CAPSLOCK):   SYMBOL1(capslock);
		CASE(NUMLOCK):    SYMBOL1(numlock);
		CASE(SCROLLLOCK): SYMBOL1(scrolllock);

		CASE(PRINTSCREEN): SYMBOL1(printscreen);
		CASE(PAUSE):       SYMBOL1(pause);
		CASE(BREAK):       SYMBOL2(_break, "break");
		CASE(SECTION):     SYMBOL1(section);
		CASE(HELP):        SYMBOL1(help);

		CASE(EISU):           SYMBOL1(eisu);
		CASE(KANA):           SYMBOL1(kana);
		CASE(KANJI):          SYMBOL1(kanji);
		CASE(IME_ON):         SYMBOL1(ime_on);
		CASE(IME_OFF):        SYMBOL1(ime_off);
		CASE(IME_MODECHANGE): SYMBOL1(ime_mode_change);
		CASE(CONVERT):        SYMBOL1(convert);
		CASE(NONCONVERT):     SYMBOL1(nonconvert);
		CASE(ACCEPT):         SYMBOL1(accept);
		CASE(PROCESS):        SYMBOL1(process);

		CASE(VOLUME_UP):   SYMBOL1(volume_up);
		CASE(VOLUME_DOWN): SYMBOL1(volume_down);
		CASE(MUTE):        SYMBOL1(mute);

		CASE(SLEEP):  SYMBOL1(sleep);
		CASE(EXEC):   SYMBOL1(exec);
		CASE(PRINT):  SYMBOL1(print);
		CASE(APPS):   SYMBOL1(apps);
		CASE(SELECT): SYMBOL1(select);
		CASE(CLEAR):  SYMBOL1(clear);

		CASE(NAVIGATION_VIEW):   SYMBOL1(navigation_view);
		CASE(NAVIGATION_MENU):   SYMBOL1(navigation_menu);
		CASE(NAVIGATION_UP):     SYMBOL1(navigation_up);
		CASE(NAVIGATION_DOWN):   SYMBOL1(navigation_down);
		CASE(NAVIGATION_LEFT):   SYMBOL1(navigation_left);
		CASE(NAVIGATION_RIGHT):  SYMBOL1(navigation_right);
		CASE(NAVIGATION_ACCEPT): SYMBOL1(navigation_accept);
		CASE(NAVIGATION_CANCEL): SYMBOL1(navigation_cancel);

		CASE(BROWSER_BACK):      SYMBOL1(browser_back);
		CASE(BROWSER_FORWARD):   SYMBOL1(browser_forward);
		CASE(BROWSER_REFRESH):   SYMBOL1(browser_refresh);
		CASE(BROWSER_STOP):      SYMBOL1(browser_stop);
		CASE(BROWSER_SEARCH):    SYMBOL1(browser_search);
		CASE(BROWSER_FAVORITES): SYMBOL1(browser_favorites);
		CASE(BROWSER_HOME):      SYMBOL1(browser_home);

		CASE(MEDIA_PREV_TRACK): SYMBOL1(media_prev);
		CASE(MEDIA_NEXT_TRACK): SYMBOL1(media_next);
		CASE(MEDIA_PLAY_PAUSE): SYMBOL1(media_play_pause);
		CASE(MEDIA_STOP):       SYMBOL1(media_stop);

		CASE(LAUNCH_MAIL):         SYMBOL1(launch_mail);
		CASE(LAUNCH_MEDIA_SELECT): SYMBOL1(launch_media_select);
		CASE(LAUNCH_APP1):         SYMBOL1(launch_app1);
		CASE(LAUNCH_APP2):         SYMBOL1(launch_app2);

		CASE(GAMEPAD_LEFT):         SYMBOL1(gamepad_left);
		CASE(GAMEPAD_RIGHT):        SYMBOL1(gamepad_right);
		CASE(GAMEPAD_UP):           SYMBOL1(gamepad_up);
		CASE(GAMEPAD_DOWN):         SYMBOL1(gamepad_down);
		CASE(GAMEPAD_LSTICK_LEFT):  SYMBOL1(gamepad_lstick_left);
		CASE(GAMEPAD_LSTICK_RIGHT): SYMBOL1(gamepad_lstick_right);
		CASE(GAMEPAD_LSTICK_UP):    SYMBOL1(gamepad_lstick_up);
		CASE(GAMEPAD_LSTICK_DOWN):  SYMBOL1(gamepad_lstick_down);
		CASE(GAMEPAD_RSTICK_LEFT):  SYMBOL1(gamepad_rstick_left);
		CASE(GAMEPAD_RSTICK_RIGHT): SYMBOL1(gamepad_rstick_right);
		CASE(GAMEPAD_RSTICK_UP):    SYMBOL1(gamepad_rstick_up);
		CASE(GAMEPAD_RSTICK_DOWN):  SYMBOL1(gamepad_rstick_down);
		CASE(GAMEPAD_A):            SYMBOL1(gamepad_a);
		CASE(GAMEPAD_B):            SYMBOL1(gamepad_b);
		CASE(GAMEPAD_X):            SYMBOL1(gamepad_x);
		CASE(GAMEPAD_Y):            SYMBOL1(gamepad_y);
		CASE(GAMEPAD_LTRIGGER):     SYMBOL1(gamepad_ltrigger);
		CASE(GAMEPAD_RTRIGGER):     SYMBOL1(gamepad_rtrigger);
		CASE(GAMEPAD_LSHOULDER):    SYMBOL1(gamepad_lshoulder);
		CASE(GAMEPAD_RSHOULDER):    SYMBOL1(gamepad_rshoulder);
		CASE(GAMEPAD_LTHUMB):       SYMBOL1(gamepad_lthumb);
		CASE(GAMEPAD_RTHUMB):       SYMBOL1(gamepad_rthumb);
		CASE(GAMEPAD_LPADDLE_0):    SYMBOL1(gamepad_lpaddle_0);
		CASE(GAMEPAD_LPADDLE_1):    SYMBOL1(gamepad_lpaddle_1);
		CASE(GAMEPAD_RPADDLE_0):    SYMBOL1(gamepad_rpaddle_0);
		CASE(GAMEPAD_RPADDLE_1):    SYMBOL1(gamepad_rpaddle_1);
		CASE(GAMEPAD_HOME):         SYMBOL1(gamepad_home);
		CASE(GAMEPAD_MENU):         SYMBOL1(gamepad_menu);
		CASE(GAMEPAD_OPTION):       SYMBOL1(gamepad_option);
		CASE(GAMEPAD_SHARE):        SYMBOL1(gamepad_share);
		CASE(GAMEPAD_START):        SYMBOL1(gamepad_start);
		CASE(GAMEPAD_SELECT):       SYMBOL1(gamepad_select);
		CASE(GAMEPAD_BUTTON_TOUCH): SYMBOL1(gamepad_button_touch);
		CASE(GAMEPAD_BUTTON_0):     SYMBOL1(gamepad_button_0);
		CASE(GAMEPAD_BUTTON_1):     SYMBOL1(gamepad_button_1);
		CASE(GAMEPAD_BUTTON_2):     SYMBOL1(gamepad_button_2);
		CASE(GAMEPAD_BUTTON_3):     SYMBOL1(gamepad_button_3);
		CASE(GAMEPAD_BUTTON_4):     SYMBOL1(gamepad_button_4);
		CASE(GAMEPAD_BUTTON_5):     SYMBOL1(gamepad_button_5);
		CASE(GAMEPAD_BUTTON_6):     SYMBOL1(gamepad_button_6);
		CASE(GAMEPAD_BUTTON_7):     SYMBOL1(gamepad_button_7);
		CASE(GAMEPAD_BUTTON_8):     SYMBOL1(gamepad_button_8);
		CASE(GAMEPAD_BUTTON_9):     SYMBOL1(gamepad_button_9);
		CASE(GAMEPAD_BUTTON_10):    SYMBOL1(gamepad_button_10);
		CASE(GAMEPAD_BUTTON_11):    SYMBOL1(gamepad_button_11);
		CASE(GAMEPAD_BUTTON_12):    SYMBOL1(gamepad_button_12);
		CASE(GAMEPAD_BUTTON_13):    SYMBOL1(gamepad_button_13);
		CASE(GAMEPAD_BUTTON_14):    SYMBOL1(gamepad_button_14);
		CASE(GAMEPAD_BUTTON_15):    SYMBOL1(gamepad_button_15);

		#undef CASE
		#undef SYMBOL1
		#undef SYMBOL2
	}
	return nil();
}
RUCY_END

static
RUCY_DEF0(get_chars)
{
	CHECK;
	const char* chars = THIS->chars();
	return chars ? value(chars) : nil();
}
RUCY_END

static
RUCY_DEF0(get_code)
{
	CHECK;
	return value(THIS->code());
}
RUCY_END

static
RUCY_DEF0(get_modifiers)
{
	CHECK;
	return value(THIS->modifiers());
}
RUCY_END

static
RUCY_DEF0(get_repeat)
{
	CHECK;
	return value(THIS->repeat());
}
RUCY_END

static
RUCY_DEF0(is_captured)
{
	CHECK;
	return value(THIS->is_captured());
}
RUCY_END


static Class cKeyEvent;

void
Init_reflex_key_event ()
{
	Module mReflex = define_module("Reflex");

	cKeyEvent = mReflex.define_class("KeyEvent", Reflex::event_class());
	cKeyEvent.define_alloc_func(alloc);
	cKeyEvent.define_private_method("initialize",      initialize);
	cKeyEvent.define_private_method("initialize_copy", initialize_copy);
	cKeyEvent.define_method("action",    get_action);
	cKeyEvent.define_method("key",       get_key);
	cKeyEvent.define_method("chars",     get_chars);
	cKeyEvent.define_method("code",      get_code);
	cKeyEvent.define_method("modifiers", get_modifiers);
	cKeyEvent.define_method("repeat",    get_repeat);
	cKeyEvent.define_method("captured?", is_captured);

	cKeyEvent.define_const("ACTION_NONE", Reflex::KeyEvent::ACTION_NONE);
	cKeyEvent.define_const("DOWN",        Reflex::KeyEvent::DOWN);
	cKeyEvent.define_const("UP",          Reflex::KeyEvent::UP);
}


namespace Reflex
{


	Class
	key_event_class ()
	{
		return cKeyEvent;
	}


}// Reflex
