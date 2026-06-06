<p align="center">
  <a href="http://llmrb.github.io/robert">
    <img src="https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEi39c9ab6rTHulzqrvy45M_omMN8cUyRxfaAph0UhlpubhMxgnJVyOEarYGmHNZgt1uUZmO8cobmrloSiAfxUjgjNOVvRZrF9n9b5tO0S-sG7e9DHfalqyYQZm6aY1jV55IzPbGPA/s1600/freebsd_jail.png" width="200" height="200" border="0" alt="mruby-jail">
  </a>
  <br>
  <strong>Robert</strong>
</p>

## About

Robert is designed to teach you about FreeBSD by answering questions
from official manual pages and documentation. He runs entirely in your
terminal and ships as a **statically linked, ~3MB binary** - no
dependencies, no Node.js, no Electron, no browser needed.

Ask questions about FreeBSD in plain English. Robert searches man
pages, documentation, the filesystem, ports, and packages, then answers
with **cited excerpts** from official docs. He runs on DeepSeek and
costs pennies to use.

[The website](https://llmrb.github.io/robert) has a full
screencast and more screenshots.

## Quick start

**1. Download the latest release**

```sh
fetch https://github.com/llmrb/robert/releases/download/v0.11.0.beta.2/robert
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

## Appearance

**FreeBSD art** - lightweight but rich console

![robert4.png](robert4.png)

**Boot** - shows a random FreeBSD tip, like `${HOME}/.profile` does.

![robert1.png](robert1.png)

**First turn** - simple greeting.

![robert2.png](robert2.png)

**Second turn** - question answered from the FreeBSD man pages.

![robert3.png](robert3.png)

**Tool confirmation** - reading and searching man pages and ports is
automatic. Reading files and filesystem searches require confirmation.

![robert4.png](robert5.png)

## Tools

Robert chains these tools autonomously: it searches man pages, the
filesystem, the local ports tree, and the package database; reads files,
port metadata, and package metadata; and synthesises answers without
hand-holding. It only pauses for confirmation when reading files or
searching the filesystem.

| Tool | Description | Confirmation |
|------|-------------|--------------|
| `man-page` | Returns the contents of a man page (optionally by section) | No |
| `man-search` | Searches manual pages for keywords via `apropos` | No |
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

- **Ports tree lookup**

  Robert can search and read a local FreeBSD ports tree. It uses
  `${PORTSDIR}` when set, otherwise `/usr/ports`.

- **Package database lookup**

  Robert can search and read package metadata from the local `pkg(8)`
  database.

- **Grounded answers**

  The system prompt explicitly forbids using training data. Every
  claim must cite a man page via blockquote. Off-topic questions
  are gently redirected.

The binary is a single C file (`main.c`) that bootstraps an mruby
VM and loads the compiled irep. The Ruby application code, TUI
framework, HTTP client, TLS, and LLM bindings are all linked
statically. The result is a self-contained 3MB binary.

## Download

Pre-built static binaries for FreeBSD 15-STABLE and 16-CURRENT can
be [downloaded from GitHub Releases](https://github.com/llmrb/robert/releases).
Each tagged release publishes a `robert` binary; the latest pre-release
is [v0.11.0.beta.2](https://github.com/llmrb/robert/releases/tag/v0.11.0.beta.2).

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

0BSD. See [LICENSE](LICENSE).
