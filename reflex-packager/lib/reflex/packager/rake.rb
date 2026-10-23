require 'rbconfig'
require 'xot/rake'
require 'reflex/packager'
require 'reflex/packager/profiles/reflex'


module Reflex


  module Packager


    module Rake

      def package_application()
        config       = Config.load REFLEX, '.'
        platform     = PLATFORMS[Packager.default_platform].new config, pack: true
        app_path     = platform.dist_path
        archive_path = platform.archive_path
        tag          = "v#{config.version}"
        srcs         = [
          *application_files(config),
          *REFLEX.config_files,
          'VERSION',
          'Gemfile.lock'
        ].select {File.file? _1}

        relative       = -> path {path.delete_prefix "#{config.dir}/"}
        reflex_package = -> *args do
          reflex = File.expand_path '../../../bin/reflex', __dir__
          sh RbConfig.ruby, reflex, 'package', '--pack', *args, '.'
        end

        desc "package the application into #{relative[app_path]}"
        alias_task :package => app_path

        desc "archive the application into #{relative[archive_path]}"
        alias_task :archive => archive_path

        namespace :package do
          platform.store_package_paths.each do |store, path|
            desc "package the application for #{store} into #{relative[path]}"
            alias_task store => path
          end
        end

        desc "release the application on GitHub, by the tag #{tag}"
        task :release => archive_path do
          ref = ENV['GITHUB_REF_NAME']
          raise "#{ref} is not the tag of the version, #{tag}" if ref && ref != tag
          release_on_github archive_path, tag: tag, notes: release_notes(tag)
        end

        namespace :upload do
          desc "upload #{relative[archive_path]} to itch.io"
          task :itchio => archive_path do
            project = config.upload.itchio_project ||
              raise("no upload.itchio.project in #{REFLEX.config_files.first}")
            Stores::Itchio.new(project).upload archive_path,
              channel: Packager.default_platform.to_s, version: config.version
          end

          platform.store_package_paths[:appstore]&.then do |pkg_path|
            desc "upload #{relative[pkg_path]} to App Store Connect"
            task :appstore => pkg_path do
              Stores::AppStore.new.upload pkg_path, platform: Packager.default_platform.to_s
            end
          end
        end

        task :clean do
          rm_rf File.dirname(platform.dist_dir)
        end

        task :clobber => :clean do
          rm_rf File.dirname(platform.platform_dir)
        end

        file app_path => srcs do
          reflex_package.call
        end

        file archive_path => app_path do
          sh(*platform.archive_command)
        end

        platform.store_package_paths.each do |store, path|
          file path => srcs do
            reflex_package.call "--#{store}"
          end
        end
      end

      private

      def application_files(config)
        config.app_files.flat_map {File.directory?(_1) ? Dir.glob("#{_1}/**/*") : _1}
      end

      def release_notes(tag)
        commit = git('-C', Reflex::Extension.root_dir, 'rev-parse', 'HEAD', err: File::NULL).strip
        [
          Xot::ChangeLog.new.changes(tag),
          ("Built with xord/all@#{commit}." unless commit.empty?)
        ].compact.join("\n\n")
      end

    end# Rake


  end# Packager


end# Reflex


include Reflex::Packager::Rake
