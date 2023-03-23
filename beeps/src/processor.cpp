#include "processor.h"


#include "SineWave.h"
#include "BlitSaw.h"
#include "BlitSquare.h"
#include "FileWvIn.h"
#include "beeps/exception.h"


namespace Beeps
{


	Processor::Processor ()
	{
	}

	Processor::~Processor ()
	{
	}

	void
	Processor::process (Signals* signals)
	{
		if (!signals || !*signals)
			argument_error(__FILE__, __LINE__);

		if (!*this)
			invalid_state_error(__FILE__, __LINE__);
	}

	Processor::operator bool () const
	{
		return true;
	}

	bool
	Processor::operator ! () const
	{
		return !operator bool();
	}


	struct SineWave::Data
	{

		stk::SineWave oscillator;

		float frequency;

	};// SineWave::Data


	SineWave::SineWave ()
	{
		set_frequency(440);
	}

	SineWave::~SineWave ()
	{
	}

	void
	SineWave::set_frequency (float frequency)
	{
		self->frequency = frequency;
		self->oscillator.setFrequency(frequency);
	}

	float
	SineWave::frequency () const
	{
		return self->frequency;
	}

	void
	SineWave::process (Signals* signals)
	{
		Super::process(signals);

		self->oscillator.tick(*Signals_get_frames(signals));
	}


	struct SquareWave::Data
	{

		stk::BlitSquare oscillator;

		float frequency;

	};// SquareWave::Data


	SquareWave::SquareWave ()
	{
		set_frequency(440);
	}

	SquareWave::~SquareWave ()
	{
	}

	void
	SquareWave::set_frequency (float frequency)
	{
		self->frequency = frequency;
		self->oscillator.setFrequency(frequency);
	}

	float
	SquareWave::frequency () const
	{
		return self->frequency;
	}

	void
	SquareWave::process (Signals* signals)
	{
		Super::process(signals);

		self->oscillator.tick(*Signals_get_frames(signals));
	}


	struct SawtoothWave::Data
	{

		stk::BlitSaw oscillator;

		float frequency;

	};// SawtoothWave::Data


	SawtoothWave::SawtoothWave ()
	{
		set_frequency(440);
	}

	SawtoothWave::~SawtoothWave ()
	{
	}

	void
	SawtoothWave::set_frequency (float frequency)
	{
		self->frequency = frequency;
		self->oscillator.setFrequency(frequency);
	}

	float
	SawtoothWave::frequency () const
	{
		return self->frequency;
	}

	void
	SawtoothWave::process (Signals* signals)
	{
		Super::process(signals);

		self->oscillator.tick(*Signals_get_frames(signals));
	}


	struct FileIn::Data
	{

		Signals signals;

	};// FileIn::Data


	FileIn::FileIn (const char* path)
	{
		if (path) self->signals = load_file(path);
	}

	FileIn::~FileIn ()
	{
	}

	void
	FileIn::process (Signals* signals)
	{
		Super::process(signals);

		Signals_copy(signals, self->signals);
	}

	uint
	FileIn::sampling_rate () const
	{
		return self->signals.sampling_rate();
	}

	uint
	FileIn::nchannels () const
	{
		return self->signals.nchannels();
	}

	float
	FileIn::seconds () const
	{
		return self->signals.seconds();
	}

	FileIn::operator bool () const
	{
		return self->signals;
	}


}// Beeps
