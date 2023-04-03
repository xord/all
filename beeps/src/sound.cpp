#include "sound.h"


#include <limits.h>
#include <algorithm>
#include "Stk.h"
#include "beeps/beeps.h"
#include "beeps/processor.h"
#include "beeps/exception.h"
#include "openal.h"
#include "signals.h"


#if 0
#define LOG(...) doutln(__VA_ARGS__)
#else
#define LOG(...)
#endif


namespace Beeps
{


	struct SoundBuffer
	{

		SoundBuffer (bool create = false)
		{
			if (create) self->create();
		}

		SoundBuffer (const Signals& signals)
		{
			self->create();
			write(signals);
		}

		SoundBuffer (ALint id)
		{
			self->id = id;
		}

		void write (const Signals& signals)
		{
			assert(signals);

			if (!*this)
				invalid_state_error(__FILE__, __LINE__);

			uint sample_rate = signals.sample_rate();
			uint nchannels   = signals.nchannels();
			uint nsamples    = signals.nsamples();
			assert(sample_rate > 0 && nchannels > 0 && nsamples > 0);

			const stk::StkFrames* frames = Signals_get_frames(&signals);
			assert(frames);

			std::vector<short> buffer;
			buffer.reserve(nsamples * nchannels);
			for (uint sample = 0; sample < nsamples; ++sample)
				for (uint channel = 0; channel < nchannels; ++channel)
					buffer.push_back((*frames)(sample, channel) * SHRT_MAX);

			alBufferData(
				self->id,
				nchannels == 2 ? AL_FORMAT_STEREO16 : AL_FORMAT_MONO16,
				&buffer[0],
				sizeof(short) * nsamples * nchannels,
				sample_rate);
			OpenAL_check_error(__FILE__, __LINE__);
		}

		operator bool () const
		{
			return self->is_valid();
		}

		bool operator ! () const
		{
			return !operator bool();
		}

		struct Data
		{

			ALint id = -1;

			bool owner = false;

			~Data ()
			{
				clear();
			}

			void create ()
			{
				clear();

				ALuint id_ = 0;
				alGenBuffers(1, &id_);
				OpenAL_check_error(__FILE__, __LINE__);

				id    = id_;
				owner = true;
			}

			void clear ()
			{
				if (owner && id >= 0)
				{
					ALuint id_ = id;
					alDeleteBuffers(1, &id_);
					OpenAL_check_error(__FILE__, __LINE__);
				}

				id    = -1;
				owner = false;
			}

			bool is_valid () const
			{
				return id >= 0;
			}

		};// Data

		Xot::PSharedImpl<Data> self;

	};// SoundBuffer


	struct SoundSource
	{

		void create ()
		{
			self->create();
		}

		SoundSource reuse ()
		{
			stop();
			set_gain(1);
			set_loop(false);

			while (unqueue());

			SoundSource source;
			source.self->id = self->id;
			self->id = -1;
			return source;
		}

		void attach (const SoundBuffer& buffer)
		{
			assert(buffer);

			if (!*this)
				invalid_state_error(__FILE__, __LINE__);

			alSourcei(self->id, AL_BUFFER, buffer.self->id);
			OpenAL_check_error(__FILE__, __LINE__);
		}

		void queue (const SoundBuffer& buffer)
		{
			assert(buffer);

			ALuint id = buffer.self->id;
			alSourceQueueBuffers(self->id, 1, &id);
			OpenAL_check_error(__FILE__, __LINE__);

			LOG("queue: %d", buffer.self->id);
		}

		bool unqueue (SoundBuffer* buffer = NULL)
		{
			ALint count = 0;
			alGetSourcei(self->id, AL_BUFFERS_PROCESSED, &count);
			OpenAL_check_error(__FILE__, __LINE__);

			if (count <= 0) return false;

			ALuint id = 0;
			alSourceUnqueueBuffers(self->id, 1, &id);
			OpenAL_check_error(__FILE__, __LINE__);

			if (buffer) *buffer = SoundBuffer((ALint) id);
			return true;
		}

