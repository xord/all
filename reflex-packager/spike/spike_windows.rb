# Spike for the Windows platform: checks the assumptions the packager relies
# on before it is written. Throwaway; drop this before merging.
#
# Run on Windows with RubyInstaller + DevKit:
#
#   gem install reflexion       # pulls xot, rucy and rays too
#   ridk enable
#   ruby spike_windows.rb
#
# To use a checkout instead of installed gems: set SPIKE_ROOT=<monorepo dir>
# after running 'rake xot rucy rays lib ext' there.

require 'rbconfig'
require 'fileutils'
require 'tmpdir'
require 'shellwords'

C = RbConfig::CONFIG

def sh(*cmd)
  puts "==> #{cmd.join ' '}"
  system(*cmd) or abort "failed: #{cmd.first}"
end

def gem_dir(name)
  root = ENV['SPIKE_ROOT']
  return File.join(root, name) if root
  Gem::Specification.find_by_name(name == 'reflex' ? 'reflexion' : name).gem_dir
rescue Gem::MissingSpecError
  nil
end

def find_in_path(file)
  ENV['PATH'].split(File::PATH_SEPARATOR)
    .map {File.join _1, file}
    .find {File.exist? _1}
end


puts '--- 1. static archives and ext objects in the gem directories'
dirs = %w[xot rucy beeps rays reflex].to_h {[_1, gem_dir(_1)]}
dirs.each do |name, dir|
  next puts "#{name}: (not installed)" unless dir
  puts "#{name}: #{dir}"
  puts "  lib/lib#{name}.a     #{File.exist? "#{dir}/lib/lib#{name}.a"}"
  puts "  ext/#{name}/*.o      #{Dir.glob("#{dir}/ext/#{name}/*.o").size} files"
  puts "  ext/#{name}/Makefile #{File.exist? "#{dir}/ext/#{name}/Makefile"}"
end
%w[xot rucy rays].each do |name|
  abort "#{name} is required to go on" unless dirs[name]
end

work = File.join Dir.tmpdir, 'reflex-spike'
FileUtils.rm_rf work
FileUtils.mkdir_p work
Dir.chdir work
puts "\nwork dir: #{work}"


puts "\n--- build spike.exe (rays linked statically, ruby dynamically)"
File.write 'spike.cpp', <<~CPP
  #include <ruby.h>

  extern "C"
  {
  	void ruby_init_ext (const char* name, void (*init)(void));
  	void Init_rays_ext ();
  }

  int
  main (int argc, char** argv)
  {
  	ruby_sysinit(&argc, &argv);
  	RUBY_INIT_STACK;
  	ruby_init();
  	ruby_init_ext("rays_ext.so", Init_rays_ext);
  	return ruby_run_node(ruby_options(argc, argv));
  }
CPP

rays = dirs['rays']
sh *C['CXX'].shellsplit, 'spike.cpp', '-o', 'spike.exe',
  "-I#{C['rubyhdrdir']}", "-I#{C['rubyarchhdrdir']}",
  *Dir.glob("#{rays}/ext/rays/*.o"),
  '-Wl,--whole-archive',
  *%w[rays rucy xot].map {"#{dirs[_1]}/lib/lib#{_1}.a"},
  '-Wl,--no-whole-archive',
  "-L#{C['libdir']}", *C['LIBRUBYARG_SHARED'].split,
  '-lgdi32', '-lopengl32', '-lglew32',
  '-static-libgcc', '-static-libstdc++'


puts "\n--- 2. static ext wins over the gem's rays_ext.so"
puts '(expect ["rays_ext.so"], not a full path to the gem)'
system 'spike.exe', '-e', <<~RUBY
  require 'rays'
  p Rays::Image.new(8, 8)
  p $LOADED_FEATURES.grep(/rays_ext/)
RUBY


puts "\n--- 3 & 4. relocated layout under a japanese path"
dest = File.join work, 'スパイク配置'
FileUtils.mkdir_p dest
FileUtils.cp 'spike.exe', dest
FileUtils.cp Dir.glob("#{C['bindir']}/*.dll"), dest
FileUtils.cp Dir.glob("#{C['bindir']}/ruby_builtin_dlls/*.dll"), dest
glew = find_in_path('glew32.dll') or abort 'glew32.dll not found in PATH'
FileUtils.cp glew, dest
FileUtils.mkdir_p "#{dest}/lib/ruby"
FileUtils.cp_r File.join(C['rubylibprefix'], C['ruby_version']), "#{dest}/lib/ruby/"
puts "copied to #{dest}"

# as if on a machine without RubyInstaller
env = {
  'PATH'          => File.join(ENV['SystemRoot'], 'System32'),
  'RUBYOPT'       => nil,
  'RUBYLIB'       => nil,
  'GEM_HOME'      => nil,
  'GEM_PATH'      => nil,
  'RUBY_DLL_PATH' => nil
}
system env, File.join(dest, 'spike.exe'), '-e', <<~RUBY
  p prefix: RbConfig::CONFIG['prefix']
  p external: Encoding.default_external, pwd: Dir.pwd
  puts '$LOAD_PATH:', $LOAD_PATH.map {"  \#{_1}"}
  require 'json';  p json:  JSON.generate([1])
  require 'psych'; p psych: Psych::VERSION
  begin
    require 'rays_ext'
    p rays_ext: $LOADED_FEATURES.grep(/rays_ext/)
  rescue Exception => e
    p rays_ext: e
  end
RUBY
puts "exit status: #{$?.exitstatus}"
