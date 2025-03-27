#include "midi.h"


#include <algorithm>
#include <RtMidi.h>
#include <xot/time.h>
#include "reflex/exception.h"
#include "reflex/debug.h"
#include "application.h"


namespace Reflex
{


	struct MIDI::Data
	{

		RtMidiIn input;

		String name;

		~Data ()
		{
			input.closePort();
		}

	};// MIDI::Data


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
	note_on (MIDI* midi, int channel, int note, float velocity)
	{
		doutln("note on: %d, %f", note, velocity);
	}

	static void
	note_off (MIDI* midi, int channel, int note, float velocity)
	{
		doutln("note off: %d, %f", note, velocity);
	}

	static void
	midi_callback (
		double timestamp, std::vector<unsigned char>* message, void* data)
	{
		MIDI* midi = (MIDI*) data;

		auto& bytes = *message;
		switch (bytes[0] >> 4)
		{
			case 0x9: note_on( midi, bytes[0] & 0xf, bytes[1], bytes[2] / 127.f); break;
			case 0x8: note_off(midi, bytes[0] & 0xf, bytes[1], bytes[2] / 127.f); break;
		}
	}

	static void
	midi_error (RtMidiError::Type type, const std::string& message, void* data)
	{
		MIDI* midi = (MIDI*) data;
		doutln("midi error: %s", message.c_str());
	}

	static void
	open_midi (MIDI* midi, uint port)
	{
		MIDI::Data* self = midi->self.get();

		if (port >= self->input.getPortCount())
			argument_error(__FILE__, __LINE__);

		self->name = self->input.getPortName(port);
		self->input.setCallback(midi_callback, midi);
		self->input.setErrorCallback(midi_error, midi);
		self->input.openPort(port);
		self->input.ignoreTypes(false, false, false);
	}


	struct MIDIDeviceManager
	{

		RtMidiIn manager;

		MIDI::List midis;

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

				MIDI::Ref midi = create_midi();
				open_midi(midi, port);

				midis.emplace_back(midi);
				Application_call_device_connect(app(), midi);
			});

			update_duplicated_port_name_count();
		}

		void on_disconnect ()
		{
			std::set<String> port_names;
			get_port_names(&port_names);

			auto removed = std::remove_if(
				midis.begin(), midis.end(),
				[&](auto& midi) {return !port_names.contains(midi->self->name);});

			for (auto it = removed; it != midis.end(); ++it)
				Application_call_device_disconnect(app(), *it);

			midis.erase(removed, midis.end());

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

	static double prev_time = 0;

	void
	process_events ()
	{
		if (!manager || (Xot::time() - prev_time) < 0.5)
			return;

		manager->update();

		prev_time = Xot::time();
	}

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
		static const MIDI::List EMPTY;
		return manager ? manager->midis : EMPTY;
	}


}// Reflex
