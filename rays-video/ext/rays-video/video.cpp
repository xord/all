#include "rays-video/ruby/video.h"


#include "rays/ruby/image.h"
#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(RAYS_VIDEO_EXPORT, Rays::Video)

#define THIS  to<Rays::Video*>(self)

#define CHECK RUCY_CHECK_OBJECT(Rays::Video, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Rays::Video>(klass);
}
RUCY_END

static
RUCY_DEF4(initialize, width, height, fps, pixel_density)
{
	RUCY_CHECK_OBJ(Rays::Video, self);

	float fps_ = to<float>(fps);
	*THIS = Rays::Video(
		to<int>(width),
		to<int>(height),
		fps_ > 0 ? fps_ : Rays::Video::DEFAULT_FPS,
		to<float>(pixel_density));
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	RUCY_CHECK_OBJ(Rays::Video, self);

	*THIS = to<Rays::Video&>(obj).dup();
}
RUCY_END

static
RUCY_DEF2(insert, index, image)
{
	CHECK;
	THIS->insert(to<size_t>(index), to<const Rays::Image&>(image));
	return self;
}
RUCY_END

static
RUCY_DEF1(append, image)
{
	CHECK;
	THIS->append(to<const Rays::Image&>(image));
	return self;
}
RUCY_END

static
RUCY_DEF1(remove, index)
{
	CHECK;
	THIS->remove(to<size_t>(index));
	return self;
}
RUCY_END

static
RUCY_DEF1(save, path)
{
	CHECK;
	THIS->save(path.c_str());
	return self;
}
RUCY_END

static
RUCY_DEF0(width)
{
	CHECK;
	return value(THIS->width());
}
RUCY_END

static
RUCY_DEF0(height)
{
	CHECK;
	return value(THIS->height());
}
RUCY_END

static
RUCY_DEF0(fps)
{
	CHECK;
	return value(THIS->fps());
}
RUCY_END

static
RUCY_DEF0(pixel_density)
{
	CHECK;
	return value(THIS->pixel_density());
}
RUCY_END

static
RUCY_DEF0(size)
{
	CHECK;
	return value(THIS->size());
}
RUCY_END

static
RUCY_DEF0(empty)
{
	CHECK;
	return value(THIS->empty());
}
RUCY_END

static
RUCY_DEF1(set_position, position)
{
	CHECK;
	THIS->set_position(to<size_t>(position));
	return position;
}
RUCY_END

static
RUCY_DEF0(get_position)
{
	CHECK;
	return value(THIS->position());
}
RUCY_END

static
RUCY_DEF0(each)
{
	CHECK;
	Value ret;
	for (auto it = THIS->begin(), end = THIS->end(); it != end; ++it)
		ret = rb_yield(value(*it));
	return ret;
}
RUCY_END

static
RUCY_DEF0(to_image)
{
	CHECK;
	return value((Rays::Image) *THIS);
}
RUCY_END

static
RUCY_DEF1(at, index)
{
	CHECK;
	return value((*THIS)[(size_t) to<int>(index)]);
}
RUCY_END

static
RUCY_DEF0(play)
{
	CHECK;
	THIS->play();
	return self;
}
RUCY_END

static
RUCY_DEF0(pause)
{
	CHECK;
	THIS->pause();
	return self;
}
RUCY_END

static
RUCY_DEF0(stop)
{
	CHECK;
	THIS->stop();
	return self;
}
RUCY_END

static
RUCY_DEF1(set_time_scale, scale)
{
	CHECK;
	THIS->set_time_scale(to<float>(scale));
	return scale;
}
RUCY_END

static
RUCY_DEF0(get_time_scale)
{
	CHECK;
	return value(THIS->time_scale());
}
RUCY_END

static
RUCY_DEF1(load, path)
{
	return value(Rays::load_video(path.c_str()));
}
RUCY_END

static
RUCY_DEF0(exts)
{
	std::vector<Value> list;
	for (const auto& ext : Rays::get_video_exts())
		list.emplace_back(ext.c_str());
	return array(list.data(), list.size());
}
RUCY_END


static Class cVideo;

void
Init_rays_video ()
{
	Module mRays = define_module("Rays");

	cVideo = mRays.define_class("Video");
	cVideo.define_alloc_func(alloc);
	cVideo.define_private_method("initialize!",     initialize);
	cVideo.define_private_method("initialize_copy", initialize_copy);
	cVideo.define_method("insert!", insert);
	cVideo.define_method("append!", append);
	cVideo.define_method("remove!", remove);
	cVideo.define_method("save", save);
	cVideo.define_method("width",         width);
	cVideo.define_method("height",        height);
	cVideo.define_method("fps",           fps);
	cVideo.define_method("pixel_density", pixel_density);
	cVideo.define_method("size",          size);
	cVideo.define_method("empty?",        empty);
	cVideo.define_method("position=", set_position);
	cVideo.define_method("position",  get_position);
	cVideo.define_method("play",  play);
	cVideo.define_method("pause", pause);
	cVideo.define_method("stop",  stop);
	cVideo.define_method("time_scale=", set_time_scale);
	cVideo.define_method("time_scale",  get_time_scale);
	cVideo.define_method("each!", each);
	cVideo.define_method("to_image", to_image);
	cVideo.define_method("[]", at);
	cVideo.define_module_function("load", load);
	cVideo.define_module_function("exts", exts);
}


namespace Rays
{


	Class
	video_class ()
	{
		return cVideo;
	}


}// Rays
