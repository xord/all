# -*- mode: ruby -*-


Pod::Spec.new do |s|
  s.name         = "Reflex"
  s.version      = File.read(File.expand_path 'VERSION', __dir__)[/[\d\.]+/]
  s.summary      = "A Graphical User Interface Tool Kit"
  s.description  = "A Graphical User Interface Tool Kit"
  s.license      = "MIT"
  s.source       = {:git => "https://github.com/xord/reflex.git"}
  s.author       = {"xordog" => "xordog@gmail.com"}
  s.homepage     = "https://github.com/xord/reflex"

  s.osx.deployment_target = "10.10"
  s.ios.deployment_target = "12.0"

  root = "${PODS_ROOT}/#{s.name}"
  exts = File.read(File.expand_path 'Rakefile', __dir__)
    .lines(chomp: true)
    .map {_1[%r|require\s*['"](\w+)/extension['"]|, 1]}
    .compact - [s.name.downcase]

  incdirs = exts.map {"#{root}/#{_1}/include"}.concat %W[
    #{root}/include
    #{root}/rays/vendor/glm
    #{root}/rays/vendor/clipper/cpp
    #{root}/rays/vendor/earcut.hpp/include/mapbox
    #{root}/rays/vendor/splines-lib
    #{root}/vendor/box2d/include
    #{root}/vendor/box2d/src
    #{root}/vendor/rtmidi/rtmidi
    ${PODS_ROOT}/CRuby/CRuby/include
  ]

  s.prepare_command    = 'rake -f pod.rake setup'
  s.preserve_paths     = exts + %w[src]
  s.requires_arc       = false
  s.osx.compiler_flags = "-DOSX"
  s.ios.compiler_flags = "-DIOS"
  s.library            = %w[c++]
  s.xcconfig           = {
    "CLANG_CXX_LANGUAGE_STANDARD"  => 'c++20',
    "GCC_PREPROCESSOR_DEFINITIONS" => '$(inherited) B2_MAX_WORLDS=256',
    "HEADER_SEARCH_PATHS"          => incdirs.join(' ')
  }

  #s.dependency = 'CRuby', git: 'https://github.com/xord/cruby'

  s.resource_bundles =
    exts.each_with_object({'Reflex' => %w[lib VERSION]}) do |ext, hash|
      hash[ext.capitalize] = %W[#{ext}/lib #{ext}/VERSION]
    end

  s.subspec "Xot" do |spec|
    spec.source_files = "xot/src/*.cpp"
  end

  s.subspec "Rucy" do |spec|
    spec.source_files = "rucy/src/*.cpp"

    spec.subspec "Ext" do |ext|
      ext.source_files = "rucy/ext/rucy/*.cpp"
    end
  end

  s.subspec "Rays" do |spec|
    spec    .source_files = "rays/src/*.cpp", "rays/src/opengl/*.cpp"
    spec.osx.source_files = "rays/src/**/osx/*.{cpp,mm}"
    spec.ios.source_files = "rays/src/**/ios/*.{cpp,mm}"
    spec.osx.frameworks   = %w[AppKit OpenGL CoreImage CoreVideo CoreMedia AVFoundation]
    spec.ios.frameworks   = %w[GLKit MobileCoreServices AVFoundation]# ImageIO

    spec.subspec "Clipper" do |sub|
      sub.source_files = "rays/vendor/clipper/cpp/*.cpp"
    end

    spec.subspec "SplineLib" do |sub|
      sub.source_files = "rays/vendor/splines-lib/Splines.cpp"
    end

    spec.subspec "Ext" do |ext|
      ext.source_files = "rays/ext/rays/*.cpp"
    end
  end

  s.subspec "Reflex" do |spec|
    spec    .source_files = "src/*.cpp"
    spec.osx.source_files = "src/osx/*.{cpp,mm}"
    spec.ios.source_files = "src/ios/*.{cpp,mm}"
    spec.osx.frameworks   = %w[Cocoa IOKit GameController]
    spec.ios.frameworks   = %w[CoreMotion GameController]

    spec.subspec "Box2D" do |sub|
      sub.source_files = "vendor/box2d/src/**/*.c"
    end

    spec.subspec "RtMidi" do |sub|
      sub.source_files   = "vendor/rtmidi/rtmidi/**/*.cpp"
      sub.compiler_flags = '-D__MACOSX_CORE__'
      sub.osx.frameworks = %w[CoreAudio CoreMIDI]
      sub.ios.frameworks = %w[CoreMIDI]
    end

    spec.subspec "Ext" do |ext|
      ext.source_files = "ext/reflex/*.cpp"
    end
  end
end
