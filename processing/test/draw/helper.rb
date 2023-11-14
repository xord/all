require 'digest/md5'
require 'fileutils'

require_relative '../helper'
require_relative 'p5'


DEFAULT_HEADER = <<~END
  background 100
  fill 255, 0, 0
  stroke 0, 255, 0
  strokeWeight 50
END


def md5(s)
  Digest::MD5.hexdigest s
end

def mkdir(dir: nil, filename: nil)
  path = dir || File.dirname(filename)
  FileUtils.mkdir_p path unless File.exist? path
end

def test_label(index = 1)
  caller_locations[index].then {|loc| "#{loc.label}_#{loc.lineno}"}
end

def test_output_path(label, source = nil, ext: '.png', dir: ext)
  path = File.join __dir__, dir, label + (source ? "_#{md5 source}" : '') + ext
  mkdir filename: path
  path
end

def test_draw(*sources, width: 1000, height: 1000, pixelDensity: 1, label: nil)
  graphics(width, height, pixelDensity).tap do |g|
    src = sources.compact.join "\n"
    g.beginDraw {g.instance_eval src}
    g.save test_output_path(label, src) if label
  end
end

def assert_draw_equal(
  *shared_header, expected, actual, default_header: DEFAULT_HEADER,
  width: 1000, height: 1000, threshold: 1.0, label: test_label)

  e = test_draw default_header, *shared_header, expected, label: "#{label}_expected"
  a = test_draw default_header, *shared_header, actual,   label: "#{label}_actual"

  assert_equal_pixels e, a, threshold: threshold
end

def assert_draw(
  *sources, default_header: DEFAULT_HEADER,
  width: 1000, height: 1000, threshold: 0.99, label: test_label)

  source = [default_header, *sources].compact.join("\n")
  path   = test_output_path "#{label}_expected", source

  pd     = draw_p5rb width, height, source, path, headless: true
  actual = test_draw source, width: width, height: height, pixelDensity: pd
  actual.save path.sub('_expected', '_actual')

  assert_equal_pixels actual.loadImage(path), actual, threshold: threshold
end

def assert_fill(*sources, **kwargs)
  assert_draw 'noStroke', *src, label: test_label, **kwargs
end

def assert_stroke(*sources, **kwargs)
  assert_draw 'noFill; stroke 0, 255, 0', *sources, label: test_label, **kwargs
end

def assert_fill_stroke(*sources, **kwargs)
  assert_draw 'stroke 0, 255, 0', *sources, label: test_label, **kwargs
end