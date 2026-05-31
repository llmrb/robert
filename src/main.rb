# frozen_string_literal: true

def main(argv)
  while option = argv.shift
    case option
    when '-v'
      puts Robert::VERSION
      exit(0)
    when '-d'
      $DEBUG = true
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
      TUI.draw(ui.root)
      catch(:breakout) do
        loop { tick(dispatch, ui) }
      end
      Robert.debug "Robert has exited"
    end
  rescue => err
    Robert.debug "Robert has crashed"
    crash(err)
  end
  Task.run
end

def tick(dispatch, ui)
  scrolled = false
  events, scroll_events, dropped_scroll_events = 0, 0, 0
  64.times do
    event = TUI.peek_event(0)
    break unless event
    events += 1
    if event.key?(:UP) || event.key?(:DOWN)
      scroll_events += 1
      next if scrolled
      scrolled = true
    end
    dispatch.on_event(event)
  end
  if events > 0
    dropped_scroll_events = scroll_events - (scrolled ? 1 : 0)
    Robert.debug "Event loop drained #{events} terminal events. " \
                 "#{scroll_events} were scroll events; " \
                 "#{dropped_scroll_events} duplicate scroll events " \
                 "were ignored for this frame."
  end
  dispatch.tick(ui)
  Task.pass
  sleep_ms 5
end

def crash(err)
  puts "#{err.class}: #{err.message}"
  err.backtrace.each { puts _1 }
  exit 1
end

main(ARGV)
