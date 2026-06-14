// -*- c++ -*-
#pragma once
#ifndef __REFLEX_WEB_VIEW_H__
#define __REFLEX_WEB_VIEW_H__


#include <functional>
#include <utility>
#include <vector>
#include <xot/pimpl.h>
#include <xot/string.h>
#include <rays/image.h>
#include <reflex/view.h>


namespace Reflex
{


	/*
		An off-screen web browser view.

		The page is rendered by a platform backend into a pixel buffer and
		drawn into the view every frame. See src/<platform>/web_view.* for
		the backend implementations.
	*/
	class WebView : public View
	{

		typedef View Super;

		public:

			// Page-load lifecycle details for on_load_start/on_load/
			// on_load_fail. code/description are zero/empty except on
			// failure.
			class LoadEvent : public Event
			{

				public:

					LoadEvent ();

					LoadEvent (
						const char* url, int code = 0,
						const char* description = NULL);

					LoadEvent (const LoadEvent* src);

					LoadEvent dup () const;

					const char* url () const;

					int code () const;

					const char* description () const;

					struct Data;

					Xot::PSharedImpl<Data> self;

			};// LoadEvent

			// A pending navigation for on_navigate (call block() to
			// cancel it) or a new-window request for on_open.
			class NavigateEvent : public Event
			{

				public:

					NavigateEvent ();

					NavigateEvent (const char* url);

					NavigateEvent (const NavigateEvent* src);

					NavigateEvent dup () const;

					const char* url () const;

					struct Data;

					Xot::PSharedImpl<Data> self;

			};// NavigateEvent

			// A message posted from page JavaScript via
			// __REFLEX__.postMessage(). data() is its JSON
			// serialization; treat the content as untrusted input.
			class MessageEvent : public Event
			{

				public:

					MessageEvent ();

					MessageEvent (const char* data);

					MessageEvent (const MessageEvent* src);

					MessageEvent dup () const;

					const char* data () const;

					struct Data;

					Xot::PSharedImpl<Data> self;

			};// MessageEvent

			// A console.log/info/warn/error/debug call forwarded from the
			// page. level() is the method name; message() is the joined
			// stringified arguments.
			class ConsoleEvent : public Event
			{

				public:

					ConsoleEvent ();

					ConsoleEvent (const char* level, const char* message);

					ConsoleEvent (const ConsoleEvent* src);

					ConsoleEvent dup () const;

					const char* level () const;

					const char* message () const;

					struct Data;

					Xot::PSharedImpl<Data> self;

			};// ConsoleEvent

			// Receives the result of eval() as a JSON array holding the
			// single result value, or NULL if the result could not be
			// serialized (or the script failed).
			typedef std::function<void (const char* result_json)>
				EvalCallback;

			// Receives whether find() located a match.
			typedef std::function<void (bool found)> FindCallback;

			// A download progress notification carried from the backend to
			// the Ruby orchestration layer. kind: 0=start 1=progress
			// 2=finish 3=fail.
			struct DownloadInfo
			{
				long id;
				int  kind;
				Xot::String url, suggested_filename, error;
				long total_bytes, received_bytes;
			};

			// A website data store -- the cookies, local storage, and
			// caches a WebView reads and writes. Pass one to WebView.new
			// to isolate browsing data (e.g. an incognito tab or a named
			// profile) or to share it between views. The store a view
			// uses is fixed when the view is created.
			class DataStore
			{

				public:

					// An ephemeral (incognito) store: nothing is written to
					// disk and the data is discarded when the store goes
					// away. A fresh, independent store on each call.
					static DataStore create_ephemeral ();

					// The shared default persistent store -- the same one
					// used when no data store is specified.
					static DataStore create_default ();

					// A named persistent profile, kept separate from the
					// default and from other names and persisted across
					// runs under name. The same name yields the same store.
					// Requires macOS 14+.
					static DataStore create_named (const char* name);

					DataStore ();

					~DataStore ();

					// True for the default and named stores, false for an
					// ephemeral one.
					bool persistent () const;

					// The profile name of a named store, or empty otherwise.
					Xot::String name () const;

					// Removes everything in the store (cookies, storage,
					// caches), asynchronously.
					void clear ();

					// All cookies in the store as an opaque, base64-encoded
					// string, or empty if there are none. Persist it and pass
					// it to set_cookies to restore them (e.g. alongside a
					// WebView's session_state when hibernating a tab).
					Xot::String cookies () const;

					// Restores cookies previously returned by cookies(),
					// merging them into the store. A NULL or empty string
					// instead clears all cookies (leaving local storage and
					// caches intact; use clear() to wipe everything).
					void set_cookies (const char* cookies);

					// Backend-internal: the native data store handle, or NULL.
					const void* native () const;

					struct Data;

					Xot::PSharedImpl<Data> self;

			};// DataStore

			WebView (const char* name = NULL);

			virtual ~WebView ();

			// Internal: creates the backing native web view bound to the
			// given data store. Called once by WebView#initialize, before
			// the view is navigated or shown.
			virtual void create_web_view (const DataStore& data_store);

			virtual void load (const char* url);

