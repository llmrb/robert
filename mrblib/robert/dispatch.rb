# frozen_string_literal: true

module Robert
  class Dispatch
    ##
    # @param [LLM::Object] context
    # @return [Robert::Dispatch]
    def initialize(context)
      @ui = context.ui
      @llm = context.llm
      @agent = context.agent
    end

    ##
    # @param [Termbox2::Event<TUI::Event>] event
    # @return [void]
    def on_event(event)
      if event.key?(:CTRL_C) || event.key?(:ESC)
        throw(:breakout)
      elsif event.key?(:ENTER)
        on_submit(event)
        redraw!
      elsif TUI.backspace?(event.key)
        ui.input.backspace
      elsif event.key?(:UP)
        ui.chat.scroll_up
      elsif event.key?(:DOWN)
        ui.chat.scroll_down
      elsif event.ch == 0x15
        ui.input.clear
      elsif event.ch >= 0x20 && event.ch <= 0x7E
        ui.input.put(event.ch.chr)
      elsif event.event?(:RESIZE)
        redraw!
      end
    end

    private

    attr_reader :llm, :agent, :ui

    def on_submit(_event)
      return if ui.input.empty?
      message = ui.input.value
      ui.center.show(ui.chat) unless showing_chat?
      agent.stream.clear
      ui.input.clear
      ui.chat.add(:user, message)
      ui.chat.add(:assistant, "")
      status_bar.left = "Thinking..."
      status_bar.right = ""
      redraw!
      talk(message)
    end

    def talk(prompt)
      agent.talk(prompt)
      status_bar.left = "Idle"
      status_bar.right = ""
    rescue => ex
      ui.chat.replace_last(:assistant, "Error: #{ex.class}: #{ex.message}")
      status_bar.left = "Request failed"
      status_bar.right = ex.class.to_s
    end

    def status_bar
      ui.status
    end

    def redraw!
      TUI.draw(ui.root)
    end

    def showing_chat?
      ui.chat.parent == ui.center
    end
  end
end
