# Changelog

## Unreleased

## v0.12.1

Changes since `v0.12.0`.

This release adds a new 4.4BSD wordmark logo, refactors the main event loop
constants into the Robert module, adds module scaffolds for Tools and Widgets,
compiles with PIE for improved security, and updates build dependencies
including mruby-llm v0.1.0.beta.17, mruby-tui v0.7.0, mruby-tui-chat v0.4.0,
and mruby-termbox2 v0.6.0.

### Changed

* **Refactor main loop constants into Robert module** <br>
  Move `INPUT_POLL_MS` and `MAX_PEEK_EVENTS` into `Robert.poll_interval` and
  `Robert.max_events`, and extract the help text into a dedicated method.

* **Compile with PIE** <br>
  Add `-fPIC` and `-pie` flags so the binary is built as a Position Independent
  Executable.

* **Update build dependencies** <br>
  Bump mruby-llm to v0.1.0.beta.17, mruby-tui to v0.7.0, mruby-tui-chat to
  v0.4.0, mruby-termbox2 to v0.6.0, and upgrade mruby.

### Add

* **Add 4.4BSD wordmark logo** <br>
  Replace the old `robert.png` with an SVG `4.4bsd.svg` wordmark logo featuring
  a Puffy-inspired terminal mascot. Update the README and documentation site to
  use the new logo.

* **Add Tools and Widgets module scaffolds** <br>
  Add empty `Robert::Tools` and `Robert::Widgets` modules as namespace
  scaffolds for future organisation.

## v0.12.0

Changes since `v0.11.0`.

This release focuses on making Robert feel stable and responsive in slow
terminals, especially over high-latency SSH. Scrolling now uses cheaper
terminal-native updates where possible, streaming markdown renders at a bounded
rate, and Robert no longer pulls the viewport to the bottom while text is still
arriving. It also pulls in the matching mruby, mruby-tui, mruby-tui-chat, and
mruby-termbox2 updates needed for that work.

### Changed

* **Optimize scroll responsiveness** <br>
  Use terminal-native scroll rendering for small row movements (`scroll_fast`),
  rely on the chat cache and avoid full root redraws when scrolling, limit
  arrow-key scroll to 4 rows per tick for smoother movement over high-latency
  links, and add a dedicated `redraw_chat!` method that renders only the chat
  viewport.

* **Improve streaming render performance** <br>
  Cap markdown rendering at 10 FPS so streaming no longer saturates a CPU core.
  Accumulate stream content chunks and flush them at a bounded rate unless a
  state transition needs an immediate draw.

* **Improve high-latency SSH performance** <br>
  Increase the input poll timeout to 20ms and cap the maximum peek-ahead events
  to 64 so scroll/key-repeat input cannot monopolize the loop before stream
  output and redraw throttles get a turn. Replace `Task.pass` with `sleep_ms 1`
  and pass control to the next task in the busy loop.

* **Disable auto-follow during text streaming** <br>
  Auto-scroll to bottom only when the user submits a message and when tool calls
  are streaming. During text streaming, the user controls the viewport with
  up/down.

* **Remove stale mruby workaround** <br>
  Remove the workaround for mruby issue #6883 from `tool_running_label` now that
  the upstream fix has been pulled.

* **Update build dependencies** <br>
  Bump mruby-tui to v0.6.0, mruby-tui-chat to v0.3.1.beta.3, mruby-termbox2 to
  v0.5.0, and pull mruby fixes.

### Fix

* **Guard against scroll crash** <br>
  Add a guard to prevent scroll crashes.

* **Log crash details** <br>
  Write the full error class, message, and backtrace to `robert.log` when Robert crashes.

### Docs

* **Update site redirect and cleanup** <br>
  Redirect the project site to 4.4bsd.dev, drop the "Appearance" section, and remove unused files.

## v0.11.0

Changes since `v0.11.0.beta.4`.

This release marks the stable v0.11.0 release, adding paste support
by batching terminal events and deferring redraws, and updating
documentation across the README and man page.

### Add

* **Add paste support** <br>
  Batch terminal events and defer redraws so pasted input prints
  almost instantly instead of one character at a time.

### Docs

* **Update README and man page** <br>
  Refresh the README and man page to describe the individual handbook
  tools (`search-user-handbook`, `search-developer-handbook`,
  `search-porter-handbook`), document the `-x` flag in the man page,
  and update descriptive copy throughout.

## v0.11.0.beta.4

Changes since `v0.11.0.beta.3`.

This release adds handbook full-text search tools for the user,
developer, and porter handbooks through a metaprogramming module,
adds a binary file guard to `read-file`, restructures the system
prompt with capability descriptions and source reference
instructions, adds a project logo, and bumps mruby-llm to
v0.1.0.beta.16.

### Add

* **Add handbook full-text search tools** <br>
  Add `search-user-handbook`, `search-developer-handbook`, and
  `search-porter-handbook` tools that search the FreeBSD handbooks
  with full-text search via `4.4bsd.dev`. Introduce
  `Robert::Handbook`, a metaprogramming module that creates a
  `LLM::Tool` subclass for each handbook.

* **Add binary file guard to `read-file`** <br>
  Add `Robert.binary?` and raise an error when `read-file` is asked
  to read a binary file.

* **Add source reference instructions** <br>
  Instruct the model to list sources used to generate a response and
  reference the source when citing documentation.

### Changed

* **Restructure system prompt** <br>
  Reword the objective to emphasise teaching FreeBSD rather than
  troubleshooting, add explicit capability descriptions for each
  tool, and add a greeting instruction.

* **Update build dependencies** <br>
  Bump mruby-llm to v0.1.0.beta.16.

### Docs

