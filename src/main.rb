# frozen_string_literal: true

##
# Event loop latency/CPU balance.
#
# Higher = fewer wakeups and less SSH/terminal churn
# Lower  = slightly faster reaction to input and stream updates
INPUT_POLL_MS = 20

##
# Limit one delayed terminal burst so scroll/key-repeat input cannot monopolize
# the loop before stream output and redraw throttles get a turn.
MAX_PEEK_EVENTS = 64

def main(argv)
  while option = argv.shift
    case option
    when '-v'
      puts Robert::VERSION
      exit(0)
    when '-d'
      $DEBUG = true
    when '-x'
      Robert.disable_confirmations!
    when '-h'
      $stderr.puts <<~USAGE
      robert [OPTIONS]

      Options:
        -h  Show help
        -v  Show version
        -d  Enable debug mode
        -x  Allow tools to run without confirmation
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

  TUI.run(ui.root) do
    Robert.set_theme
    begin
      TUI.draw(ui.root)
      reason = catch(:breakout) do
        while true
          tick(dispatch, ui)
        end
      end
      Robert.debug "Robert has exited: '#{reason}'"
    ensure
      Robert.unset_theme
    end
  end
rescue => err
  Robert.debug "Robert has crashed"
  crash(err)
end

def tick(dispatch, ui)
  event = TUI.peek_event(INPUT_POLL_MS)
  dispatch.on_peek peek_ahead(event) if event
  Task.pass
  dispatch.tick(ui)
  dispatch.refresh
end

def peek_ahead(event)
  events = [event]
  while events.length < MAX_PEEK_EVENTS and (event = TUI.peek_event(0))
    events << event
  end
  events
end

def crash(err)
  puts "#{err.class}: #{err.message}"
  err.backtrace.each { puts _1 }
  exit 1
end

main(ARGV)
