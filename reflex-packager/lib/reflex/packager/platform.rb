require 'erb'
require 'fileutils'


module Reflex


  module Packager


    TEMPLATES_DIR = File.expand_path 'templates', __dir__

    # Base class for platform specific packagers.
    #
    class Platform

      class << self

        # Copies the app in +dir+ to +dest+, with the Ruby scripts in its data
        # file in place of them, compiled by DataCompiler with the Ruby running
        # this, and the other files as they are.
        #
        # Unless +compile+, the data file is left out, for the package to
        # have it written by the Ruby in it.
        #
        def pack_app(dir, dest, compile: true)
          files   = Dir.glob('**/*', base: dir).select {File.file? File.join(dir, _1)}.sort
          scripts = DataCompiler.scripts dir

          FileUtils.mkdir_p dest
          DataCompiler.write dir, File.join(dest, DataLoader::DATA_FILE) if compile

          (files - scripts).each do |name|
            path = File.join dest, name
            FileUtils.mkdir_p File.dirname(path)
            FileUtils.cp File.join(dir, name), path
          end
        end

      end# self

      def initialize(config, verbose: false, pack: false)
        @config, @verbose, @pack = config, verbose, pack
      end

      attr_reader :config

      def profile
        config.profile
      end

      def verbose?()
        @verbose
      end

      # Whether to put the files of the app together in a data file, which
      # the package reads them from, as for a release.
      #
      def pack?()
        @pack
      end

      # Package the application as a distributable bundle.
      #
      # @param [Boolean] generate_only generate the project files but do
      #   not build them
      #
      def package(generate_only: false)
        generate
        build unless generate_only
      end

      def build_dir()
        File.join config.dir, '.build', platform_name
      end

      def dist_dir()
        File.join config.dir, 'dist'
      end

      # Returns the app name without characters unsafe for target, scheme or
      # file names.
      #
      def target()
        config.name.gsub(/[^A-Za-z0-9_\-]+/, '').then {_1.empty? ? 'App' : _1}
      end

      # The script the app starts with, in the app directory: the boot script
      # of the profile, or the main script of the app.
      #
      def start_script()
        profile.boot_main || config.main
      end

      private

      # Left out when copying a library: a gem build leaves its binaries in
      # lib/, while a package links the extensions in, and the Ruby of a
      # windows package would even prefer a rays_ext.so on the load path to
      # the one linked in.
      #
      BINARY_EXTS = %w[.so .dll .a .o .bundle]

      # Copies the Ruby code of a library and what it reads at run time into
      # +dest+: lib/ without the binaries, VERSION and res/.
      #
      def copy_library(root, dest)
        copy_tree File.join(root, 'lib'), File.join(dest, 'lib')
        %w[VERSION res].map {File.join root, _1}.select {File.exist? _1}.each do |path|
          FileUtils.mkdir_p dest
          FileUtils.cp_r path, dest
        end
      end

      def copy_tree(src, dest)
        Dir.glob('**/*', base: src).each do |path|
          from = File.join src, path
          next if File.directory?(from) || BINARY_EXTS.include?(File.extname path)
          to = File.join dest, path
          FileUtils.mkdir_p File.dirname(to)
          FileUtils.cp from, to
        end
      end

      # The files of the app, as they are, for any platform.
      #
      def app_dir()
        File.join config.dir, '.build', 'app'
      end

      # Copies the files of the app to app_dir, and to +dir+ in the build
      # directory, as they are, or packed with what reads its data file in
      # the reflex library of the package, if the app is to be packed.
      #
      def copy_app_files(dir = 'app')
        FileUtils.rm_rf app_dir
        FileUtils.mkdir_p app_dir
        config.app_files.each do |file|
          dest = File.join app_dir, file
          FileUtils.mkdir_p File.dirname(dest)
          FileUtils.cp_r File.join(config.dir, file), dest
        end
        File.write File.join(app_dir, profile.boot_main), profile.boot if
          profile.boot_main && profile.boot

        dir = File.join build_dir, dir
        FileUtils.rm_rf dir
        FileUtils.mkdir_p dir
        if pack?
          raise Error, 'a packed app needs reflex in its libraries' unless
            libraries.any? {_1.name == 'reflex'}
          Platform.pack_app app_dir, dir, compile: compile_on_generate?
          loader = File.join library_lib_dir('reflex'), 'reflex', 'packager'
          FileUtils.mkdir_p loader
          %w[data_file.rb data_loader.rb].each {FileUtils.cp File.join(__dir__, _1), loader}
        else
          FileUtils.cp_r File.join(app_dir, '.'), dir
        end
      end

      # Whether the scripts of a packed app are compiled when generating, by
      # the Ruby running this, which is the one the package runs them on.
      #
      def compile_on_generate?()
        true
      end

      def write(path, content)
        path = File.join build_dir, path
        FileUtils.mkdir_p File.dirname(path)
        File.write path, content
      end

      # Renders the template with the packager's methods, and +vars+ as
      # local variables.
      #
      def render(template, **vars)
        path = File.join TEMPLATES_DIR, platform_name, template
        b    = template_binding
        vars.each {|name, value| b.local_variable_set name, value}
        ERB.new(File.read(path), trim_mode: '-').result b
      end

      # A binding with the packager's methods and nothing else: a template
      # sees every local variable of the method its binding is made in.
      #
      def template_binding()
        binding
      end

      # Runs +cmd+, dropping what it prints if +quiet+ unless verbose, though
      # not the errors it tells.
      #
      def run(*cmd, chdir:, env: {}, quiet: false)
        puts "==> #{cmd.join ' '}"
        out = quiet && !verbose? ? {out: File::NULL} : {}
        return if system env, *cmd, chdir: chdir, **out
        raise Error, "command failed: #{cmd.join ' '}"
      end

      def check_tools(tools)
        missing = tools.reject {|name, _| executable? name}
        return if missing.empty?

        list = missing.map {|name, hint| '  %-10s -- %s' % [name, hint]}
        raise Error, "required tools not found:\n#{list.join "\n"}"
      end

      def executable?(name)
        !!find_executable(name)
      end

      # Windows finds 'g++' as 'g++.exe' through PATHEXT, which is separated
      # by ';' whatever the platform.
      #
      def find_executable(name)
        exts = ['', *ENV['PATHEXT'].to_s.split(';')]
        ENV['PATH'].to_s.split(File::PATH_SEPARATOR).each do |dir|
          exts.each do |ext|
            path = File.join dir, "#{name}#{ext}"
            return path if File.file?(path) && File.executable?(path)
          end
        end
        nil
      end

    end# Platform


  end# Packager


end# Reflex
