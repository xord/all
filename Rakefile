# -*- mode: ruby -*-


%w[xot rucy beeps rays reflex processing rubysketch]
  .map  {|s| File.expand_path "#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'xot/rake/util'

include Xot::Rake


EXTS  = %i[xot rucy beeps rays reflex]
GEMS  = EXTS + %i[processing rubysketch]
REPOS = %i[cruby] + GEMS
TASKS = %i[vendor erb lib ext test gem install uninstall upload clean clobber]

TARGETS = []


def targets ()
  TARGETS.empty? ? GEMS : TARGETS
end

def append_target (*targets)
  TARGETS.concat targets.flatten
  TARGETS.uniq!
end

def sh_each_target (cmd)
  targets.each do |t|
    cd_sh File.expand_path(t.to_s, __dir__), cmd
  end
end


default_tasks

task :all do
  append_target *REPOS
end

task :exts do
  append_target *EXTS
end

task :gems do
  append_target *GEMS
end

REPOS.each do |repo|
  task repo do
    append_target repo
  end
end

TASKS.each do |task_|
  task task_ => :scripts do
    sh_each_target "rake #{task_}"
  end
end

task :ext => :clean_bundles

task :clean_bundles do
  sh %( find . -iname 'native.bundle' | xargs rm )
end

task :run do
  raise unless name = env(:sample)
  sh %{ ruby reflex/samples/#{name}.rb }
end

task :scripts => 'scripts:build'


namespace :subtree do
  github = 'https://github.com/xord'
  branch = ENV['branch'] || 'master'
  opts   = actions? ? '-q' : ''

  task :import do
    name = ENV['name'] or raise
    sh %( git subtree add #{opts} --prefix=#{name} #{github}/#{name} #{branch} )
  end

  task :push do
    targets.each do |t|
      sh %( git subtree push #{opts} --prefix=#{t} #{github}/#{t} #{branch} )
    end
  end

  task :pull do
    targets.each do |t|
      sh %( git subtree pull #{opts} --prefix=#{t} #{github}/#{t} #{branch} )
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

    REPOS.each do |repo|
      yamls.each do |from, to|
        path = "#{repo}/#{to}"
        next unless File.exist?(path)

        task :build => path

        file path => from do
          sh %( cp #{from} #{path} )
        end
      end
    end
  end
end
