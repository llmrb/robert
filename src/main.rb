# frozen_string_literal: true

def main(argv)
  while option = argv.shift
    case option
    when '-v'
      puts Robert::VERSION
      exit(0)
    when '-d'
      $DEBUG = true
    when '-h'
      $stderr.puts <<~USAGE
      robert [OPTIONS]

      Options:
        -h  Show help
        -v  Show version
        -d  Enable debug mode
      USAGE
      exit(0)
    else
      $stderr.puts "robert: bad option #{option}"
      exit(1)
    end
  end

  Robert.debug "A new session of Robert has started"
  llm       = LLM.deepseek(key: ENV["DEEPSEEK_SECRET"])
  ui        = Robert::Tree.build(llm)
  ui.stream = Robert::Stream.new Task::Queue.new
  agent     = Robert::Agent.new(llm, stream: ui.stream)
  agent.ui  = ui
  dispatch  = Robert::Dispatch.new(LLM::Object.from(llm:, agent:, ui: agent.ui))

  Task.new(name: "event-loop") do
    TUI.run(ui.root) do
      Robert.set_theme
      TUI.draw(ui.root)
      catch(:breakout) do
        loop { tick(dispatch, ui) }
      end
      Robert.unset_theme
      Robert.debug "Robert has exited"
    end
  rescue => err
    Robert.unset_theme
    Robert.debug "Robert has crashed"
    crash(err)
  end
  Task.run
end

def tick(dispatch, ui)
  event = TUI.peek_event(5)
  dispatch.on_event(event) if event
  dispatch.tick(ui)
  Task.pass
end

def crash(err)
  puts "#{err.class}: #{err.message}"
  err.backtrace.each { puts _1 }
  exit 1
end

main(ARGV)
