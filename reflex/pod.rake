# -*- mode: ruby -*-
#
# Pins the dependencies to this checkout's commit by cloning the monorepo
# (xord/all) and checking out the commit named by HEAD's [[UUID]] trailer.


ALL_REPO = 'https://github.com/xord/all.git'
ALL_DIR  = 'all'

DEPS = File.readlines('Rakefile', chomp: true)
  .map {|line| line[%r|require\s*['"](\w+)/extension["']|, 1]}
  .compact


def head_uuid()
  `git log -1 --format=%B`[/^\[\[([0-9a-fA-F-]+)\]\]$/, 1] ||
    raise('pod.rake: HEAD has no [[UUID]] trailer; cannot pin dependencies')
end

def checkout_monorepo(uuid)
  sh %( git clone --no-tags #{ALL_REPO} #{ALL_DIR} ) unless File.directory? ALL_DIR

  commit = `git -C #{ALL_DIR} log origin/HEAD -F --grep='[[#{uuid}]]' --format=%H -1`
    .strip.then {_1.empty? ? nil : _1}
  raise "pod.rake: no commit for [[#{uuid}]] in #{ALL_REPO}" unless commit

  sh %( git -C #{ALL_DIR} checkout -q #{commit} )
end


task :clobber do
  sh %( rm -rf #{ALL_DIR} )
end

task :setup do
  checkout_monorepo head_uuid

  Dir.chdir ALL_DIR do
    sh %( VENDOR_NOCOMPILE=1 rake #{DEPS.join ' '} vendor erb )
  end
end
