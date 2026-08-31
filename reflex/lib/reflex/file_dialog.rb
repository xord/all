require 'xot/setter'
require 'xot/hookable'
require 'xot/block_util'
require 'xot/universal_accessor'
require 'xot/inspectable'
require 'reflex/ext'


module Reflex


  class FileDialog

    include Xot::Setter
    include Xot::Hookable
    include Xot::Inspectable

    def initialize(options = nil, &block)
      super()
      set options if options
      Xot::BlockUtil.instance_eval_or_block_call self, &block if block
    end

    universal_accessor :owner, :title, :extensions

    def open_file(dir = nil, &block)
      @file_block = block ? -> e {block.call e.paths.first, e} : nil
      open_file! expand(dir)
      self
    end

    def open_files(dir = nil, &block)
      @file_block = block ? -> e {block.call e.paths, e} : nil
      open_files! expand(dir)
      self
    end

    def open_directory(dir = nil, &block)
      @file_block = block ? -> e {block.call e.paths.first, e} : nil
      open_directory! expand(dir)
      self
    end

    def save_file(dir = nil, name: nil, &block)
      @file_block = block ? -> e {block.call e.paths.first, e} : nil
      save_file! expand(dir), name
      self
    end

    alias open_dir open_directory

    private

      def expand(dir)
        dir ? File.expand_path(dir.to_s) : nil
      end

      def call_file_block(e)
        block, @file_block = @file_block, nil
        block&.call e
      end

      def call_cancel_block()
        @file_block = nil
      end

  end# FileDialog


end# Reflex