		void play ()
		{
			if (!*this)
				invalid_state_error(__FILE__, __LINE__);

			alSourcePlay(self->id);
			OpenAL_check_error(__FILE__, __LINE__);
		}

		void pause ()
		{
			if (!*this) return;

			alSourcePause(self->id);
			OpenAL_check_error(__FILE__, __LINE__);
		}

		void stop ()
		{
			if (!*this) return;

			alSourceStop(self->id);
			OpenAL_check_error(__FILE__, __LINE__);
		}

		bool is_playing () const
		{
			if (!*this) return false;

			ALint state = 0;
			alGetSourcei(self->id, AL_SOURCE_STATE, &state);
			OpenAL_check_error(__FILE__, __LINE__);

			return state == AL_PLAYING;
		}

		bool is_stopped () const
		{
			if (!*this) return true;

			ALint state = 0;
			alGetSourcei(self->id, AL_SOURCE_STATE, &state);
			OpenAL_check_error(__FILE__, __LINE__);

			return state == AL_STOPPED;
		}

		void set_gain (float gain)
		{
			if (!*this) return;

			alSourcef(self->id, AL_GAIN, gain);
			OpenAL_check_error(__FILE__, __LINE__);
		}

		float gain () const
		{
			float gain = 1;
			if (!*this) return gain;

			alGetSourcef(self->id, AL_GAIN, &gain);
			OpenAL_check_error(__FILE__, __LINE__);

			return gain;
		}

		void set_loop (bool loop)
		{
			if (!*this) return;

			alSourcei(self->id, AL_LOOPING, loop ? AL_TRUE : AL_FALSE);
			OpenAL_check_error(__FILE__, __LINE__);
		}

		bool loop () const
		{
			if (!*this) return false;

			ALint loop = AL_FALSE;
			alGetSourcei(self->id, AL_LOOPING, &loop);
			OpenAL_check_error(__FILE__, __LINE__);

			return loop != AL_FALSE;
		}

		operator bool () const
		{
			return self->id >= 0;
		}

		bool operator ! () const
		{
			return !operator bool();
		}

		struct Data
		{

			ALint id = -1;

			~Data ()
			{
				clear();
			}

			void create ()
			{
				ALuint id_ = 0;
				alGenSources(1, &id_);
				if (OpenAL_no_error()) id = id_;
			}

			void clear ()
			{
				if (id < 0) return;

				ALuint id_ = id;
				alDeleteSources(1, &id_);
				OpenAL_check_error(__FILE__, __LINE__);

				id = -1;
			}

		};// Data

		Xot::PSharedImpl<Data> self;

	};// SoundSource


	struct SoundPlayer::Data
	{

		SoundSource source;

		Processor::Ref processor;

		Signals streaming_signals;

		uint streaming_offset = 0;

		std::vector<SoundBuffer> buffers;

		void attach_signals (const Signals& signals)
		{
			assert(signals);

			SoundBuffer buffer(signals);
			source.attach(buffer);
			buffers.emplace_back(buffer);
		}

		void attach_stream (Processor* processor, uint nchannels, uint sample_rate)
		{
			assert(processor && *processor && nchannels > 0 && sample_rate > 0);

			this->processor   = processor;
			streaming_signals = Signals_create(sample_rate / 1, nchannels, sample_rate);

			for (int i = 0; i < 2; ++i)
			{
				SoundBuffer buffer(true);
				if (!process_stream(&buffer)) break;

				source.queue(buffer);
				buffers.emplace_back(buffer);
			}
		}

		bool process_stream (SoundBuffer* buffer)
		{
			assert(buffer && *buffer);

			auto& sig = streaming_signals;
			if (!sig) return false;

			Signals_set_nsamples(&sig, 0);
			processor->process(&sig, &streaming_offset);

			bool has_samples = sig.nsamples() > 0;
			if (has_samples)
				buffer->write(sig);

			if (sig.nsamples() < sig.capacity())
				sig = Signals();// finish streaming

			return has_samples;
		}

