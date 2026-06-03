# Changelog

## Unreleased

## v0.9.0

Changes since `v0.8.1`.

This release adds periodic idle refresh so terminals that lose their
alternate-screen contents can recover without waiting for a key press,
fixes screen flicker by not invalidating the front buffer, and tidies
tool status labels and confirmation handling. It also bumps mruby-llm
to v0.1.0.beta.10, mruby-command to v0.1.0, and mruby-tui-chat to
v0.3.1.beta.1.

### Add

* **Periodically refresh idle UI** <br>
  Redraw while Robert is idle so terminals that lose their alternate-screen
  contents can repaint without waiting for the next key press.

### Changed

* **Update build dependencies** <br>
  Bump mruby-llm to v0.1.0.beta.10, mruby-command to v0.1.0, and
  mruby-tui-chat to v0.3.1.beta.1.

### Fix

* **Stop invalidating the front buffer during idle refresh** <br>
  Use a lightweight redraw instead of `Termbox2.invalidate` to avoid
  screen flicker while idle.

* **Fix tool status update labels** <br>
  Use present continuous tense for running labels and fix the keyword
  argument reference in finished labels.

* **Remove duplicate confirmation callback** <br>
  Remove the extra `on_tool_return` call from the confirmation widget
  so tool results are not processed twice.

## v0.8.1

Changes since `v0.8.0`.

This release preserves crash output during terminal cleanup by running
theme cleanup while the TUI is still initialized and ignoring cleanup
errors after termbox has already been torn down.

### Fix

* **Preserve crash output during terminal cleanup** <br>
  Run terminal theme cleanup while the TUI is still initialized, and
  ignore cleanup errors after termbox has already been torn down so the
  original crash can still be reported.

* **Repaint idle terminals after screen loss** <br>
  Periodically redraw while Robert is idle, so terminals that lose their
  alternate-screen contents can repaint without waiting for the next key
  press.

## v0.8.0

Changes since `v0.7.0`.

This release adds terminal theme hooks so Robert's UI uses consistent
colours and resets them on exit. It also documents the debug and help
flags in the manual page, uses a stronger theme with bright white text,
and fixes streamed output so it stays on the theme background.

### Add

* **Add terminal theme hooks** <br>
  Add `Robert.set_theme` and `Robert.unset_theme` so Robert applies its
  terminal clear attributes when the TUI starts, and resets them back to
  the terminal defaults when the UI exits or crashes.

* **Document debug and help flags** <br>
  Update the manual page to document `-d` for debug logging and `-h`
  for usage output, and use the `.Fx` macro for FreeBSD references.

### Changed

* **Use a stronger terminal theme** <br>
  Change Robert's secondary foreground color to bright white for higher
  contrast against the black terminal background.

### Fix

* **Keep streamed chat output on the theme background** <br>
  Pass Robert's background color into the chat widget so streamed
  assistant rows do not repaint the chat area using the terminal default
  background.

## v0.7.0

Changes since `v0.6.0`.

This release adds the `-h` command line flag so users can print usage
information directly from the standalone binary.

### Add

* **Add `-h` usage output** <br>
  Add a help flag that prints supported options and exits.

## v0.6.0

Changes since `v0.5.3`.

This release improves Robert's event loop, streaming responsiveness, scroll
behaviour, and idle CPU usage. It also adds debug logging for diagnosing
terminal input and streaming issues.

### Add

* **Add debug logging** <br>
  Add `Robert.debug` support for writing compact runtime diagnostics to
  `robert.log`.

* **Add deferred page scrolling** <br>
  Add page-sized deferred scrolling so PgUp/PgDn can share the normal
  redraw path without being reduced to one-line arrow-key movement.

### Fix

* **Reduce idle CPU usage** <br>
  Rework event polling so Robert stays responsive without spinning as
  aggressively while idle.

* **Improve streaming and scroll follow behaviour** <br>
  Return the chat viewport to follow mode when a new message is
  submitted and while assistant output is streaming.

