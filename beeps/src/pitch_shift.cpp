#include "beeps/processor.h"


#include "PitShift.h"
#include "signalsmith-stretch.h"
#include "signals.h"


namespace Beeps
{


	struct PitchShift::Data
	{

		signalsmith::stretch::SignalsmithStretch<float> stretch;

		float shift = 1;

	};// PitchShift::Data


	PitchShift::PitchShift (Processor* input)
	:	Super(true)
	{
		set_input(input);
	}

	PitchShift::~PitchShift ()
	{
	}

	void
	PitchShift::set_shift (float shift)
	{
		self->shift = shift;
	}

	float
	PitchShift::shift () const
	{
		return self->shift;
	}

	void
	PitchShift::process (Signals* signals)
	{
		Super::process(signals);

		if (self->shift == 1) return;

		self->stretch.reset();
		self->stretch.presetDefault(signals->nchannels(), signals->sample_rate());
		self->stretch.setTransposeFactor(self->shift);

		SignalBuffer<float> input(*signals);
		SignalBuffer<float> output(signals->nsamples(), signals->nchannels());

		self->stretch.process(
			input.channels(),  input.nsamples(),
			output.channels(), output.nsamples());

		Signals_set_buffer(signals, output);
	}

	PitchShift::operator bool () const
	{
		if (!Super::operator bool()) return false;
		return self->shift > 0;
	}


}// Beeps