		void process_and_queue_stream_buffers ()
		{
			SoundBuffer buffer;
			while (is_streaming())
			{
				if (!source.unqueue(&buffer))
					return;

				if (!process_stream(&buffer))
					return;

				source.queue(buffer);
				if (source.is_stopped()) source.play();
			}
		}

		bool is_streaming () const
		{
			return processor && streaming_signals;
		}

	};// SoundPlayer::Data


	static SoundPlayer
	create_player ()
	{
		SoundPlayer player;
		player.self->source.create();
		return player;
	}

	static SoundPlayer
	reuse_player (SoundPlayer* player)
	{
		SoundPlayer newplayer;
		newplayer.self->source = player->self->source.reuse();
		return newplayer;
	}


	namespace global
	{

		static std::vector<SoundPlayer> players;

	}// global


	static void
	remove_inactive_players ()
	{
		auto it = std::remove_if(
			global::players.begin(),
			global::players.end(),
			[](auto& player) {return !player || player.is_stopped();});

		global::players.erase(it, global::players.end());
	}

	static SoundPlayer
	get_next_player ()
	{
		SoundPlayer player;

		for (auto& p : global::players)
		{
			if (p && p.is_stopped())
			{
				player = reuse_player(&p);
				LOG("reuse stopped player");
				break;
			}
		}

		if (!player)
		{
			player = create_player();
			LOG("new player");
		}

		if (!player)
		{
			player = reuse_player(&global::players.front());
			LOG("reuse oldest player");
		}

		remove_inactive_players();

		if (player)
			global::players.emplace_back(player);

		return player;
	}

	void
	SoundPlayer_process_streams ()
	{
		for (auto& player : global::players)
		{
			if (player.self->is_streaming())
				player.self->process_and_queue_stream_buffers();
		}
	}

	void
	SoundPlayer_clear_all ()
	{
		global::players.clear();
	}


	SoundPlayer::SoundPlayer ()
	{
	}

	SoundPlayer::~SoundPlayer ()
	{
	}

	void
	SoundPlayer::play ()
	{
		self->source.play();
	}

	void
	SoundPlayer::pause ()
	{
		self->source.pause();
	}

	void
	SoundPlayer::rewind ()
	{
		not_implemented_error(__FILE__, __LINE__);
	}

	void
	SoundPlayer::stop ()
	{
		self->source.stop();
	}

	bool
	SoundPlayer::is_playing () const
	{
		return
			self->source.is_playing() ||
			self->is_streaming() && self->source.is_stopped();
	}

	bool
	SoundPlayer::is_stopped () const
	{
		return self->source.is_stopped() && !self->is_streaming();
	}

	void
	SoundPlayer::set_gain (float gain)
	{
		self->source.set_gain(gain);
	}

	float
	SoundPlayer::gain () const
	{
		return self->source.gain();
	}

	void
	SoundPlayer::set_loop (bool loop)
	{
		self->source.set_loop(loop);
	}

	bool
	SoundPlayer::loop () const
	{
		return self->source.loop();
	}

	SoundPlayer::operator bool () const
	{
		return self->source;
	}

	bool
	SoundPlayer::operator ! () const
	{
		return !operator bool();
	}


	struct Sound::Data {

		virtual ~Data ()
		{
		}

		virtual void attach_to (SoundPlayer* player)
		{
			not_implemented_error(__FILE__, __LINE__);
		}

		virtual void save (const char* path) const
		{
			not_implemented_error(__FILE__, __LINE__);
		}

		virtual uint sample_rate () const
		{
			return 0;
		}

		virtual uint nchannels () const
		{
			return 0;
		}

		virtual float seconds () const
		{
			return 0;
		}

		virtual bool is_valid () const
		{
			return false;
		}

	};// Sound::Data


	struct SoundData : public Sound::Data
	{

