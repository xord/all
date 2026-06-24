require 'optparse'
require 'fileutils'
require 'xot/block_util'


module Reflex


  module Packager


    # Command line interface for a packager executable. Instantiated with the
    # runtime profile to package for (Reflex by default).
    #
    class CLI

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
        profile      = @profile
        argv, params = parse argv, "Usage: #{profile.command} package [options] [DIR]" do
          on '--platform PLATFORM', 'target platform (default: macos)'
          on '--config PATH',       "config file path (default: DIR/#{profile.config_files.first})"
          on '--generate-only',     'generate project files but do not build'
          on '--verbose',           'verbose output'
        end

        dir      = argv.shift || '.'
        platform = (params[:platform] || 'macos').to_sym
        klass    = PLATFORMS[platform] || raise(Error, "unknown platform: '#{platform}'")
        config   = Config.load profile, dir, params[:config]
        klass.new(config, verbose: params[:verbose])
          .package generate_only: params[:'generate-only']
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
