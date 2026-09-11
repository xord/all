// -*- mode: objc -*-
#import "../video.h"


#include <map>
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#ifdef IOS
#import <MobileCoreServices/UTCoreTypes.h>
#endif
#include <xot/util.h>
#include "rays/bitmap.h"
#include "rays/exception.h"
#include "video_audio_in.h"


namespace Rays
{


	struct VideoDecoder::Data
	{

		String path;

		virtual ~Data () {}

		virtual void get_bitmap (Bitmap* bitmap, size_t index) = 0;

		virtual VideoAudioInList get_audio_tracks () const
		{
			return {};
		}

		virtual coord width () const = 0;

		virtual coord height () const = 0;

		virtual float fps () const = 0;

		virtual size_t size () const = 0;

		virtual operator bool () const = 0;

	};// VideoDecoder::Data


	static void
	copy_pixels (Bitmap* bitmap, CMSampleBufferRef sample)
	{
		if (!bitmap)
			argument_error(__FILE__, __LINE__);
		if (!*bitmap)
			argument_error(__FILE__, __LINE__, "bitmap is empty");
		if (!sample)
			argument_error(__FILE__, __LINE__);

		CVImageBufferRef pixel_buffer = CMSampleBufferGetImageBuffer(sample);
		if (!pixel_buffer)
			rays_error(__FILE__, __LINE__, "sample has no image buffer");

		int w = (int) CVPixelBufferGetWidth(pixel_buffer);
		int h = (int) CVPixelBufferGetHeight(pixel_buffer);
		if (bitmap->width() != w || bitmap->height() != h)
		{
			rays_error(
				__FILE__, __LINE__,
				"frame size %dx%d does not match the video size %dx%d",
				w, h, bitmap->width(), bitmap->height());
		}
		if (bitmap->color_space().type() != RGBA)
			argument_error(__FILE__, __LINE__, "bitmap must be RGBA");

		CVPixelBufferLockBaseAddress(pixel_buffer, kCVPixelBufferLock_ReadOnly);
		{
			// the reader hands out BGRA, the bitmap is RGBA
			const uint8_t* src = (const uint8_t*) CVPixelBufferGetBaseAddress(pixel_buffer);
			size_t src_pitch   = CVPixelBufferGetBytesPerRow(pixel_buffer);
			for (int y = 0; y < h; ++y)
			{
				const uint8_t* s = src + y * src_pitch;
				uint8_t*       d = bitmap->at<uint8_t>(0, y);
				for (int x = 0; x < w; ++x, s += 4, d += 4)
				{
					d[0] = s[2];
					d[1] = s[1];
					d[2] = s[0];
					d[3] = s[3];
				}
			}
		}
		CVPixelBufferUnlockBaseAddress(pixel_buffer, kCVPixelBufferLock_ReadOnly);
	}

	static void
	copy_pixels (Bitmap* bitmap, CGImageRef cgimage)
	{
		if (!bitmap)
			argument_error(__FILE__, __LINE__);
		if (!*bitmap)
			argument_error(__FILE__, __LINE__, "bitmap is empty");
		if (!cgimage)
			argument_error(__FILE__, __LINE__);

		int w = (int) CGImageGetWidth(cgimage);
		int h = (int) CGImageGetHeight(cgimage);
		if (bitmap->width() != w || bitmap->height() != h)
		{
			rays_error(
				__FILE__, __LINE__,
				"frame size %dx%d does not match the video size %dx%d",
				w, h, bitmap->width(), bitmap->height());
		}
		if (bitmap->color_space().type() != RGBA)
			argument_error(__FILE__, __LINE__, "bitmap must be RGBA");

		std::shared_ptr<CGColorSpace> colorspace(
			CGColorSpaceCreateDeviceRGB(),
			CGColorSpaceRelease);
		std::shared_ptr<CGContext> context(
			CGBitmapContextCreate(
				bitmap->pixels(), w, h, 8, bitmap->pitch(), colorspace.get(),
				(CGBitmapInfo) kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big),
			CGContextRelease);
		CGContextSetBlendMode(context.get(), kCGBlendModeCopy);
		CGContextDrawImage(context.get(), CGRectMake(0, 0, w, h), cgimage);
	}


	typedef std::shared_ptr<opaqueCMSampleBuffer> CMSampleBufferPtr;


	struct VideoFileDecoder : VideoDecoder::Data
	{

		enum {SKIP_MAX = 10};

