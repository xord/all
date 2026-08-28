#include "reflex/ruby/reflex.h"


#include <assert.h>
#include "reflex/exception.h"
#include "reflex/ruby/view.h"
#include "reflex/ruby/constraint.h"
#include "reflex/ruby/timer.h"
#include "reflex/ruby/midi.h"
#include "../../src/window.h"
#include "../../src/constraint.h"
#include "../../src/timer.h"
#include "../../src/midi.h"
#include "defs.h"


RUCY_DEFINE_CONVERT_TO(REFLEX_EXPORT, Reflex::KeyCode)


static Reflex::View*
create_root_view ()
{
	return new Reflex::RubyView<Reflex::View>();
}

static Reflex::SnapConstraint*
create_snap_constraint ()
{
	return new Reflex::RubyConstraint<Reflex::SnapConstraint>();
}

static Reflex::LinkConstraint*
create_link_constraint ()
{
	return new Reflex::RubyConstraint<Reflex::LinkConstraint>();
}

static Reflex::WheelConstraint*
create_wheel_constraint ()
{
	return new Reflex::RubyConstraint<Reflex::WheelConstraint>();
}

static Reflex::ChaseConstraint*
create_chase_constraint ()
{
	return new Reflex::RubyConstraint<Reflex::ChaseConstraint>();
}

static Reflex::Timer*
create_timer ()
{
	return new Reflex::RubyTimer<Reflex::Timer>();
}

static Reflex::MIDI*
create_midi ()
{
	Reflex::MIDI* midi = new Reflex::RubyMIDI<Reflex::MIDI>();
	value(midi);// apply MIDI class to ClassWrapper's value
	return midi;
}


static
RUCY_DEF0(init)
{
	Reflex::init();
	Reflex::         Window_set_create_root_view_fun(create_root_view);
	Reflex:: SnapConstraint_set_create_fun(create_snap_constraint);
	Reflex:: LinkConstraint_set_create_fun(create_link_constraint);
	Reflex::WheelConstraint_set_create_fun(create_wheel_constraint);
	Reflex::ChaseConstraint_set_create_fun(create_chase_constraint);
	Reflex::          Timer_set_create_fun(create_timer);
	Reflex::           MIDI_set_create_fun(create_midi);

	return self;
}
RUCY_END

static
RUCY_DEF0(fin)
{
	Reflex::         Window_set_create_root_view_fun(NULL);
	Reflex:: SnapConstraint_set_create_fun(NULL);
	Reflex:: LinkConstraint_set_create_fun(NULL);
	Reflex::WheelConstraint_set_create_fun(NULL);
	Reflex::ChaseConstraint_set_create_fun(NULL);
	Reflex::          Timer_set_create_fun(NULL);
	Reflex::           MIDI_set_create_fun(NULL);
	Reflex::fin();

	return self;
}
RUCY_END

static Rucy::Value
get_key_symbol (Reflex::KeyCode code)
{
	switch ((int) code)
	{
		#define CASE(key)         case Reflex::KEY_##key
		#define SYMBOL1(name)     SYMBOL2(_##name, #name)
		#define SYMBOL2(var, sym) {RUCY_SYMBOL(var, sym); return var.value();}

		#if !defined(OSX) && !defined(WIN32)
			#define HID
		#endif

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

		CASE(ENTER):     SYMBOL1(enter);// no RETURN
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

#if !defined(HID) && !defined(OSX)
		CASE(SHIFT):
#endif
		CASE(LSHIFT):
		CASE(RSHIFT):   SYMBOL1(shift);
#if !defined(HID) && !defined(OSX)
		CASE(CONTROL):
#endif
		CASE(LCONTROL):
		CASE(RCONTROL): SYMBOL1(control);
		CASE(ALT):
#if !defined(HID)
		CASE(LALT):
#endif
		CASE(RALT):     SYMBOL1(alt);
		CASE(LWIN):
		CASE(RWIN):     SYMBOL1(win);
#if !defined(HID) && !defined(OSX)
		CASE(COMMAND):
#endif
#if !defined(HID)
		CASE(LCOMMAND):
		CASE(RCOMMAND): SYMBOL1(command);
#endif
#if !defined(HID) && !defined(OSX)
		CASE(OPTION):
#endif
#if !defined(HID)
		CASE(LOPTION):
		CASE(ROPTION):  SYMBOL1(option);
#endif
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
#if !defined(HID)
		CASE(NUM_CLEAR):    SYMBOL1(clear);
#endif
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

		CASE(SLEEP):        SYMBOL1(sleep);
		CASE(EXEC):         SYMBOL1(exec);
		CASE(PRINT):        SYMBOL1(print);
		CASE(CONTEXT_MENU): SYMBOL1(context_menu);
		CASE(SELECT):       SYMBOL1(select);
		CASE(CLEAR):        SYMBOL1(clear);

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

		#undef HID
		#undef CASE
		#undef SYMBOL1
		#undef SYMBOL2
	}
	return nil();
}

