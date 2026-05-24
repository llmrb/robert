# frozen_string_literal: true

def main(argv)
  llm      = LLM.deepseek(key: ENV["DEEPSEEK_SECRET"])
  ui       = Robert::Tree.build(llm)
  stream   = Robert::Stream.new(ui)
  ui.stream = stream
  agent    = Robert::Agent.new(llm, stream:)
  agent.ui = ui
  dispatch = Robert::Dispatch.new(LLM::Object.from(llm:, agent:, ui:))

  TUI.run(ui.root) do
    catch(:breakout) do
      loop do
        TUI.draw(ui.root)
        dispatch.on_event(TUI.read_event)
      end
    end
  end
end
main(ARGV)
