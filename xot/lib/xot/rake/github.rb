require 'xot/rake/util'
require 'xot/rake/changelog'


module Xot


  module Rake

    MONOREPO             = 'xord/all'
    MONOREPO_DIR         = '../all'
    MONOREPO_FETCH_DEPTH = 100

    def setup_dependencies(only: nil, ext: true)
      deps  = dependency_names
      deps &= Array(only).map(&:to_s) if only
      return if deps.empty?

      checkout_monorepo
      link_monorepo deps, ext: ext
    end

    def setup_monorepo(ref, *libraries)
      raise 'no libraries of the monorepo to set up' if libraries.empty?
      sh 'git', 'init', '-q', MONOREPO_DIR
      Dir.chdir MONOREPO_DIR do
        sh 'git', 'fetch', '-q', '--depth', '1', "https://github.com/#{MONOREPO}.git", ref
        sh 'git', 'checkout', '-q', 'FETCH_HEAD'
      end
      link_monorepo libraries
    end

    def dependency_names()
      File.readlines('Rakefile')
        .filter_map {_1[%r{^\s*require\W+([\w\-]+)/extension\W+$}, 1]}
        .reject {File.file? "lib/#{_1}/extension.rb"} # of this repository
    end

    def checkout_monorepo()
      uuid   = git('log', '-1', '--format=%B')[/^\[\[([0-9a-fA-F-]+)\]\]$/, 1] ||
        raise('no UUID of the monorepo in the last commit')
      commit = fetch_monorepo(uuid) ||
        raise("no commit of the monorepo with the UUID #{uuid}")

      Dir.chdir(MONOREPO_DIR) {sh 'git', 'checkout', '-q', commit}
    end

    def release_on_github(*paths, tag: ENV['GITHUB_REF_NAME'], notes: nil)
      raise 'no tag to release' unless tag
      notes ||= ChangeLog.new.changes(tag).to_s
      sh('gh', 'release', 'create', tag, *paths, '--notes', notes) {|ok, _| ok} ||
        sh('gh', 'release', 'upload', tag, *paths, '--clobber')
    end

    private

    def link_monorepo(libraries, ext: true)
      libraries.each {|lib| sh 'ln', '-snf', "#{File.basename MONOREPO_DIR}/#{lib}", "../#{lib}"}
      libraries.each {|lib| sh %( cd ../#{lib} && rake ext )} if ext
    end

    def fetch_monorepo(uuid)
      unless File.directory? MONOREPO_DIR
        sh 'git', 'clone', '--no-tags', '--depth', MONOREPO_FETCH_DEPTH.to_s,
          "https://github.com/#{MONOREPO}.git", MONOREPO_DIR
      end
      Dir.chdir MONOREPO_DIR do
        loop do
          commit = git('log', 'origin/HEAD', '-F', "--grep=[[#{uuid}]]", '--format=%H', '-1').strip
          return commit unless commit.empty?

          count = git('rev-list', '--count', 'HEAD').to_i
          sh 'git', 'fetch', '--deepen', MONOREPO_FETCH_DEPTH.to_s
          return nil if git('rev-list', '--count', 'HEAD').to_i == count
        end
      end
    end


  end# Rake


end# Xot
