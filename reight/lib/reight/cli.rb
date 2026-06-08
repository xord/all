require 'optparse'
require 'reight/extension'


class Reight::CLI

  SUBCOMMANDS = %w[run edit new package]

  def help()
    <<~END
      Usage: r8 [options] <command> [args]

      Commands:
        run [DIR]        run the game (default)
        edit [DIR]       edit the game
        new NAME         create a new project
        package [DIR]    package as an application

      Options:
        -h, --help       show this message
        -v, --version    show version
    END
  end

  def run(argv)
    argv, params = parse argv do |o|
      o.on('-h', '--help')    {puts help; exit}
      o.on('-v', '--version') {puts Reight::Extension.version; exit}
    end

    case command = SUBCOMMANDS.include?(argv.first) ? argv.shift : 'run'
    when 'run'     then start command, argv, edit: false
    when 'edit'    then start command, argv, edit: true
    when 'new'     then package command, argv
    when 'package' then package command, argv
    end
  rescue OptionParser::ParseError => e
    $stderr.puts "Error: #{e.message}"
    exit 1
  end

  private

  def parse(argv, &block)
    parser = OptionParser.new(&block)
    argv   = argv.dup
    params = {}
    parser.order! argv, into: params
    return argv, params
  end

  def start(command, argv, edit:)
    argv, = parse argv do |o|
      o.on('-h', '--help') {puts "Usage: r8 #{command} [DIR]"; exit}
    end

    require 'reight'
    path = argv.shift || '.'
    path = File.expand_path path, Dir.pwd unless path.start_with?('/')
    Reight::R8.new path, edit: edit
  end

  def package(command, argv)
    require 'reflex/packager'
    cli = Reflex::Packager::CLI.new Reflex::Packager::Profile.new(
      pod:          'Reight',
      git:          'https://github.com/xord/reight',
      version:      Reight::Extension.version,
      libraries:    %w[Xot Rucy Beeps Rays Reflex Processing RubySketch Reight],
      extensions:   %w[beeps_ext rays_ext reflex_ext],
      config_files: %w[reight.yml reight.yaml r8.yml r8.yaml],
      command:      'r8',
      boot:         <<~BOOT,
        require 'reight/cli'
        Reight::CLI.new.run %w[run .]
      BOOT
      templates: {'game.rb': <<~GAME, 'reight.yml': <<~CONFIG})
        setup do
          setTitle '{{name}}'
        end

        draw do
          background 100
          text 'hello, world!', 100, 100
        end
      GAME
        name: {{name}}
        version: 1.0.0
        #bundle_id: org.xord.reight.example.{{name_id}}
        #icon: icon.png
      CONFIG

    cli.run [command] + argv.dup
  end

end# CLI
