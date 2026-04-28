// -*- mode: objc -*-
#import "video_audio_in.h"


#import <AVFoundation/AVFoundation.h>
#include "rays/exception.h"


namespace Rays
{


	struct VideoAudioIn::Data
	{

		AVAsset* asset            = nil;

		AVAssetTrack* audio_track = nil;

		uint nsamples = 0;

		Beeps::Signals buffer;

		uint           buffer_offset = 0;

		AVAssetReader* reader               = nil;

		AVAssetReaderAudioMixOutput* output = nil;

		Data (AVAsset* asset, AVAssetTrack* audio_track)
		{
			assert(asset && audio_track);

			CMFormatDescriptionRef format =
				(__bridge CMFormatDescriptionRef) audio_track.formatDescriptions.firstObject;
			if (!format)
				rays_error(__FILE__, __LINE__, "failed to get CMFormatDescription");

			const AudioStreamBasicDescription* desc =
				CMAudioFormatDescriptionGetStreamBasicDescription(format);
			if (!desc)
				rays_error(__FILE__, __LINE__, "failed to get AudioStreamBasicDescription");

			this->asset       = [asset       retain];
			this->audio_track = [audio_track retain];
			uint nchannels    = std::min<uint>(desc->mChannelsPerFrame, 2);
			this->buffer      = Beeps::Signals(2048, nchannels, desc->mSampleRate);
			double duration   = CMTimeGetSeconds(audio_track.timeRange.duration);
			this->nsamples    = (uint) (duration * buffer.sample_rate());
		}

		~Data ()
		{
			clear_reader();
			[audio_track release];
			[asset       release];
		}

		void create_reader (uint offset)
		{
			clear_reader();

			NSError* error        = nil;
			AVAssetReader* reader =
				[[[AVAssetReader alloc] initWithAsset: asset error: &error] autorelease];
			if (!reader || error)
				rays_error(__FILE__, __LINE__, "failed to create AVAssetReader");

			AVAssetReaderAudioMixOutput* output = [AVAssetReaderAudioMixOutput
				assetReaderAudioMixOutputWithAudioTracks: @[audio_track]
				audioSettings: @{
					AVFormatIDKey:               @(kAudioFormatLinearPCM),
					AVLinearPCMBitDepthKey:      @32,
					AVLinearPCMIsFloatKey:       @YES,
					AVLinearPCMIsNonInterleaved: @YES,
					AVNumberOfChannelsKey:       @(buffer.nchannels()),
				}];
			if (![reader canAddOutput: output])
				rays_error(__FILE__, __LINE__, "cannot add audio output");

			[reader addOutput: output];
			reader.timeRange = CMTimeRangeMake(
				CMTimeMakeWithSeconds(
					(double) offset / buffer.sample_rate(),
					(int32_t) buffer.sample_rate()),
				kCMTimePositiveInfinity);
			if (![reader startReading])
				rays_error(__FILE__, __LINE__, "failed to start reading audio");

			this->reader        = [reader retain];
			this->output        = [output retain];
			this->buffer_offset = offset;
			this->buffer        .clear();
		}

		void clear_reader ()
		{
			if (reader && reader.status == AVAssetReaderStatusReading)
				[reader cancelReading];

			[output release];
			output = nil;
			[reader release];
			reader = nil;
		}

		bool read_next (Beeps::Signals* signals, uint* offset)
		{
			assert(signals && offset);

			if (
				!reader ||
				*offset < buffer_offset ||
				*offset > buffer_offset + buffer.nsamples())
			{
				create_reader(*offset);
			}

			if (*offset == buffer_offset + buffer.nsamples())
			{
				if (!read_next_buffer()) return false;
				buffer_offset = *offset;
			}

			uint size = signals->append(buffer, *offset - buffer_offset);
			*offset += size;
			return size > 0;
		}

		bool read_next_buffer ()
		{
			if (!reader || !output || reader.status != AVAssetReaderStatusReading)
				return false;

			std::shared_ptr<opaqueCMSampleBuffer> samples(
				[output copyNextSampleBuffer],
				CFRelease);
			if (!samples)
				return false;

			uint nsamples = (uint) CMSampleBufferGetNumSamples(samples.get());
			if (nsamples <= 0)
				return false;

			CMBlockBufferRef block = CMSampleBufferGetDataBuffer(samples.get());
			if (!block)
				return false;

			size_t size = CMBlockBufferGetDataLength(block);
			char* data  = NULL;
			CMBlockBufferGetDataPointer(block, 0, NULL, &size, &data);
			if (!data || size <= 0)
				rays_error(__FILE__, __LINE__);

			CMFormatDescriptionRef format =
				CMSampleBufferGetFormatDescription(samples.get());
			if (!format)
				rays_error(__FILE__, __LINE__);

			const AudioStreamBasicDescription* desc =
				CMAudioFormatDescriptionGetStreamBasicDescription(format);
			if (!desc)
				rays_error(__FILE__, __LINE__);

			uint nchannels = desc->mChannelsPerFrame;
			if (nchannels != buffer.nchannels())
				rays_error(__FILE__, __LINE__);

			std::vector<const float*> channels(nchannels);
			for (uint ch = 0; ch < nchannels; ++ch)
				channels[ch] = (const float*) data + ch * nsamples;

			buffer.clear(nsamples);
			buffer.append(channels.data(), nsamples, nchannels, buffer.sample_rate());
			return buffer.nsamples() > 0;
		}

	};// VideoAudioIn::Data


	VideoAudioIn::Data*
	VideoAudioIn_Data_create (AVAsset* asset, AVAssetTrack* audio_track)
	{
		return new VideoAudioIn::Data(asset, audio_track);
	}


	VideoAudioIn::VideoAudioIn (Data* data)
	:	self(data)
	{
	}

	VideoAudioIn::~VideoAudioIn ()
	{
	}

	double
	VideoAudioIn::sample_rate () const
	{
		return self->buffer.sample_rate();
	}

	uint
	VideoAudioIn::nchannels () const
	{
		return self->buffer.nchannels();
	}

	uint
	VideoAudioIn::nsamples () const
	{
		return self->nsamples;
	}

	float
	VideoAudioIn::seconds () const
	{
		if (this->sample_rate() <= 0)
			return 0;

		return (float) (self->nsamples / this->sample_rate());
	}

	VideoAudioIn::operator bool () const
	{
		return
			Super::operator bool() &&
			self->asset &&
			self->audio_track &&
			self->buffer;
	}

	bool
	VideoAudioIn::seekable () const
	{
		return true;
	}

	void
	VideoAudioIn::generate (Context* context, Beeps::Signals* signals, uint* offset)
	{
		Super::generate(context, signals, offset);

		while (!signals->full())
		{
			if (!self->read_next(signals, offset))
				break;
		}
	}


}// Rays
