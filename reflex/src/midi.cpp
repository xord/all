#include "midi.h"


#include <algorithm>
#include <RtMidi.h>
#include <xot/time.h>
#include "reflex/exception.h"
#include "reflex/debug.h"
#include "queue.h"
#include "event.h"
#include "application.h"
#include "window.h"


namespace Reflex
{


	struct MIDI::Data
	{

		RtMidiIn input;

		String name;

		double time = 0;

		~Data ()
		{
			input.closePort();
		}

	};// MIDI::Data


	static void
	call_note_event (
		const MIDI* midi, bool on,
		int channel, int note, float velocity, double time)
	{
		Window* win = Window_get_active();
		if (!win) return;

		KeyEvent e(
			on ? KeyEvent::DOWN : KeyEvent::UP,
			NULL, KEY_MIDI_NOTE_0 + note, KeyEvent_get_modifiers(), 0);
		Window_call_key_event(win, &e);
	}


	struct MIDIEvent
	{

		typedef std::vector<unsigned char> Message;

		enum Type {UNKNOWN, MESSAGE, ERROR};

		Type type = UNKNOWN;

		MIDI::Ref midi;

		Message message;

		RtMidiError error;

		double time = 0;

		MIDIEvent ()
		:	error("")
		{
		}

		MIDIEvent (MIDI* midi, const Message& message, double time)
		:	type(MESSAGE), midi(midi), message(message), error(""), time(time)
		{
		}

		MIDIEvent (MIDI* midi, const RtMidiError& error)
		:	type(ERROR), midi(midi), error(error)
		{
		}

	};// MIDIEvent


	static Queue<MIDIEvent> queue;

	static void
	process_midi_event (const MIDIEvent& event)
	{
		switch (event.type)
		{
			case MIDIEvent::MESSAGE:
			{
				auto& bytes = event.message;
				switch (bytes[0] >> 4)
				{
					case 0x9:
						call_note_event(
							event.midi, true,
							bytes[0] & 0xf, bytes[1], bytes[2] / 127.f, event.time);
						break;

					case 0x8:
						call_note_event(
							event.midi, false,
							bytes[0] & 0xf, bytes[1], bytes[2] / 127.f, event.time);
						break;
				}
				break;
			}

			case MIDIEvent::ERROR:
				doutln("midi error: %s", event.error.what());
				break;
		}
	}

	static void
	process_midi_events ()
	{
		MIDIEvent event;
		while (queue.try_pop(&event))
			process_midi_event(event);
	}

	static void
	midi_callback (double dt, MIDIEvent::Message* message, void* data)
	{
		MIDI* midi       = (MIDI*) data;
		MIDI::Data* self = midi->self.get();

		if (self->time == 0)
			self->time = Xot::time();
		else
			self->time += dt;

		queue.push(MIDIEvent(midi, *message, self->time));
	}

	static void
	error_callback (RtMidiError::Type type, const std::string& message, void* data)
	{
		MIDI* midi = (MIDI*) data;

		queue.push(MIDIEvent(midi, RtMidiError(message, type)));
	}

	static MIDI_CreateFun midi_create_fun = NULL;

	void
	MIDI_set_create_fun (MIDI_CreateFun fun)
	{
		midi_create_fun = fun;
	}

	static MIDI*
	create_midi ()
	{
		return midi_create_fun ? midi_create_fun() : new MIDI();
	}

	static void
	open_midi (MIDI* midi, uint port)
	{
		MIDI::Data* self = midi->self.get();

		if (port >= self->input.getPortCount())
			argument_error(__FILE__, __LINE__);

		self->name = self->input.getPortName(port);
		self->input.setCallback(midi_callback, midi);
		self->input.setErrorCallback(error_callback, midi);
		self->input.openPort(port);
		self->input.ignoreTypes(false, false, false);
	}

	static MIDI::List midis;

	static void
	add_midi (MIDI* midi)
	{
		midis.emplace_back(midi);
		Application_call_device_connect(app(), midi);
	}

	static void
	remove_midi (MIDI* midi)
	{
		MIDI::Ref ref = midi;
		auto it = std::find(midis.begin(), midis.end(), ref);
		if (it == midis.end()) return;

		midis.erase(it);
		Application_call_device_disconnect(app(), ref);
	}


	struct MIDIDeviceManager
	{

		RtMidiIn manager;

		uint duplicated_port_name_count = 0;

		MIDIDeviceManager ()
		{
			update();
		}

		~MIDIDeviceManager ()
		{
			for (auto& midi : midis)
				Application_call_device_disconnect(app(), midi);
		}

		void update ()
		{
			uint count = manager.getPortCount() - duplicated_port_name_count;
			if (count > midis.size())
				on_connect();
			else if (count < midis.size())
				on_disconnect();
		}

		void on_connect ()
		{
			std::set<String> names;
			for (auto& midi : midis)
				names.emplace(midi->self->name);

			each_port([&](int port, auto& name)
			{
				if (names.contains(name)) return;

				MIDI* midi = create_midi();
				open_midi(midi, port);
				add_midi(midi);
			});

			update_duplicated_port_name_count();
		}

		void on_disconnect ()
		{
			std::set<String> port_names;
			get_port_names(&port_names);

			while (true)
			{
				auto it = std::find_if(
					midis.begin(), midis.end(),
					[&](auto& midi) {return !port_names.contains(midi->self->name);});
				if (it == midis.end()) break;

				remove_midi(*it);
			}

			update_duplicated_port_name_count();
		}

		void update_duplicated_port_name_count ()
		{
			std::set<String> port_names;
			get_port_names(&port_names);

			duplicated_port_name_count =
				manager.getPortCount() - (uint) port_names.size();
		}

		void get_port_names (std::set<String>* names)
		{
			each_port([&](int, auto& name) {names->emplace(name);});
		}

		void each_port (std::function<void(int, const std::string&)> fun)
		{
			uint size = manager.getPortCount();
			for (uint i = 0; i < size; ++i)
				fun(i, manager.getPortName(i));
		}

	};// MIDIDeviceManager


	static std::unique_ptr<MIDIDeviceManager> manager;

	void
	MIDI_init (Application* app)
	{
		if (manager)
			invalid_state_error(__FILE__, __LINE__);

		manager.reset(new MIDIDeviceManager());
	}

	void
	MIDI_fin (Application* app)
	{
		if (!manager)
			invalid_state_error(__FILE__, __LINE__);

		manager.reset();
	}

	void
	MIDI_process_events ()
	{
		process_midi_events();

		static double prev_time = 0;
		if (manager && Xot::time() - prev_time > 0.5)
		{
			manager->update();
			prev_time = Xot::time();
		}
	}


	MIDI::MIDI ()
	{
	}

	MIDI::~MIDI ()
	{
	}

	const char*
	MIDI::name () const
	{
		return self->name;
	}

	void
	MIDI::on_key (KeyEvent* e)
	{
	}

	void
	MIDI::on_key_down (KeyEvent* e)
	{
	}

	void
	MIDI::on_key_up (KeyEvent* e)
	{
	}

	MIDI::operator bool () const
	{
		return self->input.isPortOpen();
	}

	const MIDI::List&
	MIDI::all ()
	{
		return midis;
	}


}// Reflex
