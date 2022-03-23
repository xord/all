# -*- mode: ruby; coding: utf-8 -*-


POD_VERSION = 0

GITHUB_URL  = "https://github.com/xord/cruby"

RUBY_URL    = 'https://cache.ruby-lang.org/pub/ruby/3.1/ruby-3.1.0.tar.gz'
RUBY_SHA256 = '50a0504c6edcb4d61ce6b8cfdbddaa95707195fab0ecd7b5e92654b2a9412854'

OSSL_URL    = 'https://www.openssl.org/source/openssl-1.1.1n.tar.gz'
OSSL_SHA256 = '40dceb51a4f6a5275bde0e6bf20ef4b91bfc32ed57c0552e2e8e15463372b17a'


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
