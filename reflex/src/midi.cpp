#include "midi.h"


#include <math.h>
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

		RtMidiOut output;

		String name;

		double time   = 0;

		bool virtual_ = false;

		~Data ()
		{
			close();
		}

		void close ()
		{
			input.closePort();
			output.closePort();
			virtual_ = false;
		}

	};// MIDI::Data


	struct RtMidiEvent
	{

		typedef std::vector<unsigned char> Message;

		enum Type {UNKNOWN, MESSAGE, ERROR};

		Type type  = UNKNOWN;

		MIDI* midi = NULL;

		Message message;

		RtMidiError error;

		double time = 0, delta_time = 0;

		RtMidiEvent ()
		:	error("")
		{
		}

		RtMidiEvent (MIDI* midi, const Message& message, double time, double delta_time)
		:	type(MESSAGE), midi(midi), message(message), error(""),
			time(time), delta_time(delta_time)
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
	call_midi_event (MIDI* midi, const MIDIEvent& event)
	{
		NoteEvent note_e;
		if (MIDIEvent_to_note_event(&note_e, event))
			call_midi_note_event(midi, &note_e);

		ControlChangeEvent cc_e;
		if (MIDIEvent_to_control_change_event(&cc_e, event))
			midi->on_control_change(&cc_e);
	}

	static void
	call_events (MIDI* midi, const uchar* bytes, double time)
	{
		MIDIEvent event(midi, bytes, time);

		midi->on_midi(&event);
		if (event.is_blocked()) return;

		call_midi_event(midi, event);

		for (auto& win : Window_all())
		{
			MIDIEvent e = event.dup();
			Window_call_midi_event(win, &e);
		}
	}

	static MIDI::List midis;

	static MIDI::Ref
	find_midi (MIDI* midi)
	{
		auto it = std::find_if(
			midis.begin(), midis.end(),
			[=](const MIDI::Ref& ref) {return ref.get() == midi;});
		return it == midis.end() ? MIDI::Ref() : *it;
	}

	static double
	apply_time (MIDI* midi, const RtMidiEvent& event)
	{
		MIDI::Data* self = midi->self.get();
		if (self->time == 0)
			self->time  = event.time;
		else
			self->time += event.delta_time;
		return self->time;
	}

	static void
	dispatch_midi_event (RtMidiEvent* event)
	{
		switch (event->type)
		{
			case RtMidiEvent::MESSAGE:
			{
				MIDI::Ref midi = find_midi(event->midi);
				if (midi)
					call_events(midi, event->message.data(), apply_time(midi, *event));
				break;
			}

			case RtMidiEvent::ERROR:
				system_error(
					__FILE__, __LINE__,
					Xot::stringf("MIDI: %s", event->error.what()).c_str());
				break;

			case RtMidiEvent::UNKNOWN:
				invalid_state_error(__FILE__, __LINE__);
		}
	}

	static Queue<RtMidiEvent> queue;

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
		queue.push(RtMidiEvent((MIDI*) data, *message, Xot::time(), dt));
	}

	static void
	error_callback (RtMidiError::Type type, const std::string& message, void* data)
	{
		queue.push(RtMidiEvent((MIDI*) data, RtMidiError(message, type)));
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
	each_port (RtMidi& rtmidi, std::function<void(int, const std::string&)> fun)
	{
		uint size = rtmidi.getPortCount();
		for (uint i = 0; i < size; ++i)
			fun(i, rtmidi.getPortName(i));
	}

	static int
	find_port (RtMidi& rtmidi, const char* name)
	{
		int port = -1;
		each_port(rtmidi, [&](int i, const std::string& port_name)
		{
			if (port < 0 && port_name == name) port = i;
		});
		return port;
	}

	static void
	set_input_callbacks (MIDI* midi)
	{
		RtMidiIn& input = midi->self->input;
		input.setCallback(event_callback, midi);
		input.setErrorCallback(error_callback, midi);
		input.ignoreTypes(false, false, false);
	}

	static void
	open_midi (MIDI* midi, const char* name)
	{
		MIDI::Data* self = midi->self.get();
		self->name = name;

		int input = find_port(self->input, name);
		if (input >= 0)
		{
			set_input_callbacks(midi);
			self->input.openPort(input, name);
		}

		int output = find_port(self->output, name);
		if (output >= 0)
			self->output.openPort(output, name);
	}

	static void
	add_midi (MIDI* midi)
	{
		midis.emplace_back(midi);

		if (app()) Application_call_device_connect_event(app(), midi);
	}

	static void
	remove_midi (MIDI* midi)
	{
		MIDI::Ref ref = midi;
		auto it = std::find(midis.begin(), midis.end(), ref);
		if (it == midis.end()) return;

		midis.erase(it);
		if (app()) Application_call_device_disconnect_event(app(), ref);
	}


	struct MIDIDeviceManager
	{

		RtMidiIn inputs;

		RtMidiOut outputs;

		uint ninputs = 0, noutputs = 0;

		MIDIDeviceManager ()
		{
			update();
		}

		~MIDIDeviceManager ()
		{
			for (auto& midi : midis)
				Application_call_device_disconnect_event(app(), midi);
		}

		void update ()
		{
			uint nin = inputs.getPortCount(), nout = outputs.getPortCount();
			if (nin == ninputs && nout == noutputs)
				return;

			ninputs  = nin;
			noutputs = nout;

			// a MIDI is the input and the output of the same name
			std::set<String> port_names;
			std::vector<String> names_in_order;
			auto add_name = [&](int, const std::string& name)
			{
				if (port_names.emplace(name).second)
					names_in_order.emplace_back(name);
			};
			each_port(inputs,  add_name);
			each_port(outputs, add_name);

			while (true)
			{
				auto it = std::find_if(
					midis.begin(), midis.end(),
					[&](auto& midi) {return !port_names.contains(midi->self->name);});
				if (it == midis.end()) break;

				remove_midi(*it);
			}

			std::set<String> opened_names;
			for (auto& midi : midis)
				opened_names.emplace(midi->self->name);

			for (auto& name : names_in_order)
			{
				if (opened_names.contains(name)) continue;

				MIDI::Ref midi = create_midi();
				open_midi(midi, name);
				add_midi(midi);
			}
		}

	};// MIDIDeviceManager


	static std::unique_ptr<MIDIDeviceManager> manager;

	void
	MIDI_init (Application* app)
	{
#ifdef WASM
		return;
#endif

		if (!app)
			argument_error(__FILE__, __LINE__);

		if (manager) return;

		manager.reset(new MIDIDeviceManager());
	}

	void
	MIDI_fin (Application* app)
	{
		if (!app)
			argument_error(__FILE__, __LINE__);

		for (auto& midi : midis)
			midi->self->close();

		midis.clear();
		manager.reset();
	}

	void
	MIDI_open_virtual (MIDI* midi, const char* name)
	{
		if (!midi)
			argument_error(__FILE__, __LINE__);
		if (!name || *name == '\0')
			argument_error(__FILE__, __LINE__, "empty name.");
		if (*midi)
			invalid_state_error(__FILE__, __LINE__, "'%s' is opened already.", midi->name());

		MIDI::Data* self = midi->self.get();

		if (self->output.getCurrentApi() == RtMidi::WINDOWS_MM)
			not_implemented_error(__FILE__, __LINE__);

		set_input_callbacks(midi);
		self->input.openVirtualPort(name);
		self->output.openVirtualPort(name);
		self->name     = name;
		self->virtual_ = true;
		add_midi(midi);
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

	void
	enable_midi ()
	{
		Application* app_ = app();
		if (!app_)
			invalid_state_error(__FILE__, __LINE__);

		MIDI_init(app_);
	}


	MIDI::MIDI ()
	{
	}

	MIDI::MIDI (const char* name)
	{
		MIDI_open_virtual(this, name);
	}

	MIDI::~MIDI ()
	{
	}

	void
	MIDI::close ()
	{
		if (!self->virtual_)
			invalid_state_error(__FILE__, __LINE__, "only an opened virtual MIDI can be closed.");

		remove_midi(this);
		self->close();
	}

	static void
	send_message (MIDI* midi, uchar status, int channel, int data1, float data2)
	{
		if (channel < 0 || 15 < channel)
			argument_error(__FILE__, __LINE__, "invalid channel: %d", channel);

		if (!midi->has_output())
			invalid_state_error(__FILE__, __LINE__, "'%s' has no output port.", midi->name());

		uchar bytes[] = {
			(uchar) (status | channel),
			(uchar) data1,
			(uchar) round(data2 * 127)
		};
		midi->self->output.sendMessage(bytes, sizeof(bytes));
	}

	void
	MIDI::note_on (int note, float velocity, int channel)
	{
		if (note < 0 || 127 < note)
			argument_error(__FILE__, __LINE__, "invalid note: %d", note);
		if (velocity < 0 || 1 < velocity)
			argument_error(__FILE__, __LINE__, "invalid velocity: %f", velocity);

		send_message(this, 0x90, channel, note, velocity);
	}

	void
	MIDI::note_off (int note, float velocity, int channel)
	{
		if (note < 0 || 127 < note)
			argument_error(__FILE__, __LINE__, "invalid note: %d", note);
		if (velocity < 0 || 1 < velocity)
			argument_error(__FILE__, __LINE__, "invalid velocity: %f", velocity);

		send_message(this, 0x80, channel, note, velocity);
	}

	void
	MIDI::control_change (int controller, float value, int channel)
	{
		if (controller < 0 || 127 < controller)
			argument_error(__FILE__, __LINE__, "invalid controller: %d", controller);
		if (value < 0 || 1 < value)
			argument_error(__FILE__, __LINE__, "invalid value: %f", value);

		send_message(this, 0xB0, channel, controller, value);
	}

	const char*
	MIDI::name () const
	{
		return self->name;
	}

	bool
	MIDI::has_input () const
	{
		return self->input.isPortOpen() || self->virtual_;
	}

	bool
	MIDI::has_output () const
	{
		return self->output.isPortOpen() || self->virtual_;
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

	void
	MIDI::on_control_change (ControlChangeEvent* e)
	{
	}

	MIDI::operator bool () const
	{
		return has_input() || has_output();
	}

	const MIDI::List&
	MIDI::all ()
	{
		return midis;
	}


}// Reflex
