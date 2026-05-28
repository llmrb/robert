MRuby::Build.new("robert") do |conf|
  conf.toolchain
  conf.linker.flags << '-lcurl -lmbedtls'
  conf.cc.include_paths << File.join("/usr/local", "include")
  conf.linker.library_paths << File.join("/usr/local", "lib")

  conf.gembox "default"
  conf.gem core: "mruby-task"
  conf.gem git: "https://github.com/mrbgemz/mruby-tui"      , branch: "main"
  conf.gem git: "https://github.com/mrbgemz/mruby-tui-chat" , branch: "main"
  conf.gem git: "https://github.com/mrbgemz/mruby-markdown" , branch: "main"
  conf.gem git: "https://github.com/llmrb/mruby-llm"        , branch: "v0.1.0.beta.2"
  conf.gem git: "https://github.com/0x1eef/mruby-command"   , branch: "main"
  conf.gem File.expand_path(__dir__)

  case ENV["BUILD"] || "test"
  when "test", "developer"
    conf.enable_debug
  when "production"
    conf.cc.flags << "-DNDEBUG"
  else
    raise ArgumentError, "unknown BUILD=#{profile.inspect}"
  end
end
