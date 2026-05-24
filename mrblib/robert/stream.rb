# frozen_string_literal: true

module Robert
  ##
  # The {Stream} class implements a stream object
  # that wraps a UI tree, and controls the UI through
  # it.
  class Stream < LLM::Stream
    ##
    # @param [LLM::Object] ui
    # @return [Casper::Stream]
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
      tools << tool_entry(tool)
      render_assistant
      redraw!
    end

    ##
    # @param [LLM::Tool] tool
    # @param [LLM::Function::Return]
    # @return [void]
    def on_tool_return(tool, result)
      update_tool(tool, result)
      if result.error?
        status_bar.left = "Tool failed"
        status_bar.right = "#{tool_return_name(tool, result)}: #{result.value.inspect}"
        render_assistant
        redraw!
      else
        status_bar.left = "Thinking..."
        status_bar.right = ""
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

    def tool_entry(tool)
      {
        id: tool_id(tool),
        label: tool_running_label(tool),
        done_label: tool_finished_label(tool, nil),
      }
    end

    def tool_id(tool)
      tool.id || tool.object_id
    end

    def tool_return_id(tool, result)
      result.id || tool&.id || tool&.object_id
    end

    def tool_return_name(tool, result)
      tool&.name || result.name
    end

    def tool_running_label(tool)
      arguments = tool_arguments(tool)
      case tool.name
      when "man-search"
        "• Search man page database: #{format_keywords(argument(arguments, :keywords))}"
      when "man-page"
        "• Read man page: #{format_page(arguments)}"
      else
        "• #{tool.name}"
      end
    end

    def update_tool(tool, result)
      index = tools.index { _1[:id] == tool_return_id(tool, result) }
      return unless index
      tools[index] = {
        id: tools[index][:id],
        label: tools[index][:done_label],
        done_label: tools[index][:done_label],
      }
    end

    def tool_finished_label(tool, result)
      arguments = tool_arguments(tool)
      case tool_return_name(tool, result)
      when "man-search"
        "• Search man page database: #{format_keywords(argument(arguments, :keywords))}"
      when "man-page"
        "• Read man page: #{format_page(arguments)}"
      else
        "• #{tool_return_name(tool, result)}"
      end
    end

    def tool_arguments(tool)
      tool&.arguments || {}
    end

    def argument(arguments, key)
      arguments[key] || arguments[key.to_s]
    end

    def format_keywords(keywords)
      [*keywords].join(", ")
    end

    def format_page(arguments)
      name = argument(arguments, :name)
      section = argument(arguments, :section)
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

    def status_bar
      ui.status
    end
  end
end
