# frozen_string_literal: true

module Robert
  class Dispatch
    include Debug
    include Scroll

    ##
    # Maximum live markdown renders per second while a response streams.
    # Higher = smoother streaming
    # Lower  = less CPU usage
    FPS = 10

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
      @defer_redraw = false
      @needs_redraw = false
      @changed = false
      @last_render = 0.0
      @streaming = false
    end

    ##
    # Process a burst of terminal events and repaint once.
    #
    # Pasted input can arrive as hundreds of printable key events already
    # queued by the terminal. Running the normal key path for each event keeps
    # editing semantics intact, but deferring repaint avoids one full redraw per
    # pasted character.
    #
    # @param [Array<Termbox2::Event<Robert::Event>>] events
    # @return [void]
    def on_peek(events)
      return if events.empty?
      @defer_redraw = true
      events.each { on_event(_1) }
    ensure
      @defer_redraw = false
      if @needs_redraw
        @needs_redraw = false
        TUI.draw(ui.root)
      end
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
        Robert.debug "Exiting on Ctrl+D event type=#{event.type} key=#{event.key} ch=#{event.ch} mod=#{event.mod}."
        throw(:breakout, :ctrl_d)
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
      elsif input?(event)
        before = ui.input.value.length
        ui.input.put(event.ch.chr)
        Robert.debug "Input: accepted event type=#{event.type} " \
                     "key=#{event.key} ch=#{event.ch} mod=#{event.mod}; " \
                     "length #{before}->#{ui.input.value.length}."
        redraw!
      elsif printable?(event)
        Robert.debug "Input: ignored printable event type=#{event.type} " \
                     "key=#{event.key} ch=#{event.ch} mod=#{event.mod}; " \
                     "length #{ui.input.value.length}."
      elsif event.event?(:RESIZE)
        redraw!
      end
    end

    ##
    # @param [LLM::Object] ui
    # @return [void]
    def tick(ui)
      requires_redraw = false
      scroll_redraw = false
      if @scroll_delta != 0
        apply_scroll
        scroll_redraw = true
      end
      events = 0
      while event = pop
        events += 1
        kind, data = event
        Robert.debug "Assistant stream produced a #{kind.inspect} event with #{debug_event_size(data)} bytes/items."
        case kind
        when "content"
          @buffer << data
          @changed = true
        when "tool_call"
          @labels << tool_running_label(data)
          ui.chat.replace_last(:assistant, assistant_text, follow: true)
          @changed = false
          @last_render = Time.now.to_f
          requires_redraw = true
        when "tool_return"
          nil
        when "confirmation"
          @confirmation = data
          ui.status.left = data.prompt
          ui.status.right = data.hint
          requires_redraw = true
        when "confirmation_done"
          @confirmation = nil
          ui.status.left = "Thinking..."
          ui.status.right = Tree::CANCEL_HINT
          requires_redraw = true
        when "done"
          requires_redraw = flush(ui, true) || requires_redraw
          @streaming = false
          ui.status.left = "Idle"
          ui.status.right = Tree::HINTS
          requires_redraw = true
        when "cancel"
          requires_redraw = flush(ui, true) || requires_redraw
          @streaming = false
          ui.status.left = "Cancelled"
          ui.status.right = Tree::HINTS
          requires_redraw = true
        when "error"
          @streaming = false
          @changed = false
          err = data
          ui.status.left = "Error"
          ui.chat.replace_last(:assistant, "#{err.class}: #{err.message} #{err.backtrace.join("\n")}")
          requires_redraw = true
        end
      end
      requires_redraw = flush(ui) || requires_redraw
      if task&.status == :DORMANT
        Robert.debug "Assistant task is dormant; clearing the active task reference."
        @task = nil
      end
      if requires_redraw
        Robert.debug "Redrawing UI after processing #{events} assistant stream events."
        TUI.draw(ui.root)
      elsif scroll_redraw
        redraw_chat!
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
    # Render accumulated stream content at a bounded rate.
    #
    # Providers often deliver very small chunks. Parsing markdown, invalidating
    # chat layout, and repainting for every chunk can saturate a CPU while the
    # model is streaming. Keep all chunks, but update the UI at most ~10 times
    # per second unless a state transition needs an immediate flush.
    #
    # @param [LLM::Object] ui
    # @param [Boolean] force
    # @return [Boolean]
    def flush(ui, force = false)
      return false unless @changed
      now = Time.now.to_f
      return false if !force && (now - @last_render) < (1.0 / FPS)
      ui.chat.replace_last(:assistant, assistant_text)
      @changed = false
      @last_render = now
      true
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
      @streaming = true
      ui.status.left = "Thinking..."
      ui.status.right = Tree::CANCEL_HINT
      @task = Task.new(name: "agent") { talk.(msg, _agent, _ui) }
      redraw!
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
      when /^search-([a-zA-Z]+)-handbook$/
        "• Search the FreeBSD #{$1} handbook: #{fn.arguments.q}"
      when "version"
        "• Discovering Robert's version"
      when "read-package"
        "• Read package metadata: #{fn.arguments.name}"
      when "find-package"
        "• Search package database: #{fn.arguments.query}"
      when "find-port"
        "• Search ports tree: #{fn.arguments.name}"
      when "read-port"
        "• Read port metadata: #{fn.arguments.category}/#{fn.arguments.name}"
      when "read-file"
        "• Read: #{fn.arguments.path}"
      when "find"
        "• find #{fn.arguments.root} -name #{fn.arguments.name} -maxdepth #{fn.arguments.maxdepth || 1}"
      when "grep"
        "• grep #{fn.arguments.string} #{fn.arguments.root}"
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
      if @defer_redraw
        @needs_redraw = true
        return
      end
      TUI.draw(ui.root)
    end

    ##
    # Redraw only the chat viewport after a scroll movement.
    #
    # The chat widget already keeps wrapped rows cached locally; scrolling only
    # changes the viewport offset. A full root redraw clears and repaints the
    # status/input chrome as well, which costs extra terminal output over SSH
    # and makes arrow-key scrolling feel laggy. Rendering just chat keeps the
    # existing terminal back buffer for the rest of the UI and flushes only the
    # viewport diff.
    #
    # @return [void]
    def redraw_chat!
      ui.chat.render
      TUI.present
    end

    ##
    # Returns true when the chat widget is visible in the center pane.
    # @return [Boolean]
    def showing_chat?
      ui.chat.parent == ui.center
    end

    ##
    # Returns true when an event can be written to the input area
    # @return [Boolean]
    def input?(event)
      printable?(event) && !scroll_noise?(event)
    end

    ##
    # Returns true when an event carries a printable ASCII character.
    # @return [Boolean]
    def printable?(event)
      event.ch >= 0x20 && event.ch <= 0x7E
    end
  end
end
