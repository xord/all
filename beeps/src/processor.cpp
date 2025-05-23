#include "processor.h"


#include <assert.h>
#include <xot/time.h>
#include "beeps/beeps.h"
#include "beeps/exception.h"
#include "beeps/debug.h"


namespace Beeps
{


	struct Processor::Data
	{

		bool generator = false, started = false, processing = false;

		float buffering_seconds = 0;

		double last_update_time = 0;

		Processor::Ref input;

		Processor::Map sub_inputs;

	};// Processor::Data


	Signals
	get_signals (
		Processor* processor, float seconds, uint nchannels, double sample_rate)
	{
		if (sample_rate == 0)
			sample_rate = Beeps::sample_rate();

		if (!processor)
			argument_error(__FILE__, __LINE__);
		if (!*processor)
			argument_error(__FILE__, __LINE__);
		if (seconds <= 0)
			argument_error(__FILE__, __LINE__);
		if (nchannels <= 0)
			argument_error(__FILE__, __LINE__);
		if (sample_rate <= 0)
			argument_error(__FILE__, __LINE__);

		StreamContext context(seconds * sample_rate, nchannels, sample_rate);
		return context.process_next(processor);
	}

	ProcessorContext*
	Processor_get_context(Processor::Context* context)
	{
		return (ProcessorContext*) context;
	}

	float
	Processor_get_buffering_seconds (Processor* processor)
	{
		assert(processor);

		return processor->self->buffering_seconds;
	}


	Processor::Processor (bool generator)
	{
		self->generator = generator;
	}

	Processor::~Processor ()
	{
	}

	void
	Processor::reset ()
	{
		self->started = false;

		if (self->input)
			self->input->reset();

		for (auto& kv : self->sub_inputs)
			kv.second->reset();

		set_updated();
	}

	void
	Processor::set_input (Processor* input)
	{
		if (input && self->generator)
			invalid_state_error(__FILE__, __LINE__, "generator cannot have input");

		self->input = input;

		set_updated();
	}

	Processor*
	Processor::input ()
	{
		return self->input;
	}

	const Processor*
	Processor::input () const
	{
		return const_cast<Processor*>(this)->input();
	}

	void
	Processor::on_start ()
	{
	}

	Processor::operator bool () const
	{
		return self->generator || (self->input && *self->input);
	}

	bool
	Processor::operator ! () const
	{
		return !operator bool();
	}

	void
	Processor::process (Context* context, Signals* signals, uint* offset)
	{
		if (!self->started)
		{
			self->started = true;
			on_start();
		}

		self->processing = true;

		if (self->generator)
			generate(context, signals, offset);
		else
			filter(context, signals, offset);

		self->processing = false;
	}

	void
	Processor::generate (Context* context, Signals* signals, uint* offset)
	{
		if (!context)
			argument_error(__FILE__, __LINE__);
		if (!signals)
			argument_error(__FILE__, __LINE__);
		if (!*signals)
			argument_error(__FILE__, __LINE__);
		if (signals->nsamples() > 0)
			argument_error(__FILE__, __LINE__);
		if (!offset)
			argument_error(__FILE__, __LINE__);

		if (!*this)
			invalid_state_error(__FILE__, __LINE__);
		if (self->input)
			invalid_state_error(__FILE__, __LINE__);
	}

	void
	Processor::filter (Context* context, Signals* signals, uint* offset)
	{
		if (!context)
			argument_error(__FILE__, __LINE__);
		if (!signals)
			argument_error(__FILE__, __LINE__);
		if (!*signals)
			argument_error(__FILE__, __LINE__);
		if (!offset)
			argument_error(__FILE__, __LINE__);

		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		if (self->input)
			Processor_get_context(context)->process(self->input, signals, offset);
	}

	int
	Processor::max_segment_size_for_process (
		double sample_rate, uint nsamples) const
	{
		return -1;
	}

	uint
	Processor::get_segment_size (double sample_rate, uint nsamples) const
	{
		uint size = nsamples;
		for (const auto& kv : self->sub_inputs)
		{
			const auto& processor = kv.second;

			int max = processor->max_segment_size_for_process(sample_rate, nsamples);
			if (max > 0 && (uint) max < size)
				size = (uint) max;
		}
		return size;
	}

	void
	Processor::set_sub_input (uint index, Processor* input)
	{
		if (input)
			self->sub_inputs[index] = input;
		else
			self->sub_inputs.erase(index);

		set_updated();
	}

	Processor*
	Processor::sub_input (uint index) const
	{
		auto it = self->sub_inputs.find(index);
		if (it == self->sub_inputs.end())
			return NULL;

		return it->second;
	}

	void
	Processor::clear_sub_input_unless_processing (uint index)
	{
		if (!self->processing)
			set_sub_input(index, NULL);
	}

