# frozen_string_literal: true

module Robert
  ##
  # The {Agent} class implements an agent
  # with a set of predefined tools and a
  # system prompt that is injected on the
  # first turn.
  class Agent < LLM::Agent
    instructions Robert.prompt
    tools { Robert.tools }
    confirm "read-file"

    attr_accessor :ui

    def queue
      stream.task_queue
    end

    def on_tool_confirmation(tool, strategy)
      raise "Agent UI is not configured" unless ui
      Widgets::Confirmation.new(ui, tool).confirm(strategy)
    end
  end
end
