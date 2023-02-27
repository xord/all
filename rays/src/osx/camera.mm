// -*- mode: objc -*-
#import "rays/camera.h"


#import <AVFoundation/AVFoundation.h>
#include "rays/exception.h"
#include "bitmap.h"


static int video_input_queue_index = 0;


@interface VideoInput : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>
@end


@implementation VideoInput

	{
		AVCaptureSession* session;
		dispatch_queue_t queue;
		CGImageRef image;
	}

	- (id) init
	{
		self = [super init];
		if (self)
		{
			session = nil;
			queue   = nil;
			image   = nil;
		}
		return self;
	}

	- (void) dealloc
	{
		[self stop];
		[self clearImage];

		if (queue)
		{
			dispatch_release(queue);
			queue = nil;
		}

		[super dealloc];
	}

	- (dispatch_queue_t) getQueue
	{
		if (!queue)
		{
			auto name = Xot::stringf(
				"org.xord.RaysVideoInputQueue_%d",
				video_input_queue_index++);
			queue = dispatch_queue_create(name, DISPATCH_QUEUE_SERIAL);
		}
		return queue;
	}

	- (BOOL) start: (AVCaptureDevice*) device
		preset: (AVCaptureSessionPreset) preset
	{
		if (!device) return NO;

		[self stop];

		AVCaptureSession* sess = [[[AVCaptureSession alloc] init] autorelease];
		if (preset != nil)
			sess.sessionPreset = preset;

		//device.activeVideoMinFrameDuration = CMTimeMake(1, 30);

		NSError* error = nil;
		AVCaptureDeviceInput* input = [[[AVCaptureDeviceInput alloc]
			initWithDevice: device error: &error]
			autorelease];
		if (!input || error || ![sess canAddInput: input])
			return NO;

		AVCaptureVideoDataOutput* output =
			[[[AVCaptureVideoDataOutput alloc] init] autorelease];
		output.videoSettings = @{
			(NSString*) kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)
		};
		output.alwaysDiscardsLateVideoFrames = YES;
		[output setSampleBufferDelegate: self queue: [self getQueue]];
		if (![sess canAddOutput: output])
			return NO;

		[sess addInput: input];
		[sess addOutput: output];
		[sess startRunning];

		session = [sess retain];
		return YES;
	}

	- (void) captureOutput: (AVCaptureOutput*) output
		didOutputSampleBuffer: (CMSampleBufferRef) sampleBuffer
		fromConnection: (AVCaptureConnection*) connection
	{
		CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
		if (!pixelBuffer) return;

		CIImage* ciImage = [CIImage imageWithCVPixelBuffer: pixelBuffer];
		if (!ciImage) return;

		CIContext* context = [CIContext contextWithOptions: nil];
		size_t width       = CVPixelBufferGetWidth(pixelBuffer);
		size_t height      = CVPixelBufferGetHeight(pixelBuffer);
		CGRect rect        = CGRectMake(0, 0, width, height);
		CGImageRef cgImage = [context createCGImage: ciImage fromRect: rect];

		dispatch_async(dispatch_get_main_queue(), ^{
			[self clearImage];
			image = cgImage;
		});
	}

	- (void) stop
	{
		if (!session) return;

		[session stopRunning];
		[session release];
		session = nil;
	}

	- (BOOL) isActive
	{
		return session != nil;
	}

	- (void) clearImage
	{
		if (!image) return;

		CGImageRelease(image);
		image = nil;
	}

	- (CGImageRef) getImage
	{
		return image;
	}

@end// VideoInput


namespace Rays
{


	struct Camera::Data
	{

		String device_name;

		int min_width = -1, min_height = -1;

		bool resize = false, crop = false;

		mutable Image image;

		VideoInput* video_input = nil;

