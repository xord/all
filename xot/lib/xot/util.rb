require 'rbconfig'


module Xot


  extend module Util

    def osx?()
      /darwin/.match? RUBY_PLATFORM
    end

    def ios?()
      false
    end

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

    def gcc?()
      /(^|\-)g\+\+$/i.match? RbConfig::CONFIG['CXX']
    end

    def clang?()
      /(^|\s)clang/i.match? RbConfig::CONFIG['CXX']
    end

    def github_actions?()
      ENV['GITHUB_ACTIONS'] == 'true'
    end

    alias ci? github_actions?

    self

  end# Util


end# Xot