static
RUCY_DEF1(get_key_symbol, key)
{
	return get_key_symbol((Reflex::KeyCode) to<int>(key));
}
RUCY_END

static
RUCY_DEF0(process_events)
{
	Reflex::process_events();

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
	mReflex.define_singleton_method("get_key_symbol!", get_key_symbol);
	mReflex.define_singleton_method("process_events!", process_events);

	using namespace Reflex;

	#define DEFINE_CONST(name) \
		mReflex.define_const(#name, name)
	{
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
		DEFINE_CONST(MOD_SCROLL);
	}
	#undef DEFINE_CONST

	#define DEFINE_KEY_CONST(key) \
		mReflex.define_const(#key, key); \
		if ((int) key >= 0) keys.emplace_back(key)
	{
		std::vector<Value> keys;

		DEFINE_KEY_CONST(KEY_A);
		DEFINE_KEY_CONST(KEY_B);
		DEFINE_KEY_CONST(KEY_C);
		DEFINE_KEY_CONST(KEY_D);
		DEFINE_KEY_CONST(KEY_E);
		DEFINE_KEY_CONST(KEY_F);
		DEFINE_KEY_CONST(KEY_G);
		DEFINE_KEY_CONST(KEY_H);
		DEFINE_KEY_CONST(KEY_I);
		DEFINE_KEY_CONST(KEY_J);
		DEFINE_KEY_CONST(KEY_K);
		DEFINE_KEY_CONST(KEY_L);
		DEFINE_KEY_CONST(KEY_M);
		DEFINE_KEY_CONST(KEY_N);
		DEFINE_KEY_CONST(KEY_O);
		DEFINE_KEY_CONST(KEY_P);
		DEFINE_KEY_CONST(KEY_Q);
		DEFINE_KEY_CONST(KEY_R);
		DEFINE_KEY_CONST(KEY_S);
		DEFINE_KEY_CONST(KEY_T);
		DEFINE_KEY_CONST(KEY_U);
		DEFINE_KEY_CONST(KEY_V);
		DEFINE_KEY_CONST(KEY_W);
		DEFINE_KEY_CONST(KEY_X);
		DEFINE_KEY_CONST(KEY_Y);
		DEFINE_KEY_CONST(KEY_Z);

		DEFINE_KEY_CONST(KEY_0);
		DEFINE_KEY_CONST(KEY_1);
		DEFINE_KEY_CONST(KEY_2);
		DEFINE_KEY_CONST(KEY_3);
		DEFINE_KEY_CONST(KEY_4);
		DEFINE_KEY_CONST(KEY_5);
		DEFINE_KEY_CONST(KEY_6);
		DEFINE_KEY_CONST(KEY_7);
		DEFINE_KEY_CONST(KEY_8);
		DEFINE_KEY_CONST(KEY_9);

		DEFINE_KEY_CONST(KEY_MINUS);
		DEFINE_KEY_CONST(KEY_EQUAL);
		DEFINE_KEY_CONST(KEY_COMMA);
		DEFINE_KEY_CONST(KEY_PERIOD);
		DEFINE_KEY_CONST(KEY_SEMICOLON);
		DEFINE_KEY_CONST(KEY_QUOTE);
		DEFINE_KEY_CONST(KEY_SLASH);
		DEFINE_KEY_CONST(KEY_BACKSLASH);
		DEFINE_KEY_CONST(KEY_UNDERSCORE);
		DEFINE_KEY_CONST(KEY_GRAVE);
		DEFINE_KEY_CONST(KEY_YEN);
		DEFINE_KEY_CONST(KEY_LBRACKET);
		DEFINE_KEY_CONST(KEY_RBRACKET);

		DEFINE_KEY_CONST(KEY_ENTER);
		DEFINE_KEY_CONST(KEY_RETURN);
		DEFINE_KEY_CONST(KEY_SPACE);
		DEFINE_KEY_CONST(KEY_TAB);
		DEFINE_KEY_CONST(KEY_DELETE);
		DEFINE_KEY_CONST(KEY_BACKSPACE);
		DEFINE_KEY_CONST(KEY_INSERT);
		DEFINE_KEY_CONST(KEY_ESCAPE);

		DEFINE_KEY_CONST(KEY_LEFT);
		DEFINE_KEY_CONST(KEY_RIGHT);
		DEFINE_KEY_CONST(KEY_UP);
		DEFINE_KEY_CONST(KEY_DOWN);
		DEFINE_KEY_CONST(KEY_HOME);
		DEFINE_KEY_CONST(KEY_END);
		DEFINE_KEY_CONST(KEY_PAGEUP);
		DEFINE_KEY_CONST(KEY_PAGEDOWN);

		DEFINE_KEY_CONST(KEY_SHIFT);
		DEFINE_KEY_CONST(KEY_LSHIFT);
		DEFINE_KEY_CONST(KEY_RSHIFT);
		DEFINE_KEY_CONST(KEY_CONTROL);
		DEFINE_KEY_CONST(KEY_LCONTROL);
		DEFINE_KEY_CONST(KEY_RCONTROL);
		DEFINE_KEY_CONST(KEY_ALT);
		DEFINE_KEY_CONST(KEY_LALT);
		DEFINE_KEY_CONST(KEY_RALT);
		DEFINE_KEY_CONST(KEY_LWIN);
		DEFINE_KEY_CONST(KEY_RWIN);
		DEFINE_KEY_CONST(KEY_COMMAND);
		DEFINE_KEY_CONST(KEY_LCOMMAND);
		DEFINE_KEY_CONST(KEY_RCOMMAND);
		DEFINE_KEY_CONST(KEY_OPTION);
		DEFINE_KEY_CONST(KEY_LOPTION);
		DEFINE_KEY_CONST(KEY_ROPTION);
		DEFINE_KEY_CONST(KEY_FUNCTION);

		DEFINE_KEY_CONST(KEY_F1);
		DEFINE_KEY_CONST(KEY_F2);
		DEFINE_KEY_CONST(KEY_F3);
		DEFINE_KEY_CONST(KEY_F4);
		DEFINE_KEY_CONST(KEY_F5);
		DEFINE_KEY_CONST(KEY_F6);
		DEFINE_KEY_CONST(KEY_F7);
		DEFINE_KEY_CONST(KEY_F8);
		DEFINE_KEY_CONST(KEY_F9);
		DEFINE_KEY_CONST(KEY_F10);
		DEFINE_KEY_CONST(KEY_F11);
		DEFINE_KEY_CONST(KEY_F12);
		DEFINE_KEY_CONST(KEY_F13);
		DEFINE_KEY_CONST(KEY_F14);
		DEFINE_KEY_CONST(KEY_F15);
		DEFINE_KEY_CONST(KEY_F16);
		DEFINE_KEY_CONST(KEY_F17);
		DEFINE_KEY_CONST(KEY_F18);
		DEFINE_KEY_CONST(KEY_F19);
		DEFINE_KEY_CONST(KEY_F20);
		DEFINE_KEY_CONST(KEY_F21);
		DEFINE_KEY_CONST(KEY_F22);
		DEFINE_KEY_CONST(KEY_F23);
		DEFINE_KEY_CONST(KEY_F24);

		DEFINE_KEY_CONST(KEY_NUM_0);
		DEFINE_KEY_CONST(KEY_NUM_1);
		DEFINE_KEY_CONST(KEY_NUM_2);
		DEFINE_KEY_CONST(KEY_NUM_3);
		DEFINE_KEY_CONST(KEY_NUM_4);
		DEFINE_KEY_CONST(KEY_NUM_5);
		DEFINE_KEY_CONST(KEY_NUM_6);
		DEFINE_KEY_CONST(KEY_NUM_7);
		DEFINE_KEY_CONST(KEY_NUM_8);
		DEFINE_KEY_CONST(KEY_NUM_9);

		DEFINE_KEY_CONST(KEY_NUM_PLUS);
		DEFINE_KEY_CONST(KEY_NUM_MINUS);
		DEFINE_KEY_CONST(KEY_NUM_MULTIPLY);
		DEFINE_KEY_CONST(KEY_NUM_DIVIDE);
		DEFINE_KEY_CONST(KEY_NUM_EQUAL);
		DEFINE_KEY_CONST(KEY_NUM_COMMA);
		DEFINE_KEY_CONST(KEY_NUM_DECIMAL);
		DEFINE_KEY_CONST(KEY_NUM_CLEAR);
		DEFINE_KEY_CONST(KEY_NUM_ENTER);

		DEFINE_KEY_CONST(KEY_CAPSLOCK);
		DEFINE_KEY_CONST(KEY_NUMLOCK);
		DEFINE_KEY_CONST(KEY_SCROLLLOCK);

		DEFINE_KEY_CONST(KEY_PRINTSCREEN);
		DEFINE_KEY_CONST(KEY_PAUSE);
		DEFINE_KEY_CONST(KEY_BREAK);
		DEFINE_KEY_CONST(KEY_SECTION);
		DEFINE_KEY_CONST(KEY_HELP);

		DEFINE_KEY_CONST(KEY_EISU);
		DEFINE_KEY_CONST(KEY_KANA);
		DEFINE_KEY_CONST(KEY_KANJI);
		DEFINE_KEY_CONST(KEY_IME_ON);
		DEFINE_KEY_CONST(KEY_IME_OFF);
		DEFINE_KEY_CONST(KEY_IME_MODECHANGE);
		DEFINE_KEY_CONST(KEY_CONVERT);
		DEFINE_KEY_CONST(KEY_NONCONVERT);
		DEFINE_KEY_CONST(KEY_ACCEPT);
		DEFINE_KEY_CONST(KEY_PROCESS);

		DEFINE_KEY_CONST(KEY_VOLUME_UP);
		DEFINE_KEY_CONST(KEY_VOLUME_DOWN);
		DEFINE_KEY_CONST(KEY_MUTE);

		DEFINE_KEY_CONST(KEY_SLEEP);
		DEFINE_KEY_CONST(KEY_EXEC);
		DEFINE_KEY_CONST(KEY_PRINT);
		DEFINE_KEY_CONST(KEY_CONTEXT_MENU);
		DEFINE_KEY_CONST(KEY_SELECT);
		DEFINE_KEY_CONST(KEY_CLEAR);

		DEFINE_KEY_CONST(KEY_NAVIGATION_VIEW);
		DEFINE_KEY_CONST(KEY_NAVIGATION_MENU);
		DEFINE_KEY_CONST(KEY_NAVIGATION_UP);
		DEFINE_KEY_CONST(KEY_NAVIGATION_DOWN);
		DEFINE_KEY_CONST(KEY_NAVIGATION_LEFT);
		DEFINE_KEY_CONST(KEY_NAVIGATION_RIGHT);
		DEFINE_KEY_CONST(KEY_NAVIGATION_ACCEPT);
		DEFINE_KEY_CONST(KEY_NAVIGATION_CANCEL);

		DEFINE_KEY_CONST(KEY_BROWSER_BACK);
		DEFINE_KEY_CONST(KEY_BROWSER_FORWARD);
		DEFINE_KEY_CONST(KEY_BROWSER_REFRESH);
		DEFINE_KEY_CONST(KEY_BROWSER_STOP);
		DEFINE_KEY_CONST(KEY_BROWSER_SEARCH);
		DEFINE_KEY_CONST(KEY_BROWSER_FAVORITES);
		DEFINE_KEY_CONST(KEY_BROWSER_HOME);

		DEFINE_KEY_CONST(KEY_MEDIA_PREV_TRACK);
		DEFINE_KEY_CONST(KEY_MEDIA_NEXT_TRACK);
		DEFINE_KEY_CONST(KEY_MEDIA_PLAY_PAUSE);
		DEFINE_KEY_CONST(KEY_MEDIA_STOP);

		DEFINE_KEY_CONST(KEY_LAUNCH_MAIL);
		DEFINE_KEY_CONST(KEY_LAUNCH_MEDIA_SELECT);
		DEFINE_KEY_CONST(KEY_LAUNCH_APP1);
		DEFINE_KEY_CONST(KEY_LAUNCH_APP2);

		DEFINE_KEY_CONST(KEY_GAMEPAD_LEFT);
		DEFINE_KEY_CONST(KEY_GAMEPAD_RIGHT);
		DEFINE_KEY_CONST(KEY_GAMEPAD_UP);
		DEFINE_KEY_CONST(KEY_GAMEPAD_DOWN);

		DEFINE_KEY_CONST(KEY_GAMEPAD_A);
		DEFINE_KEY_CONST(KEY_GAMEPAD_B);
		DEFINE_KEY_CONST(KEY_GAMEPAD_X);
		DEFINE_KEY_CONST(KEY_GAMEPAD_Y);

		DEFINE_KEY_CONST(KEY_GAMEPAD_LSHOULDER);
		DEFINE_KEY_CONST(KEY_GAMEPAD_RSHOULDER);
		DEFINE_KEY_CONST(KEY_GAMEPAD_LTRIGGER);
		DEFINE_KEY_CONST(KEY_GAMEPAD_RTRIGGER);
		DEFINE_KEY_CONST(KEY_GAMEPAD_LTHUMB);
		DEFINE_KEY_CONST(KEY_GAMEPAD_RTHUMB);

		DEFINE_KEY_CONST(KEY_GAMEPAD_HOME);
		DEFINE_KEY_CONST(KEY_GAMEPAD_MENU);
		DEFINE_KEY_CONST(KEY_GAMEPAD_OPTION);
		DEFINE_KEY_CONST(KEY_GAMEPAD_SHARE);
		DEFINE_KEY_CONST(KEY_GAMEPAD_START);
		DEFINE_KEY_CONST(KEY_GAMEPAD_SELECT);

		mReflex.define_const("KEYS", array(keys.data(), keys.size()).freeze());
	}
	#undef DEFINE_KEY_CONST
}


namespace Rucy
{


	template <> REFLEX_EXPORT Reflex::KeyCode
	value_to<Reflex::KeyCode> (int argc, const Value* argv, bool convert)
	{
		assert(argc > 0 && argv);

		int code = value_to<int>(*argv, convert);
		if (
			code != Reflex::KEY_NONE &&
			get_key_symbol((Reflex::KeyCode) code).is_nil())
		{
			argument_error(__FILE__, __LINE__, "invalid key code -- %d", code);
		}

		return (Reflex::KeyCode) code;
	}

}// Rucy


namespace Reflex
{


	Module
	reflex_module ()
	{
		return mReflex;
	}


}// Reflex
