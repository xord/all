require 'ostruct'


module Xot


  module Invoker

    def initialize()
    end

    def handlers(create = false)
      if create
        @handlers ||= []
      else
        @handlers ? @handlers : []
      end
    end

    def add_handler(handler)
      return unless handler
      a = self.handlers true
      a.push handler unless a.include? handler
    end

    def remove_handler(handler)
      return unless handler
      self.handlers.delete handler
    end

    def invoke(name, attributes = {}, options = {})
      only     = options[:only]
      only     = [only] if only && !only.kind_of?(Array)
      handlers = only ? only : @handlers
      return unless handlers

      handlers.each do |handler|
        handler.send name, OpenStruct.new(attributes) if handler.respond_to? name
      end
    end

  end# Invoker


end# Xot
