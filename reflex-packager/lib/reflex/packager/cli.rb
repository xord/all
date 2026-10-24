require 'optparse'
require 'fileutils'
require 'xot/block_util'


module Reflex


  module Packager


    # Command line interface for a packager executable. Instantiated with the
    # runtime profile to package for (Reflex by default).
    #
    class CLI

      # The options to notarize the app by, and the steps of the notarization
      # they take.
      #
      NOTARIZE_OPTIONS = {
        notarize:          %i[submit export],
        'notarize-submit': %i[submit],
        'notarize-wait':   %i[wait],
        'notarize-export': %i[export]
      }

      def initialize(profile)
        @profile = profile
      end

      def run(argv)
        argv   = argv.dup
        parser = OptionParser.new do |o|
          o.on('--version')    {puts @profile.version; return}
          o.on('-h', '--help') {puts usage;            return}
        end
        parser.order! argv

        case command = argv.shift
        when 'new'     then create  argv
        when 'package' then package argv
        when nil       then puts usage
        else
          $stderr.puts "unknown command: '#{command}'", '', usage
          exit 1
        end
      rescue OptionParser::ParseError, Error => e
        $stderr.puts "Error: #{e.message}"
        exit 1
      end

      def create(argv)
        argv, = parse argv, "Usage: #{@profile.command} new NAME"

        name = argv.shift
        raise Error, 'project name required' unless name
        raise Error, "'#{name}' already exists" if File.exist? name

        FileUtils.mkdir_p name
        @profile.templates.each do |path, content|
          File.write File.join(name, path.to_s), gsub_template(content, name)
        end

        puts "Created #{name}/"
        hints = [
          ["cd #{name} && ruby #{@profile.templates.keys.first}", "run the application"],
          ["cd #{name} && #{@profile.command} package .",         "package as an application"]
        ]
        max = hints.map {|cmd,| cmd.length}.max
        hints.each {|cmd, desc| puts "  #{cmd.ljust max}  # #{desc}"}
      end

      def package(argv)
        profile, platform = @profile, Packager.default_platform
        argv, params      = parse argv, "Usage: #{profile.command} package [options] [DIR]" do
          on '--platform PLATFORM',
            "target platform: #{PLATFORMS.keys.join ' or '} (default: #{platform})"
          on '--config PATH',      "config file path (default: DIR/#{profile.config_files.first})"
          on '--generate-only',    'generate project files but do not build'
          on '--pack',             'put the files of the app together in a data file, for a release'
          on '--generic',          'package the app signed with Developer ID, also with --appstore'
          on '--appstore',         'package the app for the Mac App Store, only it unless --generic'
          on '--notarize',         'have Apple check the app with Developer ID, on macos'
          on '--notarize-submit',  'only submit the app to be notarized, not waiting'
          on '--notarize-wait ID', 'only wait for the notarization ID, by the API key'
          on '--notarize-export',  'only wait for the notarization submitted and export the app'
          on '--verbose',          'verbose output'
        end

        notarize = NOTARIZE_OPTIONS.filter_map {|key, value| value if params[key]}
        raise Error, "only one of #{NOTARIZE_OPTIONS.keys.map {"--#{_1}"}.join ', '}" if
          notarize.size > 1

        id = params[:'notarize-wait']
        raise Error, '--notarize-wait packages nothing, not with --appstore' if
          id && params[:appstore]
        return AppStoreConnect.new.wait_until_notarized id if id

        dir      = argv.shift || '.'
        platform = (params[:platform] || platform).to_sym
        klass    = PLATFORMS[platform] || raise(Error, "unknown platform: '#{platform}'")
        config   = Config.load profile, dir, params[:config]
        klass.new(
          config,
          verbose:  params[:verbose],
          pack:     params[:pack],
          notarize: notarize.first,
          generic:  params[:generic],
          appstore: params[:appstore]
        ).package generate_only: params[:'generate-only']
      end

      private

      def usage()
        <<~END
          Usage: #{@profile.command} <command> [options]

          Commands:
            new NAME       create a new application project
            package [DIR]  package the application in DIR (default: .) as an app

          Options:
            -h, --help     show this message
            --version      show version
        END
      end

      def parse(argv, banner = nil, &block)
        opt        = OptionParser.new
        opt.banner = banner if banner
        Xot::BlockUtil.instance_eval_or_block_call opt, &block if block
        params     = {}
        argv       = opt.parse argv.dup, into: params
        return argv, params
      end

      def gsub_template(str, name)
        {
          name:    name,
          name_id: Config.name2id(name)
        }.each do |from, to|
          str = str.gsub "{{#{from}}}", to
        end
        str
      end

    end# CLI


  end# Packager


end# Reflex
