require 'rbconfig'


module Xot


  extend module Util

    def win32?()
      RUBY_PLATFORM =~ /mswin|ming|cygwin/
    end

    def mswin?()
      RUBY_PLATFORM =~ /mswin/
    end

    def ming?()
      RUBY_PLATFORM =~ /ming/
    end

    def cygwin?()
      RUBY_PLATFORM =~ /cygwin/
    end

    def osx?()
      RUBY_PLATFORM =~ /darwin/
    end

    def ios?()
      false
    end

    def gcc?()
      RbConfig::CONFIG['CXX'] =~ /(^|\s)g\+\+/i
    end

    def clang?()
      RbConfig::CONFIG['CXX'] =~ /(^|\s)clang/i
    end

    self

  end# Util


end# Xot
