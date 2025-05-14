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


	struct RtMidiEvent
	{

		typedef std::vector<unsigned char> Message;

		enum Type {UNKNOWN, MESSAGE, ERROR};

		Type type = UNKNOWN;

		MIDI::Ref midi;

		Message message;

		RtMidiError error;

		double time = 0;

		RtMidiEvent ()
		:	error("")
		{
		}

		RtMidiEvent (MIDI* midi, const Message& message, double time)
		:	type(MESSAGE), midi(midi), message(message), error(""), time(time)
		{
		}

		RtMidiEvent (MIDI* midi, const RtMidiError& error)
		:	type(ERROR), midi(midi), error(error)
		{
		}

	};// RtMidiEvent


	static void
	call_midi_note_event (MIDI* midi, NoteEvent* event)
	{
		midi->on_note(event);
		if (event->is_blocked())
			return;

		switch ((int) event->action())
		{
			case NoteEvent::ON:  midi->on_note_on(event);  break;
			case NoteEvent::OFF: midi->on_note_off(event); break;
		}
	}

	static void
	call_midi_event (MIDI* midi, const uchar* bytes, double time)
	{
		MIDIEvent event(midi, bytes, time);

		midi->on_midi(&event);
		if (event.is_blocked()) return;

		NoteEvent note_event;
		if (MIDIEvent_to_note_event(&note_event, event))
			call_midi_note_event(midi, &note_event);

		Window* win = Window_get_active();
		if (!win) return;

		Window_call_midi_event(win, &event);
	}

	static Queue<RtMidiEvent> queue;

	static void
	dispatch_midi_event (RtMidiEvent* event)
	{
		switch (event->type)
		{
			case RtMidiEvent::MESSAGE:
				call_midi_event(event->midi, &event->message[0], event->time);
				break;

			case RtMidiEvent::ERROR:
				system_error(
					__FILE__, __LINE__,
					Xot::stringf("MIDI: %s", event->error.what()).c_str());
				break;

			case RtMidiEvent::UNKNOWN:
				invalid_state_error(__FILE__, __LINE__);
		}
	}

	static void
	process_midi_events ()
	{
		RtMidiEvent event;
		while (queue.try_pop(&event))
			dispatch_midi_event(&event);
	}

	static void
	event_callback (double dt, RtMidiEvent::Message* message, void* data)
	{
		MIDI* midi       = (MIDI*) data;
		MIDI::Data* self = midi->self.get();

		if (self->time == 0)
			self->time = Xot::time();
		else
			self->time += dt;

		queue.push(RtMidiEvent(midi, *message, self->time));
	}

	static void
	error_callback (RtMidiError::Type type, const std::string& message, void* data)
	{
		MIDI* midi = (MIDI*) data;

		queue.push(RtMidiEvent(midi, RtMidiError(message, type)));
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
	open_midi (MIDI* midi, uint port, const char* name)
	{
		MIDI::Data* self = midi->self.get();

		if (port >= self->input.getPortCount())
			argument_error(__FILE__, __LINE__);

		self->input.setCallback(event_callback, midi);
		self->input.setErrorCallback(error_callback, midi);
		self->input.openPort(port, name);
		self->input.ignoreTypes(false, false, false);
		self->name = name;
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

			each_port([&](int port, const std::string& name)
			{
				if (names.contains(name)) return;

				MIDI::Ref midi = create_midi();
				open_midi(midi, port, name.c_str());
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
			each_port([&](int, const std::string& name) {names->emplace(name);});
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
	MIDI::on_midi (MIDIEvent* e)
	{
	}

	void
	MIDI::on_note (NoteEvent* e)
	{
	}

	void
	MIDI::on_note_on (NoteEvent* e)
	{
	}

	void
	MIDI::on_note_off (NoteEvent* e)
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
