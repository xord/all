# -*- coding: utf-8 -*-
require_relative 'helper'


class TestPackagerConfig < Test::Unit::TestCase

  RP          = Reflex::Packager
  Config      = RP::Config
  MacOSConfig = RP::MacOSConfig

  MAIN = File.basename(__FILE__)

  def config(dir: __dir__, main: nil, parent: nil, stderr: nil, **hash)
    main ||= MAIN
    Config.new TEST_PROFILE, dir, {main: main, **hash}, stderr: stderr
  end

  def load_config(dir, path = nil)
    Config.load TEST_PROFILE, dir, path
  end

  def stderr()
    [].tap {|array|
      def array.puts(s) = self << s
    }
  end

  def touch(path, data = '')
    FileUtils.mkdir_p File.dirname path
    File.write path, data
  end

  def tmpdir(
    yaml_path: 'reflex.yaml',
    yaml:      '',
    main_path: 'main.rb',
    main:      '',
    &block)

    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        File.write yaml_path, yaml if yaml_path && yaml
        File.write main_path, main if main_path && main
        block.call dir
      end
    end
  end

  def test_load()
    tmpdir                      {|dir| assert_equal 'main.rb',  load_config(dir).main}
    tmpdir(yaml: nil)           {|dir| assert_equal 'main.rb',  load_config(dir).main}
    tmpdir(yaml: 'a: b: c')     {|dir| assert_raise(RP::Error) {load_config dir}}
    tmpdir                      {|dir| assert_raise(RP::Error) {load_config "#{dir}/nodir"}}

    tmpdir(yaml_path: '1.yaml') {|dir| assert_equal 'main.rb',  load_config(dir, '1.yaml').main}
    tmpdir                      {|dir| assert_raise(RP::Error) {load_config dir, '2.yaml'}}
    tmpdir(yaml_path: '3.yml')  {|dir| assert_raise(RP::Error) {load_config dir, '3.yaml'}}
    tmpdir(yaml_path: '4.yaml') {|dir| assert_raise(RP::Error) {load_config dir, '4.yml'}}

    tmpdir(yaml: 'name: 5')     {|dir| assert_equal '5',        load_config(dir).name}

    tmpdir(yaml_path: 'reflex.yml', yaml: 'main: 6.rb', main_path: '6.rb') {|dir|
      File.write      'reflex.yaml',      'main: 7.rb'
      assert_equal '6.rb', load_config(dir).main
    }
  end

  def test_load_full_config()
    tmpdir yaml: <<~YAML, main_path: 'app.rb' do |dir|
      name:      My App
      bundle_id: com.example.myapp
      version:   1.2.3
      main:      app.rb
      icon:      icon.png
      files:     ['*.rb', data]
      pods:
        reflex: {git: https://example.com/reflex, tag: v1}
      macos:
        deployment_target: '12.0'
        archs: [arm64, x86_64]
        codesign: {identity: Developer ID, team_id: ABCDE12345}
    YAML
      touch 'icon.png'
      touch '1.rb'
      touch 'data/2.json'
      c = load_config dir
      assert_equal 'My App',                                       c.name
      assert_equal 'com.example.myapp',                            c.bundle_id
      assert_equal '1.2.3',                                        c.version
      assert_equal 'app.rb',                                       c.main
      assert_equal 'icon.png',                                     c.icon
      assert_equal %w[*.rb data],                                  c.files
      assert_equal %w[1.rb app.rb data],                           c.app_files
      assert_equal({git: 'https://example.com/reflex', tag: 'v1'}, c.pods[:reflex])
      assert_equal '12.0',                                         c.macos.deployment_target
      assert_equal %w[arm64 x86_64],                               c.macos.archs
      assert_equal 'Developer ID',                                 c.macos.codesign_identity
      assert_equal 'ABCDE12345',                                   c.macos.codesign_team_id
    end
  end

  def test_name()
    assert_equal 'test', config()         .name
    assert_equal '1',    config(name: 1)  .name
    assert_equal 'test', config(name: nil).name
  end

  def test_bundle_id()
    assert_equal 'org.xord.reflex.test',   config()                  .bundle_id
    assert_equal 'a.b',                    config(bundle_id: 'a.b')  .bundle_id
    assert_equal 'org.xord.reflex.name-1', config( name:    'Name-1').bundle_id
    assert_equal 'org.xord.reflex.name-2', config('name' => 'Name-2').bundle_id
    assert_raise(RP::Error)               {config bundle_id: ''}
    assert_raise(RP::Error)               {config bundle_id: 'a'}
    assert_raise(RP::Error)               {config bundle_id: 'a.'}
    assert_raise(RP::Error)               {config name: 'アプリ'}
  end

  def test_version()
    assert_equal '0.1.0',    config()              .version
    assert_equal '1',        config(version: '1')  .version
    assert_equal '2.3',      config(version: '2.3').version
    assert_equal '0.1.0',    config(version: nil)  .version
    assert_raise(RP::Error) {config version: '4.'}
  end

  def test_main()
    assert_equal 'test_packager_config.rb', config()                 .main
    assert_equal 'helper.rb',               config(main: 'helper.rb').main
    assert_raise(RP::Error)                {config main: 'nofile.rb'}
  end

  def test_icon()
    assert_nil                config()                 .icon
    assert_equal 'helper.rb', config(icon: 'helper.rb').icon
    assert_raise(RP::Error)  {config icon: 'nofile.png'}
  end

  def test_files()
    assert_nil                  config()                  .files
    assert_equal %w[helper.rb], config(files: 'helper.rb').files
    assert_equal %w[a b],       config(files: %w[a b])    .files
  end

  def test_pods()
    assert_equal({cruby: {}, reflex: {}}, config()                            .pods)
    assert_equal({tag:    '6'},           config(pods: {cruby: {tag:    '6'}}).pods[:cruby])
    assert_equal({branch: '7'},           config(pods: {cruby: {branch: '7'}}).pods[:cruby])
    assert_equal({git:    '8'},           config(pods: {cruby: {git:    '8'}}).pods[:cruby])
    assert_equal({path:   '9'},           config(pods: {cruby: {path:   '9'}}).pods[:cruby])
  end

  def test_app_files()
    tmpdir                      do |dir|
      touch 'x.rb'
      assert_equal %w[main.rb],      load_config(dir).app_files
    end

    tmpdir yaml: "files: ['*']" do |dir|
      touch 'x.rb'
      assert_equal %w[main.rb x.rb], load_config(dir).app_files
    end

    tmpdir yaml: "files: ['*']" do |dir|
      %w[build dist].each {Dir.mkdir _1}
      touch 'build/1.rb'
      touch 'dist/2.rb'
      assert_equal %w[main.rb],      load_config(dir).app_files
    end

    tmpdir yaml_path: 'a.yaml', yaml: <<~YAML, main_path: 'b.rb' do |dir|
      main: b.rb
      files: '*'
    YAML
      %w[c.json d.png].each {touch _1}
      assert_equal(
        %w[a.yaml b.rb c.json d.png],
        load_config(dir, 'a.yaml').app_files.map {File.basename _1})
    end
  end

  def test_macos_deployment_target()
    assert_equal '11.0',     config()                               .macos.deployment_target
    assert_equal '11.0',     config(macos: {})                      .macos.deployment_target
    assert_equal '1',        config(macos: {deployment_target: 1})  .macos.deployment_target
    assert_equal '11.0',     config(macos: {deployment_target: nil}).macos.deployment_target
    assert_raise(RP::Error) {config(macos: {deployment_target: {}})}
  end

  def test_macos_archs()
    assert_equal ['arm64'],  config()                      .macos.archs
    assert_equal ['arm64'],  config(macos: {})             .macos.archs
    assert_equal ['1'],      config(macos: {archs: 1})     .macos.archs
    assert_equal ['2', '3'], config(macos: {archs: [2, 3]}).macos.archs
    assert_equal ['arm64'],  config(macos: {archs: nil})   .macos.archs
    assert_raise(RP::Error) {config(macos: {archs: []})}
    assert_raise(RP::Error) {config(macos: {archs: {}})}
  end

  def test_macos_codesign_identity()
    assert_equal '-',        config()                                  .macos.codesign_identity
    assert_equal '-',        config(macos: {})                         .macos.codesign_identity
    assert_equal '-',        config(macos: {codesign: {}})             .macos.codesign_identity
    assert_equal '-',        config(macos: {codesign: nil})            .macos.codesign_identity
    assert_equal '1',        config(macos: {codesign: {identity: 1}})  .macos.codesign_identity
    assert_equal '-',        config(macos: {codesign: {identity: nil}}).macos.codesign_identity
    assert_raise(RP::Error) {config(macos: {codesign: 2})}
    assert_raise(RP::Error) {config(macos: {codesign: {identity: {}}})}
  end

  def test_macos_codesign_team_id()
    assert_nil               config()                                 .macos.codesign_team_id
    assert_nil               config(macos: {})                        .macos.codesign_team_id
    assert_nil               config(macos: {codesign: {}})            .macos.codesign_team_id
    assert_nil               config(macos: {codesign: nil})           .macos.codesign_team_id
    assert_equal '1',        config(macos: {codesign: {team_id: 1}})  .macos.codesign_team_id
    assert_nil               config(macos: {codesign: {team_id: nil}}).macos.codesign_team_id
    assert_raise(RP::Error) {config(macos: {codesign: 2})}
    assert_raise(RP::Error) {config(macos: {codesign: {team_id: {}}})}
  end

  def test_warn_unknown_key()
    e = stderr

    config stderr: e,                                k1: 1
    assert_equal "unknown key '/k1'",                e.shift

    config stderr: e,                                macos: {k2: 2}
    assert_equal "unknown key '/macos/k2'",          e.shift

    config stderr: e,                                macos: {codesign: {k3: 3}}
    assert_equal "unknown key '/macos/codesign/k3'", e.shift
  end

  def test_invalid_value_type()
    assert_raise(RP::Error) {config macos: 'arm64'}
    assert_raise(RP::Error) {config pods:  ['cruby']}
  end

end# TestPackagerConfig
