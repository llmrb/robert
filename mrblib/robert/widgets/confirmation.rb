# frozen_string_literal: true

module Robert::Widgets
  ##
  # {Confirmation} renders an inline status-bar confirmation prompt.
  class Confirmation
    ##
    # @param [LLM::Object] ui
    # @param [LLM::Function] tool
    def initialize(ui, tool)
      @ui = ui
      @tool = tool
    end

    ##
    # Prompt for confirmation and resolve the tool call.
    #
    # @param [Symbol] strategy
    # @return [LLM::Function::Return]
    def confirm(strategy)
      previous_left = status_bar.left
      previous_right = status_bar.right
      status_bar.left = prompt
      status_bar.right = "[Enter/y] allow [n/Esc] deny"
      redraw!
      loop do
        event = TUI.read_event
        if event.key?(:CTRL_C)
          throw(:breakout)
        elsif event.key?(:ESC) || event.ch == ?n.ord || event.ch == ?N.ord
          result = tool.cancel(reason: "user denied tool execution")
          finish(tool, result, previous_left, previous_right)
          return result
        elsif event.key?(:ENTER) || event.ch == ?y.ord || event.ch == ?Y.ord
          result = tool.spawn(strategy).wait
          finish(tool, result, "Thinking...", "")
          return result
        elsif event.event?(:RESIZE)
          redraw!
        end
      end
    end

    private

    attr_reader :ui, :tool

    def finish(tool, result, left, right)
      ui.stream&.on_tool_return(tool, result) if ui.respond_to?(:stream)
      status_bar.left = left
      status_bar.right = right
      redraw!
    end

    def prompt
      case tool.name
      when "read-file"
        "Allow robert to read #{argument(:path)}?"
      else
        "Allow robert to run #{tool.name}?"
      end
    end

    def argument(key)
      arguments = tool.arguments || {}
      arguments[key] || arguments[key.to_s] || "(unknown)"
    end

    def redraw!
      TUI.draw(ui.root)
    end

    def status_bar
      ui.status
    end
  end
end
