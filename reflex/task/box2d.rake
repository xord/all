# -*- mode: ruby; coding: utf-8 -*-


task :box2d => 'box2d:update'


namespace :box2d do


  mod     = MODULE
  tmp_dir = mod.root_dir 'tmp'

  lib_git  = 'https://github.com/erincatto/Box2D'
  lib_name = File.basename lib_git
  lib_root = "#{tmp_dir}/#{lib_name}"
  lib_path = "Box2D/Box2D"

  copy_from    = "#{lib_root}/#{lib_path}"
  copy_to_base = mod.root_dir 'src/physics'
  copy_to      = "#{copy_to_base}/#{File.basename lib_path}"
  copy_exts    = %w[h cpp]


  task :update => [:clone, copy_to_base] do
    sh %( rm -rf #{copy_to} )
    sh %( cp -r #{copy_from} #{copy_to_base} )

    Dir.glob "#{copy_to}/**/*" do |path|
      ext = path[/\.[^.]+$/]
      sh %( rm -f #{path} ) if ext && ext !~ /\.(#{copy_exts.join '|'})/i
    end
  end

  task :clone => tmp_dir do
    Dir.chdir tmp_dir do
      sh %( git clone #{lib_git} ) unless File.exist? lib_root
      Dir.chdir lib_root do
        sh %( git pull --rebase )
      end
    end
  end

  directory tmp_dir, copy_to_base


end# :box2d
