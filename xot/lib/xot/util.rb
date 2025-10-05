require 'rbconfig'


module Xot


  extend module Util

    def get_env!(name, defval = nil)
      val = ENV[name.to_s] || Object.const_get(name) rescue defval
      val.dup rescue val
    end

    def get_env(name, defval = nil)
      case val = get_env!(name, defval)
      when /^\d+$/        then val.to_i
      when 'true',  true  then true
      when 'false', false then false
      when nil            then nil
      else                     val
      end
    end

    def get_env_array(name, defval = nil)
      val = get_env! name, defval
      val = val.strip.split(/\s+/) if val.kind_of? String
      val
    end

    def append_env(name, *args)
      ENV[name] = (ENV[name] || '') + " #{args.flatten.join ' '}"
    end

    def cc()
      get_env :CC, RbConfig::CONFIG['CC'] || 'gcc'
    end

    def cxx()
      get_env :CXX, RbConfig::CONFIG['CXX'] || 'g++'
    end

    def ar()
      get_env :AR, RbConfig::CONFIG['AR']  || 'ar'
    end

    def verbose?(state = nil)
      if state != nil
        ::Rake.verbose state
        ENV['VERBOSE'] = (!!state).to_s
      end
      ::Rake.verbose
    end

    def debug?(state = nil)
      ENV['DEBUG'] = (!!state).to_s if state != nil
      get_env :DEBUG, false
    end

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
      /(^|\-)gcc$/i.match? cc
    end

    def clang?()
      /(^|\-)clang/i.match? cc
    end

    def github_actions?()
      ENV['GITHUB_ACTIONS'] == 'true'
    end

    alias ci? github_actions?

    self

  end# Util


end# Xot