	void
	Processor::set_updated ()
	{
		self->last_update_time = Xot::time();
	}


	Generator::Generator ()
	:	Super(true)
	{
	}

	void
	Generator::filter (Context* context, Signals* signals, uint* offset)
	{
		beeps_error(__FILE__, __LINE__);
	}


	Filter::Filter (Processor* input)
	:	Super(false)
	{
		if (input) set_input(input);
	}

	void
	Filter::set_buffering_seconds (float seconds)
	{
		Super::self->buffering_seconds = seconds;

		set_updated();
	}

	void
	Filter::generate (Context* context, Signals* signals, uint* offset)
	{
		beeps_error(__FILE__, __LINE__);
	}


	SignalsBuffer::SignalsBuffer (
		uint nsamples_per_block, uint nchannels, double sample_rate)
	{
		buffer = Signals_create(nsamples_per_block, nchannels, sample_rate);
		assert(*this);
	}

	void
	SignalsBuffer::process (
		ProcessorContext* context,
		Processor* processor, Signals* signals, uint* offset)
	{
		assert(processor && context && signals && offset);

		if (
			last_update_time < processor->self->last_update_time ||
			*offset < buffer_offset)
		{
			clear();
		}

		if (buffer.nsamples() == 0)
			buffer_next(context, processor, *offset);

		while (true)
		{
			*offset += Signals_copy(signals, buffer, *offset - buffer_offset);

			bool signals_full = signals->nsamples() == signals->capacity();
			bool  buffer_full =   buffer.nsamples() ==   buffer.capacity();
			if (signals_full || !buffer_full)
				break;

			buffer_next(context, processor, buffer_offset + buffer.nsamples());
		}
	}

	SignalsBuffer::operator bool () const
	{
		return buffer;
	}

	bool
	SignalsBuffer::operator ! () const
	{
		return !operator bool();
	}

	void
	SignalsBuffer::buffer_next (
		ProcessorContext* context, Processor* processor, uint offset)
	{
		Signals_clear(&buffer);
		buffer_offset = offset;
		context->process(processor, &buffer, &offset, true);

		last_update_time = Xot::time();
	}

	void
	SignalsBuffer::clear ()
	{
		Signals_clear(&buffer);
		buffer_offset = 0;
	}


	ProcessorContext::ProcessorContext (uint nchannels, double sample_rate)
	:	sample_rate(sample_rate), nchannels(nchannels)
	{
	}

	Sample
	ProcessorContext::process (
		Processor* processor, uint nsamples, uint offset, bool ignore_buffer)
	{
		assert(processor);

		if (!signal) signal = Signals_create(nsamples, 1, sample_rate);
		Signals_clear(&signal, nsamples);

		SignalsBuffer* buffer = NULL;
		uint offset_          = offset;
		if (!ignore_buffer && (buffer = get_buffer(processor)))
			buffer->process(this, processor, &signal, &offset_);
		else
			processor->process(this, &signal, &offset_);

		if (offset_ == offset || signal.empty())
			return 0;

		return *signal.samples();
	}

	void
	ProcessorContext::process (
		Processor* processor, Signals* signals, uint* offset, bool ignore_buffer)
	{
		assert(processor);

		SignalsBuffer* buffer = NULL;
		if (!ignore_buffer && (buffer = get_buffer(processor)))
			buffer->process(this, processor, signals, offset);
		else
			processor->process(this, signals, offset);
	}

	static uintptr_t
	get_buffer_key (Processor* processor)
	{
		assert(processor);

		return (uintptr_t) processor->self.get();
	}

	SignalsBuffer*
	ProcessorContext::get_buffer (Processor* processor)
	{
		float buffering_sec = Processor_get_buffering_seconds(processor);
		if (buffering_sec <= 0) return NULL;

		uintptr_t key = get_buffer_key(processor);
		auto it       = buffers.find(key);
		if (it != buffers.end()) return it->second.get();

		SignalsBuffer* buffer =
			new SignalsBuffer(buffering_sec * sample_rate, nchannels, sample_rate);

		buffers.emplace(key, buffer);
		return buffer;
	}


	StreamContext::StreamContext (
		uint nsamples_per_process, uint nchannels, double sample_rate)
	:	context(nchannels, sample_rate),
		signals(Signals_create(nsamples_per_process, nchannels, sample_rate)),
		nsamples_per_process(nsamples_per_process)
	{
	}

	Signals
	StreamContext::process_next (Processor* processor)
	{
		assert(processor);

		Signals_clear(&signals, nsamples_per_process);
		context.process(processor, &signals, &offset);

		if (signals.nsamples() < nsamples_per_process)
			finished = true;

		return signals;
	}

	bool
	StreamContext::is_finished () const
	{
		return finished;
	}


}// Beeps
