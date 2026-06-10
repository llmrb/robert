<p align="center">
  <a href="http://llmrb.github.io/robert">
    <img src="./robert.png" width="150" height="150" border="0" alt="mruby-jail">
  </a>
  <br>
</p>

Robert is designed to teach you about FreeBSD by answering questions
from official manual pages and the FreeBSD Handbook. He runs entirely
in your terminal and ships as a **statically linked, ~3MB binary** -
no dependencies, no Node.js, no Electron, no browser needed.

Ask questions about FreeBSD in plain English. Robert searches man
pages, the Handbook with full-text search, the filesystem, ports, and
packages, then answers with **cited excerpts** from official docs. He
runs on DeepSeek and costs pennies to use.

**See also:**

* [4.4bsd.dev/robert](https://4.4bsd.dev/robert)

## Quick start

**1. Download the latest release**

```sh
fetch https://github.com/llmrb/robert/releases/download/v0.11.0/robert
chmod +x robert
```

**2. Set your DeepSeek API key**

```sh
export DEEPSEEK_SECRET="sk-..."
```

**3. Run it**

```sh
./robert
```

## Tools

Robert chains these tools autonomously: it searches man pages, the
FreeBSD user, developer, and porter handbooks, the filesystem, the
local ports tree, and the package database; reads files, port metadata,
and package metadata; and synthesises answers without hand-holding. It
only pauses for confirmation when reading files or searching the
filesystem.

| Tool | Description | Confirmation |
|------|-------------|--------------|
| `man-page` | Returns the contents of a man page (optionally by section) | No |
| `man-search` | Searches manual pages for keywords via `apropos` | No |
| `search-user-handbook` | Searches the FreeBSD user's handbook with full-text search | No |
| `search-developer-handbook` | Searches the FreeBSD developer's handbook with full-text search | No |
| `search-porter-handbook` | Searches the FreeBSD porter's handbook with full-text search | No |
| `read-file` | Reads a file from the filesystem | Yes |
| `find` | Searches for files and directories from a root path | Yes |
| `grep` | Searches for text across files below a root path | Yes |
| `find-port` | Searches a local ports tree for a port name | No |
| `read-port` | Reads a port's `Makefile`, `pkg-descr`, and `distinfo` | No |
| `find-package` | Searches the `pkg(8)` database for package origins | No |
| `read-package` | Reads exact package metadata from the `pkg(8)` database | No |
| `version` | Reports Robert's version number | No |

## How it works

Robert is built on [mruby-llm](https://github.com/llmrb/mruby-llm),
the mruby port of [llm.rb](https://github.com/llmrb/llm.rb). The
architecture is designed for a single-purpose terminal app:

- **Cooperative task scheduler**

  The LLM call runs in a worker task while the event loop keeps the
  UI responsive.

- **Streaming TUI**

  Tokens arrive from the API and render incrementally in the chat
  widget, with live tool-call status.

- **Roff sanitisation**

  Raw man output often includes overstrike sequences (`_\b/` for
  underlined `/`) or underscore-wrapped paths like `_/dev_`. Those are
  stripped before they reach the model, preventing garbled paths.

- **Handbook search**

  Robert can search the FreeBSD user, developer, and porter handbooks
  with full-text search, then use matching Handbook results alongside
  manual pages.

- **Ports tree lookup**

  Robert can search and read a local FreeBSD ports tree. It uses
  `${PORTSDIR}` when set, otherwise `/usr/ports`.

- **Package database lookup**

  Robert can search and read package metadata from the local `pkg(8)`
  database.

- **Grounded answers**

  The system prompt explicitly forbids using training data. Every
  claim must cite official FreeBSD documentation via blockquote.
  Off-topic questions are gently redirected.

The binary is a single C file (`main.c`) that bootstraps an mruby
VM and loads the compiled irep. The Ruby application code, TUI
framework, HTTP client, TLS, and LLM bindings are all linked
statically. The result is a self-contained 3MB binary.

## Download

Pre-built static binaries for FreeBSD 15-STABLE and 16-CURRENT can
be [downloaded from GitHub Releases](https://github.com/llmrb/robert/releases).
Each tagged release publishes a `robert` binary; the latest release
is [v0.11.0](https://github.com/llmrb/robert/releases/tag/v0.11.0).

## Build from source

Robert is an mruby gem built with the mruby-llm runtime.

```sh
git clone https://github.com/llmrb/robert.git
cd robert
make
```

The Makefile expects an mruby checkout at `../mruby`. Override with
`MRUBY_DIR=/path/to/mruby` if needed. Run `make static` for a
statically linked binary (~3MB) or `make` for a dynamically linked
one (~2MB).

## Association

This project belongs to the [llm.rb](https://github.com/llmrb/llm.rb#readme)
family of projects. [mruby-llm](https://github.com/llmrb/mruby-llm)
is a port of [llm.rb](https://github.com/llmrb/llm.rb) to mruby.

## License

0BSD. <br>
See [LICENSE](LICENSE).
