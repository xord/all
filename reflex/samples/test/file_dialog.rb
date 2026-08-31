# Manual check for FileDialog.
#
# Each key opens a dialog. The window logs what came back, newest first.
# A dialog with an owner appears as a sheet on macos.
#
# Three things answer a selection: the block given to open_file and
# friends, the on_file hook of the dialog, and the on_file hook of the
# owner window, in that order. A hook does not cost the block its turn,
# even though it hides the method the block used to be called from.
#
#   1. press 1 and pick a file
#        -> 'block', 'dialog on_file' and 'window on_file_open' all log
#           the path, in that order, the hook here costing nothing
#   2. press 1 and cancel
#        -> 'dialog on_cancel' logs, and no path is logged
#   3. press 2 and pick more than one file
#        -> every path is logged
#   4. press 3
#        -> only directories can be chosen, and files are greyed out
#   5. press 4, type a name and save
#        -> the path is logged, and 'window on_file_save' follows it
#   6. press 5
#        -> the dialog opens in the home directory
#   7. press 6
#        -> the name field is already filled with untitled.png
#   8. press 7
#        -> the dialog is a window of its own, not a sheet, and the log
#           shows no 'window on_file_open': it has no owner
#   9. press 1 and look at the file list
#        -> only .png and .jpg files can be chosen, and folders stay open
#  10. press 1 where a file is named in capitals, IMAGE.PNG say
#        -> it can be chosen too, the extension is matched either case

%w[xot rays reflex]
  .map  {|s| File.expand_path "../../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'


KEYS = [
  '1: open_file            2: open_files',
  '3: open_directory       4: save_file',
  '5: open_files in ~      6: save_file named untitled.png',
  '7: open_files with no owner'
]

LOG = []

def log(text)
  LOG.unshift text
  puts text
end


Reflex.start do
  win = Reflex::Window.new title: 'FileDialog', frame: [100, 100, 560, 400]

  # the event reaches the owner window too, after the dialog itself
  win.on(:file_open) {|e| log "window on_file_open: #{e.paths}"}
  win.on(:file_save) {|e| log "window on_file_save: #{e.path}"}

  make = -> (title, owner: win) {
    dialog = Reflex::FileDialog.new owner: owner, title: title do
      extensions %w[png jpg]
    end
    # no super, and the block still runs: it is called from the wrapper,
    # before this hook, rather than from the method this hook hides
    dialog.on(:file)   {|e| log "dialog on_file: #{e.action} #{e.paths}"}
    dialog.on(:cancel) {|e| log 'dialog on_cancel'}
    dialog
  }

  win.on(:key_down) do |e|
    case e.chars
    when '1' then make['Open a file']     .open_file      {|path|  log "block: #{path}"}
    when '2' then make['Open files']      .open_files     {|paths| log "block: #{paths}"}
    when '3' then make['Open a directory'].open_directory {|path|  log "block: #{path}"}
    when '4' then make['Save a file']     .save_file      {|path|  log "block: #{path}"}
    when '5' then make['Open files in ~'] .open_files('~') {|paths| log "block: #{paths}"}
    when '6'
      make['Save as'].save_file(name: 'untitled.png') {|path| log "block: #{path}"}
    when '7'
      make['No owner', owner: nil].open_files {|paths| log "block: #{paths}"}
    else next
    end
    log "-- #{e.chars}"
  end

  win.on(:draw) do |e|
    p = e.painter
    p.background 0.1, 0.1, 0.15
    p.fill 1
    KEYS.each_with_index {|text, i| p.text text, 10, 10 + i * 18}
    p.fill 0.5, 1, 0.5
    LOG.first(14).each_with_index {|text, i| p.text text, 10, 100 + i * 18}
  end

  win.on(:update) {|e| win.redraw}

  win.show
end
