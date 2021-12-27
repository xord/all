# -*- mode: ruby; coding: utf-8 -*-


POD_VERSION = 1

GITHUB_URL  = "https://github.com/xord/cruby"

RUBY_URL    = 'https://cache.ruby-lang.org/pub/ruby/3.0/ruby-3.0.3.tar.gz'
RUBY_SHA256 = '3586861cb2df56970287f0fd83f274bd92058872d830d15570b36def7f1a92ac'

OSSL_URL    = 'https://www.openssl.org/source/openssl-1.1.1m.tar.gz'
OSSL_SHA256 = 'f89199be8b23ca45fc7cb9f1d8d3ee67312318286ad030f5316aca6462db6c96'


module CRuby
  def self.version ()
    *heads, patch = ruby_version
    [*heads, patch * 100 + POD_VERSION].join '.'
  end

  def self.ruby_version ()
    m = RUBY_URL.match /ruby\-(\d)\.(\d)\.(\d)(?:\-\w*)?\.tar\.gz/
    raise "invalid ruby version" unless m && m.captures.size == 3
    m.captures.map &:to_i
  end
end
