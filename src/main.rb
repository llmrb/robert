# frozen_string_literal: true

def main(argv)
  while option = argv.shift
    case option
    when '-v'
      puts Robert::VERSION
      exit(0)
    else
      $stderr.puts "robert: bad option #{option}"
      exit(1)
    end
  end

  llm       = LLM.deepseek(key: ENV["DEEPSEEK_SECRET"])
  ui        = Robert::Tree.build(llm)
  ui.stream = Robert::Stream.new Task::Queue.new
  agent     = Robert::Agent.new(llm, stream: ui.stream)
  agent.ui  = ui
  dispatch  = Robert::Dispatch.new(LLM::Object.from(llm:, agent:, ui: agent.ui))

  Task.new(name: "event-loop") do
    TUI.run(ui.root) do
      TUI.draw(ui.root)
      catch(:breakout) do
        loop do
          if event = TUI.peek_event
            dispatch.on_event(event)
          end
          dispatch.tick(ui)
          Task.pass
          sleep_ms 25
        end
      end
    end
  rescue => err
    crash(err)
  end
  Task.run
end

def crash(err)
  puts "#{err.class}: #{err.message}"
  err.backtrace.each { puts _1 }
  exit 1
end

main(ARGV)
