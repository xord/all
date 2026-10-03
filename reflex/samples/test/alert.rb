# Manual check for Reflex.alert.
#
#   ruby alert.rb
#        -> a window counts its frames and shows the largest dt so far.
#           each key shows an alert, which returns only when closed
#      1   with a title
#            macos:   the title in bold, the message under it
#            windows: the title in the title bar
#      2   with no title
#            macos:   the message in bold
#            windows: an empty title bar, not 'Error'
#      3   a long message over many lines, as a backtrace
#      4   a message and a title in japanese
#      5   in 3 seconds: switch to another app meanwhile
#            -> the alert comes to the front and takes the keyboard
#      q   quit
#        while an alert is open, the frame count stops. once it is
#        closed, 'closed' is logged and the largest dt jumps by about the
#        time it was open, as requestAnimationFrame does after alert()
#   ruby alert.rb before
#        -> an alert shows before the app starts, in front of the
#           terminal, and closes with return. then the window opens and
#           'on_start' is logged: an alert does not keep the app from
#           finishing its launch

%w[xot rays reflex]
  .map  {|s| File.expand_path "../../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'


KEYS = [
  '1: with a title     2: with no title',
  '3: long message     4: japanese',
  '5: in 3 seconds     q: quit'
]

LOG = []

def log(text)
  LOG.unshift text
  puts text
end


Reflex.alert 'Shown before the app starts.', title: 'Before' if ARGV[0] == 'before'

Reflex.start do
  log 'on_start'

  frames, max_dt = 0, 0

  win = Reflex::Window.new title: 'Reflex.alert', frame: [100, 100, 560, 360]

  alert = -> (message, title = nil) {
    Reflex.alert message, title: title
    log "closed: #{title.inspect}"
  }

  win.on(:key_down) do |e|
    case e.chars
    when '1' then alert['The message.', 'The Title']
    when '2' then alert['The message with no title.']
    when '3'
      lines = 40.times.map {"  from /path/to/app/file_#{_1}.rb:#{_1 * 7}:in 'method_#{_1}'"}
      alert[["boom (RuntimeError)", *lines].join("\n"), 'Long']
    when '4' then alert['日本語のメッセージ', '日本語のタイトル']
    when '5'
      log 'an alert in 3 seconds'
      win.root.delay(3) {alert['Shown by a timer.', 'Timer']}
    when 'q' then Reflex.quit
    end
  end

  win.on(:update) do |e|
    frames += 1
    max_dt  = e.dt if e.dt > max_dt
    win.redraw
  end

  win.on(:draw) do |e|
    p = e.painter
    p.background 0.1, 0.1, 0.15
    p.fill 1
    KEYS.each_with_index {|text, i| p.text text, 10, 10 + i * 18}
    p.text "frames: #{frames}   max dt: #{'%.3f' % max_dt}", 10, 76
    p.fill 0.5, 1, 0.5
    LOG.first(12).each_with_index {|text, i| p.text text, 10, 110 + i * 18}
  end

  win.show
end
