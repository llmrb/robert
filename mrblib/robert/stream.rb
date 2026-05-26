# frozen_string_literal: true

module Robert
  ##
  # The {Stream} class implements a stream object
  # that wraps a UI tree, and controls the UI through
  # it.
  class Stream < LLM::Stream
    ##
    # @param [LLM::Object] ui
    # @return [Robert::Stream]
    def initialize(ui)
      @tools = []
      @ui = ui
      @buffer = +""
    end

    ##
    # @param [String] chunk
    #  A chunk
    # @return [void]
    def on_content(chunk)
      buffer << chunk
      render_assistant
      ui.status.left = "Thinking..."
      redraw!
    end

    ##
    # @param [LLM::Tool, nil] tool
    # @param [LLM::Function::Return, nil]
    # @return [void]
    def on_tool_call(tool, error)
      return queue << error if error
      tools << {
        id: tool.id,
        label: tool_running_label(tool),
        done_label: tool_finished_label(tool, nil)
      }
      render_assistant
      redraw!
    end

    ##
    # @param [LLM::Tool] tool
    # @param [LLM::Function::Return]
    # @return [void]
    def on_tool_return(tool, result)
      index = tools.index { _1[:id] == tool.id }
      tools[index] = {
        id: tools[index][:id],
        label: tools[index][:done_label],
        done_label: tools[index][:done_label]
      }
      if result.error?
        ui.status.left = "Tool failed"
        ui.status.right = "#{tool.name}: #{result.value.inspect}"
        render_assistant
        redraw!
      else
        ui.status.left = "Thinking..."
        ui.status.right = ""
        render_assistant
        redraw!
      end
    end

    ##
    # Clear the buffer
    # @return [void]
    def clear
      @buffer = ""
      @tools  = []
    end

    private

    attr_reader :ui, :buffer, :tools

    def render_assistant
      ui.chat.replace_last(:assistant, Markdown.new(assistant_text.rstrip).ast)
    end

    def tool_running_label(tool)
      case tool.name
      when "man-search"
        "• Search man page database: #{format_keywords(tool.arguments)}"
      when "man-page"
        "• Read man page: #{format_page(tool.arguments)}"
      else
        "• #{tool.name}"
      end
    end

    def tool_finished_label(tool, result)
      case tool.name
      when "man-search"
        "• Search man page database: #{format_keywords(tool.arguments)}"
      when "man-page"
        "• Read man page: #{format_page(tool.arguments)}"
      else
        "• #{tool.name}"
      end
    end

    def format_keywords(arguments)
      [*arguments.keywords].join(", ")
    end

    def format_page(arguments)
      name, section = arguments.name, arguments.section
      return name.to_s if section.nil? || section.to_s.empty?
      "#{name}(#{section})"
    end

    def assistant_text
      [tool_history_text, buffer].reject(&:empty?).join("\n\n")
    end

    def tool_history_text
      return "" if tools.empty?
      tools.map { _1[:label] }.join("\n")
    end

    def redraw!
      TUI.draw(ui.root)
    end
  end
end
