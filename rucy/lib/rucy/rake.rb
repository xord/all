require 'xot/rake'


module Rucy


  module Rake


    def rdoc()
      env :RDOC, 'rdoc'# 'yardoc'
    end

    def rucy2rdoc()
      env :RUCY2RDOC, 'rucy2rdoc'
    end

    def generate_documents()
      rdocdir = ".doc/#{ext_dir}"
      srcs    = FileList["#{ext_dir}/**/*.{#{src_exts.join ','}}"]
      rdocs   = Hash[srcs.map{|path| [path, "#{rdocdir}/#{File.basename path}"]}]
      out     = "#{doc_dir}/index.html"

      alias_task :doc   => out
      alias_task :clean => 'doc:clean'

      namespace :doc do
        desc "build documents"
        file out => rdocs.values do
          sh %( #{rdoc} #{rdocs.values.join ' '} )
        end

        rdocs.each do |(src, rdoc)|
          file rdoc => [src, rdocdir] do
            sh %( #{rucy2rdoc} #{src} > #{rdoc} )
          end
        end

        directory rdocdir

        task :clean do
          sh %( rm -rf #{doc_dir} #{rdocdir} #{rdocs.values.join ' '} )
        end
      end
    end


  end# Rake


end# Rucy


include Rucy::Rake


File.expand_path('../../bin', __dir__).tap do |path|
  ENV['PATH'] += ":#{path}" unless ENV['PATH'].split(':').include?(path)
end
