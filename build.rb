MRuby::Build.new("robert") do |conf|
  profile = ENV["BUILD"] || "test"
  static  = ENV["STATIC"] == "1"
  curldir = File.expand_path(ENV["CURLDIR"] || "/usr/local")

  conf.toolchain
  conf.cc.include_paths << File.join(curldir, "include")
  conf.linker.library_paths << File.join(curldir, "lib")

  if static
    conf.linker.flags << [
      File.join(curldir, "lib", "libcurl.a"),
      File.join(curldir, "lib", "libnghttp2.a"),
      File.join(curldir, "lib", "libmbedtls.a"),
      File.join(curldir, "lib", "libmbedx509.a"),
      File.join(curldir, "lib", "libmbedcrypto.a"),
      "-pthread"
    ].join(" ")
  else
    conf.linker.flags << "-lcurl -lmbedtls"
  end

  conf.gembox "default"
  conf.gem core: "mruby-task"

  #conf.gem File.realpath File.join(__dir__, "..", "mruby-termbox2")
  #conf.gem File.realpath File.join(__dir__, "..", "mruby-tui")
  conf.gem git: "https://github.com/mrbgemz/mruby-tui"      , branch: "v0.6.0"

  #conf.gem File.realpath File.join(__dir__, "..", "mruby-tui-chat")
  conf.gem git: "https://github.com/mrbgemz/mruby-tui-chat" , branch: "v0.3.1.beta.3"

  #conf.gem File.realpath File.join(__dir__, "..", "..", "mrbgemz", "mruby-markdown")
  conf.gem git: "https://github.com/mrbgemz/mruby-markdown" , branch: "main"

  #conf.gem File.realpath File.join(__dir__, "..", "mruby-llm")
  conf.gem git: "https://github.com/llmrb/mruby-llm"        , branch: "v0.1.0.beta.16"

  #conf.gem File.realpath File.join(__dir__, "..", "..", "0x1eef", "mruby-process")
  conf.gem github: "0x1eef/mruby-process", branch: "v0.2.0"

  #conf.gem File.realpath File.join(__dir__, "..", "..", "0x1eef", "mruby-command")
  conf.gem git: "https://github.com/0x1eef/mruby-command"   , branch: "v0.2.0.beta.2"

  conf.gem File.expand_path(__dir__)

  case profile
  when "test", "developer"
    conf.enable_debug
  when "production"
    conf.cc.flags << "-Os -ffunction-sections -fdata-sections -DNDEBUG"
    conf.linker.flags << "-Wl,--gc-sections"
  else
    raise ArgumentError, "unknown BUILD=#{profile.inspect}"
  end
end
