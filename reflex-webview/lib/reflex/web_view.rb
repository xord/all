require 'json'
require 'reflex/view'
require 'reflex-webview/ext'


module Reflex


  class WebView

    # One entry in the back/forward history. Navigable via #go.
    class HistoryItem

      attr_reader :url, :title

      def initialize(web_view, offset, url, title)
        @web_view, @offset, @url, @title = web_view, offset, url, title
      end

      # Offset from the current entry (negative = back, positive
      # = forward, 0 = current).
      attr_reader :offset

      # Navigates the WebView to this history entry.
      def go()
        @web_view.go_to @offset
      end

    end# HistoryItem

    # The outcome of a #find / #find_next / #find_previous call.
    class FindResult

      # The total number of matches on the page.
      attr_reader :count

      # The 1-based position of the current match, or 0 if there are none.
      attr_reader :index

      def initialize(count, index)
        @count, @index = count, index
      end

      # Whether any match was found.
      def found?() = @count > 0

    end# FindResult

    # A file download in progress. In on_download, set #path to choose
    # where it is saved (defaults to the current directory); #cancel
    # aborts it. Progress and completion arrive via on_download_progress,
    # on_download_finish, and on_download_fail.
    class Download

      attr_reader :url, :suggested_filename, :state, :error
      attr_reader :total_bytes, :received_bytes
      attr_accessor :path

      def initialize(web_view, id, url, suggested_filename, total_bytes)
        @web_view           = web_view
        @id                 = id
        @url                = url
        @suggested_filename = suggested_filename
        @total_bytes        = total_bytes
        @received_bytes     = 0
        @state              = :downloading
        @path               = nil
      end

      # Fraction completed in 0.0..1.0 (0 if the total is unknown).
      def fraction()
        @total_bytes.to_i > 0 ? @received_bytes.to_f / @total_bytes : 0.0
      end

      # Cancels the download.
      def cancel()
        @web_view.__send__ :cancel_download!, @id
      end

      def update__(received, total, state, error)
        @received_bytes = received
        @total_bytes    = total if total.to_i > 0
        @state          = state
        @error          = error
      end

    end# Download

    # Wraps a Download for the on_download* handlers (e.download).
    class DownloadEvent

      attr_reader :download

      def initialize(download)
        @download = download
      end

    end# DownloadEvent

    # The server certificate of the current page (see WebView#certificate).
    class Certificate

      # The common names of the certificate's subject and issuer.
      attr_reader :subject, :issuer

      # The validity period as Time objects (or nil if unavailable).
      attr_reader :not_before, :not_after

      # The serial number and SHA-256 fingerprint, as hex strings.
      attr_reader :serial, :fingerprint

      def initialize(subject, issuer, not_before, not_after, serial, fingerprint)
        @subject     = subject
        @issuer      = issuer
        @not_before  = not_before.to_f > 0 ? Time.at(not_before) : nil
        @not_after   = not_after.to_f  > 0 ? Time.at(not_after)  : nil
        @serial      = serial
        @fingerprint = fingerprint
      end

    end# Certificate

    # An HTTP authentication challenge for on_authenticate. Call #use to
    # proceed with credentials, or #cancel to abort.
    class AuthEvent

      attr_reader :host, :port, :realm, :method

      def initialize(web_view, id, host, port, realm, method)
        @web_view, @id = web_view, id
        @host, @port, @realm, @method = host, port, realm, method.to_sym
      end

      # Proceeds with the given username and password.
      def use(user, password)
        @web_view.__send__ :respond_auth!, @id, true, user.to_s, password.to_s
      end

      # Cancels the challenge (the load fails).
      def cancel()
        @web_view.__send__ :respond_auth!, @id, false, nil, nil
      end

    end# AuthEvent

    # An invalid-certificate notice for on_certificate_error. Call
    # #proceed to continue anyway, or #cancel to block the load.
    class CertificateErrorEvent

      attr_reader :host, :error

      def initialize(web_view, id, host, error)
        @web_view, @id, @host, @error = web_view, id, host, error
      end

      # Continues the load despite the invalid certificate.
      def proceed()
        @web_view.__send__ :respond_certificate!, @id, true
      end

      # Blocks the load.
      def cancel()
        @web_view.__send__ :respond_certificate!, @id, false
      end

    end# CertificateErrorEvent

    # A permission request for on_permission. Call #grant or #deny.
    class PermissionEvent

      attr_reader :origin, :type

      def initialize(web_view, id, origin, type)
        @web_view, @id, @origin, @type = web_view, id, origin, type.to_sym
      end

      def grant()
        @web_view.__send__ :respond_permission!, @id, true
      end

      def deny()
        @web_view.__send__ :respond_permission!, @id, false
      end

    end# PermissionEvent

    class MessageEvent

      # The message posted from page JavaScript, parsed from JSON.
      # The page is free to send anything: treat as untrusted input.
      def data()
        @data ||= JSON.parse raw_data
      end

    end# MessageEvent

    class NavigateEvent

      # The kind of navigation as a Symbol: :link, :form, :back_forward,
      # :reload, :form_resubmit, or :other.
      def type()
        raw_type.to_sym
      end

    end# NavigateEvent

    # Creates a WebView. +data_store+ is the website data store (cookies,
    # local storage, caches) the view reads and writes; it defaults to the
    # shared DataStore.default. Pass DataStore.new for an ephemeral
    # (incognito) view, DataStore.load('name') for a named profile, or
    # another view's #data_store to share its data. The store is fixed for
    # the life of the view. Remaining options and the block configure the
    # view as for any Reflex::View (e.g. name:, frame:).
    def initialize(data_store = DataStore.default, **options, &block)
      @data_store = data_store
      create_web_view! data_store
      super(options.empty? ? nil : options, &block)
    end

    # The website data store backing this view (see #initialize). Pass it
    # to WebView.new(other.data_store) to share browsing data.
    def data_store()
      @data_store ||= DataStore.default
    end

    # Navigates to +url+. With +headers+ (a Hash), sends them as extra
    # HTTP request headers.
    def load(url, headers: nil)
      load! url.to_s, headers&.map {|k, v| [k.to_s, v.to_s]}
      self
    end

    # Navigates to +url+. Equivalent to #load.
    def url=(url)
      load url.to_s
      url
    end

    # Searches the page for +text+, highlighting every match (the current
    # one tinted differently) and scrolling to it. +forward+ picks which
    # match becomes current first, +case_sensitive+ the matching, +wrap+
    # whether #find_next / #find_previous wrap past the ends.
    #
    # The block (optional) is called with a FindResult positionally and
    # the keyword +found:+: {|result, found:| ...} (found: is also a
    # keyword for back-compatibility). result.count is the total number of
    # matches and result.index the current one (1-based, 0 if none).
    #
    # Matches are found in the page's plain text (cross-origin iframes and
    # shadow DOM are not searched). See #find_next / #find_previous /
    # #clear_find.
    def find(text, forward: true, case_sensitive: false, wrap: true, &block)
      @find_state = [case_sensitive, wrap]
      find__ "find(#{text.to_json}, #{!!case_sensitive}, #{!!forward}, #{!!wrap})", &block
      self
    end

    # Moves to the next match (highlighting it). No-op if #find was never
    # called. The block receives the FindResult as for #find.
    def find_next(&block)
      return self unless @find_state
      find__ "next(#{!!@find_state[1]})", &block
      self
    end

    # Moves to the previous match. No-op if #find was never called.
    def find_previous(&block)
      return self unless @find_state
      find__ "prev(#{!!@find_state[1]})", &block
      self
    end

    # Removes the find highlights.
    def clear_find()
      @find_state = nil
      eval_js! 'window.__REFLEX_FIND__ && window.__REFLEX_FIND__.clear()'
      self
    end

    # Runs a __REFLEX_FIND__ call and delivers its {count, index} to the
    # block as a FindResult.
    private def find__(call, &block)
      js = "window.__REFLEX_FIND__ ? window.__REFLEX_FIND__.#{call} : {count: 0, index: 0}"
      eval_js(js) do |r|
        r ||= {}
        result = FindResult.new r['count'].to_i, r['index'].to_i
        block.call result, found: result.found? if block
      end
    end

    # Mutes (or, with false, unmutes) the page's audio. See #muted?.
    def mute(state = true)
      mute! state
      self
    end

    # Reloads the current page. Pass true to bypass the cache and
    # revalidate every resource.
    def reload(ignore_cache = false)
      reload! ignore_cache
      self
    end

    # Sends a message to page JavaScript, delivered to the page's
    # __REFLEX__.onmessage handler. +data+ is serialized to JSON, so it
    # must be JSON-encodable.
    def post_message(data)
      post_message! JSON.generate(data)
      self
    end

    # The back history as HistoryItem objects, oldest first.
    def back_list()
      raw = back_list!
      n   = raw.size
      raw.each_with_index.map {|(url, title), i|
        HistoryItem.new self, i - n, url, title}
    end

    # The forward history as HistoryItem objects, nearest first.
    def forward_list()
      forward_list!.each_with_index.map {|(url, title), i|
        HistoryItem.new self, i + 1, url, title}
    end

    # The current history entry as a HistoryItem, or nil.
    def current_item()
      url, title = current_item!
      url && HistoryItem.new(self, 0, url, title)
    end

    alias eval_js! eval_js

    # Runs JavaScript in the page. With a block, the result is
    # delivered to it asynchronously (nil if the script failed or the
    # result is not expressible as JSON).
    def eval_js(script, &block)
      if block
        eval_js!(script) {|json| block.call(json && JSON.parse(json).first)}
      else
        eval_js! script
      end
      self
    end

    # Called when page JavaScript posts a message via
    # __REFLEX__.postMessage(data). Override in a subclass.
    def on_message(e)
    end

    # Called when the page's web content process crashes. The default
    # reloads the page; override (without calling super) to handle it
    # differently.
    def on_crash(e)
      reload
    end

    # Called for each page console.* call (e.level / e.message).
    # Override in a subclass.
    def on_console(e)
    end

    # The server certificate of the current page as a Certificate, or nil
    # for a non-HTTPS page. See also #secure?.
    def certificate()
      a = certificate!
      a && Certificate.new(*a)
    end

    # Called for an HTTP authentication challenge. The default cancels;
    # override (without super) and call e.use(user, password) or e.cancel.
    def on_authenticate(e)
      e.cancel
    end

    # Called when a page's certificate is invalid. The default blocks the
    # load; override (without super) and call e.proceed or e.cancel.
    def on_certificate_error(e)
      e.cancel
    end

    # Called when a page requests a permission (e.type is :camera,
    # :microphone, or :camera_and_microphone). The default denies;
    # override (without super) and call e.grant or e.deny.
    def on_permission(e)
      e.deny
    end

    # Internal: fans an auth challenge out to on_authenticate.
    def handle_auth_event(id, host, port, realm, method)
      on_authenticate AuthEvent.new(self, id, host, port, realm, method)
    end

    # Internal: fans a certificate error out to on_certificate_error.
    def handle_certificate_error_event(id, host, error)
      on_certificate_error CertificateErrorEvent.new(self, id, host, error)
    end

    # Internal: fans a permission request out to on_permission.
    def handle_permission_event(id, origin, type)
      on_permission PermissionEvent.new(self, id, origin, type)
    end

    # Called when a download starts. Set e.download.path to choose the
    # destination (defaults to the current directory); call
    # e.download.cancel to abort. Override in a subclass.
    def on_download(e)
    end

    # Called as a download progresses (e.download.fraction etc.).
    def on_download_progress(e)
    end

    # Called when a download completes (e.download.path is the file).
    def on_download_finish(e)
    end

    # Called when a download fails or is cancelled (e.download.error).
    def on_download_fail(e)
    end

    # Internal: receives raw download notifications from the backend and
    # fans them out to the on_download* handlers, keeping one Download
    # object per download.
    def handle_download_event(id, kind, url, filename, error, total, received)
      @downloads ||= {}
      case kind
      when 0   # start
        d = Download.new self, id, url, filename, total
        @downloads[id] = d
        on_download DownloadEvent.new(d)
        path = d.path || unique_download_path__(filename)
        commit_download! id, path.to_s
      when 1   # progress
        d = @downloads[id] or return
        d.update__ received, total, :downloading, nil
        on_download_progress DownloadEvent.new(d)
      when 2   # finish
        d = @downloads.delete(id) or return
        d.update__ received, total, :finished, nil
        on_download_finish DownloadEvent.new(d)
      when 3   # fail
        d = @downloads.delete(id) or return
        d.update__ received, total, :failed, error
        on_download_fail DownloadEvent.new(d)
      end
    end

    # Default destination: the current directory, with the suggested
    # name made unique against existing files.
    def unique_download_path__(filename)
      filename = 'download' if filename.nil? || filename.empty?
      base = File.join Dir.pwd, filename
      return base unless File.exist?(base)

      ext  = File.extname filename
      stem = File.basename filename, ext
      i    = 1
      i += 1 while File.exist?(File.join(Dir.pwd, "#{stem} (#{i})#{ext}"))
      File.join Dir.pwd, "#{stem} (#{i})#{ext}"
    end

    # Called when the page favicon URL changes (see #favicon).
    # Override in a subclass.
    def on_favicon_change(e)
    end

    # Called when the hovered link URL changes (see #hovered_url).
    # Override in a subclass.
    def on_hover(e)
    end

    # Called before each main-frame navigation. Call e.block to cancel
    # the navigation. Override in a subclass.
    def on_navigate(e)
    end

    # Called for window.open / target=_blank requests. The default
    # opens the URL in this view; a browser app overrides this to
    # create a new tab or window instead.
    def on_open(e)
      load e.url unless e.blocked?
    end

    # Called when a page starts loading. Override in a subclass.
    def on_load_start(e)
    end

    # Called when a page finishes loading. Override in a subclass.
    def on_load(e)
    end

    # Called when a page fails to load. Override in a subclass.
    def on_load_fail(e)
    end

    # Called when the page title changes. Override in a subclass.
    def on_title_change(e)
    end

    # Called when the page URL changes. Override in a subclass.
    def on_url_change(e)
    end

    # Called when the back/forward list changes, including via the
    # page's JS History API. Override in a subclass.
    def on_history_change(e)
    end

  end# WebView


end# Reflex
