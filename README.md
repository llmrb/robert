## About

Robert is designed to help you learn about FreeBSD through its official
documentation and man pages. It is distributed as a standalone, 2MB
binary. The [website](https://llmrb.github.io/robert) provides a
rich introduction with screenshots and a screencast.

Robert requires DeepSeek, and it is almost free to use but
robert _could_ also work with other providers.

## Appearance

**Boot**

The boot screen runs `fortune freebsd-tips` <br>
Similar to the default FreeBSD default `${HOME}/.profile`.

![robert1.png](robert1.png)

**First turn**

Simple greeting.

![robert2.png](robert2.png)

**Second turn**

Question answered from the FreeBSD man pages.

![robert3.png](robert3.png)

**Tool confirmation**

No confirmation required to read, or search man pages. <br>
Confirmation required to read files.

![robert4.png](robert4.png)

## Install

[GitHub builds a binary](.github/workflows/freebsd-build.yml) from
the repository's source code and it is run every time a commit is
pushed to the repository. The binary is roughly 1.78MB in size,
and it can be downloaded
[here](https://github.com/llmrb/robert/releases/tag/latest).

## Association

This project belongs to the [llm.rb](https://github.com/llmrb/llm.rb#readme) family of
projects. The [mruby-llm](https://github.com/llmrb/mruby-llm#readme) runtime is a
port of [llm.rb](https://github.com/llmrb/llm.rb) to mruby, and it was used
to build this project.

## License

0BSD. See [LICENSE](LICENSE).