* **Improve terminal key handling** <br>
  Switch terminal input handling and scroll throttling to reduce stale
  key-repeat effects while scrolling.

## v0.5.3

Changes since `v0.5.2`.

This release improves the README and makes the test build path install the
mbedTLS dependency needed by the static build.

### Fix

* **Install mbedTLS for test builds** <br>
  Update build setup so `make test` has the required mbedTLS package
  available.

### Docs

* **Improve README download instructions** <br>
  Refresh the README download section and version references.

## v0.5.2

Changes since `v0.5.1`.

This release adds CI test coverage and cleans man page output before it is
sent to the model.

### Add

* **Run tests on CI** <br>
  Add the test target to GitHub Actions.

### Fix

* **Strip man page syntax from tool output** <br>
  Remove roff overstrike formatting from manual page output so the model
  receives clean text.

## v0.5.1

Changes since `v0.5.0`.

This release fixes mrbgem load ordering and corrects documentation version
references.

### Fix

* **Fix mrbgem load order** <br>
  Adjust load ordering so Robert's mruby dependencies are available when
  the app starts.

### Docs

* **Correct documented version** <br>
  Update documentation to point at the current release.

## v0.5.0

Changes since `v0.4.0`.

This release adds Robert's dispatch scroll module and updates Robert to a
newer mruby-llm prerelease.

### Add

* **Add `Robert::Dispatch::Scroll`** <br>
  Move scroll behaviour into a dedicated dispatch module.

### Changed

* **Update mruby-llm** <br>
  Bump Robert's mruby-llm dependency to `v0.1.0.beta.5`.

## v0.4.0

Changes since `v0.3.0`.

This release updates the static binary messaging and build lockfile.

### Changed

* **Document the 3MB standalone binary size** <br>
  Update documentation to describe Robert as a 3MB standalone binary.

* **Update build lockfile** <br>
  Refresh the build lockfile for the release.

## v0.3.0

Changes since `v0.2.1`.

This release focuses on runtime performance, including curl performance,
redraw reduction, and a small sleep in the main loop.

### Fix

* **Reduce unnecessary redraws** <br>
  Redraw only when needed instead of repainting on every loop iteration.

* **Improve curl and build performance** <br>
  Tune the static build and curl configuration for better runtime
  performance.

* **Avoid a hot busy loop** <br>
  Sleep briefly in the main loop to reduce CPU usage.

## v0.2.1

Changes since `v0.2.0`.

This release fixes the certificate path used by the static binary and
refreshes documentation assets.

### Fix

* **Use the system certificate bundle** <br>
  Configure the static build to use `/etc/ssl/cert.pem`.

### Docs

* **Refresh docs assets and version references** <br>
  Update the site images and documented release version.

## v0.2.0

Changes since `v0.1.1`.

This release adds static binary distribution support and refreshes the
project site screencast.

### Add

* **Distribute static binaries** <br>
  Add build support for publishing Robert as a standalone binary.

### Docs

* **Refresh the docs screencast** <br>
  Update the product site demo assets.

## v0.1.1

Changes since `v0.1.0`.

This release adds installation support and cleans up the manual page
metadata.

### Add

* **Add `make install`** <br>
  Add an install target for installing Robert locally.

### Docs

* **Update manual page metadata** <br>
  Update the manual page author information.

## v0.1.0

Initial release.

This release introduces Robert as a standalone mruby FreeBSD assistant with
manual page tools, file-reading confirmation, concurrent streaming, a
terminal UI, a man page, and a GitHub Pages product site.

### Add

* **Add the Robert TUI assistant** <br>
  Add the initial terminal UI, prompt, FreeBSD tip splash, and assistant
  tool integration.

* **Add FreeBSD documentation tools** <br>
  Add tools for reading manual pages, searching the manual page database,
  reading files with confirmation, and reporting Robert's version.

* **Add concurrent streaming with mruby-task** <br>
  Add task-based streaming so the UI can remain responsive while the
  assistant is producing output.

* **Add documentation and release automation** <br>
  Add the README, manual page, product site, screenshots, screencast, and
  GitHub Actions binary build.
