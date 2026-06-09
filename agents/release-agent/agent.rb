
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
    raise "search string is empty" if str1.empty?
    contents = File.read(path)
    matches = contents.scan(str1).length
    raise "search string not found in #{path}" if matches == 0
    updated = contents.sub(str1, str2)
    raise "replacement produced no change in #{path}" if updated == contents
    raise "replacement would empty #{path}" if !contents.empty? && updated.empty?
    File.open(path, "w") { |f| f.write(updated) }
    {contents: updated, replacements: 1}
  end
end

class GitLog < LLM::Tool
  name "git-log"
  description "Provides access to the repository's recent commit history"

  def call
    {stdout: command.stdout}
  end

  private

  def command
    Command.new("git", "log", "-n", "30")
  end
end

class GitTag < LLM::Tool
  name "git-tag"
  description "Provides access to the repository's git tags"

  def call
    {stdout: command.stdout}
  end

  private

  def command
    Command.new("git", "tag")
  end
end

class GitShow < LLM::Tool
  name "git-show"
  description "Provides the contents of a commit"
  parameter :ref, String, "The git ref"
  required %i[ref]

  def call(ref:)
    {stdout: command(ref:).stdout}
  end

  private

  def command(ref:)
    Command.new("git", "show", ref)
  end
end

##
# stream

class Stream < LLM::Stream
  def on_content(content)
    $stdout << content
  end

  def on_tool_call(tool, error)
    $stdout << ["tool call", tool.name, "\n"].join(" ")
  end

  def on_tool_return(tool, result)
    $stdout << ["tool return:", tool.name, "\n"].join(" ")
  end
end

##
# main

dir = File.dirname(__FILE__)
llm = LLM.deepseek(key: ENV["DEEPSEEK_SECRET"])
agent = LLM::Agent.new(llm, stream: Stream.new, skills: [dir])

print "Enter version: "
ver = $stdin.gets.chomp
puts "Does #{ver} look right to you?"
print "answer (yes/no): "
loop do
  reply = $stdin.gets.chomp
  if reply.to_s.downcase[0] == 'y'
    agent.talk("Release #{ver}!")
    break
  elsif reply.to_s.downcase[0] == 'n'
    puts "Release aborted"
    break
  else
    print "answer (yes/no): "
  end
end
