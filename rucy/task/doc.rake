# -*- mode: ruby -*-


File.expand_path('../bin', __dir__).tap do |path|
  ENV['PATH'] += ":#{path}" unless ENV['PATH'].split(':').include?(path)
end


task :doc => 'doc:build'

%w[clean rdoc].each do |t|
  task t.intern => "doc:#{t}"
end


namespace :doc do


  ext       = EXTENSIONS.last
  name      = env :NAME,      ext.name.downcase
  extdir    = env :EXTDIR,    'ext'
  docdir    = env :DOCDIR,    'doc'
  rdoc      = env :RDOC,      'rdoc'# 'yardoc'
  rucy2rdoc = env :RUCY2RDOC, 'rucy2rdoc'

  srcdir  = "#{extdir}/#{name}"
  rdocdir = ".doc/#{srcdir}"

  srcs  = FileList["#{srcdir}/**/*.cpp"]
  rdocs = Hash[srcs.map{|path| [path, "#{rdocdir}/#{File.basename path}"]}]
  out   = "#{docdir}/index.html"


  task :build => out

  task :clean do
    sh %( rm -rf #{docdir} #{rdocs.values.join ' '} )
  end

  task :rdoc => rdocs.values

  file out => :rdoc do
    sh %( #{rdoc} #{rdocs.values.join ' '} )
  end

  rdocs.each do |(cpp, rdoc)|
    file rdoc => [cpp, rdocdir] do
      sh %( #{rucy2rdoc} #{cpp} > #{rdoc} )
    end
  end

  directory rdocdir


end# :doc
