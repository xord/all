# rays-video ChangeLog


## [v0.3.0] - 2026-11-04

- [BREAKING] Make the frames of a video read-only views sharing one decoded frame, and take a writable copy by Image#dup
- [BREAKING] Reject frames whose size or pixel density differs from the video's
- Decode video files sequentially with AVAssetReader, which is many times faster
- Add Video#get and #set, as #[] and #[]=
- Add Video#push and #<< as aliases of #append, which returns self now
- Show the last frame for an index past the estimated last one

- Fix Video#insert crashing on an index past the end, and raise IndexError
- Fix a crash on the error paths, as saving a GIF to a path that cannot be written
- Fix linking the extension statically on macOS
- Fix the build for iOS


## [v0.2.0] - 2026-08-04

- Update dependencies


## [v0.1.5] - 2026-06-23

- Update dependencies


## [v0.1.4] - 2026-06-12

- Update dependencies


## [v0.1.3] - 2026-05-20

- Update dependencies


## [v0.1.2] - 2026-05-17

- Rewrite README.md
- Add PR template
- CI: Migrate release-gem.yml from actions/create-release to gh release create


## [v0.1.1] - 2026-05-10

- Add VideoAudioIn to support audio playback in Video class
- Remove deprecated has_rdoc= from gemspecs


## [v0.1] - 2026-04-23

- Initial version
