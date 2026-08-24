require 'tmpdir'

MESA_VERSION = '26.2.0'

def sh(cmd)
  puts cmd
  system cmd or raise "failed: #{cmd}"
end

def setup_mesa(version = MESA_VERSION)
  name = "mesa3d-#{version}-release-msvc"
  url  = "https://github.com/pal1000/mesa-dist-win/releases/download/#{version}/#{name}.7z"

  Dir.mktmpdir do |dir|
    Dir.chdir dir do
      sh %( curl -Lo mesa.7z #{url} )
      sh %( 7z x mesa.7z )
      sh %( powershell.exe .\\systemwidedeploy.cmd 1 )
    end
  end

  File.open(ENV['GITHUB_ENV'], 'a') {|f| f.puts 'GALLIUM_DRIVER=llvmpipe'}
end
