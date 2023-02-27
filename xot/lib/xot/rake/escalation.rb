# -*- coding: utf-8 -*-


require 'rake'


module Rake
  class Application

    alias invoke_task_org invoke_task

    def invoke_task(*args, &block)
      invoke_task_org(*args, &block)
    rescue RuntimeError => e
      if e.message =~ /don't\s+know\s+.*\s+task\s+/i
        escalate_tasks
      else
        raise
      end
    end

    def escalate_tasks()
      Dir.chdir '..' do
        cmd = "rake #{ARGV.join ' '}"
        $stderr.puts "(in #{Dir.pwd}) #{cmd}"
        system cmd
      end
      exit 0
    end

  end
end
