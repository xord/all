require 'rbconfig'


module Xot


  extend module Util

    def win32?()
      /mswin|ming|cygwin/.match? RUBY_PLATFORM
    end

    def mswin?()
      /mswin/.match? RUBY_PLATFORM
    end

    def mingw?()
      /ming/.match? RUBY_PLATFORM
    end

    def cygwin?()
      /cygwin/.match? RUBY_PLATFORM
    end

    def osx?()
      /darwin/.match? RUBY_PLATFORM
    end

    def ios?()
      false
    end

    def gcc?()
      /(^|\s)g\+\+/i.match? RbConfig::CONFIG['CXX']
    end

    def clang?()
      /(^|\s)clang/i.match? RbConfig::CONFIG['CXX']
    end

    def github_actions?()
      (ENV['GITHUB_ACTIONS'] || 0).to_i != 0
    end

    alias ci? github_actions?

    self

  end# Util


end# Xot
