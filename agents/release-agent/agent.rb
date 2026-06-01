
##
# Tools

class ReadFile < LLM::Tool
  name "read-file"
  description "Reads a file"
  parameter :path, String, "The path to a file"
  parameter :limit, Integer, "The maximum number of characters to read"
  required %i[path]

  def call(path:, limit: nil)
    if limit.nil?
      {contents: File.read(path)}
    else
      {contents: File.read(path)[0..limit]}
    end
  end
end

class ReplaceInFile < LLM::Tool
  name "replace-in-file"
  description "Perform an in-place substitution on a file"
  parameter :path, String, "The path to a file"
  parameter :str1, String, "The string to replace"
  parameter :str2, String, "The replacement string"
  required %i[path str1 str2]

  def call(path:, str1:, str2:)
    contents = File.read(path)
    File.open(path, "w+") { |f| f.write contents.gsub!(str1, str2) }
    {contents:}
  end
end

class Git < LLM::Tool
  name "git"
  description "Provides an interface to the git command"
  parameter :argv, Array[String], "The argument given to 'git'"
  required %i[argv]

  def call(argv:)
    {stdout: spawn(argv).stdout}
  end

  private

  def spawn(argv)
    Command.new("git")
      .argv(*argv)
      .stdout
  end
end

##
# stream
class Stream < LLM::Stream
  def on_content(content)
    $stdout << content
  end

  def on_tool_call(tool, error)
    $stdout << ["[tool call]", tool.name, "\n"].join(" ")
  end

  def on_tool_return(tool, result)
    $stdout << ["[tool return]", tool.name, "\n"].join(" ")
  end
end

##
# main

llm = LLM.deepseek(key: ENV["DEEPSEEK_SECRET"])
agent = LLM::Agent.new(
  llm,
  stream: Stream.new,
  skills: [File.join(Dir.pwd, "skills", "release-agent")],
  tools: [ReadFile, ReplaceInFile, Git]
)
agent.talk("Release v0.8.0!")
