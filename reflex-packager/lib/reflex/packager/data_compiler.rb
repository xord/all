require_relative 'data_file'


module Reflex


  module Packager


    # Compiles the Ruby scripts of an app into instruction sequences for its
    # data file, which DataLoader reads them from, named as the scripts but
    # with .rbc.
    #
    # They are compiled by the Ruby running this, which has to be the one a
    # package runs them on, with their paths relative to the app directory,
    # as the one the package runs in has them.
    #
    # A package carries none of this, which requires nothing but DataFile,
    # for an app to compile its scripts with the Ruby in it.
    #
    module DataCompiler

      class << self

        # The names of the Ruby scripts of the app in +dir+.
        #
        def scripts(dir)
          Dir.glob('**/*.rb', base: dir).select {File.file? File.join(dir, _1)}.sort
        end

        # Compiles the Ruby scripts of the app in +dir+ into the files of its
        # data file, with the version of the Ruby.
        #
        def compile(dir)
          data = scripts(dir).to_h do |name|
            source = File.read File.join(dir, name), encoding: Encoding::UTF_8
            iseq   = RubyVM::InstructionSequence.compile source, name, name
            [name.sub(/\.rb\z/, '.rbc'), iseq.to_binary]
          end
          data['.ruby-version'] = RUBY_VERSION
          data
        end

        # Writes the data file at +path+ with the Ruby scripts of the app in
        # +dir+ compiled, all of them before writing it.
        #
        def write(dir, path)
          DataFile.write path, compile(dir)
        end

      end# self

    end# DataCompiler


  end# Packager


end# Reflex
