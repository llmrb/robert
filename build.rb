MRuby::Build.new("robert") do |conf|
  profile = ENV["BUILD"] || "test"
  curldir = File.expand_path(ENV["CURLDIR"] || "/usr/local")
  static = ENV["STATIC"] == "1"

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
  conf.gem git: "https://github.com/mrbgemz/mruby-tui"      , branch: "v0.3.0"
  conf.gem git: "https://github.com/mrbgemz/mruby-tui-chat" , branch: "main"
  conf.gem git: "https://github.com/mrbgemz/mruby-markdown" , branch: "main"
  conf.gem git: "https://github.com/llmrb/mruby-llm"        , branch: "v0.1.0.beta.5"
  conf.gem git: "https://github.com/0x1eef/mruby-command"   , branch: "main"
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
