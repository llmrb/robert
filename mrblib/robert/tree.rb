# frozen_string_literal: true

module Robert
  ##
  # The {Tree} module builds the UI tree when the
  # application boots.
  #
  # Layout:
  #
  #   VBox root
  #   ├── HBox body (flex)
  #   │   ├── Fill
  #   │   ├── Chat
  #   │   └── Fill
  #   ├── StatusBar (height: 1)
  #   └── TextArea (height: 5)
  module Tree
    HINTS = "\u2191\u2193 scroll \u00b7 Ctrl+D exit"
    CANCEL_HINT = "Ctrl+C to cancel"

    extend self

    ##
    # @return [LLM::Object]
    #  Returns a UI tree
    def build(llm)
      ui = LLM::Object.from({})
      ui.root = TUI::VBox.new
      ui.body = TUI::HBox.new
      ui.left_fill = fill(width: 0.2)
      ui.center = Widgets::Pane.new(width: 0.6)
      ui.chat = chat
      ui.banner = banner
      ui.right_fill = fill(width: 0.2)
      ui.status = status_bar(llm)
      ui.input = TUI::TextArea.new(height: 5, fg: Theme::FG_MUTED, bg: Theme::BG_DEFAULT)
      ui.center.show(ui.banner)
      ui.body.add(ui.left_fill)
      ui.body.add(ui.center)
      ui.body.add(ui.right_fill)
      ui.root.add(ui.body)
      ui.root.add(ui.status)
      ui.root.add(ui.input)
      ui
    end

    private

    def fill(width:)
      TUI::Fill.new(width:, fg: Theme::FG_MUTED, bg: Theme::BG_DEFAULT)
    end

    def chat
      TUI::Chat.new(
        roles: true,
        assistant_fg: Theme::FG_PRIMARY,
        text_fg: Theme::FG_SECONDARY,
        bg: Theme::BG_DEFAULT,
        labels: {user: "You", assistant: "Robert"}
      )
    end

    def banner
      Widgets::Splash.new(
        "FreeBSD Tip:",
        Robert.boot_message,
        fg: Theme::FG_SECONDARY,
        bg: Theme::BG_DEFAULT
      )
    end

    ##
    # @api private
    def status_bar(llm)
      TUI::StatusBar.new(
        llm ? "Idle" : "No LLM configured",
        right: llm.key? ? HINTS : "set DEEPSEEK_SECRET",
        fg: Theme::FG_SECONDARY,
        bg: Theme::BG_DEFAULT
      )
    end
  end
end
