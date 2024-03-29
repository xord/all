%w[../xot ../rucy ../rays ../reflex .]
  .map  {|s| File.expand_path "../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'xot/test'
require 'processing/all'

require 'digest/md5'
require 'fileutils'
require 'tempfile'
require 'test/unit'

include Xot::Test


DEFAULT_DRAW_HEADER = <<~END
  background 100
  fill 255, 0, 0
  stroke 0, 255, 0
  strokeWeight 50
END

THRESHOLD_TO_BE_FIXED = 0.0


def test_with_browser?()
  (ENV['TEST_WITH_BROWSER'] || '0') != '0'
end

def md5(s)
  Digest::MD5.hexdigest s
end

def mkdir(dir: nil, filename: nil)
  path = dir || File.dirname(filename)
  FileUtils.mkdir_p path unless File.exist? path
end

def test_label(frame_offset = 1, suffix: nil)
  suffix = suffix ? "_#{suffix}" : ''
  caller_locations[frame_offset]
    .then {|loc| "#{loc.label}_#{loc.lineno}#{suffix}"}
end

def temp_path(ext: nil, &block)
  f     = Tempfile.new
  path  = f.path
  path += ext if ext
  f.close!
  block.call path
  File.delete path
end

def draw_output_path(label, *sources, ext: '.png', dir: ext)
  src  = sources.compact.then {|ary| ary.empty? ? '' : "_#{md5 ary.join("\n")}"}
  path = File.join __dir__, dir, label + src + ext
  mkdir filename: path
  path
end

def get_pixels(image)
  %i[@image @image__]
    .map {image.instance_variable_get _1}
    .compact
    .first
    .pixels
end

def graphics(width = 10, height = 10, *args, &block)
  Processing::Graphics.new(width, height, *args).tap do |g|
    g.beginDraw {block.call g, g.getInternal__} if block
  end
end

def test_draw(*sources, width: 1000, height: 1000, pixelDensity: 1, label: nil)
  graphics(width, height, pixelDensity).tap do |g|
    g.renderMode :p5js
    g.beginDraw {g.instance_eval sources.compact.join("\n")}
    g.save draw_output_path(label, *sources) if label
  end
end


def assert_equal_vector(v1, v2, delta = 0.000001)
  assert_in_delta v1.x, v2.x, delta
  assert_in_delta v1.y, v2.y, delta
  assert_in_delta v1.z, v2.z, delta
end

def assert_equal_pixels(expected, actual, threshold: 1.0)
  exp_pixels = get_pixels expected
  act_pixels = get_pixels actual
  raise "Number of pixels does not match" if act_pixels.size != exp_pixels.size

  equal_count = exp_pixels.zip(act_pixels).count {|a, b| a == b}
  equal_rate  = equal_count.to_f / act_pixels.size.to_f
  assert equal_rate >= threshold, <<~EOS
    The rate of the same pixel #{equal_rate} is below the threshold #{threshold}
  EOS
end

def assert_equal_draw(
  *shared_header, expected, actual, default_header: DEFAULT_DRAW_HEADER,
  width: 1000, height: 1000, threshold: 1.0, label: test_label)

  e = test_draw default_header, *shared_header, expected, label: "#{label}_expected"
  a = test_draw default_header, *shared_header, actual,   label: "#{label}_actual"

  assert_equal_pixels e, a, threshold: threshold
end

def assert_svg_draw(
  svg_xml,
  width: 1000, height: 1000, threshold: 0.99, label: test_label, **kwargs)

  source = <<~END
    background 255
    shape Processing::SVGLoader.new(self).parse <<~SVG
      <?xml version="1.0" encoding="UTF-8"?>
      <svg xmlns="http://www.w3.org/2000/svg"
        xmlns:xlink="http://www.w3.org/1999/xlink"
        viewBox="0 0 100 100">
        #{svg_xml}
      </svg>
    SVG
  END
  assert_draw_on_browser(
    source, width, height, threshold, label, **kwargs
  ) do |path|
    draw_svg width, height, svg_xml, path, **kwargs
  end
end

def assert_p5_draw(
  *sources, default_header: DEFAULT_DRAW_HEADER,
  width: 1000, height: 1000, threshold: 0.99, label: test_label, **kwargs)

  source = [default_header, *sources].compact.join("\n")
  assert_draw_on_browser(
    source, width, height, threshold, label, **kwargs
  ) do |path|
    draw_p5rb width, height, source, path, **kwargs
  end
end

def assert_draw_on_browser(
  source, width, height, threshold, label, **kwargs, &draw_on_browser)

  return unless test_with_browser?

  path   = draw_output_path "#{label}_expected", source
  pd     = draw_on_browser.call path
  actual = test_draw source, width: width, height: height, pixelDensity: pd
  actual.save path.sub('_expected', '_actual')

  assert_equal_pixels actual.loadImage(path), actual, threshold: threshold
end

def assert_p5_fill(*sources, **kwargs)
  assert_p5_draw 'noStroke', *sources, label: test_label, **kwargs
end

def assert_p5_stroke(*sources, **kwargs)
  assert_p5_draw 'noFill; stroke 0, 255, 0', *sources, label: test_label, **kwargs
end

def assert_p5_fill_stroke(*sources, **kwargs)
  assert_p5_draw 'stroke 0, 255, 0', *sources, label: test_label, **kwargs
end


require_relative 'browser' if test_with_browser?
