// -*- mode: objc -*-
#pragma once
#ifndef __RAYS_VIDEO_SRC_OSX_VIDEO_AUDIO_IN_H__
#define __RAYS_VIDEO_SRC_OSX_VIDEO_AUDIO_IN_H__


#import <AVFoundation/AVFoundation.h>
#include "../video_audio_in.h"


namespace Rays
{


	VideoAudioIn::Data* VideoAudioIn_Data_create (
		AVAsset* asset, AVAssetTrack* audio_track);


}// Rays


#endif//EOH