		AVAsset* asset              = nil;

		AVAssetTrack* video_track   = nil;

		AVAssetReader* reader       = nil;

		AVAssetReaderOutput* output = nil;

		ssize_t next_index          = -1;

		VideoFileDecoder (const char* path)
		{
			NSURL* url = [NSURL fileURLWithPath: [NSString stringWithUTF8String: path]];
			if (!url)
				rays_error(__FILE__, __LINE__, "invalid file path");

			AVURLAsset* asset_ =
				[[[AVURLAsset alloc] initWithURL: url options: nil] autorelease];
			if (!asset_)
				rays_error(__FILE__, __LINE__, "failed to create AVURLAsset");

			NSArray<AVAssetTrack*>* tracks =
				[asset_ tracksWithMediaType: AVMediaTypeVideo];
			if (!tracks || tracks.count == 0)
				rays_error(__FILE__, __LINE__, "no video tracks found");

			AVAssetTrack* track = tracks[0];
			if (track.nominalFrameRate <= 0)
				rays_error(__FILE__, __LINE__, "invalid fps");

			asset       = [asset_ retain];
			video_track = [track retain];
		}

		~VideoFileDecoder ()
		{
			stop_reading();
			[video_track release];
			[asset       release];
		}

		void get_bitmap (Bitmap* bitmap, size_t index) override
		{
			ssize_t sindex = (ssize_t) index;
			if (next_index < 0 || sindex < next_index || sindex - next_index > SKIP_MAX)
				start_reading(frame_time(index));

			CMSampleBufferPtr sample = read_sample(sindex);
			if (!sample && reader.status == AVAssetReaderStatusFailed)
			{
				// a failed reader can not be reused, so try once more from scratch
				start_reading(frame_time(index));
				sample = read_sample(sindex);
			}
			if (!sample && reader.status == AVAssetReaderStatusCompleted)
			{
				// size() is an estimate, so an index past the end shows the last frame
				start_reading(last_frame_time());
				sample = read_sample(sindex);
			}
			if (!sample)
			{
				rays_error(
					__FILE__, __LINE__, "failed to decode frame %zu: %s",
					index, reader_error());
			}

			copy_pixels(bitmap, sample.get());
		}

		void start_reading (CMTime time)
		{
			stop_reading();

			NSError* error         = nil;
			AVAssetReader* reader_ =
				[[[AVAssetReader alloc] initWithAsset: asset error: &error] autorelease];
			if (!reader_ || error)
			{
				rays_error(
					__FILE__, __LINE__, "failed to create AVAssetReader: %s",
					error ? error.localizedDescription.UTF8String : "unknown");
			}

			NSDictionary* settings =
			@{
				(NSString*) kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)
			};
			AVAssetReaderOutput* output_ = nil;
			if (CGAffineTransformIsIdentity(video_track.preferredTransform))
			{
				AVAssetReaderTrackOutput* track_output = [AVAssetReaderTrackOutput
					assetReaderTrackOutputWithTrack: video_track outputSettings: settings];
				track_output.alwaysCopiesSampleData = NO;
				output_ = track_output;
			}
			else
			{
				// let a composition apply the track's rotation to each frame
				AVAssetReaderVideoCompositionOutput* composition_output =
					[AVAssetReaderVideoCompositionOutput
						assetReaderVideoCompositionOutputWithVideoTracks: @[video_track]
						videoSettings: settings];
				composition_output.videoComposition =
					[AVMutableVideoComposition videoCompositionWithPropertiesOfAsset: asset];
				composition_output.alwaysCopiesSampleData = NO;
				output_ = composition_output;
			}
			if (![reader_ canAddOutput: output_])
				rays_error(__FILE__, __LINE__, "cannot add output to AVAssetReader");
			[reader_ addOutput: output_];

			reader_.timeRange = CMTimeRangeMake(time, kCMTimePositiveInfinity);
			if (![reader_ startReading])
			{
				NSString* desc = reader_.error.localizedDescription;
				rays_error(
					__FILE__, __LINE__, "failed to start reading: %s",
					desc ? desc.UTF8String : "unknown");
			}

			reader     = [reader_ retain];
			output     = [output_ retain];
			next_index = frame_index(time);
		}

		void stop_reading ()
		{
			if (reader) [reader cancelReading];
			[output release];
			[reader release];
			output     = nil;
			reader     = nil;
			next_index = -1;
		}