		typedef Sound::Data Super;

		Signals signals;

		SoundData (
			Processor* processor, float seconds, uint nchannels, uint sample_rate)
		{
			assert(
				processor && *processor &&
				seconds > 0 && nchannels > 0 && sample_rate > 0);

			Signals signals =
				Signals_create(seconds * sample_rate, nchannels, sample_rate);
			if (!signals)
				beeps_error(__FILE__, __LINE__, "failed to create a signals");

			uint offset = 0;
			processor->process(&signals, &offset);
			if (!signals)
				beeps_error(__FILE__, __LINE__, "failed to process signals");

			this->signals = signals;
		}

		void attach_to (SoundPlayer* player) override
		{
			assert(player && *player);

			player->self->attach_signals(signals);
		}

		void save (const char* path) const override
		{
			if (!signals)
				invalid_state_error(__FILE__, __LINE__);

			Signals_save(signals, path);
		}

		uint sample_rate () const override
		{
			return signals ? signals.sample_rate() : Super::sample_rate();
		}

		uint nchannels () const override
		{
			return signals ? signals.nchannels() : Super::sample_rate();
		}

		float seconds () const override
		{
			return signals ? Signals_get_seconds(signals) : Super::seconds();
		}

		bool is_valid () const override
		{
			return signals;
		}

	};// SoundData


	struct StreamSoundData : public Sound::Data
	{

		Processor::Ref processor;

		uint sample_rate_ = 0, nchannels_ = 0;

		StreamSoundData (Processor* processor, uint nchannels, uint sample_rate)
		{
			assert(processor && *processor && nchannels > 0 && sample_rate > 0);

			this->processor    = processor;
			this->sample_rate_ = sample_rate;
			this->nchannels_   = nchannels;
		}

		void attach_to (SoundPlayer* player) override
		{
			assert(player && *player);

			player->self->attach_stream(processor, nchannels_, sample_rate_);
		}

		uint sample_rate () const override
		{
			return sample_rate_;
		}

		uint nchannels () const override
		{
			return nchannels_;
		}

		float seconds () const override
		{
			return -1;
		}

		bool is_valid () const override
		{
			return processor && sample_rate_ > 0 && nchannels_ > 0;
		}

	};// StreamSoundData


	Sound
	load_sound (const char* path)
	{
		FileIn* f = new FileIn(path);
		return Sound(f, f->seconds(), f->nchannels(), f->sample_rate());
	}


	Sound::Sound ()
	{
	}

	Sound::Sound (
		Processor* processor, float seconds, uint nchannels, uint sample_rate)
	{
		Processor::Ref ref = processor;

		if (!processor || !*processor)
			argument_error(__FILE__, __LINE__);

		if (sample_rate <= 0) sample_rate = Beeps::sample_rate();

		if (seconds > 0)
			self.reset(new SoundData(processor, seconds, nchannels, sample_rate));
		else
			self.reset(new StreamSoundData(processor, nchannels, sample_rate));
	}

	Sound::~Sound ()
	{
	}

	SoundPlayer
	Sound::play ()
	{
		SoundPlayer player = get_next_player();
		if (!player)
			invalid_state_error(__FILE__, __LINE__);

		self->attach_to(&player);
		player.play();

#if 0
		std::string ox = "";
		for (auto& player : global::players)
			ox += player.is_playing() ? 'o' : 'x';
		LOG("%d players. (%s)", global::players.size(), ox.c_str());
#endif

		return player;
	}

	void
	Sound::save (const char* path) const
	{
		self->save(path);
	}

	uint
	Sound::sample_rate () const
	{
		return self->sample_rate();
	}

	uint
	Sound::nchannels () const
	{
		return self->nchannels();
	}

	float
	Sound::seconds () const
	{
		return self->seconds();
	}

	Sound::operator bool () const
	{
		return self->is_valid();
	}

	bool
	Sound::operator ! () const
	{
		return !operator bool();
	}


}// Beeps