			virtual void load_html (const char* html);

			virtual void eval (const char* script);

			virtual void eval (const char* script, EvalCallback callback);

			// Delivers a message to page JavaScript by invoking
			// __REFLEX__.onmessage(data); data_json is the JSON-encoded
			// payload. No-op if the page set no onmessage handler.
			virtual void post_message (const char* data_json);

			// Searches the page for text, highlighting and scrolling to
			// the next match. callback (if any) receives whether a match
			// was found.
			virtual void find (const char* text, FindCallback callback);

			// Starts downloading url (e.g. for a 'save link as' action).
			virtual void download (const char* url);

			// Backend hooks used by the Ruby download orchestration:
			// commit_download supplies the chosen destination once
			// on_download has run; cancel_download aborts it.
			virtual void commit_download (long id, const char* path);

			virtual void cancel_download (long id);

			virtual void reload ();

			// When ignore_cache is true, bypasses the cache and revalidates
			// every resource (reloadFromOrigin).
			virtual void reload (bool ignore_cache);

			virtual void go_back ();

			virtual void go_forward ();

			// A back/forward history entry: its url and title.
			typedef std::pair<Xot::String, Xot::String> HistoryEntry;

			// The back/forward list (oldest first for back, nearest first
			// for forward), reflecting JS History API changes live.
			virtual std::vector<HistoryEntry> back_list () const;

			virtual std::vector<HistoryEntry> forward_list () const;

			// Fills url/title with the current history entry; returns
			// false if there is none.
			virtual bool current_item (
				Xot::String* url, Xot::String* title) const;

			// Navigates to the history entry at offset from the current
			// one (negative = back, positive = forward). No-op if out of
			// range.
			virtual void go_to (int offset);

			virtual void stop ();

			virtual bool can_go_back () const;

			virtual bool can_go_forward () const;

			virtual bool loading () const;

			// Estimated load progress in [0, 1].
			virtual float progress () const;

			virtual Xot::String url () const;

			virtual Xot::String title () const;

			// The page's favicon URL, or empty if none.
			virtual Xot::String favicon () const;

			// The link URL currently under the pointer, or empty if none.
			virtual Xot::String hovered_url () const;

			virtual void set_user_agent (const char* user_agent);

			virtual Xot::String user_agent () const;

			// Page zoom factor (1.0 = 100%).
			virtual void set_zoom (float zoom);

			virtual float zoom () const;

			// Allows attaching Safari's Web Inspector (macOS 13.3+).
			virtual void set_inspectable (bool inspectable);

			virtual bool inspectable () const;

			// Keeps the page's hardware video layers (MSE/EME, e.g. YouTube)
			// compositing into the capture. The macOS backend does this by
			// holding a hidden 1px corner of the off-screen host window on
			// the display; without it such video shows up blank. Off by
			// default. No effect on backends that capture video anyway.
			virtual void set_video_capture (bool enabled);

			virtual bool video_capture () const;

			// The page session (back/forward history, scroll position, and
			// form field values) as an opaque, base64-encoded string, or an
			// empty string if there is nothing to save yet. Persist it and
			// pass it back to set_session_state to restore a tab (the page
			// reloads, then its form values and scroll are reapplied).
			virtual Xot::String session_state () const;

			// Restores a value previously returned by session_state(). There
			// is no "clear" semantics: a NULL/empty or otherwise invalid
			// value raises rather than silently doing nothing.
			virtual void set_session_state (const char* state);

			// A copy of the latest rendered page image, or an empty image
			// if no frame has been captured yet.
			virtual Rays::Image to_image () const;

			// Called when the page's web content process crashes. The
			// default reloads the page; override to handle it differently.
			virtual void on_crash (Event* e);

			// Called for each page console.* call.
			virtual void on_console (ConsoleEvent* e);

			// Internal: delivers a download notification to the Ruby
			// orchestration layer (which fans it out to on_download etc.).
			virtual void on_download_event (const DownloadInfo& info);

			virtual void on_message (MessageEvent* e);

			virtual void on_navigate (NavigateEvent* e);

			virtual void on_open (NavigateEvent* e);

			virtual void on_load_start (LoadEvent* e);

			virtual void on_load (LoadEvent* e);

			virtual void on_load_fail (LoadEvent* e);

			virtual void on_title_change (Event* e);

			virtual void on_url_change (Event* e);

			// Called when the back/forward list changes, including via
			// the page's JS History API (pushState/replaceState/go).
			virtual void on_history_change (Event* e);

			virtual void on_favicon_change (Event* e);

			// Called when the hovered link URL changes (see hovered_url()).
			virtual void on_hover (Event* e);

			virtual void on_update (UpdateEvent* e);

			virtual void on_draw (DrawEvent* e);

			virtual void on_resize (FrameEvent* e);

			virtual void on_pointer (PointerEvent* e);

			virtual void on_wheel (WheelEvent* e);

			virtual void on_key (KeyEvent* e);

			virtual void on_focus (FocusEvent* e);

			struct Data;

			Xot::PImpl<Data> self;

	};// WebView


}// Reflex


#endif//EOH
