#include "beeps/filter.h"


#include <math.h>
#include <assert.h>
#include <algorithm>
#include "pffft.h"
#include "beeps/beeps.h"
#include "beeps/exception.h"
#include "signals.h"


namespace Beeps
{


	struct PFFFTDestroySetup
	{
		void operator () (PFFFT_Setup* ptr)
		{
			pffft_destroy_setup(ptr);
		}
	};

	struct PFFFTAlignedFree
	{
		void operator () (float* ptr)
		{
			pffft_aligned_free(ptr);
		}
	};


	struct Analyser::Data
	{

		Signals signals;

		Spectrum spectrum;

		std::unique_ptr<PFFFT_Setup, PFFFTDestroySetup> pffft;

		std::unique_ptr<float[], PFFFTAlignedFree> fft_buffer;

		uint fft_size = 0;

		~Data ()
		{
			clear();
		}

		void setup (uint size)
		{
			if (size == fft_size) return;

			if (size == 0 || size % 32 != 0)
				argument_error(__FILE__, __LINE__, "fft_size must be a multiple of 32");

			std::unique_ptr<PFFFT_Setup, PFFFTDestroySetup> setup(
				pffft_new_setup(size, PFFFT_REAL));
			if (!setup)
			{
				argument_error(
					__FILE__, __LINE__, "fft_size must have no prime factors but 2, 3, and 5");
			}

			clear();

			signals   = Signals(std::min(size, (uint) Beeps::sample_rate()));
			pffft     = std::move(setup);
			fft_buffer.reset((float*) pffft_aligned_malloc(sizeof(float) * size));
			fft_size  = size;
		}

		void clear ()
		{
			if (!pffft) return;

			signals   = Signals();
			spectrum  .clear();
			pffft     .reset();
			fft_buffer.reset();
			fft_size  = 0;
		}

		bool is_valid () const
		{
			return signals && pffft && fft_buffer && fft_size > 0;
		}

	};// Analyser::Data


	Analyser::Analyser (uint fft_size, Processor* input)
	:	Super(input)
	{
		set_fft_size(fft_size);
	}

	Analyser::~Analyser ()
	{
	}

	void
	Analyser::set_fft_size (uint size)
	{
		self->setup(size);
	}

	uint
	Analyser::fft_size () const
	{
		return self->fft_size;
	}

	float
	Analyser::resolution () const
	{
		if (self->fft_size == 0) return 0;
		return self->signals.sample_rate() / self->fft_size;
	}

	const Signals&
	Analyser::signals () const
	{
		return self->signals;
	}

	static void
	apply_hann_window (float* buffer, uint nsamples)
	{
		for (uint i = 0; i < nsamples; ++i)
			buffer[i] *= 0.5 * (1 - cos(2 * M_PI * i / nsamples));
	}

	static uint
	copy_signals_to_fft_buffer (float* buffer, uint size, const Signals& signals)
	{
		const double* samples = signals.samples();
		uint nsamples         = size > signals.nsamples() ? signals.nsamples() : size;

		switch (signals.nchannels())
		{
			case 1:
				for (uint i = 0; i < nsamples; ++i)
					buffer[i] = samples[i];
				break;

			case 2:
				for (uint i = 0; i < nsamples; ++i, samples += 2)
					buffer[i] = (samples[0] + samples[1]) * 0.5;
				break;

			default:
				beeps_error(__FILE__, __LINE__);
		}

		apply_hann_window(buffer, nsamples);

		for (uint i = nsamples; i < size; ++i)
			buffer[i] = 0;

		return nsamples;
	}

	static void
	update_spectrum (
		Analyser::Spectrum* spectrum, const float* buffer, uint buffer_size,
		uint nsamples)
	{
		assert(spectrum && spectrum->empty() && buffer && (buffer_size % 2) == 0);

		uint size = buffer_size / 2;
		spectrum->reserve(size);

		if (nsamples == 0)
			return spectrum->resize(size, 0);

		// doubled back, as the Hann window halves the amplitudes
		float div = 2.0 / nsamples;

		// buffer[0] and [1] are the real DC and Nyquist, not a complex pair
		spectrum->push_back(fabs(buffer[0]) * div);
		for (uint i = 1; i < size; ++i)
		{
			const float* p = buffer + i * 2;
			spectrum->push_back(sqrt(p[0] * p[0] + p[1] * p[1]) * div * 2);
		}
	}

	const Analyser::Spectrum&
	Analyser::spectrum () const
	{
		if (self->spectrum.empty() && *this)
		{
			float* p      = &self->fft_buffer[0];
			uint nsamples = copy_signals_to_fft_buffer(p, self->fft_size, self->signals);
			pffft_transform_ordered(self->pffft.get(), p, p, NULL, PFFFT_FORWARD);
			update_spectrum(&self->spectrum, p, self->fft_size, nsamples);
		}
		return self->spectrum;
	}

	Analyser::operator bool () const
	{
		if (!Super::operator bool()) return false;
		return self->is_valid();
	}

	bool
	Analyser::seekable () const
	{
		const Processor* in = input();
		return !in || in->seekable();
	}

	static void
	shift (Signals* signals, uint nsamples)
	{
		if (nsamples == 0)
			return;

		if (nsamples > signals->nsamples())
			return signals->clear();

		Sample* from         = Signals_at(signals, nsamples);
		Sample* to           = Signals_at(signals, 0);
		uint nsamples_remain = signals->nsamples() - nsamples;
		uint size            = nsamples_remain * signals->nchannels();
		for (uint i = 0; i < size; ++i)
			*to++ = *from++;

		Signals_set_nsamples(signals, nsamples_remain);
	}

	static void
	append (Signals* to, const Signals& from)
	{
		assert(to->nchannels() == from.nchannels());

		uint nchannels       =  to->nchannels();
		uint nsamples        = std::min(from.nsamples(), to->capacity() - to->nsamples());
		uint size            = nsamples * nchannels;
		      Sample*   to_p = Signals_at(to,   to->nsamples());
		const Sample* from_p = Signals_at(from, from.nsamples() - nsamples);
		for (uint i = 0; i < size; ++i)
			*to_p++ = *from_p++;

		Signals_set_nsamples(to, to->nsamples() + nsamples);
	}

	void
	Analyser::filter (Context* context, Signals* signals, uint* offset)
	{
		Super::filter(context, signals, offset);

		auto& in =      *signals;
		auto& my = self->signals;

		if (my.nchannels() != in.nchannels() || my.sample_rate() != in.sample_rate())
			my = Signals(my.capacity(), in.nchannels(), in.sample_rate());

		uint total_nsamples = my.nsamples() + in.nsamples();
		if (total_nsamples > my.capacity())
			shift(&my, total_nsamples - my.capacity());

		append(&my, in);

		self->spectrum.clear();
	}


}// Beeps
