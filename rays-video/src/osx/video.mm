// -*- mode: objc -*-
#import "../video.h"


#include <map>
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#include "rays/bitmap.h"
#include "rays/exception.h"
#include "video_audio_in.h"


namespace Rays
{


	struct VideoReader::Data
	{

		virtual ~Data () {}

		virtual Image decode_image (size_t index, float pixel_density) const = 0;

		virtual VideoAudioInList get_audio_tracks () const
		{
			return {};
		}

		virtual coord width () const   = 0;

		virtual coord height () const  = 0;

		virtual float fps () const     = 0;

		virtual size_t size () const   = 0;

		virtual operator bool () const = 0;

	};// VideoReader::Data


	static Bitmap
	to_bitmap (CGImageRef cgimage)
	{
		if (!cgimage)
			argument_error(__FILE__, __LINE__);

		int w = (int) CGImageGetWidth(cgimage);
		int h = (int) CGImageGetHeight(cgimage);
		Bitmap bmp(w, h, RGBA);

		std::shared_ptr<CGColorSpace> colorspace(
			CGColorSpaceCreateDeviceRGB(),
			CGColorSpaceRelease);
		std::shared_ptr<CGContext> context(
			CGBitmapContextCreate(
				bmp.pixels(), w, h, 8, bmp.pitch(), colorspace.get(),
				(CGBitmapInfo) kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big),
			CGContextRelease);
		CGContextDrawImage(context.get(), CGRectMake(0, 0, w, h), cgimage);

		return bmp;
	}


	struct VideoFileReader : VideoReader::Data
	{

		AVAsset* asset = nil;

		AVAssetTrack* video_track = nil;

		VideoFileReader (const char* path)
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

		~VideoFileReader ()
		{
			[video_track release];
			[asset       release];
		}

		Image decode_image (size_t index, float pixel_density) const override
		{
			AVAssetImageGenerator* generator =
				[[[AVAssetImageGenerator alloc] initWithAsset: asset] autorelease];
			generator.appliesPreferredTrackTransform = YES;
			generator.requestedTimeToleranceBefore   = kCMTimeZero;
			generator.requestedTimeToleranceAfter    = kCMTimeZero;

			CMTime time    = CMTimeMakeWithSeconds((double) index / fps(), 600);
			NSError* error = nil;
			std::shared_ptr<CGImage> cgimage(
				[generator copyCGImageAtTime: time actualTime: nil error: &error],
				CGImageRelease);
			if (!cgimage || error)
			{
				rays_error(
					__FILE__, __LINE__, "failed to decode frame %zu: %s",
					index, error ? error.localizedDescription.UTF8String : "unknown");
			}

			return Image(to_bitmap(cgimage.get()), pixel_density);
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

		coord width () const override
		{
			return (int) video_track.naturalSize.width;
		}

		coord height () const override
		{
			return (int) video_track.naturalSize.height;
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

	};// VideoFileReader


	struct GIFFileReader : VideoReader::Data
	{

		enum {DEFAULT_FPS = 10};

		std::shared_ptr<CGImageSource> source;

		int w = 0, h = 0;

		float fps_ = 0;

		GIFFileReader (const char* path)
		{
			NSURL* url = [NSURL fileURLWithPath: [NSString stringWithUTF8String: path]];
			if (!url)
				rays_error(__FILE__, __LINE__, "invalid file path");

			std::shared_ptr<CGImageSource> source(
				CGImageSourceCreateWithURL((CFURLRef) url, NULL),
				CFRelease);
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
			this->fps_   = delay > 0 ? std::round(1 / delay) : DEFAULT_FPS;
		}

		Image decode_image (size_t index, float pixel_density) const override
		{
			std::shared_ptr<CGImage> cgimage(
				CGImageSourceCreateImageAtIndex(source.get(), index, NULL),
				CGImageRelease);
			if (!cgimage)
			{
				rays_error(
					__FILE__, __LINE__, "failed to decode GIF frame %zu", index);
			}

			return Image(to_bitmap(cgimage.get()), pixel_density);
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
				CFRelease);
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

	};// GIFFileReader


	static bool
	is_gif_path (const char* path)
	{
		return String(path).downcase().ends_with(".gif");
	}


	VideoReader::VideoReader ()
	:	self(NULL)
	{
	}

	VideoReader::VideoReader (const char* path)
	:	self(NULL)
	{
		if (!path || *path == '\0')
			argument_error(__FILE__, __LINE__, "path is empty");

		if (is_gif_path(path))
			self.reset(new GIFFileReader(path));
		else
			self.reset(new VideoFileReader(path));
	}

	Image
	VideoReader::decode_image (size_t index, float pixel_density) const
	{
		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		return self->decode_image(index, pixel_density);
	}

	VideoAudioInList
	VideoReader::get_audio_tracks () const
	{
		if (!*this) return {};
		return self->get_audio_tracks();
	}

	coord
	VideoReader::width () const
	{
		if (!*this) return 0;
		return self->width();
	}

	coord
	VideoReader::height () const
	{
		if (!*this) return 0;
		return self->height();
	}

	float
	VideoReader::fps () const
	{
		if (!*this) return 0;
		return self->fps();
	}

	size_t
	VideoReader::size () const
	{
		if (!*this) return 0;
		return self->size();
	}

	VideoReader::operator bool () const
	{
		return self && *self;
	}

	bool
	VideoReader::operator ! () const
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
			CFRelease);
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
