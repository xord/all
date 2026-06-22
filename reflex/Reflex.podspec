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

  all  = "${PODS_ROOT}/#{s.name}/all"
  deps = File.read(File.expand_path 'Rakefile', __dir__)
    .lines(chomp: true)
    .map {_1[%r|require\s*['"](\w+)/extension['"]|, 1]}
    .compact

  incdirs = deps.map {"#{all}/#{_1}/include"}.concat %W[
    #{all}/rays/vendor/glm
    #{all}/rays/vendor/clipper/cpp
    #{all}/rays/vendor/earcut.hpp/include/mapbox
    #{all}/rays/vendor/splines-lib
    #{all}/reflex/vendor/box2d/include
    #{all}/reflex/vendor/box2d/src
    #{all}/reflex/vendor/rtmidi/rtmidi
    ${PODS_ROOT}/CRuby/CRuby/include
  ]

  s.prepare_command    = 'rake -f pod.rake setup'
  s.preserve_paths     = deps.product(%w[include src ext vendor]).map {"all/#{_1}/#{_2}"}
  s.requires_arc       = false
  s.osx.compiler_flags = "-DOSX"
  s.ios.compiler_flags = "-DIOS"
  s.library            = %w[c++]
  s.xcconfig           = {
    "CLANG_CXX_LANGUAGE_STANDARD"  => 'c++20',
    "GCC_PREPROCESSOR_DEFINITIONS" => '$(inherited) B2_MAX_WORLDS=256',
    "HEADER_SEARCH_PATHS"          => incdirs.join(' ')
  }

  s.resource_bundles =
    deps.each_with_object({}) do |dep, hash|
      hash[dep.capitalize] = %w[lib VERSION].map {"all/#{dep}/#{_1}"}
    end

  s.subspec "Xot" do |spec|
    spec.source_files = "all/xot/src/*.cpp"
  end

  s.subspec "Rucy" do |spec|
    spec.source_files = "all/rucy/src/*.cpp"

    spec.subspec "Ext" do |ext|
      ext.source_files = "all/rucy/ext/rucy/*.cpp"
    end
  end

  s.subspec "Rays" do |spec|
    spec    .source_files = "all/rays/src/*.cpp", "all/rays/src/opengl/*.cpp"
    spec.osx.source_files = "all/rays/src/**/osx/*.{cpp,mm}"
    spec.ios.source_files = "all/rays/src/**/ios/*.{cpp,mm}"
    spec.osx.frameworks   = %w[AppKit OpenGL CoreImage CoreVideo CoreMedia AVFoundation]
    spec.ios.frameworks   = %w[GLKit MobileCoreServices AVFoundation]

    spec.subspec "Clipper" do |sub|
      sub.source_files = "all/rays/vendor/clipper/cpp/*.cpp"
    end

    spec.subspec "SplineLib" do |sub|
      sub.source_files = "all/rays/vendor/splines-lib/Splines.cpp"
    end

    spec.subspec "Ext" do |ext|
      ext.source_files = "all/rays/ext/rays/*.cpp"
    end
  end

  s.subspec "Reflex" do |spec|
    spec    .source_files = "all/reflex/src/*.cpp"
    spec.osx.source_files = "all/reflex/src/osx/*.{cpp,mm}"
    spec.ios.source_files = "all/reflex/src/ios/*.{cpp,mm}"
    spec.osx.frameworks   = %w[Cocoa IOKit GameController]
    spec.ios.frameworks   = %w[CoreMotion GameController]

    spec.subspec "Box2D" do |sub|
      # Box2D 3.x is written in C
      sub.source_files = "all/reflex/vendor/box2d/src/**/*.c"
    end

    spec.subspec "RtMidi" do |sub|
      sub.source_files       = "all/reflex/vendor/rtmidi/rtmidi/**/*.cpp"
      sub.osx.compiler_flags = "-D__MACOSX_CORE__"
      sub.osx.frameworks     = %w[CoreMIDI CoreAudio]
    end

    spec.subspec "Ext" do |ext|
      ext.source_files = "all/reflex/ext/reflex/*.cpp"
    end
  end
end
