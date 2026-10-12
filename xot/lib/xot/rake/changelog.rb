module Xot


  class ChangeLog

    HEADING = /^[[:blank:]]*##\s*\[\s*v(\d[\d\.]*)\s*\].*$/

    def initialize(path = 'ChangeLog.md')
      @path = path
    end

    attr_reader :path

    def add(version, changes, date: Time.now)
      version = version.to_s.delete_prefix 'v'
      section = [
        "## [v#{version}] - #{date.strftime '%Y-%m-%d'}",
        changes.map {"- #{_1}"}.join("\n")
      ].join("\n\n")

      text = File.read @path
      if index = text.index(HEADING)
        text.insert(index, "#{section}\n\n\n")
      else
        text = "#{text.rstrip}\n\n\n#{section}\n"
      end
      File.write @path, text
    end

    def sections()
      File.read(@path)
        .split(HEADING)
        .drop(1)
        .each_slice(2)
        .to_h {|version, changes| [version, changes.to_s.strip]}
    end

    def versions()
      sections.keys
    end

    def changes(version)
      sections[version.to_s.delete_prefix 'v']
    end

  end# ChangeLog


end# Xot
