# frozen_string_literal: true

module Robert
  class Dispatch
    ##
    # @param [LLM::Object] context
    # @return [Robert::Dispatch]
    def initialize(context)
      @ui    = context.ui
      @llm   = context.llm
      @agent = context.agent
      @buffer = +""
      @last_event = 0.0
      @task = nil
      @confirmation = nil
      @labels = []
    end

    ##
    # @param [Termbox2::Event<Robert::Event>]
    # @return [void]
    def on_event(event)
      now = Time.now.to_f
      elapsed = now - @last_event
      @last_event = now
      if confirmation
        on_confirmation_event(event)
      elsif event.key?(:CTRL_C) and task
        interrupt
        ui.status.left = "Cancelled"
        ui.status.right = Tree::HINTS
        redraw!
      elsif event.key?(:CTRL_D)
        throw(:breakout)
      elsif event.key?(:ENTER) && elapsed < 0.05
        ui.input.put("\n")
        redraw!
      elsif event.key?(:ENTER)
        on_submit(event)
      elsif event.ch == 0x0A
        ui.input.put("\n")
        redraw!
      elsif TUI.backspace?(event.key)
        ui.input.backspace
        redraw!
      elsif event.key?(:UP)
        ui.chat.scroll_up
        redraw!
      elsif event.key?(:DOWN)
        ui.chat.scroll_down
        redraw!
      elsif event.ch == 0x15
        ui.input.clear
        redraw!
      elsif event.ch >= 0x20 && event.ch <= 0x7E
        ui.input.put(event.ch.chr)
        redraw!
      elsif event.event?(:RESIZE)
        redraw!
      end
    end

    ##
    # @param [LLM::Object] ui
    # @return [void]
    def tick(ui)
      while event = pop_event
        kind, data = event
        case kind
        when "content"
          @buffer << data
          ui.chat.append(:assistant, assistant_text)
        when "tool_call"
          @labels << tool_running_label(data)
          ui.chat.replace_last(:assistant, assistant_text)
        when "tool_return"
          @labels << tool_finished_label(data)
          ui.chat.replace_last(:assistant, assistant_text)
        when "confirmation"
          @confirmation = data
          ui.status.left = data.prompt
          ui.status.right = data.hint
        when "confirmation_done"
          @confirmation = nil
          ui.status.left = "Thinking..."
          ui.status.right = ""
        when "done"
          ui.status.left = "Idle"
          ui.status.right = Tree::HINTS
        when "cancel"
          ui.status.left = "Cancelled"
          return
        when "error"
          ui.chat.replace_last(:assistant, data)
        end
      end
      if task&.status == :DORMANT
        @task = nil
      end
      TUI.draw(ui.root)
    end

    private

    attr_reader :llm, :agent, :task, :ui, :confirmation

    def assistant_text
      Markdown.new([@labels.join("\n"), @buffer].join("\n")).ast
    end

    def pop_event
      agent.queue.pop(true)
    rescue Task::Error
      nil
    end

    def on_confirmation_event(event)
      if event.key?(:CTRL_C) || event.key?(:ESC) || event.ch == ?n.ord || event.ch == ?N.ord
        confirmation.deny
      elsif event.key?(:ENTER) || event.ch == ?y.ord || event.ch == ?Y.ord
        confirmation.allow
      elsif event.event?(:RESIZE)
        redraw!
      end
    end

    def on_submit(_event)
      return if ui.input.empty?
      @buffer = +""
      @labels = []
      message = ui.input.value
      ui.center.show(ui.chat) unless showing_chat?
      ui.input.clear
      ui.chat.add(:user, message)
      ui.chat.add(:assistant, "")
      ui.status.left = "Thinking..."
      ui.status.right = "Ctrl+C to cancel"
      _agent = agent
      @task = Task.new(name: "agent") do
        _agent.talk(message)
        _agent.queue.push ["done", nil]
      rescue LLM::Interrupt
        _agent.queue.push ["cancel", nil]
      rescue => e
        _agent.queue.push ["error", "error: #{e.class}: #{e.message}"]
      end
      TUI.draw(ui.root)
    end

    def terminate(task)
      task.terminate
    rescue
      nil
    ensure
      @task = nil
    end

    def tool_running_label(fn)
      case fn.name
      when "man-search"
        "• Search man page database: #{fn.arguments.keywords.join(", ")}"
      when "man-page"
        page = fn.arguments.name
        page = "#{page}(#{fn.arguments.section})" if fn.arguments.section
        "• Read man page: #{page}"
      else
        "• call: #{fn.name}"
      end
    end

    def tool_finished_label(fn)
      case fn.name
      when "man-search"
        "• Searched man page database (#{fn.arguments.join(", ")})"
      when "man-page"
        page = fn.arguments.name
        page = "#{page}(#{fn.arguments.section})" if fn.arguments.section
        "• Read man page: #{page}"
      else
        "• done: #{fn.name}"
      end
    end

    def interrupt
      agent.interrupt!
    rescue
      terminate(task)
    end

    def redraw!
      TUI.draw(ui.root)
    end

    def showing_chat?
      ui.chat.parent == ui.center
    end
  end
end