* **Document handbook full-text search** <br>
  Update the README and docs site to describe Handbook search
  support, add `search-handbook` to the tool table, and update
  descriptive copy throughout.

* **Add project logo** <br>
  Add `robert.png` and use it in the README header in place of the
  previous image.

* **Fix link** <br>
  Replace the website link with a link to `4.4bsd.dev/robert`.

## v0.11.0.beta.3

Changes since `v0.11.0.beta.2`.

This release adds a `-x` flag to run tools without user confirmation,
reworks the project copy to describe Robert as a FreeBSD teacher
throughout the README, man page, and project site, bumps mruby-llm
to v0.1.0.beta.14, and updates mruby.

### Add

* **Add `-x` confirmation bypass flag** <br>
  Add a `-x` option that allows tools to run without requiring
  user confirmation.

### Changed

* **Update project copy** <br>
  Reword the README, project site, and man page to describe Robert
  as a FreeBSD teacher rather than an AI assistant, and use "He"
  consistently throughout.

* **Update build dependencies** <br>
  Bump mruby-llm to v0.1.0.beta.14 and update mruby.

### Docs

* **Fix README formatting** <br>
  Add missing blank lines between list items in the How it works
  section.

## v0.11.0.beta.2

Changes since `v0.11.0.beta.1`.

This release adds `find-package` and `read-package` tools for searching
the local `pkg(8)` database and reading package metadata, adds runtime
interrupt support so long-running commands can be cancelled with Ctrl+C,
fixes the confirmation widget done signal, and bumps mruby-llm to
v0.1.0.beta.11, mruby-process to v0.2.0, mruby-command to
v0.2.0.beta.2, and adds mruby-chan v0.3.0.

### Add

* **Add package database tools** <br>
  Add `find-package` and `read-package` tools so Robert can search the
  local `pkg(8)` database and read exact package metadata from it.

* **Add runtime interrupt support** <br>
  Interrupt long-running commands with Ctrl+C, introduce task and fork
  concurrency methods, and show full backtraces in error messages.

### Changed

* **Update package and ports documentation** <br>
  Refresh README, project site, and manual page copy to describe Robert
  as a FreeBSD assistant that uses man pages, documentation, the local
  ports tree, and package metadata.

* **Update build dependencies** <br>
  Bump mruby-tui to v0.4.1, mruby-llm to v0.1.0.beta.11,
  mruby-process to v0.2.0, mruby-command to v0.2.0.beta.2, and add
  mruby-chan v0.3.0.

### Fix

* **Improve port and package lookup** <br>
  Optimise `find-port`, avoid parent directory matches, and make
  `read-package` require an exact package origin match.

* **Fix confirmation widget done signal** <br>
  Ensure `confirmation_done` is always pushed to the task queue,
  whether the user allows or denies the tool.

* **Add sanitizer regression coverage** <br>
  Add tests for `Robert.sanitize` so unsafe control bytes stay out of
  JSON request content.

## v0.11.0.beta.1

Changes since `v0.10.0`.

This release adds `find-port` and `read-port` tools for searching a
local ports tree and reading port metadata, fixes scroll noise that
could leak `?` into the input area, improves man page cleaning to
remove underscore-wrapped paths, adds debug logging for input
handling, and updates tool parameter descriptions to advise the model
that `maxdepth` must be `<= 2`.

### Add

* **Add port search and read tools** <br>
  Add `find-port` and `read-port` tools so Robert can search a local
  copy of the ports tree and read port metadata from it. Both tools
  are registered in the dispatch and have their own status labels.

* **Add input debug logging** <br>
  Add debug log statements for printable character input to help
  diagnose missing character issues in the input area.

### Changed

* **Improve man page path cleaning** <br>
  Strip underscore wrappers from already-cleaned paths (e.g.
  `_/dev_` → `/dev`) so the model receives cleaner text.

* **Update find/grep parameter descriptions** <br>
  Advise the model that `maxdepth` must be `<= 2` in the `find` and
  `grep` tool parameter descriptions.

* **Update system prompt** <br>
  Reorganise the system prompt to describe each capability separately,
  including the new port tools.

### Fix

* **Fix `?` appearing in input area during scroll** <br>
  Add a `scroll_noise?` guard so printable fragments leaked by
  repeated scroll keys are not written to the input area. Track the
  last scroll event time and filter characters that arrive within the
  noise window.

## v0.10.0

Changes since `v0.9.0`.

This release adds new `find` and `grep` tools for searching files and
text on the filesystem, validates filesystem tool requests, improves
tool status labels, routes command-backed tools through sanitized result
payloads, and strips unsafe control bytes from tool output.

### Add

* **Add file and directory search tool** <br>
  Add a `find` tool so Robert can search for files and directories below
  a requested root path. The tool requires confirmation, uses bounded
  traversal, shows a tool-specific status label, and is documented in the
  README and project site.

* **Add text search tool** <br>
  Add a `grep` tool so Robert can search for text across files below a
  requested root path. The tool requires confirmation, uses bounded
  traversal and output, shows a tool-specific status label, and is
  documented in the README and project site.

### Changed

* **Validate filesystem tool requests** <br>
  Reject empty `find` and `grep` queries, and cap their `maxdepth` at 2 so
  filesystem searches stay bounded.

* **Update tool status labels** <br>
  Shorten file and man-page labels, include `find` depth in the running
  label, add a `version` label, and remove noisy finished labels.

* **Use sanitized command results** <br>
  Route command-backed tools through `Robert.spawn`, returning sanitized
  `{stdout:, stderr:}` payloads instead of raw strings.

### Fix

* **Strip unsafe control bytes from tool output** <br>
  Add `Robert.sanitize` so file and command output cannot put raw C0
  control bytes into the next JSON request body.

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