		AVCaptureSessionPreset get_preset (AVCaptureDevice* device)
		{
			int w = min_width, h = min_height;
			if (w > 0 && h > 0)
			{
				#define SUPPORT(x) \
					[device supportsAVCaptureSessionPreset: AVCaptureSessionPreset##x]

				if (w <= 320 && h <= 240 && SUPPORT(320x240))
					return AVCaptureSessionPreset320x240;

				if (w <= 352 && h <= 288 && SUPPORT(352x288))
					return AVCaptureSessionPreset352x288;

				if (w <= 640 && h <= 480 && SUPPORT(640x480))
					return AVCaptureSessionPreset640x480;

				if (w <= 960 && h <= 540 && SUPPORT(960x540))
					return AVCaptureSessionPreset960x540;

				if (/*w <= 1280 && h <= 720 &&*/ SUPPORT(1280x720))
					return AVCaptureSessionPreset1280x720;

				//if (w <= 1920 && h <= 1080 && SUPPORT(1920x1080))
				//	return AVCaptureSessionPreset1920x1080;

				//if (SUPPORT(3840x2160))
				//	return AVCaptureSessionPreset3840x2160;

				#undef SUPPORT
			}

			return nil;
		}

		void update_image_from_video_input () const
		{
			if (!video_input) return;

			CGImageRef cgImage = [video_input getImage];
			if (!cgImage) return;

			coord draw_x, draw_y, draw_width, draw_height;
			int bitmap_width, bitmap_height;
			get_draw_bounds(
				&draw_x, &draw_y, &draw_width, &draw_height,
				&bitmap_width, &bitmap_height,
				cgImage);

			if (
				!image ||
				image.bitmap().width()  != bitmap_width ||
				image.bitmap().height() != bitmap_height)
			{
				image = Image(Bitmap(bitmap_width, bitmap_height));
			}

			Bitmap_draw_image(
				&image.bitmap(), cgImage,
				draw_x, draw_y, draw_width, draw_height);

			[video_input clearImage];
		}

		void get_draw_bounds (
			coord* draw_x, coord* draw_y, coord* draw_width, coord* draw_height,
			int* bitmap_width, int* bitmap_height,
			CGImageRef image) const
		{
			int image_width   = (int) CGImageGetWidth(image);
			int image_height  = (int) CGImageGetHeight(image);
			float image_ratio = (float) image_width / (float) image_height;

			if (resize && min_width > 0 && min_height > 0)
			{
				float min_size_ratio = (float) min_width / (float) min_height;
				if (image_ratio > min_size_ratio)
				{
					*draw_width  = min_height * image_ratio;
					*draw_height = min_height;
				}
				else
				{
					*draw_width  = min_width;
					*draw_height = min_width / image_ratio;
				}
			}
			else if (resize && min_width > 0)
			{
				*draw_width  = min_width;
				*draw_height = min_width / image_ratio;
			}
			else if (resize && min_height > 0)
			{
				*draw_width  = min_height * image_ratio;
				*draw_height = min_height;
			}
			else
			{
				*draw_width  = image_width;
				*draw_height = image_height;
			}

			*draw_x        = 0;
			*draw_y        = 0;
			*bitmap_width  = *draw_width;
			*bitmap_height = *draw_height;

			if (crop && min_width > 0)
			{
				*draw_x       = min_width / 2 - *draw_width / 2;
				*bitmap_width = min_width;
			}
			if (crop && min_height > 0)
			{
				*draw_y        = min_height / 2 - *draw_height / 2;
				*bitmap_height = min_height;
			}
		}

	};// Camera::Data


	static NSArray<AVCaptureDevice*>*
	get_video_devices ()
	{
		NSMutableArray<AVCaptureDevice*>* devices = [NSMutableArray array];
		for (AVCaptureDevice* d in AVCaptureDevice.devices)
		{
			if ([d hasMediaType: AVMediaTypeVideo])
				[devices addObject: d];
		}
		return devices;
	}

	static AVCaptureDevice*
	get_default_video_device ()
	{
		AVCaptureDevice* device =
			[AVCaptureDevice defaultDeviceWithMediaType: AVMediaTypeVideo];
		if (!device)
			rays_error(__FILE__, __LINE__, "Default camera device is not found.");

		return device;
	}

	static AVCaptureDevice*
	get_video_device (const char* name)
	{
		if (!name || *name == 0)
			return get_default_video_device();

		for (AVCaptureDevice* d in get_video_devices())
		{
			if (strcmp(name, d.localizedName.UTF8String) == 0)
				return d;
		}

		rays_error(__FILE__, __LINE__, "Camera device '%s' is not found.", name);
		return nil;
	}

	std::vector<String>
	get_camera_device_names ()
	{
		std::vector<String> names;
		for (AVCaptureDevice* d in get_video_devices())
			names.emplace_back(d.localizedName.UTF8String);
		return names;
	}


	Camera::Camera (
		const char* device_name,
		int min_width, int min_height, bool resize, bool crop)
	{
		if (device_name)
			self->device_name = device_name;

		self->min_width  = min_width;
		self->min_height = min_height;
		self->resize     = resize;
		self->crop       = crop;
	}

	Camera::~Camera ()
	{
		stop();
	}

	bool
	Camera::start ()
	{
		if (!self->video_input) self->video_input = [[VideoInput alloc] init];

		AVCaptureDevice* device = get_video_device(self->device_name.c_str());
		return [self->video_input start: device preset: self->get_preset(device)];
	}

	void
	Camera::stop ()
	{
		if (!self->video_input) return;

		[self->video_input stop];
		[self->video_input release];
		self->video_input = nil;
	}

	bool
	Camera::is_active () const
	{
		return self->video_input && [self->video_input isActive];
	}

	void
	Camera::set_min_width (int width)
	{
		self->min_width = width;
	}

	int
	Camera::min_width () const
	{
		return self->min_width;
	}

	void
	Camera::set_min_height (int height)
	{
		self->min_height = height;
	}

	int
	Camera::min_height () const
	{
		return self->min_height;
	}

	void
	Camera::set_resize (bool resize)
	{
		self->resize = resize;
	}

	bool
	Camera::is_resize () const
	{
		return self->resize;
	}

	void
	Camera::set_crop (bool crop)
	{
		self->crop = crop;
	}

	bool
	Camera::is_crop () const
	{
		return self->crop;
	}

	const Image*
	Camera::image () const
	{
		self->update_image_from_video_input();
		return self->image ? &self->image : NULL;
	}

	Camera::operator bool () const
	{
		return true;
	}

	bool
	Camera::operator ! () const
	{
		return !operator bool();
	}


}// Rays