		CMSampleBufferPtr read_sample (ssize_t index)
		{
			// Reads on until the sample shown at 'index', or the last one when the
			// stream ends before that. NULL on failure.

			CMSampleBufferPtr last;
			while (true)
			{
				CMSampleBufferPtr sample([output copyNextSampleBuffer], Xot::safe_cfrelease);
				if (!sample)
					return reader.status == AVAssetReaderStatusCompleted ? last : NULL;

				if (!CMSampleBufferGetImageBuffer(sample.get()))
					continue;

				ssize_t sample_index =
					frame_index(CMSampleBufferGetPresentationTimeStamp(sample.get()));
				next_index           = sample_index + 1;
				if (sample_index >= index) return sample;

				last = sample;
			}
		}

		CMTime frame_duration () const
		{
			CMTime duration = video_track.minFrameDuration;
			if (CMTIME_IS_VALID(duration) && duration.value > 0)
				return duration;

			return CMTimeMakeWithSeconds(1 / fps(), 600);
		}

		CMTime frame_time (size_t index) const
		{
			return CMTimeMultiply(frame_duration(), (int32_t) index);
		}

		CMTime last_frame_time () const
		{
			CMTime end = CMTimeRangeGetEnd(video_track.timeRange);
			return CMTimeMaximum(CMTimeSubtract(end, frame_duration()), kCMTimeZero);
		}

		ssize_t frame_index (CMTime time) const
		{
			// A frame that straddles the start of the time range comes out with its
			// time clipped to the start, so truncate rather than round

			CMTime duration = frame_duration();
			CMTime t        = CMTimeConvertScale(
				time, duration.timescale, kCMTimeRoundingMethod_RoundTowardZero);
			return (ssize_t) (t.value / duration.value);
		}

		const char* reader_error () const
		{
			NSString* desc = reader ? reader.error.localizedDescription : nil;
			return desc ? desc.UTF8String : "unknown";
		}

		VideoAudioInList get_audio_tracks () const override
		{
			NSArray<AVAssetTrack*>* tracks =
				[asset tracksWithMediaType: AVMediaTypeAudio];
			if (!tracks || tracks.count == 0)
				return {};

			VideoAudioInList list;
			for (AVAssetTrack* track in tracks)
				list.emplace_back(new VideoAudioIn(VideoAudioIn_Data_create(asset, track)));

			return list;
		}

		CGSize frame_size () const
		{
			// the size after the track's rotation is applied
			CGSize size = CGSizeApplyAffineTransform(
				video_track.naturalSize, video_track.preferredTransform);
			return CGSizeMake(fabs(size.width), fabs(size.height));
		}

		coord width () const override
		{
			return (int) std::round(frame_size().width);
		}

		coord height () const override
		{
			return (int) std::round(frame_size().height);
		}

		float fps () const override
		{
			return video_track.nominalFrameRate;
		}

		size_t size () const override
		{
			double duration = CMTimeGetSeconds(video_track.timeRange.duration);
			return (size_t) std::round(duration * fps());
		}

