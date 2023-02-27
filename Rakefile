# -*- mode: ruby -*-


%w[xot rucy beeps rays reflex processing rubysketch]
  .map  {|s| File.expand_path "#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}


require 'xot/rake/util'

include Xot::Rake


EXTENSIONS = %i[xot rucy beeps rays reflex processing rubysketch]
TASKS      = %i[vendor erb lib ext test gem install uninstall upload clean clobber]

TARGETS = []


def targets ()
  TARGETS.empty? ? EXTENSIONS : TARGETS
end

def sh_each_target (cmd)
  targets.each do |t|
    cd_sh File.expand_path(t.to_s, __dir__), cmd
  end
end


task :default

task :quiet do
  ENV['RAKEOPT'] = '--quiet'
end

task :debug do
  debug true
end

task :all do
  TARGETS.concat EXTENSIONS
end

EXTENSIONS.each do |ext|
  task ext do
    TARGETS << ext
  end
end

TASKS.each do |task_|
  task task_ => :scripts do
    sh_each_target "rake #{task_}"
  end
end

task :run do
  raise unless name = env(:sample)
  sh %{ ruby reflex/samples/#{name}.rb }
end

task :scripts => 'scripts:build'


namespace :subtree do
  github = 'https://github.com/xord'
  opts   = actions? ? '-q' : ''

  task :import do
    targets.each do |t|
      sh %( git subtree add #{opts} --prefix=#{t} #{github}/#{t} master )
    end
  end

  task :push do
    targets.each do |t|
      sh %( git subtree push #{opts} --prefix=#{t} #{github}/#{t} master )
    end
  end

  task :pull do
    targets.each do |t|
      sh %( git subtree pull #{opts} --prefix=#{t} #{github}/#{t} master )
    end
  end
end


namespace :scripts do
  task :build => ['hooks:build', 'workflows:build']

  namespace :hooks do
    hooks = Dir.glob('.hooks/*')
      .map {|path| [path, ".git/hooks/#{File.basename path}"]}
      .to_h

    task :build => hooks.values

    hooks.each do |from, to|
      file to => from do
        sh %( cp #{from} #{to} )
      end
    end
  end

  namespace :workflows do
    yamls = Dir.glob('.workflows/*.{yaml,yml,rb}')
      .map {|path| [path, ".github/workflows/#{File.basename path}"]}
      .to_h

    EXTENSIONS.each do |ext|
      yamls.each do |from, to|
        path = "#{ext}/#{to}"

        task :build => path

        file path => from do
          sh %( cp #{from} #{path} )
        end
      end
    end
  end
end
