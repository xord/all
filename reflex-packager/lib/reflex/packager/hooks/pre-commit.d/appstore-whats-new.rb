#!/usr/bin/env ruby

# Writes the section added to a ChangeLog.md in the commit into whatsNew of
# store/appstore/<language>/version.yml beside it, of all the languages, in
# the language of the ChangeLog, to be translated after, and adds them to
# the commit.
#
# Copied into pre-commit.d of the hooks of git by 'rake hooks' of an app,
# which the pre-commit of xot runs, so that it runs with any ruby, requiring
# nothing but the standard libraries.
#
# Rewrites whatsNew as text, to keep how the others are written and the
# comments, and checks the result as YAML.


require 'yaml'


HEADING = /##\s*\[\s*v(\d[\d\.]*)\s*\]\s*-\s*\d{4}-\d{2}-\d{2}\s*$/

def git(*args)
  IO.popen ['git', *args], &:read
end

def added_version(changelog)
  git('diff', '--cached', '--', changelog)[/^\+\s*#{HEADING}/, 1]
end

# The text of the section of +version+ in +changelog+ in the commit.
#
def section(changelog, version)
  lines = git('show', ":#{changelog}").lines(chomp: true)
  start = lines.index {_1 =~ /^\s*#{HEADING}/ && $1 == version}
  lines[start + 1..].take_while {_1 !~ /^\s*##\s/}.join("\n").strip
end

def whats_new(yaml, text)
  block = "whatsNew: |-\n" + text.lines.map {_1 == "\n" ? _1 : "  #{_1}"}.join + "\n"
  key   = /^whatsNew:.*\n(?:\n*[ \t].*\n)*/
  yaml  = "#{yaml}\n" unless yaml.empty? || yaml.end_with?("\n")
  yaml.match?(key) ? yaml.sub(key) {block} : yaml + block
end

def whats_new?(yaml, old, text)
  YAML.safe_load(yaml) == (YAML.safe_load(old) || {}).merge('whatsNew' => text)
rescue Psych::Exception
  false
end

git('ls-files').lines(chomp: true)
  .grep(%r{(\A|/)ChangeLog\.md\z})
  .each do |changelog|
    paths = Dir.glob File.join(File.dirname(changelog), 'store/appstore/*/version.yml')
    ver   = added_version changelog
    next if paths.empty? || !ver

    text  = section changelog, ver
    yamls = paths.to_h do |path|
      abort "pre-commit: #{path} has changes not to be overwritten" unless
        git('diff', '--', path).empty?

      old  = File.read path
      yaml = whats_new old, text
      abort "pre-commit: failed to write whatsNew into #{path}" unless
        whats_new? yaml, old, text

      [path, yaml]
    end
    yamls.each do |path, yaml|
      File.write path, yaml
      system 'git', 'add', path, exception: true
    end
  end
