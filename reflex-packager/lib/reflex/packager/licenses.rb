require 'json'


module Reflex


  module Packager


    # The licenses of what a packaged app is built of, as {name => text}: the
    # Ruby the platform embeds, the libraries, what they have in their
    # vendor/, and the gems of the Gemfile, written into the app as FILE for
    # it to show them. Included by a platform, with Gems.
    #
    # The standard gems, as ostruct, are left to the license of Ruby, which
    # covers them.
    #
    module Licenses

      FILE = 'licenses.json'

      # The files of a license in a directory, of any case: copying.txt too.
      #
      FILES = '{LICENSE,LICENCE,COPYING,BSDL,LEGAL,MIT-LICENSE}*'

      def licenses()
        {
          **runtime_licenses,
          **libraries.to_h {[_1.name, license_of(_1.root)]},
          **vendor_dirs.to_h {[File.basename(_1), license_of(_1)]},
          **license_gem_roots.to_h {|name, root| [name, license_of(root)]}
        }
      end

      private

      def write_licenses()
        write FILE, JSON.pretty_generate(licenses)
      end

      # The licenses of the Ruby the platform embeds, by name.
      #
      def runtime_licenses()
        {}
      end

      # The directories under vendor/ of the libraries the app is built of.
      #
      def vendor_dirs()
        []
      end

      # The texts of the license files in +dir+, joined.
      #
      def license_of(dir)
        files = Dir.glob(FILES, File::FNM_CASEFOLD, base: dir)
          .map {File.join dir, _1}.select {File.file? _1}.sort
        raise Error, "no license file in '#{dir}'" if files.empty?
        files.map {File.read(_1, encoding: 'UTF-8').strip}.join("\n\n")
      end

      # The roots of the gems of the Gemfile shipped with the app, by name,
      # but the ones Ruby comes with.
      #
      def license_gem_roots()
        standard = standard_specs.map {_1['name']}
        gemfile_specs
          .select {app_gem_dirs.key?(_1['name']) && !standard.include?(_1['name'])}
          .to_h {[_1['name'], _1['root']]}
      end

    end# Licenses


  end# Packager


end# Reflex
