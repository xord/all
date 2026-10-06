require 'rubygems'


module Reflex


  module Packager


    # A library a packaged app runs on: a gem with lib/<name>/extension.rb, as
    # xot, rays and reflex are, whose Ruby code a package bundles and whose
    # extension, if it has lib/<name>/ext.rb, a package links.
    #
    class Library

      # @param [String] name the directory of the library under lib/
      # @param [String] root the directory of the gem
      #
      def initialize(name, root)
        @name, @root = name, root
      end

      attr_reader :name, :root

      # The extension to register (Init_<extension>), or nil.
      #
      def extension()
        return nil unless File.file? File.join(root, 'lib', name, 'ext.rb')
        "#{name.tr '-', '_'}_ext"
      end

      def to_s()
        name
      end

      # Returns the libraries the gem of +extension+ depends on, as its gemspec
      # has them, and itself last, each after the ones it depends on.
      #
      # A gem is looked for in the directories on the load path first, as
      # RUBYLIB points to the ones of a repository being worked on, and then in
      # the installed gems.
      #
      # @param [Module] extension the Extension of the gem, which has root_dir
      #
      # @return [Array<Library>] libraries
      #
      def self.collect(extension)
        libraries, visited, sources = [], {}, source_roots
        visit = -> (root, spec) do
          name = library_name root
          next if !name || visited[root]
          visited[root] = true
          spec.runtime_dependencies.each {|dep| find_gem(dep, sources)&.then {visit.call(*_1)}}
          libraries << new(name, root)
        end
        root = File.expand_path extension.root_dir
        visit.call root, spec_of(root)
        libraries
      end

      # The directory under lib/ with extension.rb, or nil.
      #
      def self.library_name(root)
        path = Dir.glob(File.join root, 'lib', '*', 'extension.rb').first
        path && File.basename(File.dirname path)
      end

      # Returns [root, spec] of the gem +dep+ asks for, or nil.
      #
      def self.find_gem(dep, sources)
        root = sources[dep.name]
        return [root, spec_of(root)] if root
        spec = dep.to_spec
        [spec.full_gem_path, spec]
      rescue Gem::LoadError
        nil
      end

      # The gems on the load path which are not installed ones, by name.
      #
      def self.source_roots()
        $LOAD_PATH
          .map {File.dirname File.expand_path(_1.to_s)}
          .uniq
          .reject {installed? _1}
          .select {Dir.glob(File.join _1, '*.gemspec').any?}
          .to_h {[spec_of(_1).name, _1]}
      end

      def self.spec_of(root)
        installed = Gem::Specification.find {_1.full_gem_path == root}
        return installed if installed
        path = Dir.glob(File.join root, '*.gemspec').first or
          raise Error, "no gemspec in '#{root}'"
        # a gemspec may run git ls-files, which lists the files of the repository it is run in
        Dir.chdir(root) {Gem::Specification.load path} or
          raise Error, "failed to load '#{path}'"
      end

      def self.installed?(root)
        Gem.path.any? {root.start_with? File.join(_1, 'gems', '')}
      end

      private_class_method :library_name, :find_gem, :source_roots, :spec_of, :installed?

    end# Library


  end# Packager


end# Reflex
