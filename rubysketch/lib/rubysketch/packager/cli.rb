require 'optparse'
require 'rubysketch/extension'
require 'rubysketch/packager'


module RubySketch


  module Packager


    # Command line interface for the 'rubysketch' executable.
    #
    module CLI

      USAGE = <<~END
        Usage: rubysketch <command> [options]

        Commands:
          package [DIR]  package the sketch in DIR (default: .) as an application
          new NAME       create a new sketch project

        Options:
          -h, --help     show this message
          --version      show version
      END

      module_function

      def run(argv)
        argv = argv.dup
        case command = argv.shift
        when 'package'           then package argv
        when 'new'               then create argv
        when '--version'         then puts Extension.version
        when nil, '-h', '--help' then puts USAGE
        else
          $stderr.puts "unknown command: '#{command}'", '', USAGE
          exit 1
        end
      rescue Error => e
        $stderr.puts "Error: #{e.message}"
        exit 1
      end

      def package(argv)
        params      = {}
        opt         = OptionParser.new
        opt.banner  = 'Usage: rubysketch package [options] [DIR]'
        opt.version = Extension.version

        opt.on '--platform PLATFORM', 'target platform (default: macos)'
        opt.on '--config PATH',
          "config file path (default: DIR/#{Config::DEFAULT_FILE})"
        opt.on '--generate-only', 'generate project files but do not build'
        opt.on '--verbose',       'verbose output'

        argv     = opt.parse argv, into: params
        dir      = argv.shift || '.'
        platform = (params[:platform] || 'macos').to_sym
        klass    = PLATFORMS[platform]
        raise Error, "unknown platform: '#{platform}'" unless klass

        config = Config.load dir, params[:config]
        klass.new(config, verbose: params[:verbose])
          .package generate_only: params[:'generate-only']
      end

      def create(argv)
        opt        = OptionParser.new
        opt.banner = 'Usage: rubysketch new NAME'

        argv = opt.parse argv
        name = argv.shift
        raise Error, 'project name required' unless name
        raise Error, "'#{name}' already exists" if File.exist? name

        FileUtils.mkdir_p name
        File.write File.join(name, 'main.rb'), <<~END
          require 'rubysketch'
          using RubySketch

          draw do
            background 0
            textSize 30
            text 'hello, world!', 10, 100
          end
        END
        File.write File.join(name, Config::DEFAULT_FILE), <<~END
          name: #{name}
          #bundle_id: com.example.#{name.downcase.gsub(/[^a-z0-9]+/, '')}
          #version: 1.0.0
          #icon: icon.png
        END
        puts "Created #{name}/"
        puts "  cd #{name} && ruby main.rb           # run the sketch"
        puts "  cd #{name} && rubysketch package .   # package as an application"
      end

    end# CLI


  end# Packager


end# RubySketch
