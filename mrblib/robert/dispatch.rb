# frozen_string_literal: true

module Robert
  class Dispatch
    include Debug
    include Scroll

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
      @scroll_delta = 0
      @last_idle_refresh = Time.now.to_f
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
        scroll_later(1)
      elsif event.key?(:DOWN)
        scroll_later(-1)
      elsif event.key?(:PGUP)
        scroll_page_later(ui.chat.rh / 2)
      elsif event.key?(:PGDN)
        scroll_page_later(-(ui.chat.rh / 2))
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
      requires_redraw = false
      requires_redraw = apply_scroll if @scroll_delta != 0
      events = 0
      while event = pop
        events += 1
        requires_redraw = true
        kind, data = event
        Robert.debug "Assistant stream produced a #{kind.inspect} event with #{debug_event_size(data)} bytes/items."
        case kind
        when "content"
          @buffer << data
          ui.chat.append(:assistant, assistant_text)
          follow!
        when "tool_call"
          @labels << tool_running_label(data)
          ui.chat.replace_last(:assistant, assistant_text)
          follow!
        when "tool_return"
          @labels << tool_finished_label(data)
          ui.chat.replace_last(:assistant, assistant_text)
          follow!
        when "confirmation"
          @confirmation = data
          ui.status.left = data.prompt
          ui.status.right = data.hint
        when "confirmation_done"
          @confirmation = nil
          ui.status.left = "Thinking..."
          ui.status.right = Tree::CANCEL_HINT
        when "done"
          ui.status.left = "Idle"
          ui.status.right = Tree::HINTS
        when "cancel"
          ui.status.left = "Cancelled"
          ui.status.right = Tree::HINTS
        when "error"
          err = data
          ui.status.left = "Error"
          ui.chat.replace_last(:assistant, "#{err.class}: #{err.message}")
          follow!
        end
      end
      if task&.status == :DORMANT
        Robert.debug "Assistant task is dormant; clearing the active task reference."
        @task = nil
      end
      if requires_redraw
        Robert.debug "Redrawing UI after processing #{events} assistant stream events."
        TUI.draw(ui.root)
      end
    end

    ##
    # Periodically redraw while idle.
    #
    # Some terminals can lose their visible alternate-screen contents when
    # switching windows or sessions. A lightweight redraw lets Robert recover
    # without waiting for the next key press.
    #
    # @return [void]
    def refresh
      return if task || ui.busy
      now = Time.now.to_f
      return if now - @last_idle_refresh < 1.0
      @last_idle_refresh = now
      Robert.debug "Refreshing idle UI."
      TUI.draw(ui.root)
    end

    private

    attr_reader :llm, :agent, :task, :ui, :confirmation

    ##
    # Render the accumulated assistant stream as markdown.
    # @return [TUI::Markdown::Node]
    def assistant_text
      Markdown.new([@labels.join("\n"), "\n", @buffer].join("\n")).ast
    end

    ##
    # Pop the next pending stream event without blocking.
    # @return [Array(String, Object), nil]
    def pop
      agent.queue.pop(true)
    rescue Task::Error
      nil
    end

    ##
    # Route keyboard input to the active tool confirmation prompt.
    # @param [Termbox2::Event<Robert::Event>] event
    # @return [void]
    def on_confirmation_event(event)
      if event.key?(:CTRL_C) || event.key?(:ESC) || event.ch == ?n.ord || event.ch == ?N.ord
        confirmation.deny
      elsif event.key?(:ENTER) || event.ch == ?y.ord || event.ch == ?Y.ord
        confirmation.allow
      elsif event.event?(:RESIZE)
        redraw!
      end
    end

    ##
    # Submit the input buffer and start an assistant task.
    # @param [Termbox2::Event<Robert::Event>] _event
    # @return [void]
    def on_submit(_event)
      return if ui.input.empty? || ui.busy
      @buffer, @labels = +"", []
      talk, msg, _agent, _ui = method(:talk), ui.input.value, agent, ui
      Robert.debug "Submitting user message with #{msg.length} characters."
      ui.busy = true
      ui.center.show(ui.chat) unless showing_chat?
      ui.input.clear
      ui.chat.add(:user, msg)
      ui.chat.add(:assistant, "")
      follow!
      ui.status.left = "Thinking..."
      ui.status.right = Tree::CANCEL_HINT
      @task = Task.new(name: "agent") { talk.(msg, _agent, _ui) }
      TUI.draw(ui.root)
    end

    ##
    # Run the assistant turn in a task and report completion back to the UI queue.
    # @param [String] msg
    # @param [Robert::Agent] agent
    # @param [LLM::Object] ui
    # @return [void]
    def talk(msg, agent, ui)
      agent.talk(msg)
      agent.queue.push ["done", nil]
    rescue LLM::Interrupt
      agent.queue.push ["cancel", nil]
    rescue => err
      agent.queue.push ["error", err]
    ensure
      ui.busy = false
    end

    ##
    # Stop a running task and clear the active task reference.
    # @param [Task] task
    # @return [void]
    def terminate(task)
      task.terminate
    rescue
      nil
    ensure
      @task = nil
    end

    ##
    # Build the status label shown while a tool is running.
    # @param [LLM::Function] fn
    # @return [String]
    def tool_running_label(fn)
      case fn.name
      when "find"
        "• find #{fn.arguments.root} -name #{fn.arguments.name}"
      when "man-search"
        "• Searching man page database: #{fn.arguments.keywords.join(", ")}"
      when "man-page"
        page = fn.arguments.name
        page = "#{page}(#{fn.arguments.section})" if fn.arguments.section
        "• Reading man page: #{page}"
      else
        "• call: #{fn.name}"
      end
    end

    ##
    # Build the status label shown after a tool returns.
    # @param [LLM::Function] fn
    # @return [String]
    def tool_finished_label(fn)
      case fn.name
      when "find"
        "• find complete"
      when "man-search"
        "• Search complete (#{fn.arguments.keywords.join(", ")})"
      when "man-page"
        page = fn.arguments.name
        page = "#{page}(#{fn.arguments.section})" if fn.arguments.section
        "• Read man page: #{page}"
      else
        "• done: #{fn.name}"
      end
    end

    ##
    # Interrupt the active assistant request, falling back to task termination.
    # @return [void]
    def interrupt
      agent.interrupt!
    rescue
      terminate(task)
    end

    ##
    # Redraw the current UI tree.
    # @return [void]
    def redraw!
      TUI.draw(ui.root)
    end

    ##
    # Returns true when the chat widget is visible in the center pane.
    # @return [Boolean]
    def showing_chat?
      ui.chat.parent == ui.center
    end
  end
end