		operator bool () const override
		{
			return asset && video_track && video_track.nominalFrameRate > 0;
		}

	};// VideoFileDecoder


	struct GIFFileDecoder : VideoDecoder::Data
	{

		enum {DEFAULT_FPS = 10};

		std::shared_ptr<CGImageSource> source;

		int w = 0, h = 0;

		float fps_ = 0;

		GIFFileDecoder (const char* path)
		{
			NSURL* url = [NSURL fileURLWithPath: [NSString stringWithUTF8String: path]];
			if (!url)
				rays_error(__FILE__, __LINE__, "invalid file path");

			std::shared_ptr<CGImageSource> source(
				CGImageSourceCreateWithURL((CFURLRef) url, NULL),
				Xot::safe_cfrelease);
			if (!source)
				rays_error(__FILE__, __LINE__, "failed to create CGImageSource");

			size_t count = CGImageSourceGetCount(source.get());
			if (count == 0)
				rays_error(__FILE__, __LINE__, "GIF has no frames");

			std::shared_ptr<CGImage> first_frame(
				CGImageSourceCreateImageAtIndex(source.get(), 0, NULL),
				CGImageRelease);
			if (!first_frame)
				rays_error(__FILE__, __LINE__, "failed to decode first GIF frame");

			this->source = source;
			this->w      = (int) CGImageGetWidth(first_frame.get());
			this->h      = (int) CGImageGetHeight(first_frame.get());
			float delay  = get_frame_delay(0);
			this->fps_   = delay > 0 ? std::round(1 / delay) : (float) DEFAULT_FPS;
		}

		void get_bitmap (Bitmap* bitmap, size_t index) override
		{
			std::shared_ptr<CGImage> cgimage(
				CGImageSourceCreateImageAtIndex(source.get(), index, NULL),
				CGImageRelease);
			if (!cgimage)
			{
				rays_error(
					__FILE__, __LINE__, "failed to decode GIF frame %zu", index);
			}

			copy_pixels(bitmap, cgimage.get());
		}

		coord width () const override
		{
			return w;
		}

		coord height () const override
		{
			return h;
		}

		float fps () const override
		{
			return fps_;
		}

		size_t size () const override
		{
			return source ? CGImageSourceGetCount(source.get()) : 0;
		}

		operator bool () const override
		{
			return source && CGImageSourceGetCount(source.get()) > 0;
		}

		float get_frame_delay (size_t index)
		{
			std::shared_ptr<const __CFDictionary> props(
				CGImageSourceCopyPropertiesAtIndex(source.get(), index, NULL),
				Xot::safe_cfrelease);
			if (!props)
				return 0;

			CFDictionaryRef gif_props = NULL;
			if (!CFDictionaryGetValueIfPresent(
				props.get(), kCGImagePropertyGIFDictionary, (const void**) &gif_props))
			{
				return 0;
			}

			CFNumberRef num = NULL;
			if (CFDictionaryGetValueIfPresent(
				gif_props, kCGImagePropertyGIFUnclampedDelayTime, (const void**) &num))
			{
				float value = 0;
				CFNumberGetValue(num, kCFNumberFloatType, &value);
				if (value > 0) return value;
			}
			if (CFDictionaryGetValueIfPresent(
				gif_props, kCGImagePropertyGIFDelayTime, (const void**) &num))
			{
				float value = 0;
				CFNumberGetValue(num, kCFNumberFloatType, &value);
				if (value > 0) return value;
			}

			return 0;
		}

	};// GIFFileDecoder


	static bool
	is_gif_path (const char* path)
	{
		return String(path).downcase().ends_with(".gif");
	}


	VideoDecoder::VideoDecoder ()
	:	self(NULL)
	{
	}

	VideoDecoder::VideoDecoder (const char* path)
	:	self(NULL)
	{
		if (!path || *path == '\0')
			argument_error(__FILE__, __LINE__, "path is empty");

		if (is_gif_path(path))
			self.reset(new GIFFileDecoder(path));
		else
			self.reset(new VideoFileDecoder(path));

		self->path = path;
	}

	void
	VideoDecoder::get_bitmap (Bitmap* bitmap, size_t index)
	{
		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		self->get_bitmap(bitmap, index);
	}

	VideoAudioInList
	VideoDecoder::get_audio_tracks () const
	{
		if (!*this) return {};
		return self->get_audio_tracks();
	}

	const char*
	VideoDecoder::path () const
	{
		if (!*this) return "";
		return self->path.c_str();
	}

	coord
	VideoDecoder::width () const
	{
		if (!*this) return 0;
		return self->width();
	}

	coord
	VideoDecoder::height () const
	{
		if (!*this) return 0;
		return self->height();
	}

	float
	VideoDecoder::fps () const
	{
		if (!*this) return 0;
		return self->fps();
	}

	size_t
	VideoDecoder::size () const
	{
		if (!*this) return 0;
		return self->size();
	}

	VideoDecoder::operator bool () const
	{
		return self && *self;
	}

	bool
	VideoDecoder::operator ! () const
	{
		return !operator bool();
	}


	static CVPixelBufferRef
	create_pixel_buffer (const Bitmap& bmp)
	{
		CVPixelBufferRef pixel_buffer = NULL;
		CVReturn status               = CVPixelBufferCreate(
			kCFAllocatorDefault, bmp.width(), bmp.height(), kCVPixelFormatType_32BGRA,
			(CFDictionaryRef) @{
				(NSString*) kCVPixelBufferCGImageCompatibilityKey:         @YES,
				(NSString*) kCVPixelBufferCGBitmapContextCompatibilityKey: @YES,
			},
			&pixel_buffer);
		if (status != kCVReturnSuccess || !pixel_buffer)
			rays_error(__FILE__, __LINE__, "CVPixelBufferCreate() failed");

		CVPixelBufferLockBaseAddress(pixel_buffer, 0);

		void* dest        = CVPixelBufferGetBaseAddress(pixel_buffer);
		size_t dest_pitch = CVPixelBufferGetBytesPerRow(pixel_buffer);
		const void* src   = bmp.pixels();
		int src_pitch     = bmp.pitch();

		// Bitmap is RGBA, CVPixelBuffer is BGRA — need to swizzle
		for (int y = 0, h = bmp.height(); y < h; ++y)
		{
			const uint8_t* s = (const uint8_t*) src  + y *  src_pitch;
			uint8_t*       d = (uint8_t*)       dest + y * dest_pitch;
			for (int x = 0, w = bmp.width(); x < w; ++x)
			{
				d[x * 4 + 0] = s[x * 4 + 2]; // B
				d[x * 4 + 1] = s[x * 4 + 1]; // G
				d[x * 4 + 2] = s[x * 4 + 0]; // R
				d[x * 4 + 3] = s[x * 4 + 3]; // A
			}
		}

		CVPixelBufferUnlockBaseAddress(pixel_buffer, 0);
		return pixel_buffer;
	}

	static void
	save_as_video (const Video& video, const char* path, CFStringRef file_type)
	{
		NSURL* url = [NSURL fileURLWithPath: [NSString stringWithUTF8String: path]];

		// Remove existing file
		[[NSFileManager defaultManager] removeItemAtURL: url error: nil];

		NSError* error        = nil;
		AVAssetWriter* writer = [[[AVAssetWriter alloc]
			initWithURL: url fileType: (AVFileType) file_type error: &error]
			autorelease];
		if (!writer || error)
			rays_error(__FILE__, __LINE__, "AVAssetWriter creation failed");

		AVAssetWriterInput* input = [AVAssetWriterInput
			assetWriterInputWithMediaType: AVMediaTypeVideo outputSettings: @{
				AVVideoCodecKey:  AVVideoCodecH264,
				AVVideoWidthKey:  @(video.width()),
				AVVideoHeightKey: @(video.height()),
			}];
		input.expectsMediaDataInRealTime = NO;
		if (![writer canAddInput: input])
			rays_error(__FILE__, __LINE__, "cannot add writer input");

		AVAssetWriterInputPixelBufferAdaptor* adaptor =
			[AVAssetWriterInputPixelBufferAdaptor
				assetWriterInputPixelBufferAdaptorWithAssetWriterInput: input
				sourcePixelBufferAttributes: @{
					(NSString*) kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA),
					(NSString*) kCVPixelBufferWidthKey:           @(video.width()),
					(NSString*) kCVPixelBufferHeightKey:          @(video.height())
				}];

		[writer addInput: input];
		[writer startWriting];
		[writer startSessionAtSourceTime: kCMTimeZero];

		for (size_t i = 0, size = video.size(); i < size; ++i)
		{
			while (!input.readyForMoreMediaData)
				[NSThread sleepForTimeInterval: 0.01];

			CMTime time = CMTimeMake(i, (int32_t) video.fps());
			CVPixelBufferRef pixel_buffer = create_pixel_buffer(video[i].bitmap());
			bool result =
				[adaptor appendPixelBuffer: pixel_buffer withPresentationTime: time];
			CVPixelBufferRelease(pixel_buffer);
			if (!result)
				rays_error(__FILE__, __LINE__, "appendPixelBuffer failed at frame %zu", i);
		}

		[input markAsFinished];

		dispatch_semaphore_t sem = dispatch_semaphore_create(0);
		[writer finishWritingWithCompletionHandler: ^{
			dispatch_semaphore_signal(sem);
		}];
		dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
		dispatch_release(sem);

		if (writer.status != AVAssetWriterStatusCompleted)
		{
			rays_error(
				__FILE__, __LINE__, "video writing failed: %s",
				writer.error.localizedDescription.UTF8String);
		}
	}

	static CGImageRef
	create_cgimage_from_bitmap (const Bitmap& bmp)
	{
		std::shared_ptr<CGColorSpace> colorspace(
			CGColorSpaceCreateDeviceRGB(), CGColorSpaceRelease);
		std::shared_ptr<CGDataProvider> provider(
			CGDataProviderCreateWithData(
				NULL, bmp.pixels(), bmp.height() * bmp.pitch(), NULL),
			CGDataProviderRelease);
		return CGImageCreate(
			bmp.width(),
			bmp.height(),
			bmp.color_space().bpc(),
			bmp.color_space().Bpp() * 8,
			bmp.pitch(),
			colorspace.get(),
			(CGBitmapInfo) kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big,
			provider.get(),
			NULL,
			false,
			kCGRenderingIntentDefault);
	}

	static void
	save_as_gif (const Video& video, const char* path)
	{
		NSURL* url = [NSURL fileURLWithPath: [NSString stringWithUTF8String: path]];

		std::shared_ptr<CGImageDestination> dest(
			CGImageDestinationCreateWithURL((CFURLRef) url, kUTTypeGIF, video.size(), NULL),
			Xot::safe_cfrelease);
		if (!dest)
			rays_error(__FILE__, __LINE__, "CGImageDestinationCreateWithURL() failed");

		CGImageDestinationSetProperties(dest.get(), (CFDictionaryRef) @{
			(NSString*) kCGImagePropertyGIFDictionary: @{
				(NSString*) kCGImagePropertyGIFLoopCount: @0,// infinite loop
			}
		});

		NSDictionary* frame_props = @{
			(NSString*) kCGImagePropertyGIFDictionary: @{
				(NSString*) kCGImagePropertyGIFDelayTime: @(1.0 / video.fps()),
			},
		};
		for (size_t i = 0, size = video.size(); i < size; ++i)
		{
			std::shared_ptr<CGImage> cgimage(
				create_cgimage_from_bitmap(video[i].bitmap()),
				CGImageRelease);
			if (!cgimage)
				rays_error(__FILE__, __LINE__, "failed to get CGImage for frame %zu", i);

			CGImageDestinationAddImage(
				dest.get(), cgimage.get(), (CFDictionaryRef) frame_props);
		}

		if (!CGImageDestinationFinalize(dest.get()))
			rays_error(__FILE__, __LINE__, "CGImageDestinationFinalize() failed");
	}

	struct VideoFormats
	{

		StringList exts;

		std::map<String, AVFileType> ext2type;

	};// VideoFormats

	static const VideoFormats&
	get_video_formats ()
	{
		static VideoFormats formats = []()
		{
			VideoFormats formats;

			if (@available(macOS 11.0, iOS 14.0, *))
			{
				AVMutableComposition* comp = [AVMutableComposition composition];
				[comp addMutableTrackWithMediaType: AVMediaTypeVideo
					preferredTrackID: kCMPersistentTrackID_Invalid];

				AVAssetExportSession* session = [AVAssetExportSession
					exportSessionWithAsset: comp
					presetName: AVAssetExportPresetPassthrough];
				UTType* movie_type = [UTType typeWithIdentifier: @"public.movie"];
				for (AVFileType file_type in session.supportedFileTypes)
				{
					UTType* type = [UTType typeWithIdentifier: file_type];
					if (
						!type ||
						!type.preferredFilenameExtension ||
						![type conformsToType: movie_type])
					{
						continue;
					}
					String ext = type.preferredFilenameExtension.UTF8String;
					formats.exts.push_back(ext);
					formats.ext2type[ext] = file_type;
				}
			}
			else
			{
				formats.exts            = {"mp4", "mov", "m4v"};
				formats.ext2type["mp4"] = AVFileTypeMPEG4;
				formats.ext2type["mov"] = AVFileTypeQuickTimeMovie;
				formats.ext2type["m4v"] = AVFileTypeAppleM4V;
			}

			formats.exts.push_back("gif");
			return formats;
		}();
		return formats;
	}

	const StringList&
	get_video_exts ()
	{
		return get_video_formats().exts;
	}

	static CFStringRef
	get_video_file_type (const char* path_)
	{
		String path = String(path_).downcase();
		auto dot    = path.rfind('.');
		if (dot == String::npos)
			return nil;

		String ext      = path.substr(dot + 1);
		const auto& map = get_video_formats().ext2type;
		auto it         = map.find(ext);
		if (it == map.end())
			return nil;

		return (CFStringRef) it->second;
	}

	void
	Video::save (const char* path)
	{
		if (!path || *path == '\0')
			argument_error(__FILE__, __LINE__, "path is empty");
		if (empty())
			invalid_state_error(__FILE__, __LINE__, "no frames to save");

		if (is_gif_path(path))
			save_as_gif(*this, path);
		else
		{
			CFStringRef file_type = get_video_file_type(path);
			if (!file_type)
				argument_error(__FILE__, __LINE__, "unsupported video format");
			save_as_video(*this, path, file_type);
		}
	}


}// Rays
