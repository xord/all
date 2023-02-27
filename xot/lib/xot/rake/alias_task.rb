# -*- coding: utf-8 -*-


require 'rake/task'
require 'rake/dsl_definition'


module Xot


  module Rake


    class AliasTask < ::Rake::Task

      def timestamp()
        prerequisite_tasks.map {|pre| pre.timestamp}.max || ::Rake::EARLY
      end

    end# AliasTask


  end# Rake


end# Xot


module Rake
  module DSL
    def alias_task(*args, &block)
      Xot::Rake::AliasTask.define_task(*args, &block)
    end
  end
end
