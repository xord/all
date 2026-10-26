require 'rbconfig'
require 'xot/rake'
require 'reflex/packager'
require 'reflex/packager/profiles/reflex'


module Reflex


  module Packager


    module Rake

      # The metadata of the app for the App Store, in the directory of the app.
      #
      APPSTORE_METADATA_DIR = 'store/appstore'

      # Defines the tasks to package and release the app, by +profile+,
      # which the rake file of the gem of another profile gives.
      #
      def package_application(profile = REFLEX)
        config       = Config.load profile, '.'
        platform     = PLATFORMS[Packager.default_platform].new config, pack: true
        app_path     = platform.dist_path
        archive_path = platform.archive_path
        tag          = "v#{config.version}"
        srcs         = [
          *config.app_files,
          *profile.config_files,
          'VERSION',
          'Gemfile.lock'
        ].select {File.file? _1}

        relative       = -> path {path.delete_prefix "#{config.dir}/"}
        reflex_package = -> *args do
          sh RbConfig.ruby, profile.executable, 'package', *args
        end
        appstore       = -> {'--appstore' if config.upload.appstore? && get_env(:appstore, false)}
        no_upload      = -> key do
          puts "not uploading, by upload.#{key} of #{profile.config_files.first}"
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

        if Packager.default_platform == :macos
          desc 'notarize the application, waiting for Apple to check it, ' +
            'and package it for the Mac App Store too by appstore=true, with upload.appstore'
          task :notarize do
            reflex_package.call '--pack', '--notarize', *appstore.call, '.'
          end

          namespace :notarize do
            desc 'submit the application to be notarized, not waiting for it, ' +
              'and package it for the Mac App Store too by appstore=true, with upload.appstore'
            task :submit do
              reflex_package.call '--pack', '--notarize-submit', *appstore.call, '.'
            end

            desc 'wait for the notarization of id=ID, by the API key'
            task :wait do
              id = ENV['id'].then {_1 unless _1.to_s.empty?} ||
                raise('no id=ID of the notarization to wait for')
              reflex_package.call '--notarize-wait', id
            end

            desc 'export the application notarized, waiting for the notarization'
            task :export do
              reflex_package.call '--pack', '--notarize-export', '.'
            end
          end
        end

        desc "release the application archived or packaged on GitHub, by the tag #{tag}"
        task :release do
          ref = ENV['GITHUB_REF_NAME']
          raise "#{ref} is not the tag of the version, #{tag}" if ref && ref != tag
          paths = [archive_path, *platform.store_package_paths.values].select {File.file? _1}
          raise 'nothing to release, archive or package the application first' if paths.empty?
          release_on_github(*paths, tag: tag, notes: release_notes(tag))
        end

        namespace :download do
          namespace :appstore do
            desc "download the metadata of the app in App Store Connect into #{APPSTORE_METADATA_DIR}"
            task :metadata do
              Stores::AppStore.new.download_metadata File.join(config.dir, APPSTORE_METADATA_DIR),
                bundle_id: config.bundle_id, platform: :macos
            end
          end
        end

        namespace :upload do
          desc "upload #{relative[archive_path]} to itch.io, by upload.itchio"
          if config.upload.itchio?
            task :itchio => archive_path do
              # on CI, where butler can not be logged in
              raise 'no BUTLER_API_KEY to upload to itch.io' if
                ENV['GITHUB_ACTIONS'] && ENV['BUTLER_API_KEY'].to_s.empty?
              Stores::Itchio.new(config.upload.itchio_project).upload archive_path,
                channel: Packager.default_platform.to_s, version: config.version
            end
          else
            task(:itchio) {no_upload[:itchio]}
          end

          platform.store_package_paths[:appstore]&.then do |pkg_path|
            desc "upload #{relative[pkg_path]} to App Store Connect, by upload.appstore"
            if config.upload.appstore?
              task :appstore => pkg_path do
                Stores::AppStore.new.upload pkg_path, platform: Packager.default_platform.to_s
              end
            else
              task(:appstore) {no_upload[:appstore]}
            end
          end

          namespace :appstore do
            desc "upload the metadata in #{APPSTORE_METADATA_DIR} to App Store Connect," +
              ' only showing the changes by dryrun=1'
            task :metadata do
              Stores::AppStore.new.upload_metadata File.join(config.dir, APPSTORE_METADATA_DIR),
                bundle_id: config.bundle_id, platform: :macos,
                dry_run: get_env_bool(:dryrun)
            end
          end
        end

        task :hooks do
          install_hooks File.join(__dir__, 'hooks')
        end

        task :clean do
          rm_rf File.dirname(platform.dist_dir)
        end

        task :clobber => :clean do
          rm_rf File.dirname(platform.platform_dir)
        end

        file app_path => srcs do
          reflex_package.call '--pack', '.'
        end

        file archive_path => app_path do
          sh(*platform.archive_command)
        end

        platform.store_package_paths.each do |store, path|
          file path => srcs do
            reflex_package.call '--pack', "--#{store}", '.'
          end
        end
      end

      # Defines the task test, running test/**/test_*.rb with lib/ on the
      # load path.
      #
      def test_application()
        test_ruby_extension
      end

      private

      def release_notes(tag)
        commit = ENV['MONOREPO_COMMIT'] ||
          git('-C', Reflex::Extension.root_dir, 'rev-parse', 'HEAD', err: File::NULL).strip
        [
          Xot::ChangeLog.new.changes(tag),
          ("Built with xord/all@#{commit}." unless commit.empty?)
        ].compact.join("\n\n")
      end

    end# Rake


  end# Packager


end# Reflex


include Reflex::Packager::Rake

# for the task verbose, which the workflows run rake with
default_tasks
